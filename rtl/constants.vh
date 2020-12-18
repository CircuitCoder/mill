localparam I_1_opcode = 7'b0010011; // addi slti sltiu xori ori andi slli srli srai clz ctz
localparam I_2_opcode = 7'b0000011; // lb lh lw lbu lhu
localparam I_3_opcode = 7'b1100111; // jalr
localparam R_opcode   = 7'b0110011; // add sub sll slt sltu xor srl sra or and min
localparam S_opcode   = 7'b0100011; // sb sh sw
localparam B_opcode   = 7'b1100011; // beq bne blt bge bltu bgeu
localparam J_opcode   = 7'b1101111; // jal
localparam U_1_opcode = 7'b0110111; // lui
localparam U_2_opcode = 7'b0010111; // auipc
localparam E_opcode   = 7'b1110011; // ecall ebreak mret csrrc csrrw csrrs

localparam ADD_funct3  = 3'b000; // add sub ecall ebreak mret (add16 bitrev)
localparam SLL_funct3  = 3'b001; // sll clz ctz csrrw
localparam SLT_funct3  = 3'b010; // slt csrrs
localparam SLTU_funct3 = 3'b011; // sltu csrrc
localparam XOR_funct3  = 3'b100; // xor min
localparam SR_funct3   = 3'b101; // srl sra
localparam OR_funct3   = 3'b110;
localparam AND_funct3  = 3'b111;

localparam ADD_funct7 = 7'b0000000;
localparam SUB_funct7 = 7'b0100000;
localparam ADD16_funct7   = 7'b0010000;
localparam BITREV_funct7  = 7'b0110000;
localparam SRL_funct7 = 7'b0000000;
localparam SRA_funct7 = 7'b0100000;

localparam LB_funct3  = 3'b000;
localparam LH_funct3  = 3'b001;
localparam LW_funct3  = 3'b010;
localparam LBU_funct3 = 3'b100;
localparam LHU_funct3 = 3'b101;

localparam BEQ_funct3  = 3'b000;
localparam BNE_funct3  = 3'b001;
localparam BLT_funct3  = 3'b100;
localparam BGE_funct3  = 3'b101;
localparam BLTU_funct3 = 3'b110;
localparam BGEU_funct3 = 3'b111;

localparam SB_funct3  = 3'b000;
localparam SH_funct3  = 3'b001;
localparam SW_funct3  = 3'b010;

localparam mstatus  = 12'h300;
localparam mtvec    = 12'h305;
localparam mscratch = 12'h340;
localparam mepc     = 12'h341;
localparam mcause   = 12'h342;
localparam mtval    = 12'h343;

localparam ecall_csr  = 12'h001;
localparam ebreak_csr = 12'h000;
localparam mret_csr   = 12'h302;