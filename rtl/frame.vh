typedef struct packed
{
    //logic issue_on;
    logic [31:0] pc;
    logic stop_next_time;
} IF_struct;

typedef struct packed
{
    logic [31:0] pc;
    logic [31:0] ins;
    logic [31:0] pcbias;
} IF2_struct;

typedef struct packed
{
    logic inst_illegal;
    logic inst_addr_misaligned;
    logic [4:0] rs1;
    logic [31:0] rs1value;
    logic [4:0] rs2;
    logic [31:0] rs2value;
    logic [4:0] rd;
    logic [11:0] csr_r;
    logic [11:0] csr_w;
    logic [31:0] m_status;
    logic [11:0] cbm_detect;
    logic [31:0] rexpvalue;
    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [31:0] imm;
    logic [31:0] pc;
    logic [6:0] funct7;
    logic [31:0] pcbias;
} ID_struct;

typedef struct packed
{
    logic [4:0] rd;
    logic [11:0] csr_w;
    logic [6:0] opcode;
    logic [31:0] alu_result;
    logic [31:0] alu_exp_result;
    logic base_ram_en; // 1
    logic base_dataz; // 1
    logic base_read; // 0
    logic base_write; // 0
    logic ext_read; // 0
    logic ext_write; // 0
    logic [19:0] adr;
    logic [3:0] byte_en;
    logic [31:0] mem_val;
    logic uart_read; // 0
    logic uart_write; // 0
    logic uart_lsr_read; // 0
    logic val_signed; // 1

    logic [31:0] pc; //debug
    logic [19:0] base_adr_val;
    logic [3:0] base_be_val;
    /*
    logic vga_write;
    logic [12:0] vga_adr;
    logic [7:0] vga_data;*/
} EX_struct;

typedef struct packed
{
    logic [4:0] rd;
    logic [11:0] csr_w;
    logic [31:0] alu_result;
    logic [31:0] alu_exp_result;
    logic [31:0] base_mem_val;
    logic [31:0] ext_mem_val;
    logic base_read;
    logic ext_read;
    logic [3:0] byte_en;
    logic [7:0] uart_lsr_val;
    logic uart_lsr_read;
    logic WB_enable;
    logic WB_exp_enable;
    logic val_signed;
    logic uart_read;
} MEM_struct;
