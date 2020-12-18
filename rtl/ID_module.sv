`timescale 1ns / 1ps

module ID_module(
    input wire [31:0] ins,
    output logic [6:0] opcode,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] imm,
    output logic [11:0] cbm_detect
);

    `include "frame.vh"
    `include "constants.vh"

    always_comb begin
        rs1 = ins[19:15];
        rs2 = ins[24:20];
        if (ins[6:0] == S_opcode || ins[6:0] == B_opcode) begin
            rd = 5'b0;
        end
        else begin
            rd = ins[11:7];
        end
        cbm_detect = ins[31:20];
        opcode = ins[6:0];
        funct3 = ins[14:12];
        funct7 = ins[31:25];
        unique case(ins[6:0])
            J_opcode: begin
                imm = {
                    {11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0
                };
            end
            U_1_opcode, U_2_opcode: begin
                imm = {
                    ins[31:12], 12'b0
                };
            end
            B_opcode: begin
                imm = {
                    {19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0
                };
            end
            S_opcode: begin
                imm = {
                    {20{ins[31]}}, ins[31:25], ins[11:7]
                };
            end
            I_1_opcode, I_2_opcode, I_3_opcode:begin
                imm = {
                    {20{ins[31]}}, ins[31:20]
                };
            end
            default: begin
                imm = 32'h00000000;
            end
        endcase
    end
endmodule
