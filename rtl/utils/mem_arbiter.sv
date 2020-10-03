/**
 * Prioritized memory arbiter
 *
 * Priority goes to master ports with lower index
 */

`ifndef __MEM_ARBITER_H__
`define __MEM_ARBITER_H__

`include "utils/queue.sv";

module mem_arbiter #(
  parameter CNT = 2,
  parameter QUEUE_DEPTH = 4
) (
  decoupled.in master_req [CNT],
  decoupled.out master_resp [CNT],

  decoupled.out slave_req,
  decoupled.out slave_resp,

  input clk,
  input rst
);

// TODO: queue with depth = 0
// TODO: fallthrough queue
localparam MASTER_IDX_WIDTH = $clog2(CNT);
typedef bit [MASTER_IDX_WIDTH-1:0] master_idx;

decoupled buffer_in, buffer_out;

queue #(
  .Data(master_idx),
  .DEPTH(QUEUE_DEPTH)
) buffer (
  .enq(buffer_in),
  .deq(buffer_out),

  .clk,
  .rst
);

// Request arbiter logic
wire has_req;
always_comb begin
  has_req = '0;
  for (i = 0; i < CNT; i = i+1) begin
    if(!has_req) begin
      buffer_in.data = i;
      slave_req.data = master_req[i].data;
      master_req[i].ready = slave_req.fire();
    end

    has_req = has_req | master_req[i].valid;
  end

  slave_req.valid = has_req && buffer_in.ready;
  buffer_in.valid = slave_req.fire();
end

// Response arbiter logic
for (genvar i = 0; i < CNT; i = i+1) begin
  assign master_resp[i].valid = slave_resp.valid && i === buffer_out.data;
  assign master_resp[i].data = slave_resp.data;
end

assign slave_resp.ready = master_resp[buffer_out.data].ready;
assign buffer_out.ready = slave_resp.fire();

endmodule : mem_arbiter

`endif // __MEM_ARBITER_H__
