`ifndef __EXEC_RESULT_SV__
`define __EXEC_RESULT_SV__

`include "types.sv"

// All implemented exceptions
typedef enum [3:0] {
  EX_INSTR_ADDR_MISALIGNED = 'h0,
  EX_INSTR_ACCESS_FAULT = 'h1,
  EX_ILLEGAL_INSTR = 'h2,
  EX_BREAKPOINT = 'h3,
  EX_LOAD_ADDR_MISALIGNED = 'h4,
  EX_LOAD_ACCESS_FAULT = 'h5,
  EX_STORE_ADDR_MISALIGNED = 'h6,
  EX_STORE_ACCESS_FAULT = 'h7,
  EX_M_ECALL = 'hB
} ex_type;

typedef struct packed {
  reg_idx rd_idx;
  gpreg rd_val;

  logic br_valid;
  addr br_target;

  // MRET, etc
  logic ret_valid;

  logic ex_valid;
  ex_type ex;
} exec_result;
// Flag priorities: ex_valid > ret_valid > br_valid

`endif // __EXEC_RESULT_SV__
