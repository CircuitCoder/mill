/**
 * Prioritized memory arbiter
 *
 * Priority goes to master ports with lower index
 */

`ifndef __MEM_ARBITER_H__
`define __MEM_ARBITER_H__

`include "utils/queue.sv"

module mem_arbiter #(
  parameter CNT = 2,
  parameter QUEUE_DEPTH = 4,
  parameter ADDR_WIDTH = 32
) (
  decoupled.in master_req [CNT],
  decoupled.out master_resp [CNT],

  decoupled.out slave_req,
  decoupled.in slave_resp,

  input clk,
  input rst
);

localparam MASTER_IDX_WIDTH = $clog2(CNT);
typedef bit [MASTER_IDX_WIDTH-1:0] master_idx;

decoupled #(
  .Data(master_idx)
) buffer_in (), buffer_out ();

queue #(
  .Data(master_idx),
  .DEPTH(QUEUE_DEPTH),
  .FALLTHROUGH(1)
) buffer (
  .enq(buffer_in),
  .deq(buffer_out),

  .flush('0),

  .clk,
  .rst
);

// Request arbiter l [CNT]ogic
wire master_valid [CNT];
wire mreq master_req_data [CNT];
for(genvar i = 0; i < CNT; i = i+1) begin
  assign master_valid[i] = master_req[i].valid;
  assign master_req_data[i] = master_req[i].data;
end

var master_idx sel;
var bit has_req;

always_comb begin
  has_req = '0;
  sel = 'X;
  slave_req.data = 'X;
  for(int i = CNT - 1; i >= 0; i = i - 1) begin
    master_idx casted = master_idx '(i);
    if(master_valid[casted]) begin
      sel = casted;
      slave_req.data = master_req_data[casted];
    end
    has_req |= master_valid[casted];
  end
end

for(genvar i = 0; i < CNT; i = i+1) begin
  assign master_req[i].ready = slave_req.valid && slave_req.ready && sel === i;
end

assign buffer_in.data = sel;

// Mitigate bug
assign slave_req.valid = has_req && buffer_in.ready && !rst;
assign buffer_in.valid = slave_req.valid && slave_req.ready;

// Response arbiter logic
for (genvar i = 0; i < CNT; i = i+1) begin
  assign master_resp[i].valid = slave_resp.valid && i === buffer_out.data && buffer_out.valid;
  assign master_resp[i].data = slave_resp.data;
end

wire master_ready [CNT];
for(genvar i = 0; i < CNT; i = i+1) begin
  assign master_ready[i] = master_resp[i].ready;
end

assign slave_resp.ready = buffer_out.valid && master_ready[buffer_out.data] && !rst;
assign buffer_out.ready = slave_resp.valid && slave_resp.ready;

endmodule : mem_arbiter

`endif // __MEM_ARBITER_H__
