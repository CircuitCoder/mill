module sram_debouncer #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int CYCLE = 2 // CYCLE * CYCLE_LEN > 10ns
) (
  /* SRAM interface */
  output var logic [ADDR_WIDTH-1:0] sram_addr,

  output var logic [DATA_WIDTH/8-1:0] sram_wbe,
  output var logic [DATA_WIDTH/8-1:0] sram_rbe,

  inout tri logic [DATA_WIDTH-1:0] sram_data,

  /* CPU interface */
  // Request
  input var logic [ADDR_WIDTH-1:0] addr,

  input var logic [DATA_WIDTH-1:0] wdata,

  input var logic [DATA_WIDTH/8-1:0] wbe,

  input var logic req_valid,
  output var logic req_ready,

  // Response
  output var logic [DATA_WIDTH-1:0] rdata,
  output var logic resp_valid,
  input var logic resp_ready,

  input var clk,
  input var rst
);

// FF
logic [DATA_WIDTH-1:0] wdata_ff;
logic [ADDR_WIDTH-1:0] addr_ff;
logic [DATA_WIDTH/8-1:0] wbe_ff;
logic holding;

typedef logic [$clog2(CYCLE)-1:0] counter_t;
counter_t counter, counter_n, counter_inc;

assign counter_inc = counter == CYCLE-1 ? 0 : counter + 1;

assign resp_valid = counter == 0 && holding;
assign req_ready = counter == 0 && (!holding || resp_ready);

logic enq, deq;
assign enq = req_valid && req_ready;
assign deq = resp_valid && resp_ready;

assign sram_addr = addr_ff;
assign sram_wbe = wbe_ff;
assign sram_rbe = ~wbe_ff;

for(genvar i = 0; i < DATA_WIDTH/8; ++i) begin
  assign sram_data[i*8+:8] = wbe_ff[i] ? wdata_ff[i*8+:8] : 'Z;
end

assign rdata = sram_data;

always_comb begin
  if(counter != 0) counter_n = counter_inc;
  else if(enq) counter_n = counter_inc;
  else counter_n = counter;
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    counter <= 0;
    wbe_ff <= '0;
    holding <= '0;

    addr_ff <= 'X;
    wdata_ff <= 'X;
  end else begin
    counter <= counter_n;
    if(enq) begin
      wbe_ff <= wbe;
      addr_ff <= addr;
      wdata_ff <= wdata;
    end

    if(enq && !deq) holding <= '1;
    else if(deq && !enq) holding <= '0;
  end
end

endmodule
