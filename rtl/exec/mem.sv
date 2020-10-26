`ifndef __MEM_SV__
`define __MEM_SV__

`include "types.sv"

module mem #(
) (
  decoupled.in decoded,
  output exec_result result,

  decoupled.out mem_req,
  decoupled.in mem_resp,

  input clk,
  input rst
);

typedef enum {
  STATE_CALC, STATE_REQ, STATE_RESP
} state_t;

state_t state, state_n;

// Address calculation
addr raw;

logic inval_align;
logic inval_instr;

addr aligned;
addr aligned_pipe;

logic [1:0] shift;
logic [1:0] shift_pipe;

logic [3:0] be;
logic [3:0] be_pipe;

mtrans shifted_req;
mtrans shifted_req_pipe;

assign raw = decoded.data.rs1_val + decoded.data.imm;
assign aligned = { raw[31:2], 2'b00 };
assign shift = raw[1:0];

assign inval_instr = decoded.data.funct3[2] && (
  decoded.data.funct3[1:0] == 2'b10 || decoded.data.op == INSTR_STORE
);

always_comb begin
  inval_align = '0;
  be = 'X;

  unique case({ decoded.data.funct3[1:0], shift })
    // SB
    { 2'b00, 2'b00 }: be = 4'b0001;
    { 2'b00, 2'b01 }: be = 4'b0010;
    { 2'b00, 2'b10 }: be = 4'b0100;
    { 2'b00, 2'b11 }: be = 4'b1000;

    // SH
    { 2'b01, 2'b00 }: be = 4'b0011;
    { 2'b01, 2'b10 }: be = 4'b1100;

    // SW
    { 2'b10, 2'b00 }: be = 4'b1111;

    default: inval_align = '1;
  endcase
end

assign shifted_req = decoded.data.rs2_val <<< (shift * 8);

always_ff @(posedge clk) begin
  aligned_pipe <= aligned;
  shift_pipe <= shift;
  be_pipe <= be;
  shifted_req_pipe <= shifted_req;
end

assign mem_req.data.a = aligned_pipe;
assign mem_req.data.be = be_pipe;
assign mem_req.data.d = shifted_req_pipe;

always_comb begin
  unique case(decoded.data.op)
    INSTR_STORE: mem_req.data.we = '1;
    INSTR_LOAD: mem_req.data.we = '0;
    default: mem_req.data.we = 'X;
  endcase
end

assign mem_req.valid = state == STATE_REQ;

assign mem_resp.ready = '1;

mtrans shifted_resp;
assign shifted_resp = mem_resp.data >>> (shift_pipe * 8);
gpreg readout;

always_comb begin
  unique case(decoded.data.funct3)
    // LBx
    3'b000: readout = unsigned'(32'(signed'(shifted_resp[7:0])));
    3'b100: readout = { 24'b0, shifted_resp[7:0] } ;

    // LH
    3'b001: readout = unsigned'(32'(signed'(shifted_resp[15:0])));
    3'b101: readout = { 16'b0, shifted_resp[15:0] } ;

    3'b010: readout = shifted_resp;
    default: readout = 'hX;
  endcase
end

assign result.rd_idx = decoded.data.rd;
assign result.rd_val = readout;
assign result.br_valid = '0;
assign result.br_target = 'X;
assign result.ret_valid = '0;

always_comb begin
  if(inval_instr) begin
    result.ex_valid = '1;
    result.ex = EX_ILLEGAL_INSTR;
    result.ex_tval = '0;
  end else if(inval_align) begin
    result.ex_valid = '1;
    result.ex = decoded.data.op == INSTR_STORE ? EX_STORE_ADDR_MISALIGNED : EX_LOAD_ADDR_MISALIGNED;
    result.ex_tval = raw;
  end else begin
    result.ex_valid = '0;
    result.ex = ex_type'('X);
    result.ex_tval = 'X;
  end
end

/* State transfer and output validity */
always_comb begin
  state_n = state;
  decoded.ready = '0;

  unique case(state)
    STATE_CALC: begin
      if(inval_align || inval_instr) decoded.ready = '1;
      else if(decoded.valid) state_n = STATE_REQ;
    end
    STATE_REQ: begin
      if(mem_req.ready && !mem_resp.valid) begin
        state_n = STATE_RESP;
      end else begin
        decoded.ready = '1;
        state_n = STATE_CALC;
      end
    end
    STATE_RESP: begin
      if(mem_resp.valid) begin
        decoded.ready = '1;
        state_n = STATE_CALC;
      end
    end
  endcase
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) state <= STATE_CALC;
  else state <= state_n;
end

endmodule

`endif // __MEM_SV__
