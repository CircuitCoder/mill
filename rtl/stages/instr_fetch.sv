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
gpreg sent_addr;
logic sent;

assign mem_req.data.a = pc.data;
assign mem_req.data.we = '0;
assign mem_req.data.be = 'X;
assign mem_req.data.d = 'X;
assign mem_req.valid = pc.valid && !sent && !flush;
assign pc.ready = mem_req.ready;

assign fetched.data.raw = mem_resp.data;
assign fetched.data.pc = sent ? sent_addr : pc.data;
assign fetched.valid = mem_resp.valid;
assign mem_resp.ready = fetched.ready;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    sent <= '0;
  end else begin
    if(mem_resp.valid && mem_resp.ready) begin
      sent <= '0;
    end else if(mem_req.valid && mem_req.ready) begin
      sent <= '1;
      sent_addr <= pc.data;
    end
  end
end

endmodule : instr_fetch

`endif // __INSTR_FETCH_SV__
