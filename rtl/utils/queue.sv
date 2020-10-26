`ifndef __QUEUE_SV__
`define __QUEUE_SV__

`include "types.sv"
`include "utils/counter.sv"

// TODO: 0-depth queue
module queue #(
  parameter type Data = gpreg,
  parameter int DEPTH = 2,
  parameter bit FALLTHROUGH = 0,
  parameter bit PIPE = 0
) (
  decoupled.in enq,
  decoupled.out deq,

  input flush,

  input clk,
  input rst
);

Data store [DEPTH];

localparam IDX_WIDTH = DEPTH == 1 ? 1 : $clog2(DEPTH);
typedef logic [IDX_WIDTH-1:0] idx;

idx head, tail;
logic head_tick, tail_tick;

counter #(.BOUND(DEPTH)) head_cnt (
  .current(head),
  .tick(head_tick),
  .flush,
  .clk, .rst
);

counter #(.BOUND(DEPTH)) tail_cnt (
  .current(tail),
  .tick(tail_tick),
  .flush,
  .clk, .rst
);

wire full, empty;
logic maybe_full;
assign full = tail == head && maybe_full;
assign empty = tail == head && !maybe_full;

if(PIPE) begin
  assign enq.ready = (!full) || deq.valid;
end else begin
  assign enq.ready = !full;
end

if(FALLTHROUGH) begin
  assign deq.valid = !empty || enq.valid;
  assign deq.data = empty ? enq.data : store[head];
end else begin
  assign deq.valid = !empty;
  assign deq.data = store[head];
end

assign head_tick = deq.valid && deq.ready;
assign tail_tick = enq.valid && enq.ready;

always_ff @(posedge clk or posedge rst) begin
  if(rst) maybe_full <= '0;
  else if(flush) maybe_full <= '0;
  else if(head_tick != tail_tick) maybe_full <= tail_tick;
end

always_ff @(posedge clk) begin
  if(enq.valid && enq.ready) store[tail] <= enq.data;
end

endmodule

`endif // __QUEUE_SV__
