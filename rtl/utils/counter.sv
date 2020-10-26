`ifndef __COUNTER_SV__
`define __COUNTER_SV__

module counter #(
  parameter int BOUND = 1,
  parameter int WIDTH = BOUND == 1 ? 1 : $clog2(BOUND)
) (
  input tick,
  output logic [WIDTH-1:0] current,

  input flush,

  input clk,
  input rst
);

if(BOUND === 1) begin
  logic _unused = &{ tick, clk, rst, flush };
  assign current = '0;
end else begin
  logic [WIDTH-1:0] cnt;
  assign current = cnt;

  always_ff @(posedge clk or posedge rst) begin
    if(rst) cnt <= 0;
    else if(flush) cnt <= 0;
    else if(tick) begin
      if(cnt === BOUND - 1) begin
        cnt <= 0;
      end else begin
        cnt <= cnt + 1;
      end
    end
  end
end

endmodule

`endif // __COUNTER_SV__
