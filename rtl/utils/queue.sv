`ifndef __QUEUE_SV__
`define __QUEUE_SV__

`include "types.sv";

// TODO: 0-depth queue
// TODO: fallthrough
// TODO: flush
module queue #(
  parameter type Data = gpreg,
  parameter int DEPTH = 2
) (
  decoupled.in enq,
  decoupled.out deq,

  input clk,
  input rst
);

localparam IDX_WIDTH = $clog2(DEPTH);
typedef bit [IDX_WIDTH-1:0] idx;

Data store [DEPTH];
idx head, tail;
wire full = tail + 1 === head;
wire empty = tail === head;

assign enq.ready = !full;
assign deq.valid = !empty;
assign deq.data = store[head];

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
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
