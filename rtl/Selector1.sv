`timescale 1ns / 1ps
module Selector1(
    input wire [6:0] opcode,
    input wire [31:0] rs1value,
    input wire [31:0] PC,

    output logic[31:0] oprand_1
);

`include "frame.vh"
`include "constants.vh"
always_comb begin
    case(opcode)
        J_opcode, U_2_opcode, B_opcode, I_3_opcode: begin
            oprand_1 = PC;
        end
        default: begin
            oprand_1 = rs1value;
        end
    endcase
end
endmodule