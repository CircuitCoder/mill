`timescale 1ns / 1ps
module ctz(
    input wire [31:0] oprand1,
    output logic [31:0] ctz_result
    );

    wire [31:0] lowbit;
    
    assign lowbit = (oprand1 & ((~oprand1) + 1'b1));
    
    wire res0;
    wire res1;
    wire res2;
    wire res3;
    wire res4;
    
    assign res0 = lowbit[1] | lowbit[3] | lowbit[5] | lowbit[7]
                | lowbit[9] | lowbit[11]| lowbit[13]| lowbit[15]
                | lowbit[17]| lowbit[19]| lowbit[21]| lowbit[23]
                | lowbit[25]| lowbit[27]| lowbit[29]| lowbit[31];
                
    assign res1 = lowbit[2] | lowbit[3] | lowbit[6] | lowbit[7]
                | lowbit[10]| lowbit[11]| lowbit[14]| lowbit[15]
                | lowbit[18]| lowbit[19]| lowbit[22]| lowbit[23]
                | lowbit[26]| lowbit[27]| lowbit[30]| lowbit[31];
                
    assign res2 = lowbit[4] | lowbit[5] | lowbit[6] | lowbit[7]
                | lowbit[12]| lowbit[13]| lowbit[14]| lowbit[15]
                | lowbit[20]| lowbit[21]| lowbit[22]| lowbit[23]
                | lowbit[28]| lowbit[29]| lowbit[30]| lowbit[31];
                
    assign res3 = lowbit[8] | lowbit[9] | lowbit[10]| lowbit[11]
                | lowbit[12]| lowbit[13]| lowbit[14]| lowbit[15]
                | lowbit[24]| lowbit[25]| lowbit[26]| lowbit[27]
                | lowbit[28]| lowbit[29]| lowbit[30]| lowbit[31];
                
    assign res4 = lowbit[16]| lowbit[17]| lowbit[18]| lowbit[19]
                | lowbit[20]| lowbit[21]| lowbit[22]| lowbit[23]
                | lowbit[24]| lowbit[25]| lowbit[26]| lowbit[27]
                | lowbit[28]| lowbit[29]| lowbit[30]| lowbit[31];
    
    always_comb begin
        if (oprand1 == 32'b0) begin
            ctz_result = 32'd32;
        end
        else begin
            ctz_result = {27'b0, res4, res3, res2, res1, res0};
        end
    end
    
endmodule
