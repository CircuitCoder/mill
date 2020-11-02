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
gpreg default_ex_tval;

assign result.ret_valid = default_ret_valid;
assign result.ex_valid = default_ex_valid || invalid_priv;
assign result.ex = invalid_priv ? EX_ILLEGAL_INSTR : default_ex;
assign result.ex_tval = default_ex_tval;

gpreg jalr_dest_raw;
gpreg jalr_dest;
assign jalr_dest_raw = decoded.data.rs1_val + decoded.data.imm;
assign jalr_dest = { jalr_dest_raw[31:1], 1'b0 };

always_comb begin
  result.br_valid = '0;
  result.br_target = 'X;
  result.rd_idx = decoded.data.rd;
  result.rd_val = 'X;

  invalid_priv = '0;
  default_ex_valid = '0;
  default_ex = ex_type'('X);
  default_ret_valid = '0;
  default_ex_tval = 'X;

  unique case(decoded.data.op)
    INSTR_JALR: begin
      result.br_valid = '1;
      result.br_target = jalr_dest;
      result.rd_val = decoded.data.pc + 4; // TODO: C-extension warning

      if(jalr_dest[1:0] != '0) begin
        default_ex_valid = '1;
        default_ex = EX_INSTR_ADDR_MISALIGNED;
        default_ex_tval = jalr_dest;
      end
    end
    INSTR_MISC_MEM: begin
      // FENCE and FENCE.I, regard as no-op
      if(decoded.data.funct3 != '0 && decoded.data.funct3 != 3'b1) begin
        default_ex_valid = '1;
        default_ex = EX_ILLEGAL_INSTR;
      end
    end
    INSTR_LUI: begin
      result.br_valid = '0;
      result.rd_val = decoded.data.imm;
    end
    INSTR_INVAL: begin
      default_ex_valid = '1;
      default_ex = EX_ILLEGAL_INSTR;
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
logic _unused = &{ clk, rst, jalr_dest_raw[0] };

endmodule

`endif // __MISC_SV__
