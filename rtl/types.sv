`ifndef __TYPES_SV__
`define __TYPES_SV__

`include "types/decoupled.sv"

localparam XLEN = 32;

typedef bit [XLEN-1:0] gpreg; // General purpose register
typedef bit [31:0] instr; // Full-width instruction

`endif // __TYPES_SV__
