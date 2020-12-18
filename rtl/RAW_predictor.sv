`timescale 1ns / 1ps
module RAW_predictor(
    input wire [31:0] IF2ins,
    input wire [6:0] IDopcode,
    input wire [4:0] IDrd,
    output logic RAW_conflict
    );

    `include "frame.vh"
    `include "constants.vh"

    always_comb begin
        RAW_conflict = IDopcode == I_2_opcode && (
            IDrd == IF2ins[19:15] && ((IF2ins[6:0] != J_opcode && IF2ins[6:0] !=  U_2_opcode && IF2ins[6:0] != U_1_opcode) || (IF2ins[6:0] == E_opcode && IF2ins[14:12] != 3'b000))
            || IDrd == IF2ins[24:20] && (IF2ins[6:0] == B_opcode || IF2ins[6:0] ==  S_opcode || IF2ins[6:0] == R_opcode)
        );
    end
endmodule
