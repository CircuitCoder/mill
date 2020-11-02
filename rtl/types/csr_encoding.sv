`ifndef __CSR_ENCODING_SV__
`define __CSR_ENCODING_SV__

`include "types.sv"

typedef logic [1:0] csr_req_type;
localparam csr_req_type CSRW = 2'b01, CSRS = 2'b10, CSRC = 2'b11;

typedef logic [11:0] csr_addr;

// MRO
localparam csr_addr CSR_MVENDORID = 'hF11;
localparam csr_addr CSR_MARCHID = 'hF12;
localparam csr_addr CSR_MIMPID = 'hF13;
localparam csr_addr CSR_MHARTID = 'hF14;

// MRW
localparam csr_addr CSR_MSTATUS = 'h300;
localparam csr_addr CSR_MISA = 'h301;
localparam csr_addr CSR_MIE = 'h304;
localparam csr_addr CSR_MTVEC = 'h305;

localparam csr_addr CSR_MSCRATCH = 'h340;
localparam csr_addr CSR_MEPC = 'h341;
localparam csr_addr CSR_MCAUSE = 'h342;
localparam csr_addr CSR_MTVAL = 'h343;
localparam csr_addr CSR_MIP = 'h344;

// We don't supports PMP

// We only supports two of the mandatory timers
localparam csr_addr CSR_MCYCLE = 'hb00;
localparam csr_addr CSR_MINSTRET = 'hb02;

localparam csr_addr CSR_MCYCLEH = 'hb80;
localparam csr_addr CSR_MINSTRETH = 'hb82;

localparam csr_addr CSR_MCOUNTINHIBIT = 'h320;

typedef struct packed {
  csr_req_type t;
  csr_addr a;
  gpreg d;
} csr_req;

typedef struct packed {
  gpreg d;
  logic exists;
} csr_resp;

typedef enum {
  CSR_EFF_IDLE,
  CSR_EFF_INSTRET,
  CSR_EFF_EX,
  CSR_EFF_INT,
  CSR_EFF_RET
} csr_effect_type;

typedef struct packed {
  csr_effect_type t;
  // Payloads
  logic [3:0] src;
  gpreg epc;
  gpreg tval;
} csr_effect;

`endif // __CSR_ENCODING_SV__
