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

typedef enum {
  STATE_REQ,
  STATE_WAIT_RESP, // Waiting for memory
  STATE_WAIT_DOWNSTREAM, // Waiting for downstream
  STATE_FLUSHED // Flushed!
} state_t;

state_t state, state_n;

instr holding_instr;

assign mem_req.data.a = pc.data;
assign mem_req.data.we = '0;
assign mem_req.data.be = 'X;
assign mem_req.data.d = 'X;

assign fetched.data.pc = pc.data;
assign fetched.data.raw = state == STATE_WAIT_DOWNSTREAM ? holding_instr : mem_resp.data;

logic sending, receiving, draining;

assign sending = mem_req.valid && mem_req.ready;
assign receiving = mem_resp.valid && mem_resp.ready;
assign draining = fetched.valid && fetched.ready;

assign mem_req.valid = state == STATE_REQ && pc.valid;
assign pc.ready = draining;

assign fetched.valid = state == STATE_WAIT_DOWNSTREAM || mem_resp.valid && state != STATE_FLUSHED;
assign mem_resp.ready = state != STATE_WAIT_DOWNSTREAM;

always_comb begin
  state_n = state;

  unique case(state)
    STATE_REQ: begin
      if(flush) begin
        if(sending && !receiving) state_n = STATE_FLUSHED;
        else state_n = STATE_REQ;
      end
      else if(sending && receiving && draining) state_n = STATE_REQ;
      else if(sending && receiving) state_n = STATE_WAIT_DOWNSTREAM;
      else if(sending) state_n = STATE_WAIT_RESP;
    end
    STATE_WAIT_RESP: begin
      assert(!mem_req.valid);
      if(flush) state_n = STATE_FLUSHED;
      else if(receiving && draining) state_n = STATE_REQ;
      else if(receiving) state_n = STATE_WAIT_DOWNSTREAM;
    end
    STATE_WAIT_DOWNSTREAM: begin
      if(flush) state_n = STATE_REQ;
      else if(draining) state_n = STATE_REQ;
    end
    STATE_FLUSHED: begin
      if(receiving) state_n = STATE_REQ;
    end
  endcase
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    state <= STATE_REQ;
    holding_instr <= 'X;
  end else begin
    state <= state_n;

    // Holding data
    if(receiving) holding_instr <= mem_resp.data;
  end
end

endmodule : instr_fetch

`endif // __INSTR_FETCH_SV__
