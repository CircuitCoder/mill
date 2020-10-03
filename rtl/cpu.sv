`include "types.sv"

`include "stages/instr_fetch.sv"

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
decoupled #(
  .Data(addr)
) if_pc;

// By defualt, npc = pc + 4 for RV32I impls
assign npc = pc + 4;
assign if_pc.data = pc;
assign if_pc.valid = '1;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    pc <= BOOT_VEC;
  end else begin
    if(if_pc.fire()) pc <= npc;
  end
end

// Memory interface
decoupled #(
  .Data(addr)
) mem_sub_req [2];

decoupled #(
  .Data(mtrans)
) mem_sub_resp [2];

mem_arbiter #(
  .CNT(2),
  .QUEUE_DEPTH(2)
) arbiter (
  .master_req(mem_sub_req),
  .master_resp(mem_sub_resp),

  .slave_req(mem_req),
  .slave_resp(mem_resp),

  .clk,
  .rst
);

// Stages
decoupled #(
  .Data(instr)
) id_fetched;

instr_fetch #(
  .MAX_FETCHING_INSTR(1)
) if_inst (
  .pc(if_pc),
  .fetched(id_fetched),
  .mem_req(mem_sub_req[0]),
  .mem_resp(mem_sub_resp[0]),

  .flush('0),
  
  .clk,
  .rst
);

assign id_fetched.ready = '1;

// Void all unused signals
(* keep = "soft" *) wire _unused = &{
  id_fetched.data,
  id_fetched.valid,
  ints
};

endmodule : cpu
