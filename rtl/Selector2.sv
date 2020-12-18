`timescale 1ns / 1ps
module Selector2(
    input wire [6:0] opcode,
    input wire [31:0] rs2value,
    input wire [31:0] imm,
    input wire [31:0] rexpvalue,

    output logic[31:0] oprand_2
);

`include "frame.vh"
`include "constants.vh"

always_comb begin
    case(opcode)
        I_1_opcode, I_2_opcode, U_1_opcode, U_2_opcode, S_opcode, B_opcode: begin
            oprand_2 = imm;
        end
        J_opcode, I_3_opcode: begin
            oprand_2 = {29'b0, 3'b100};
        end
        E_opcode:begin
            oprand_2 = rexpvalue;
        end
        default: begin
            oprand_2 = rs2value;
        end
    endcase
end
endmodule