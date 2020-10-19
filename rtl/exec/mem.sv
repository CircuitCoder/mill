`ifndef __MEM_SV__
`define __MEM_SV__

`include "types.sv"

module mem #(
) (
  decoupled.in decoded,
  output exec_result result,

  decoupled.out mem_req,
  decoupled.in mem_resp,

  input flush,

  input clk,
  input rst
);

logic request_sent = '0;

addr raw;
assign raw = decoded.data.rs1_val + decoded.data.imm;
addr aligned = { raw[31:2], 2'b00 };
logic [1:0] shift = raw[1:0];

assign mem_req.data.a = aligned;

logic [3:0] be;
logic inval_addr;
logic inval_instr;
assign inval_instr = decoded.data.funct3[2] && (
  decoded.data.funct3[1:0] == 2'b10 || decoded.data.op == INSTR_STORE
);

always_comb begin
  inval_addr = '0;
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

    default: inval_addr = '1;
  endcase
end

always_comb begin
  unique case(decoded.data.op)
    INSTR_STORE: mem_req.data.we = '1;
    INSTR_LOAD: mem_req.data.we = '0;
  endcase
end

// TODO: handles inval addr & inval instr
// TODO: handles flush

logic _unused_flush = flush;
logic _unused_inval = |{ inval_addr, inval_instr };

assign mem_req.data.be = be;
assign mem_req.data.d = decoded.data.rs2_val <<< shift;
assign mem_req.valid = decoded.valid && !request_sent;

assign mem_resp.ready = '1;
assign decoded.ready = mem_resp.valid;

mtrans shifted;
assign shifted = mem_resp.data >>> shift;
gpreg readout;

always_comb begin
  /* verilator lint_off CASEINCOMPLETE */
  unique0 case(decoded.data.funct3)
    // LBx
    3'b000: readout = 32'(signed'(shifted[7:0]));
    3'b100: readout = { 24'b0, shifted[7:0] } ;

    // LH
    3'b001: readout = 32'(signed'(shifted[15:0]));
    3'b101: readout = { 16'b0, shifted[15:0] } ;

    3'b010: readout = shifted;
  endcase
  /* verilator lint_on CASEINCOMPLETE */
end

assign result.rd_idx = decoded.data.rd;
assign result.rd_val = readout;
assign result.br_valid = '0;
assign result.br_target = 'X;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    request_sent <= '0;
  end else begin
    if(mem_resp.valid) begin
      request_sent <= '0;
    end else if(mem_req.fire()) begin
      request_sent <= '1;
    end
  end
end

endmodule

`endif // __MEM_SV__
