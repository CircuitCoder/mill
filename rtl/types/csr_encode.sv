`ifndef __CSR_ENCODE_SV__
`define __CSR_ENCODE_SV__

`include "types.sv"

typedef enum [1:0] {
  CSRW = 2'b01, CSRS = 2'b10, CSRC = 2'b11
} csr_req_type;

typedef enum [11:0] {
  // MRO
  CSR_MVENDORID = 'hF11,
  CSR_MARCHID = 'hF12,
  CSR_MIMPID = 'hF13,
  CSR_MHARTID = 'hF14,

  // MRW
  CSR_MSTATUS = 'h300,
  CSR_MISA = 'h301,
  CSR_MIE = 'h304,
  CSR_MTVEC = 'h305,

  CSR_MSCRATCH = 'h340,
  CSR_MEPC = 'h341,
  CSR_MCAUSE = 'h342,
  CSR_MTVAL = 'h343,
  CSR_MIP = 'h344,

  // We don't supports PMP

  // We only supports two of the mandatory timers
  CSR_MCYCLE = 'hb00,
  CSR_MINSTRET = 'hb02,

  CSR_MCYCLEH = 'hb80,
  CSR_MINSTRETH = 'hb82,

  CSR_MCOUNTINHIBIT = 'h320
} csr_addr;

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

`endif // __CSR_ENCODE_SV__
