//`include "types.sv"

module top #(
  parameter [31:0] BOOT_VEC = 'h80000000,
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter INT_SRC_CNT = 1
) (
  // Memory request
  output var [ADDR_WIDTH-1:0] mem_req_addr,
  output var mem_req_we,
  output var [DATA_WIDTH-1:0] mem_req_data,
  output var [(DATA_WIDTH/8)-1:0] mem_req_be,
  output var mem_req_valid,
  input var mem_req_ready,

  // Memory response
  input var [DATA_WIDTH-1:0] mem_resp_data,
  input var mem_resp_valid,
  output var mem_resp_ready,

  input var [INT_SRC_CNT-1:0] ints,

  // Clock and reset
  input var clk,
  input var rst
);
/*
decoupled #(
  .Data(mreq)
) mem_req ();

decoupled #(
  .Data(mtrans)
) mem_resp ();

assign mem_req_addr = mem_req.data.a;
assign mem_req_we = mem_req.data.we;
assign mem_req_be = mem_req.data.be;
assign mem_req_data = mem_req.data.d;

assign mem_req_valid = mem_req.valid;
assign mem_req.ready = mem_req_ready;

assign mem_resp.data = mem_resp_data;
assign mem_resp.valid = mem_resp_valid;
assign mem_resp_ready = mem_resp.ready;

cpu #(
  .INT_SRC_CNT(INT_SRC_CNT),
  .BOOT_VEC(BOOT_VEC)
) cpu (
  .mem_req,
  .mem_resp,

  .ints,

  .clk,
  .rst
);*/

wire [31:0] base_ram_data;
logic [19:0] base_ram_addr;
logic [3:0] base_ram_be_n;
logic base_ram_ce_n;
logic base_ram_oe_n;
logic base_ram_we_n;
wire [31:0] ext_ram_data;
logic [19:0] ext_ram_addr;
logic [3:0] ext_ram_be_n;
logic ext_ram_ce_n;
logic ext_ram_oe_n;
logic ext_ram_we_n;

logic base_en = (~base_ram_ce_n) & ((~base_ram_oe_n) | (~base_ram_we_n));
logic ext_en = (~ext_ram_ce_n) & ((~ext_ram_oe_n) | (~ext_ram_we_n));
assign mem_req_addr = base_en ? {10'b1000_0000_00, base_ram_addr, 2'b00} : ext_en ? {10'b1000_0000_01, ext_ram_addr, 2'b00} : 0;
assign mem_req_we = (~base_ram_we_n) | (~ext_ram_we_n);
assign mem_req_be = base_en ? ~base_ram_be_n : ext_en ? ~ext_ram_be_n : 0;
assign mem_req_data = (~base_ram_we_n) ? base_ram_data : (~ext_ram_we_n) ? ext_ram_data : 0;
assign mem_req_valid = base_en | ext_en;

assign base_ram_data = (~base_ram_we_n) ? 32'bz : mem_resp_data;
assign ext_ram_data = (~ext_ram_we_n) ? 32'bz : mem_resp_data;
assign mem_resp_ready = base_en | ext_en;

wire uart_ready = 1'b0;
wire uart_tbre = 1'b0;
wire uart_tsre = 1'b0;

core cpu_core
(
    .clk(clk),
    .clkshift(clk),
    .rst(rst),
    
    .uart_ready,
    .uart_tbre,
    .uart_tsre,
    
    .base_data(base_ram_data),
    .base_adr(base_ram_addr),
    .base_be(base_ram_be_n),
    .base_ce(base_ram_ce_n),
    .base_oe(base_ram_oe_n),
    .base_we(base_ram_we_n),

    .ext_data(ext_ram_data),
    .ext_adr(ext_ram_addr),
    .ext_be(ext_ram_be_n),
    .ext_ce(ext_ram_ce_n),
    .ext_oe(ext_ram_oe_n),
    .ext_we(ext_ram_we_n)
);

endmodule : top
