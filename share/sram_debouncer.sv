module sram_debouncer #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int CYCLE = 2 // CYCLE * CYCLE_LEN > 10ns
) (
  /* SRAM interface */
  output var logic [ADDR_WIDTH-1:0] sram_addr,

  output var logic sram_we_n,
  output var logic sram_re_n,
  output var logic [DATA_WIDTH/8-1:0] sram_be_n,

  inout tri logic [DATA_WIDTH-1:0] sram_data,

  /* CPU interface */
  // Request
  input var logic [ADDR_WIDTH-1:0] addr,

  input var logic [DATA_WIDTH-1:0] wdata,

  input var logic we,
  input var logic [DATA_WIDTH/8-1:0] wbe,

  input var logic req_valid,
  output var logic req_ready,

  // Response
  output var logic [DATA_WIDTH-1:0] rdata,
  output var logic resp_valid,
  input var logic resp_ready,

  input var clk,
  input var clk_90, // CLK + 90deg
  input var rst
);

// FF
logic we_ff;
logic [DATA_WIDTH-1:0] wdata_ff;
logic [ADDR_WIDTH-1:0] addr_ff;
logic [DATA_WIDTH/8-1:0] be_ff;
logic holding;

assign sram_be_n = ~be_ff;
assign sram_addr = addr_ff;
assign sram_data = we_ff ? wdata_ff : 'Z;
assign rdata = sram_data;

typedef logic [$clog2(CYCLE)-1:0] counter_t;
counter_t counter, counter_n, counter_inc;

assign counter_inc = counter == CYCLE-1 ? 0 : counter + 1;

assign resp_valid = counter == 0 && holding;
assign req_ready = counter == 0 && (!holding || resp_ready);

logic enq, deq;
assign enq = req_valid && req_ready;
assign deq = resp_valid && resp_ready;

always_comb begin
  if(counter != 0) counter_n = counter_inc;
  else if(enq) counter_n = counter_inc;
  else counter_n = counter;
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    counter <= 0;
    we_ff <= '0;
    holding <= '0;

    addr_ff <= 'X;
    wdata_ff <= 'X;
    be_ff <= 'X;
  end else begin
    counter <= counter_n;
    if(enq) begin
      we_ff <= we;
      be_ff <= we ? wbe : ~((DATA_WIDTH/8)'(0));
      addr_ff <= addr;
      wdata_ff <= wdata;
    end

    if(enq) begin
      holding <= '1;
      assert(!holding || deq);
    end else if(deq) holding <= '0;
  end
end

localparam FIRST_CNT = CYCLE == 1 ? 0 : 1;
assign sram_we_n = !(we_ff && holding && !(counter == FIRST_CNT && clk && !clk_90) && !(counter == '0 && !clk && !clk_90));
assign sram_re_n = !((!we_ff) && holding);

endmodule
