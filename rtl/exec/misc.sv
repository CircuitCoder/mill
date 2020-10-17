`ifndef __MISC_SV__
`define __MISC_SV__

`include "types.sv"

module misc #(
) (
  decoupled.in decoded,
  exec_reult result,

  input flush,
  input clk,
  input rst
);

assign decoded.ready = result.ready;

always_comb begin
  result.rd = decoded.rd;
  unique case(decoded.data.op)
    INSTR_JALR: begin
      result.br_valid = '1;
      result.br_target = decoded.rs1_val + decoded.imm;
      result.rd_val = decoded.pc + 4; // TODO: C-extension warning
    end
    INSTR_LUI: begin
      result.br_valid = '0;
      result.rd_val = decoded.imm;
    end
    INSTR_INVAL: begin
      // TODO: Exception
      result.br_valid = '0;
      result.rd = '0;
    end
  endcase
end

endmodule;

`endif // __MISC_SV__
