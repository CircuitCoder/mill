`ifndef __REGFILE_SV__
`define __REGFILE_SV__

`include "types.sv"

module regfile #(
  parameter READER = 2,
  parameter WRITER = 1,
  parameter FEEDBACK = 2,

  parameter COUNT = 32
) (
  input reg_idx read_addr [READER],
  output gpreg read_data [READER],

  input reg_idx write_addr [WRITER],
  input gpreg write_data [WRITER],

  input reg_idx feedback_addr [FEEDBACK],
  input gpreg feedback_data [FEEDBACK],

  input clk,
  input rst
);

gpreg [COUNT-1:0] storage;

// Reading
always_comb begin
  for(int i = 0; i < READER; ++i) begin
    read_data[i] = storage[read_addr[i]];

    // Feedback port with lower index takes precedence
    for(int j = FEEDBACK-1; j > 0; --j) begin
      if(read_addr[i] == feedback_addr[j])
        read_data[i] = feedback_data[j];
    end

    if(read_addr[i] == 0) read_data[i] = 0;
  end
end

always_ff @(posedge clk) begin
  for(int i = 0; i < WRITER; ++i) begin
    storage[write_addr[i]] <= write_data[i];
  end
end

// We don't care about reset state
wire _unused_rst = rst;

endmodule

`endif // __REGFILE_SV__
