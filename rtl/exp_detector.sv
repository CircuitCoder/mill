`timescale 1ns / 1ps

module exp_detector(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [11:0] csr,
    input wire [31:0] PCnow,
    input wire [31:0] m_status,
    input wire [31:0] rs1value,
    input wire [31:0] imm,

    input wire inst_illegal,
    input wire inst_addr_misaligned,

    output logic [31:0] mepc_change,
    output logic [31:0] mcause_change,
    output logic [31:0] m_status_change,
    output logic exp_occur,
    output logic mret_occur,
    output logic EX_shutdown
);
    `include "constants.vh"

    logic break_exp;
    logic call_exp;
    logic illegal_exp;

    logic load_addr_misaligned;
    logic store_addr_misaligned;
    logic load_access_fault;
    logic store_access_fault;
    logic [31:0] load_store_addr;

    assign load_store_addr = rs1value + imm;

    //if user-MODE, can't use M-mode instr
    assign illegal_exp = (opcode == E_opcode && m_status[12:11] == 2'b11
                            && ((funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011)
                                || (funct3 == 3'b000 && csr == 12'h302))) | inst_illegal;
    assign break_exp = (opcode == E_opcode && funct3 == 3'b000 && csr == ebreak_csr);
    assign call_exp = (opcode == E_opcode && funct3 == 3'b000 && csr == ecall_csr);

    always_comb begin
        if(opcode != I_2_opcode) begin
            load_access_fault = 1'b0;
            load_addr_misaligned = 1'b0;
        end
        else begin
            load_access_fault = 1'b0;
            //lw lh
            load_addr_misaligned = ((funct3 == 3'b001 || funct3 == 3'b101) && load_store_addr[0] != 1'b0)
                                || (funct3 == 3'b010 && load_store_addr[1:0] != 2'b00);
        end
    end

    always_comb begin
        if(opcode != S_opcode) begin
            store_access_fault = 1'b0;
            store_addr_misaligned = 1'b0;
        end
        else begin
            store_access_fault = 1'b0;
            //sw sh
            store_addr_misaligned = (funct3 == 3'b001 && load_store_addr[0] != 1'b0)
                                ||  (funct3 == 3'b010 && load_store_addr[1:0] != 2'b00);
        end
    end

    //if load or store exception occur, MEM must stop
    assign EX_shutdown = load_addr_misaligned | store_addr_misaligned
                    | load_access_fault | store_access_fault;

    assign exp_occur = break_exp | call_exp | illegal_exp | inst_addr_misaligned
                    | load_addr_misaligned | store_addr_misaligned | load_access_fault | store_access_fault;
    assign mret_occur = (opcode == E_opcode && funct3 == 3'b000 && csr == mret_csr);

    assign m_status_change = mret_occur ? 32'h00001800 : 32'h000000000;
    assign mepc_change = exp_occur ? PCnow : 32'h00000000;

    always_comb begin
        if(illegal_exp) begin
            mcause_change = 32'h00000002;
        end
        else if(inst_addr_misaligned) begin
            mcause_change = 32'h00000000;
        end
        else if(break_exp) begin
            mcause_change = 32'h00000008;
        end
        else if(call_exp) begin
            mcause_change = 32'h00000003;
        end
        else if(load_access_fault) begin
            mcause_change = 32'h00000005;
        end
        else if(store_access_fault) begin
            mcause_change = 32'h00000007;
        end
        else if(load_addr_misaligned) begin
            mcause_change = 32'h00000004;
        end
        else if(store_addr_misaligned) begin
            mcause_change = 32'h00000006;
        end
        else begin
            mcause_change = 32'h00000000;
        end
    end
endmodule