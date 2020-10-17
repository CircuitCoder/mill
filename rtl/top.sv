`include "types.sv"

module top #(
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

decoupled #(
  .Data(mreq)
) mem_req;

decoupled #(
  .Data(mtrans)
) mem_resp;

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
  INT_SRC_CNT
) cpu (
  .mem_req,
  .mem_resp,

  .ints,

  .clk,
  .rst
);

endmodule : top
