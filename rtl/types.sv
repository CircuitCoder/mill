`ifndef __TYPES_SV__
`define __TYPES_SV__

localparam XLEN = 32;

typedef logic [XLEN-1:0] gpreg; // General purpose register
typedef logic [31:0] instr; // Full-width instruction
typedef logic [31:0] addr; // Address
typedef logic [31:0] mtrans; // Memory transfer
typedef logic [4:0] reg_idx;

`include "types/decoupled.sv"
`include "types/decoded_instr.sv"

`endif // __TYPES_SV__
