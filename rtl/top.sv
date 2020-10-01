module Top #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter INT_SRC_CNT = 1
) (
  // Memory request
  output [ADDR_WIDTH-1:0] mem_req_addr,
  output mem_req_valid,
  input mem_req_ready,

  // Memory response
  input [DATA_WIDTH-1:0] mem_resp_data,
  input mem_resp_valid,
  output mem_resp_ready,

  input [INT_SRC_CNT-1:0] ints,

  // Clock and reset
  input clk,
  input rst
);

assign mem_req_valid = '0;
assign mem_resp_ready = '0;

endmodule
