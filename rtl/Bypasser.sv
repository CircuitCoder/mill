`timescale 1ns / 1ps
// bypasser to resolve RAW conflict
module Bypasser(
    input wire [4:0] rs,
    input wire [31:0] rsvalue,
    input wire [4:0] e_bypass_r,
    input wire [31:0] e_bypass_v,
    input wire [4:0] w_bypass_r,
    input wire [31:0] w_bypass_v,
    output logic [31:0] bypasser_output
    );

    `include "frame.vh"
    `include "constants.vh"

    always_comb begin
        if (rs == 5'b0) begin
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
