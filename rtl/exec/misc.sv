`ifndef __MISC_SV__
`define __MISC_SV__

`include "types.sv"

module misc #(
) (
  decoupled.in decoded,
  output exec_result result,

  input clk,
  input rst
);

assign decoded.ready = '1;
logic invalid_priv;
logic default_ex_valid;
logic default_ret_valid;
ex_type default_ex;

assign result.ret_valid = default_ret_valid;
assign result.ex_valid = default_ex_valid || invalid_priv;
assign result.ex = invalid_priv ? EX_ILLEGAL_INSTR : default_ex;

always_comb begin
  result = 'X;
  result.rd_idx = decoded.data.rd;

  invalid_priv = '0;
  default_ex_valid = '0;
  default_ex = ex_type'('X);
  default_ret_valid = '0;

  unique case(decoded.data.op)
    INSTR_JALR: begin
      result.br_valid = '1;
      result.br_target = decoded.data.rs1_val + decoded.data.imm;
      result.rd_val = decoded.data.pc + 4; // TODO: C-extension warning
    end
    INSTR_LUI: begin
      result.br_valid = '0;
      result.rd_val = decoded.data.imm;
    end
    INSTR_INVAL: begin
      // TODO: Exception
    end
    INSTR_SYSTEM: begin
      if(decoded.data.imm[4:0] == 5'b0) begin
        // ECALL
        invalid_priv = decoded.data.imm[11:5] != 0;
        default_ex_valid = '1;
        default_ex = EX_M_ECALL;
      end else if(decoded.data.imm[4:0] == 5'b00001) begin
        // EBREAK
        invalid_priv = decoded.data.imm[11:5] != 0;
        default_ex_valid = '1;
        default_ex = EX_BREAKPOINT;
      end else if(decoded.data.imm[4:0] == 5'b00010) begin
        // xRET, only MRET is implemented
        invalid_priv = decoded.data.imm[11:5] != 7'b0011000;
        default_ret_valid = '1;
      end else invalid_priv = '1;
    end
  endcase
end

// Misc is fully combinatory
logic _unused = &{ clk, rst };

endmodule

`endif // __MISC_SV__
