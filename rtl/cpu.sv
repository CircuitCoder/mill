`include "types.sv"

module cpu #(
  parameter INT_SRC_CNT = 1,
  parameter [31:0] BOOT_VEC = 0
) (
  decoupled.out mem_req,
  decoupled.in mem_resp,

  input bit[INT_SRC_CNT-1:0] ints,

  input var clk,
  input var rst
);

// PC logic
reg [31:0] pc;
wire [31:0] npc;

// By defualt, npc = pc + 4 for RV32I impls
assign npc = pc + 4;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    pc <= BOOT_VEC;
  end else begin
    pc <= npc;
  end
end

// Memory interface
assign mem_req.data = '0;
assign mem_req.valid = '0;

assign mem_resp.ready = '0;

// Void all unused signals
(* keep = "soft" *) wire _unused = &{
  mem_req.ready,
  mem_resp.data,
  mem_resp.valid,
  ints
};

endmodule : cpu
