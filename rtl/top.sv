/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSED */

module top #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter INT_SRC_CNT = 1
) (
  // Memory request
  output var [ADDR_WIDTH-1:0] mem_req_addr,
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

assign mem_req_valid = '0;
assign mem_resp_ready = '0;

endmodule
