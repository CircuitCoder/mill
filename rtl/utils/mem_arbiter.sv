/**
 * Prioritized memory arbiter
 *
 * Priority goes to master ports with lower index
 */

`ifndef __MEM_ARBITER_H__
`define __MEM_ARBITER_H__

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
localparam QUEUE_IDX_WIDTH = $clog2(QUEUE_DEPTH);
localparam MASTER_IDX_WIDTH = $clog2(CNT);
typedef bit [MASTER_IDX_WIDTH-1:0] master_idx;
typedef bit [QUEUE_IDXX_WIDTH-1:0] queue_idx;

// Queue logic
master_idx queue [QUEUE_DEPTH];
queue_idx queue_head, queue_tail;
wire queue_full = queue_tail + 1 === queue_head;
wire queue_empty = queue_tail === queue_head;

wire queue_push;
wire master_idx queue_push_data;
wire queue_pop;
wire master_idx queue_pop_data = queue[queue_head];

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    queue_head <= 0;
    queue_tail <= 0;
  end else begin
    if(queue_push && !queue_full) queue_tail <= queue_tail + 1;
    if(queue_pop && !queue_empty) queue_head <= queue_head + 1;
  end
end

always_ff @(posedge clk) begin
  if(queue_push) queue[queue_tail] <= queue_push_data;
end

// Request arbiter logic
wire has_req;
always_comb begin
  has_req = '0;
  for (i = 0; i < CNT; i = i+1) begin
    if(!has_req) begin
      queue_push_data = i;
      slave_req.data = master_req[i].data;
      master_req[i].ready = slave_req.fire();
    end

    has_req = has_req | master_req[i].valid;
  end

  slave_req.valid = has_req;
  queue_push = slave_req.fire();
end

// Response arbiter logic
for (genvar i = 0; i < CNT; i = i+1) begin
  assign master_resp[i].valid = slave_resp.valid && i === queue_pop_data;
  assign master_resp[i].data = slave_resp.data;
end

assign slave_resp.ready = master_resp[queue_pop_data].ready;
assign queue_pop = slave_resp.fire();

endmodule : mem_arbiter

`endif // __MEM_ARBITER_H__
