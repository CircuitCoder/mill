`ifndef __EXECUTE_SV__
`define __EXECUTE_SV__

`include "types.sv"

`include "exec/alu.sv"
`include "exec/misc.sv"
`include "exec/pcrel.sv"
`include "exec/mem.sv"
`include "exec/csr.sv"

module execute #(
) (
  decoupled.in decoded,
  decoupled.out result, // Unblockable

  decoupled.out mem_req,
  decoupled.in mem_resp,

  decoupled.out csrfile_req,
  input csr_resp csrfile_resp,

  input clk,
  input rst
);

decoupled #(.Data(decoded_instr)) misc_input ();
decoupled #(.Data(decoded_instr)) alu_input ();
decoupled #(.Data(decoded_instr)) mem_input ();
decoupled #(.Data(decoded_instr)) pcrel_input ();
decoupled #(.Data(decoded_instr)) csr_input ();

exec_result misc_result;
exec_result alu_result;
exec_result mem_result;
exec_result pcrel_result;
exec_result csr_result;

assign misc_input.data = decoded.data;
assign alu_input.data = decoded.data;
assign mem_input.data = decoded.data;
assign pcrel_input.data = decoded.data;
assign csr_input.data = decoded.data;

/* Misc (LUI/JALR/Invalid) */
misc #() misc_inst (
  .decoded(misc_input),
  .result(misc_result),

  .clk, .rst
);

/* ALU */
alu #() alu_inst (
  .decoded(alu_input),
  .result(alu_result),

  .clk, .rst
);

/* PCRel (AUIPC/B/JAL) */
pcrel #() pcrel_inst (
  .decoded(pcrel_input),
  .result(pcrel_result),

  .clk, .rst
);

/* Mem */
mem #() mem_inst (
  .decoded(mem_input),
  .result(mem_result),

  .mem_req, .mem_resp,

  .clk, .rst
);

/* CSR */
csr #() csr_inst (
  .decoded(csr_input),
  .result(csr_result),

  .csrfile_req, .csrfile_resp,

  .clk, .rst
);

/* Arbiter */

always_comb begin
  misc_input.valid = '0;
  alu_input.valid = '0;
  mem_input.valid = '0;
  pcrel_input.valid = '0;
  csr_input.valid = '0;
  result.valid = '0;

  unique case(decoded.data.op)
    INSTR_INVAL, INSTR_JALR, INSTR_LUI, INSTR_MISC_MEM: begin
      misc_input.valid = decoded.valid;
      decoded.ready = misc_input.ready;
      result.valid = misc_input.ready && decoded.valid;
      result.data = misc_result;
    end
    INSTR_OP, INSTR_OP_IMM: begin
      alu_input.valid = decoded.valid;
      decoded.ready = alu_input.ready;
      result.valid = alu_input.ready && decoded.valid;
      result.data = alu_result;
    end
    INSTR_LOAD, INSTR_STORE: begin
      mem_input.valid = decoded.valid;
      decoded.ready = mem_input.ready;
      result.valid = mem_input.ready && decoded.valid;
      result.data = mem_result;
    end
    INSTR_BRANCH, INSTR_JAL, INSTR_AUIPC: begin
      pcrel_input.valid = decoded.valid;
      decoded.ready = pcrel_input.ready;
      result.valid = pcrel_input.ready && decoded.valid;
      result.data = pcrel_result;
    end
    INSTR_SYSTEM: begin
      if(decoded.data.funct3 != 3'b000) begin
        csr_input.valid = decoded.valid;
        decoded.ready = csr_input.ready;
        result.valid = csr_input.ready && decoded.valid;
        result.data = csr_result;
      end else begin
        misc_input.valid = decoded.valid;
        decoded.ready = misc_input.ready;
        result.valid = misc_input.ready && decoded.valid;
        result.data = misc_result;
      end
    end
  endcase
end

endmodule

`endif // __EXECUTE_SV__
