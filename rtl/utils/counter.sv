`ifndef __COUNTER_SV__
`define __COUNTER_SV__

module counter #(
  parameter int BOUND = 1,
  parameter int WIDTH = $clog2(BOUND)
) (
  input tick,
  output current,

  input clk,
  input rst
);

if(BOUND === 1) begin
  wire _unused = &{ tick, clk, rst };
  assign current = '0;
end else begin
  parameter WIDTH = $clog2(BOUND);
  reg [WIDTH-1:0] cnt;
  assign current = cnt;

  always_ff @(posedge clk or posedge rst) begin
    if(rst) cnt <= 0;
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
