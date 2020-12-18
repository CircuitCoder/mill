`timescale 1ns / 1ps
module ALU_module(
    input wire[31:0] rs1value,
    input wire[31:0] rs2value,
    input wire[6:0] opcode,
    input wire[2:0] funct3,
    input wire[6:0] funct7,
    output logic [31:0] alu_result,
    output logic [31:0] alu_exp_result
);

    `include "constants.vh"

    logic slt_result;
    logic [31:0] ctz_result, clz_result;

    slt _slt(
        .oprand1(rs1value),
        .oprand2(rs2value),
        .slt_result(slt_result)
    );

    ctz _ctz(
        .oprand1(rs1value),
        .ctz_result(ctz_result)
    );

    ctz _clz(
        .oprand1({<<{rs1value}}),
        .ctz_result(clz_result)
    );
    
    wire[16:0] add16temp;
    wire[16:0] add16ans;
    
    assign add16temp = {1'b0, rs1value[15:0]} + {1'b0, rs2value[15:0]};
    assign add16ans = {1'b0, add16temp[15:0]} + {16'b0, add16temp[16:16]};

always_comb begin
    case(opcode)
        U_1_opcode: begin
            alu_result = rs2value;
            alu_exp_result = 0;
        end
        U_2_opcode, J_opcode, I_3_opcode, B_opcode, I_2_opcode, S_opcode: begin
            alu_result = rs1value + rs2value;
            alu_exp_result = 0;
        end
        I_1_opcode: begin
            alu_exp_result = 0;
            case (funct3)
                ADD_funct3: begin
                    alu_result = rs1value + rs2value;
                end
                SLL_funct3: begin
                    if (rs2value[11:5] == 7'b0) begin
                        alu_result = rs1value << rs2value[4:0];
                    end
                    else if (rs2value[11:0] == 12'b0110000_00000) begin
                        //clz
                        alu_result = clz_result;
                    end
                    else if (rs2value[11:0] == 12'b0110000_00001) begin
                        // ctz
                        alu_result = ctz_result;
                    end
                    else begin
                        alu_result = 0;
                    end
                end
                SLT_funct3: begin
                    alu_result = {31'b0, slt_result};
                end
                SLTU_funct3: begin
                    alu_result = {31'b0, rs1value < rs2value};
                end
                XOR_funct3: begin
                    alu_result = rs1value ^ rs2value;
                end
                SR_funct3: begin
                    case(funct7)
                        SRL_funct7: begin
                            alu_result = rs1value >> rs2value[4:0];
                        end
                        SRA_funct7: begin
                            alu_result = ({32{rs1value[31]}} << ( 32 -  rs2value[4:0])) | (rs1value >> rs2value[4:0]) ;
                        end
                        default: begin
                            alu_result = 0;
                        end
                    endcase
                end
                OR_funct3: begin
                    alu_result = rs1value | rs2value;
                end
                AND_funct3: begin
                    alu_result = rs1value & rs2value;
                end
                default: begin
                    alu_result = 0;
                end
            endcase
        end
        R_opcode: begin
            alu_exp_result = 0;
            case (funct3)
                ADD_funct3: begin
                    case(funct7)
                        ADD_funct7: begin
                            alu_result = rs1value + rs2value;
                        end
                        SUB_funct7: begin
                            alu_result = rs1value - rs2value;
                        end
                        ADD16_funct7: begin
                            alu_result = {16'b0, add16ans[15:0]};
                        end
                        BITREV_funct7: begin
                            alu_result = {<<8{rs1value}};
                        end
                        default: begin
                            alu_result = 0;
                        end
                    endcase
                end
                SLL_funct3: begin
                    alu_result = rs1value << rs2value[4:0];
                end
                SLT_funct3: begin
                    alu_result = {31'b0, slt_result};
                end
                SLTU_funct3: begin
                    alu_result = {31'b0, rs1value < rs2value};
                end
                XOR_funct3: begin
                    if (funct7 == 7'b0) begin
                        alu_result = rs1value ^ rs2value;
                    end
                    else if (funct7 == 7'b0000101) begin
                        //min
                        if (slt_result) begin
                            alu_result = rs1value;
                        end
                        else begin
                            alu_result = rs2value;
                        end
                    end
                    else begin
                        alu_result = 0;
                    end
                end
                SR_funct3: begin
                    case(funct7)
                        SRL_funct7: begin
                            alu_result = rs1value >> rs2value[4:0];
                        end
                        SRA_funct7: begin
                            alu_result = ({32{rs1value[31]}} << ( 32 -  rs2value[4:0])) | (rs1value >> rs2value[4:0]) ;
                        end
                        default: begin
                            alu_result = 0;
                        end
                    endcase
                end
                OR_funct3: begin
                    alu_result = rs1value | rs2value;
                end
                AND_funct3: begin
                    alu_result = rs1value & rs2value;
                end
                default: begin
                    alu_result = 0;
                end
            endcase
        end
        E_opcode:begin
            case(funct3)
                SLL_funct3:begin
                    alu_result     = rs2value;
                    alu_exp_result = rs1value;
                end
                SLT_funct3:begin
                    alu_result     = rs2value;
                    alu_exp_result = rs1value | rs2value;
                end
                SLTU_funct3:begin
                    alu_result     = rs2value;
                    alu_exp_result = ~rs1value & rs2value;
                end
                default:begin
                    alu_result = 0;
                    alu_exp_result = 0;
                end
            endcase
        end
        default: begin
            alu_result = 0;
            alu_exp_result = 0;
        end
    endcase
end
endmodule