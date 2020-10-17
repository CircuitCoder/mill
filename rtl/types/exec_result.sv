`ifndef __EXEC_RESULT_SV__
`define __EXEC_RESULT_SV__

`include "types.sv";

typedef struct packed {
  reg_idx rd_idx;
  gpreg rd_val;

  logic br_valid;
  addr br_target;
} exec_result;

`endif // __EXEC_RESULT_SV__
