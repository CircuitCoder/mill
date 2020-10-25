`ifndef __CSR_SV__
`define __CSR_SV__

`include "types.sv"

module csr #() (
  decoupled.out csrfile_req,
  input csr_resp csrfile_resp,

  decoupled.in decoded,
  output exec_result result,

  input clk,
  input rst
);

logic from_imm;
assign from_imm = decoded.data.funct3[2];

logic inval_funct3;
assign inval_funct3 = decoded.data.funct3[1:0] == 2'b00;

assign csrfile_req.data.a = decoded.data.imm[11:0];
assign csrfile_req.data.d = from_imm ? { 27'b0, decoded.data.rs1 } : decoded.data.rs1_val;
assign csrfile_req.data.t = decoded.data.funct3[1:0];

// Write check! We cannot write to xRO fields
logic is_dest_ro;
logic is_writing;
assign is_dest_ro = csrfile_req.data.a[11:10] == 2'b11;
assign is_writing = csrfile_req.data.d != '0;

logic inval_writing;
assign inval_writing = is_dest_ro && is_writing;

logic ex;
assign ex = inval_funct3 || inval_writing || !csrfile_resp.exists;

assign csrfile_req.valid = decoded.valid && !ex;
assign decoded.ready = csrfile_req.ready || ex;

// TODO: exception
assign result.rd_idx = decoded.data.rd;
assign result.rd_val = csrfile_resp.d;
assign result.br_valid = '0;
assign result.br_target = 'X;
assign result.ret_valid = '0;
assign result.ex_valid = '0;
assign result.ex = '0;
assign result.ex_tval = '0;

// TODO: flush pipeline

wire _unused = &{ clk, rst };

endmodule

`endif // __CSRFILE_SV__
