`timescale 1ns / 1ps
//this module is similar with Bypasser, provide fresh exp_register value.
module Bypasser_exp(
    input wire [11:0] rs,
    input wire [31:0] rsvalue,
    input wire [11:0] e_bypass_r,
    input wire [31:0] e_bypass_v,
    input wire [11:0] w_bypass_r,
    input wire [31:0] w_bypass_v,
    output logic [31:0] bypasser_output
);

    `include "frame.vh"
    `include "constants.vh"

    wire [2:0] rs_reg;

    reg_exp_convertor _rs_reg(
        .csr(rs),
        .csr_reg(rs_reg)
    );

    always_comb begin
        if (rs_reg == 3'b110) begin
            bypasser_output = 32'b0;
        end
        else begin
            if (e_bypass_r == rs) begin
                bypasser_output = e_bypass_v;
            end
            else if (w_bypass_r == rs) begin
                bypasser_output = w_bypass_v;
            end
            else begin
                bypasser_output = rsvalue;
            end
        end
    end
endmodule