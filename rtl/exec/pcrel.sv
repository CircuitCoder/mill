`ifndef __PCREL_SV__
`define __PCREL_SV__

`include "types.sv"

module pcrel #(
) (
  decoupled.in decoded,
  output exec_result result,

  input clk,
  input rst
);

assign decoded.ready = '1;

addr rel;
assign rel = decoded.data.pc + decoded.data.imm;

logic branching;
logic inval_br_funct3;
gpreg lhs;
gpreg rhs;
assign lhs = decoded.data.rs1_val;
assign rhs = decoded.data.rs2_val;

always_comb begin
  inval_br_funct3 = '0;
  branching = 'X;

  unique case(decoded.data.funct3)
    3'b000: branching = lhs == rhs; // BEQ
    3'b001: branching = lhs != rhs; // BNE
    3'b100: branching = signed'(lhs) < signed'(rhs); // BLT
    3'b101: branching = signed'(lhs) >= signed'(rhs); // BGE
    3'b110: branching = lhs < rhs; // BLTU
    3'b111: branching = lhs >= rhs; // BGEU
    default: inval_br_funct3 = '1;
  endcase
end

assign result.rd_idx = decoded.data.rd;
assign result.br_target = rel;

logic inval_instr;
always_comb begin
  inval_instr = '0;
  unique case(decoded.data.op)
    INSTR_AUIPC: begin
      result.br_valid = '0;
      result.rd_val = rel;
    end
    INSTR_JAL: begin
      result.br_valid = '1;
      result.rd_val = decoded.data.pc + 4; // TODO: change me when adding C-ext
    end
    INSTR_BRANCH: begin
      result.br_valid = branching;
      result.rd_val = 'X;
      inval_instr = inval_br_funct3;
    end
  endcase
end

// TODO: inval instr
logic _unused_inval = inval_instr;

assign result.ret_valid = '0;
assign result.ex_valid = '0;
assign result.ex = '0;
assign result.ex_tval = '0;

// PCRel is fully combinatory
logic _unused = &{ clk, rst };

endmodule

`endif // __PCREL_SV__
