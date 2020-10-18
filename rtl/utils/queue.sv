`ifndef __QUEUE_SV__
`define __QUEUE_SV__

`include "types.sv";

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

localparam IDX_WIDTH = $clog2(DEPTH);
typedef bit [IDX_WIDTH-1:0] idx;

Data store [DEPTH];
idx head, tail;
wire full = tail + 1 === head;
wire empty = tail === head;

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

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    head <= 0;
    tail <= 0;
  end else if(flush) begin
    head <= 0;
    tail <= 0;
  end else begin
    if(enq.fire()) tail <= tail + 1;
    if(deq.fire()) head <= head + 1;
  end
end

always_ff @(posedge clk) begin
  if(enq.fire()) store[tail] <= enq.data;
end

endmodule

`endif // __QUEUE_SV__
