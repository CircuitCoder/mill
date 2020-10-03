`ifndef __INSTR_FETCH_SV__
`define __INSTR_FETCH_SV__

`include "utils/mem_arbiter.sv"
`include "types.sv"

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

localparam int INSTR_COUNTER = $clog2(MAX_FETCHING_INSTR);
bit [INSTR_COUNTER-1:0] cnt;
localparam int BOUND = MAX_FETCHING_INSTR - 1;

// TODO: flush logic
assign mem_req.data = pc.data;
assign mem_req.valid = pc.valid && cnt !== BOUND;
assign pc.ready = mem_req.ready;

// TODO: buffer for one cycle!
assign mem_resp.ready = fetched.ready;
assign fetched.data = mem_resp.data;
assign fetched.valid = mem_resp.valid;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    cnt <= 0;
  end else begin
    if(mem_req.fire() && !mem_resp().fire()) begin
      cnt <= cnt + 1;
    end
    if(!mem_req.fire() && mem_resp().fire()) begin
      cnt <= cnt - 1;
    end
  end
end

endmodule : instr_fetch

`endif // __INSTR_FETCH_SV__
