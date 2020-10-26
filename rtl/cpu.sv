`include "types.sv"

`include "components/regfile.sv"
`include "components/csrfile.sv"
`include "components/mem_arbiter.sv"

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

/* PC logic */
gpreg pc;

logic br_valid;
gpreg br_target;

decoupled #(
  .Data(addr)
) if_pc ();

assign if_pc.data = pc;
assign if_pc.valid = '1;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    pc <= BOOT_VEC;
  end else begin
    if(br_valid) pc <= br_target;
    // By defualt, npc = pc + 4 for RV32I impls
    else if(if_pc.ready) pc <= pc + 4;
  end
end

/* Memory interface */
decoupled #(
  .Data(mreq)
) mem_sub_req [2] ();

decoupled #(
  .Data(mtrans)
) mem_sub_resp [2] ();

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

decoupled #(
  .Data(csr_req)
) csrfile_req;

csr_resp csrfile_resp;

csr_effect csrfile_effect;

gpreg csr_mtvec;
gpreg csr_mepc;

csrfile #(
) csrfile_inst (
  .csr_mtvec,
  .csr_mepc,

  .req(csrfile_req),
  .resp(csrfile_resp),

  .effect(csrfile_effect),

  .clk,
  .rst
);

/* Stage registers */
decoupled #(
  .Data(fetched_instr)
) if_fetched ();

decoupled #(
  .Data(fetched_instr)
) id_fetched ();

queue #(
  .Data(fetched_instr),
  .DEPTH(2),
  .PIPE(1)
) if_id_queue (
  .enq(if_fetched),
  .deq(id_fetched),

  .flush(br_valid),

  .clk, .rst
);

decoupled #(
  .Data(decoded_instr)
) id_decoded ();

decoupled #(
  .Data(decoded_instr)
) ex_decoded ();

queue #(
  .Data(decoded_instr),
  .DEPTH(2),
  .PIPE(1)
) id_ex_queue (
  .enq(id_decoded),
  .deq(ex_decoded),

  .flush(br_valid),

  .clk, .rst
);

decoupled #(
  .Data(exec_result)
) ex_result ();

decoupled #(
  .Data(exec_result)
) commit ();

// Currently we are branching from ex, hence we don't have to flush the ex_commit_queue and ex itself
queue #(
  .Data(exec_result),
  .DEPTH(2),
  .PIPE(1)
) ex_commit_queue (
  .enq(ex_result),
  .deq(commit),

  .flush('0),

  .clk, .rst
);

// We don't need to guard against valid here, because
// RegFile's read results will only be effective on pipeline move edges
assign ex_fb_idx = ex_result.valid ? ex_result.data.rd_idx : 'h0;
assign ex_fb_val = ex_result.data.rd_val;

// Branching and csr effects
always_comb begin
  csrfile_effect.src = 'X;
  csrfile_effect.epc = 'X;
  csrfile_effect.tval = 'X;

  if(!ex_result.valid) begin
    br_valid = '0;
    br_target = 'X;
    csrfile_effect.t = CSR_EFF_IDLE;
  end else if(ex_result.data.ex_valid) begin
    br_valid = '1;
    br_target = csr_mtvec;

    csrfile_effect.t = CSR_EFF_EX;
    csrfile_effect.src = ex_result.data.ex;
    csrfile_effect.tval = ex_result.data.ex_tval;
    // Here we assumes that EX is combinatory
    csrfile_effect.epc = ex_decoded.data.pc;
  end else if(ex_result.data.ret_valid) begin
    br_valid = '1;
    br_target = csr_mepc;

    csrfile_effect.t = CSR_EFF_RET;
  end else begin
    br_valid = ex_result.data.br_valid;
    br_target = ex_result.data.br_target;

    csrfile_effect.t = CSR_EFF_INSTRET;
  end
end

/* Stages */

instr_fetch #(
) if_inst (
  .pc(if_pc),
  .fetched(if_fetched),
  .mem_req(mem_sub_req[1]),
  .mem_resp(mem_sub_resp[1]),

  .flush(br_valid),
  
  .clk,
  .rst
);

instr_decode #(
) id_inst (
  .fetched(id_fetched),
  .decoded(id_decoded),

  .rs_idx,
  .rs_val,

  .flush(br_valid),
  .clk, .rst
);

execute #(
) ex_inst (
  .decoded(ex_decoded),
  .result(ex_result),

  .mem_req(mem_sub_req[0]),
  .mem_resp(mem_sub_resp[0]),

  .csrfile_req,
  .csrfile_resp,

  .clk, .rst
);

/* Commit */
assign commit.ready = '1;
assign rd_idx = commit.valid && !commit.data.ex_valid ? commit.data.rd_idx : '0;
assign rd_val = commit.data.rd_val;

// Void all unused signals
(* keep = "soft" *) wire _unused = &{
  ints
};

endmodule : cpu
