`ifndef __ALU_SV__
`define __ALU_SV__

`include "types.sv"

module alu #(
) (
  decoupled.in decoded,
  output exec_result result,

  input flush,

  input clk,
  input rst
);

assign decoded.ready = '1;

logic [31:0] operand1 = decoded.data.rs1_val;
logic [31:0] operand2;

// Instruction is R-type or I-type, hence:
logic [2:0] funct3 = decoded.data.funct3;
logic [6:0] funct7 = decoded.data.imm[11:5];
logic funct7_action_bit = funct7[5];
logic inval_funct7;

always_comb begin
  unique case(decoded.data.op)
    INSTR_OP_IMM: begin
      operand2 = decoded.data.imm;
      unique case(funct3)
        3'b101: // SRxI
          inval_funct7 = funct7 != 7'b0000000 && funct7 != 7'b0100000;
        3'b001: // SLLI
          inval_funct7 = funct7 != 7'b0000000;
        default:
          inval_funct7 = '0;
      endcase
    end
    INSTR_OP: begin
      operand2 = decoded.data.rs2_val;
      unique case(funct3)
        3'b101, 3'b000: // SRx, ADD/SUB
          inval_funct7 = funct7 != 7'b0000000 && funct7 != 7'b0100000;
        default:
          inval_funct7 = funct7 != 7'b0000000;
      endcase
    end
  endcase
end

gpreg computation;

always_comb begin
  unique case(funct3)
    0'b000: // ADD/SUB
      computation = funct7_action_bit ? operand1 - operand2 : operand1 + operand2;
    0'b001: // SLL
      computation = operand1 << operand2[4:0];
    0'b010: // SLT
      computation = (signed'(operand1) < signed'(operand2)) ? '1 : '0;
    0'b011: // SLTU
      computation = (operand1 < operand2) ? '1 : '0;
    0'b100: // XOR
      computation = operand1 ^ operand2;
    0'b101: // SRL / SRA
      computation = funct7_action_bit ? (signed'(operand1) >>> operand2[4:0]) : (operand1 >> operand2[4:0]);
    0'b110: // OR
      computation = operand1 | operand2;
    0'b110: // AND
      computation = operand1 & operand2;
  endcase
end

// TODO: invalid instruction on invalid funct7
logic _unused_inval_funct7 = inval_funct7;

assign result.rd_idx = decoded.data.rd;
assign result.rd_val = computation;
assign result.br_valid = '0;
assign result.br_target = 'X;

// ALU is fully combinatory
logic _unused = &{ clk, rst, flush };

endmodule;

`endif // __ALU_SV__
