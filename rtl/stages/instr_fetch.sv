`ifndef __INSTR_FETCH_SV__
`define __INSTR_FETCH_SV__

`include "types.sv"
`include "components/mem_arbiter.sv"

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

instr slot;
logic slot_taken;

assign fetched.data.pc = sent ? sent_addr : pc.data;
assign fetched.data.raw = slot_taken ? slot : mem_resp.data;
assign fetched.valid = slot_taken || mem_resp.valid;
assign mem_resp.ready = !slot_taken;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    sent <= '0;
    slot_taken <= '0;
  end else begin
    // Sent logic
    if(mem_req.valid && mem_req.ready) begin
      sent_addr <= pc.data;
    end

    if(mem_resp.valid && mem_resp.ready) begin
      sent <= '0;
    end else if(mem_req.valid && mem_req.ready) begin
      sent <= '1;
    end

    // Slot logic
    if(mem_resp.valid && mem_resp.ready) begin
      slot <= mem_resp.data;
    end

    if(fetched.ready) begin
      slot_taken <= '0;
    end else if(mem_resp.valid && mem_resp.ready) begin
      slot_taken <= '1;
    end
  end
end

endmodule : instr_fetch

`endif // __INSTR_FETCH_SV__
