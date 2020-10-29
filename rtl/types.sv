`ifndef __TYPES_SV__
`define __TYPES_SV__

localparam XLEN = 32;

typedef logic [XLEN-1:0] gpreg; // General purpose register
typedef logic [31:0] instr; // Full-width instruction
typedef logic [31:0] addr; // Address
typedef logic [31:0] mtrans; // Memory transfer
typedef logic [4:0] reg_idx;

typedef struct packed {
  addr a;
  logic we;
  logic [3:0] be;
  mtrans d;
} mreq;

`include "types/decoupled.sv"
`include "types/instr.sv"
`include "types/exec_result.sv"
`include "types/csr_encoding.sv"

`endif // __TYPES_SV__
