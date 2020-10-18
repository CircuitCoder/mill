`ifndef __MISC_SV__
`define __MISC_SV__

`include "types.sv"

module misc #(
) (
  decoupled.in decoded,
  output exec_result result,

  input flush,
  input clk,
  input rst
);

assign decoded.ready = '1;

always_comb begin
  result.rd_idx = decoded.data.rd;
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
    default: $error("Unexpected instruction op");
  endcase
end

// Misc is fully combinatory
logic _unused = &{ clk, rst, flush };

endmodule;

`endif // __MISC_SV__
