`timescale 1ns / 1ps

module csr_selector(
    input wire [11:0] csr,
    input wire [2:0] funct3,
    input wire [6:0] opcode,

    output logic[11:0] csr_r_output,
    output logic[11:0] csr_w_output
);

    `include "constants.vh"
    always_comb begin
        if(funct3 == 3'b000 && opcode == 7'b1110011) begin
            case(csr)
                //read mtvec
                ecall_csr, ebreak_csr:begin
                    csr_r_output = 12'h305;
                end
                //read mret register
                mret_csr: begin
                    csr_r_output = 12'h341;
                end
                //decided by first 12 bits
                default: begin
                    csr_r_output = csr;
                end
            endcase
        end
        else if(opcode == 7'b1110011 || opcode == 7'b0001111) begin
            csr_r_output = csr;
        end
        else begin
            //mtvec is fresh
            csr_r_output = 12'h305;
        end
    end

    //not exception: write for unused register
    assign csr_w_output = opcode == 7'b1110011 ? csr : 12'h000;
endmodule