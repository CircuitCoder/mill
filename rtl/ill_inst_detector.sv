`timescale 1ns / 1ps
module ill_inst_detector(
    input wire [31:0] inst,

    output logic inst_illegal
);
    `include "constants.vh"

    wire [2:0] csr_reg;
    reg_exp_convertor csr_detect(
        .csr(inst[31:20]),
        .csr_reg(csr_reg)
    );

    always_comb begin
        case(inst[6:0])
            I_1_opcode: begin
                inst_illegal = (inst[14:12] == 3'b001 && inst[31:25] != 7'b0000000
                                && inst[31:20] != 12'h600 && inst[31:20] != 12'h601)
                            || (inst[14:12] == 3'b101 && inst[31:25] != 7'b0000000 && inst[31:25] != 7'b0100000);
            end
            I_2_opcode: begin
                inst_illegal = (inst[14:12] == 3'b011 || inst[14:12] == 3'b110 || inst[14:12] == 3'b111);
            end
            I_3_opcode: begin
                inst_illegal = (inst[14:12] != 3'b000);
            end
            R_opcode: begin
                inst_illegal = (inst[14:12] == 3'b000 && inst[31:25] != 7'b0000000 && inst[31:25] != 7'b0100000 
                                                      && inst[31:25] != 7'b0010000 && inst[31:25] != 7'b0110000)//add sub (add16 bitrev)
                            || ((inst[14:12] != 3'b000 && inst[14:12] != 3'b100 && inst[14:12] != 3'b101) && inst[31:25] != 7'b0000000)//sll slt sltu or and
                            || (inst[14:12] == 3'b100 && inst[31:25] != 7'b0000000 && inst[31:25] != 7'b0000101)//xor min
                            || (inst[14:12] == 3'b101 && inst[31:25] != 7'b0000000 && inst[31:25] != 7'b0100000);//srl sra
            end
            S_opcode: begin
                inst_illegal = (inst[14:12] != 3'b000 && inst[14:12] != 3'b001 && inst[14:12] != 3'b010);
            end
            B_opcode: begin
                inst_illegal = (inst[14:12] == 3'b010 || inst[14:12] == 3'b011);
            end
            J_opcode, U_1_opcode, U_2_opcode: begin
                inst_illegal = 1'b0;
            end
            E_opcode: begin
                inst_illegal = (inst[14:12] > 3'b011)
                            || (inst[14:12] < 3'b100 && inst[14:12] > 3'b000 && csr_reg == 3'b110)
                            || (inst[14:12] == 3'b000 && (inst[11:7] != 5'b00000 || inst[19:15] != 5'b00000) &&
                                inst[31:20] != 12'h000 && inst[31:20] != 12'h001 && inst[31:20] != 12'h302);
            end
            default:begin
                inst_illegal = inst == 32'h00000000 ? 1'b0 : 1'b1;
            end
       endcase
    end
endmodule