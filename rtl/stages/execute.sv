`ifndef __EXECUTE_SV__
`define __EXECUTE_SV__

`include "types.sv"

`include "exec/alu.sv"
`include "exec/misc.sv"

module execute #(
) (
  decoupled.in decoded,
  decoupled.out result, // Unblockable

  input flush,

  input clk,
  input rst
);

always begin
  assert(result.ready);
end

decoupled #(.Data(decoded_instr)) misc_input;
decoupled #(.Data(decoded_instr)) alu_input;

exec_result misc_result;
exec_result alu_result;

assign misc_input.data = decoded.data;
assign alu_input.data = decoded.data;

/* Misc (LUI/JALR/Invalid) */
misc #() misc_inst (
  .decoded(misc_input),
  .result(misc_result),

  .flush, .clk, .rst
);

/* ALU */
alu #() alu_inst (
  .decoded(alu_input),
  .result(alu_result),

  .flush, .clk, .rst
);
// TODO: PCRel (AUIPC/B/JAL)
// TODO: Mem

/* Arbiter */

always_comb begin
  misc_input.valid = '0;
  alu_input.valid = '0;
  result.valid = '0;

  unique case(decoded.data.op)
    INSTR_INVAL, INSTR_JALR, INSTR_LUI: begin
      misc_input.valid = decoded.valid;
      decoded.ready = misc_input.ready;
      result.valid = misc_input.ready;
      result.data = misc_result;
    end
    INSTR_OP, INSTR_OP_IMM: begin
      alu_input.valid = decoded.valid;
      decoded.ready = alu_input.ready;
      result.valid = alu_input.ready;
      result.data = alu_result;
    end
  endcase
end

endmodule;

`endif // __EXECUTE_SV__
