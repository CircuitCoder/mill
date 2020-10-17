`ifndef __DECODED_INSTR_SV__
`define __DECODED_INSTR_SV__

typedef enum {
  INSTR_R, INSTR_I, INSTR_S, INSTR_U, INSTR_J, INSTR_B
} instr_fmt;

typedef enum {
  /* 00xxx */
  INSTR_LOAD,
  // LOAD_FP,
  // custom_0,
  INSTR_MISC_MEM,
  INSTR_OP_IMM,
  INSTR_AUIPC,
  // OP_IMM_32,
  // 48b extension

  /* 01xxx */
  INSTR_STORE,
  // STORE_FP,
  // custom_1,
  // AMO,
  INSTR_OP,
  INSTR_LUI,
  // OP_32,
  // 64b extension

  /* 10xxx has nothing in RV-I32 */

  /* 11xxx */
  INSTR_BRANCH,
  INSTR_JALR,
  // reserved
  INSTR_JAL,
  INSTR_SYSTEM,
  // reserved
  // custom_3
  // > 80b extension

  // Finally, our good old friend,
  INSTR_INVAL
} instr_op;

typedef struct packed {
  logic [31:0] imm;
  instr_op op;

  reg_idx rs1;
  reg_idx rs2;
  reg_idx rd;

  logic [2:0] funct3;
  // funct7 = imm[11:5]
} decoded_instr;

`endif // __DECODED_INSTR_SV__
