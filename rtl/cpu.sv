`include "types.sv"

`include "components/regfile.sv"

`include "stages/instr_fetch.sv"
`include "stages/instr_decode.sv"
`include "stages/execute.sv"

`include "types.sv"

module cpu #(
  parameter INT_SRC_CNT = 1,
  parameter [31:0] BOOT_VEC = 'h80000000
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

/* Memory interface */
decoupled #(
  .Data(addr)
) mem_sub_req [2];

decoupled #(
  .Data(mtrans)
) mem_sub_resp [2];

// TODO: make data mem request the privileged one
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

/* Components */
reg_idx rs_idx [2], rd_idx, ex_fb_idx;
gpreg rs_val [2], rd_val, ex_fb_val;

reg_idx fb_idx [2];
reg_idx write_idx [1];
assign fb_idx[0] = ex_fb_idx;
assign fb_idx[1] = rd_idx;
assign write_idx[0] = rd_idx;

gpreg fb_val [2];
gpreg write_val [1];
assign fb_val[0] = ex_fb_val;
assign fb_val[1] = rd_val;
assign write_val[0] = rd_val;

regfile #(
) regfile_inst (
  .read_addr(rs_idx),
  .read_data(rs_val),

  .feedback_addr(fb_idx),
  .feedback_data(fb_val),

  .write_addr(write_idx),
  .write_data(write_val),
  .clk,
  .rst
);

/* Stage registers */
decoupled #(
  .Data(fetched_instr)
) if_fetched;

decoupled #(
  .Data(fetched_instr)
) id_fetched;

queue #(
  .Data(fetched_instr),
  .DEPTH(2),
  .PIPE(1)
) if_id_queue (
  .enq(if_fetched),
  .deq(id_fetched),

  .clk, .rst
);

decoupled #(
  .Data(decoded_instr)
) id_decoded;

decoupled #(
  .Data(decoded_instr)
) ex_decoded;

queue #(
  .Data(decoded_instr),
  .DEPTH(2),
  .PIPE(1)
) id_ex_queue (
  .enq(id_decoded),
  .deq(ex_decoded),

  .clk, .rst
);

decoupled #(
  .Data(exec_result)
) ex_result;

decoupled #(
  .Data(exec_result)
) commit;

queue #(
  .Data(exec_result),
  .DEPTH(2),
  .PIPE(1)
) ex_commit_queue (
  .enq(ex_result),
  .deq(commit),

  .clk, .rst
);

// We don't need to guard against valid here, because
// RegFile's read results will only be effective on pipeline move edges
assign ex_fb_idx = ex_result.data.rd_idx;
assign ex_fb_val = ex_result.data.rd_val;

/* Stages */

instr_fetch #(
  .MAX_FETCHING_INSTR(1)
) if_inst (
  .pc(if_pc),
  .fetched(if_fetched),
  .mem_req(mem_sub_req[0]),
  .mem_resp(mem_sub_resp[0]),

  .flush('0),
  
  .clk,
  .rst
);

instr_decode #(
) id_inst (
  .fetched(id_fetched),
  .decoded(id_decoded),

  .rs_idx,
  .rs_val,

  .flush('0),
  .clk, .rst
);

execute #(
) ex_inst (
  .decoded(ex_decoded),
  .result(ex_result),

  .flush('0),
  .clk, .rst
);

/* Commit */
assign commit.ready = '1;
assign rd_idx = commit.valid ? commit.data.rd_idx : '0;
assign rd_val = commit.data.rd_val;

// TODO: branch

// Void all unused signals
(* keep = "soft" *) wire _unused = &{
  ex_result.data,
  ex_result.valid,
  mem_sub_req[1].ready,
  mem_sub_resp[1].valid,
  mem_sub_resp[1].data,
  ints
};

assign mem_sub_req[1].valid = '0;
assign mem_sub_resp[1].ready = '0;

endmodule : cpu
