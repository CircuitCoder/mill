`timescale 1ns / 1ps
// judge whether jump
module brancher(
    input wire [31:0] oprand1,
    input wire [31:0] oprand2,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    output logic is_taken,
    output logic is_branch,
    output logic [31:0] imm_out,
    input wire [31:0] imm_in,
    input wire [31:0] IDpc
    );

    `include "frame.vh"
    `include "constants.vh"

    wire slt_result;

    slt _slt(
        .oprand1(oprand1),
        .oprand2(oprand2),
        .slt_result(slt_result)
    );

    assign is_branch = opcode == B_opcode || opcode == J_opcode || opcode == I_3_opcode;

    always_comb begin
        if (opcode == B_opcode) begin
            case(funct3)
                BEQ_funct3: begin
                    is_taken = oprand1 == oprand2;
                end
                BNE_funct3: begin
                    is_taken = oprand1 != oprand2;
                end
                BLT_funct3: begin
                    is_taken = slt_result;
                end
                BGE_funct3: begin
                    is_taken = ~slt_result;
                end
                BLTU_funct3: begin
                    is_taken = oprand1 < oprand2;
                end
                BGEU_funct3: begin
                    is_taken = oprand1 >= oprand2;
                end
                default: begin
                    is_taken = 1'b0;
                end
            endcase
        end
        else if (opcode == J_opcode) begin
            is_taken = 1'b1;
        end
        else if (opcode == I_3_opcode) begin // jalr
            is_taken = 1'b1;
        end
        else begin
            is_taken = 1'b0;
        end
        if (opcode == I_3_opcode) begin
            imm_out = oprand1 + imm_in - IDpc;
        end
        else begin
            imm_out = imm_in;
        end
    end
endmodule
