`ifndef __INSTR_FETCH_SV__
`define __INSTR_FETCH_SV__

`include "types.sv"
`include "utils/mem_arbiter.sv"

module instr_fetch #(
  parameter int MAX_FETCHING_INSTR = 1
) (
  decoupled.in pc,
  decoupled.out fetched,

  input flush,

  decoupled.out mem_req,
  decoupled.in mem_resp,

  input clk,
  input rst
);

// Addr queue
decoupled #(
  .Data(addr)
) addr_enq;
decoupled #(
  .Data(addr)
) addr_deq;

queue #(
  .DEPTH(MAX_FETCHING_INSTR+1),
  .FALLTHROUGH(1)
) addr_queue (
  .enq(addr_enq),
  .deq(addr_deq),

  .clk,
  .rst
);

// TODO: flush logic
wire _unused_flush = flush;

assign addr_enq.valid = pc.valid && mem_req.ready;
assign addr_enq.data = pc.data;

assign mem_req.data = pc.data;
assign mem_req.valid = pc.valid && addr_enq.ready;

assign pc.ready = mem_req.ready && addr_enq.ready;

assign fetched.data.raw = mem_resp.data;
assign fetched.data.pc = addr_deq.data;
assign fetched.valid = mem_resp.valid && addr_deq.valid;

assign mem_resp.ready = fetched.ready;
assign addr_deq.ready = fetched.ready;

endmodule : instr_fetch

`endif // __INSTR_FETCH_SV__
