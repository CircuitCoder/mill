`ifndef __INSTR_DECODE_SV__
`define __INSTR_DECODE_SV__

`include "types.sv"

module instr_decode #(
) (
  decoupled.in fetched, // instr
  decoupled.out decoded, // decoded_instr

  output reg_idx rs_idx [2], // To regfile
  input gpreg rs_val [2], // From regfile
 
  input flush,

  input clk,
  input rst
);

// This stage is combinatory logic, hence no clocking signal is needed
logic _unused_signals = &{ flush, clk, rst };
decoded_instr result;
instr from;
assign from = fetched.data.raw;

assign decoded.data = result;
assign decoded.valid = fetched.valid;
assign fetched.ready = decoded.ready;

// Decode instr_type
instr_op result_op;
instr_fmt result_fmt;
always_comb begin
  // We don't have C-extension, hence:
  if(from[1:0] != 2'b11) begin
    result_op = INSTR_INVAL;
  end else begin
    unique case(from[6:2])
      5'b00000: begin
        result_op = INSTR_LOAD;
        result_fmt = INSTR_I;
      end
      5'b00011: begin
        result_op = INSTR_MISC_MEM;
        // We treat MISC-MEM instructions as if they are I-type instructions.
        // FENCE.I do have I-type, and we can retrieve flags from imm for FENCE.
        result_fmt = INSTR_I;
      end
      5'b00100: begin
        result_op = INSTR_OP_IMM;
        result_fmt = INSTR_I;
      end
      5'b00101: begin
        result_op = INSTR_AUIPC;
        result_fmt = INSTR_U;
      end

      5'b01000: begin
        result_op = INSTR_STORE;
        result_fmt = INSTR_S;
      end
      5'b01100: begin
        result_op = INSTR_OP;
        result_fmt = INSTR_R;
      end
      5'b01101: begin
        result_op = INSTR_LUI;
        result_fmt = INSTR_U;
      end

      5'b11000: begin
        result_op = INSTR_BRANCH;
        result_fmt = INSTR_B;
      end
      5'b11001: begin
        result_op = INSTR_JALR;
        result_fmt = INSTR_I;
      end
      5'b11011: begin
        result_op = INSTR_JAL;
        result_fmt = INSTR_J;
      end
      5'b11100: begin
        result_op = INSTR_SYSTEM;
        // Flags are in imm
        result_fmt = INSTR_I;
      end

      default: begin
        result_op = INSTR_INVAL;
      end
    endcase
  end
end
assign result.op = result_op;

// Decode rs1, rs2, rd
logic has_rs1, has_rs2, has_rd;
assign has_rs1 = result_fmt != INSTR_U && result_fmt != INSTR_J;
assign has_rs2 = result_fmt != INSTR_U && result_fmt != INSTR_J && result_fmt != INSTR_I;
assign has_rd = result_fmt != INSTR_S && result_fmt != INSTR_B;

// Prevents circular warning result -> regfile -> result
reg_idx rs1;
reg_idx rs2;
assign rs1 = has_rs1 ? from[19:15] : '0;
assign rs2 = has_rs2 ? from[24:20] : '0;

assign result.rs1 = rs1;
assign result.rs2 = rs2;
assign result.rd = has_rd ? from[11:7] : '0;

// Decode imm
logic sign_bit;
assign sign_bit = from[31];
always_comb begin // TODO: test does length mismatch triggers a warning?
  // We handle R-type instruction as if they are I-type. Then imm[11:4] = funct7
  unique case(result_fmt)
    INSTR_I, INSTR_R: result.imm = { {20{sign_bit}}, from[31:20] };
    INSTR_S: result.imm = { {20{sign_bit}}, from[31:25], from[11:7] };
    INSTR_B: result.imm = { {19{sign_bit}}, from[31], from[7], from[30:25], from[11:8], 1'b0 };
    INSTR_U: result.imm = { from[31:12], 12'b0 };
    INSTR_J: result.imm = { {11{sign_bit}}, from[31], from[19:12], from[20], from[30:21], 1'b0 };
  endcase
end

// Decode funct3
assign result.funct3 = from[14:12];

// Read rs
assign rs_idx [0] = rs1;
assign rs_idx [1] = rs2;

assign result.rs1_val = rs_val [0];
assign result.rs2_val = rs_val [1];

// Assign pc
assign result.pc = fetched.data.pc;

endmodule

`endif // __INSTR_DECODE_SV__
