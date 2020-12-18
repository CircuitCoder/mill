`timescale 1ns / 1ps
module slt(
    input wire [31:0] oprand1,
    input wire [31:0] oprand2,
    output logic slt_result
    );
    
    always_comb begin
        case({oprand1[31], oprand2[31]})
            2'b01: begin
                slt_result = 1'b0;
            end
            2'b10: begin
                slt_result = 1'b1;
            end
            default: begin
                slt_result = oprand1 < oprand2;
            end
        endcase
    end
    
endmodule
