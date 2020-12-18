`timescale 1ns / 1ps
module predictor_processor(
    input wire [52:0] predictor[7:0],
    input wire [20:0] currentPC,
    output logic [2:0] update_adr,
    output logic [31:0] predictor_result
    );
    
    wire [7:0] cmp;
    
    // 8 comparators for fully-connected BTB
    assign cmp[0] = (predictor[0][52:32] == currentPC);
    assign cmp[1] = (predictor[1][52:32] == currentPC);
    assign cmp[2] = (predictor[2][52:32] == currentPC);
    assign cmp[3] = (predictor[3][52:32] == currentPC);
    assign cmp[4] = (predictor[4][52:32] == currentPC);
    assign cmp[5] = (predictor[5][52:32] == currentPC);
    assign cmp[6] = (predictor[6][52:32] == currentPC);
    assign cmp[7] = (predictor[7][52:32] == currentPC);
    
    wire [7:0] lowbit;
    
    assign lowbit = (cmp & ((~cmp) + 1'b1)); // convert to one-hot
    
    wire [2:0] res;
    
    assign res[0] = lowbit[1] | lowbit[3] | lowbit[5] | lowbit[7];
    assign res[1] = lowbit[2] | lowbit[3] | lowbit[6] | lowbit[7];
    assign res[2] = lowbit[4] | lowbit[5] | lowbit[6] | lowbit[7];
    assign update_adr = res;
    
    always_comb begin
        if(cmp == 8'h00) begin
            predictor_result = {29'b0, 3'b100};
        end
        else begin
            predictor_result = predictor[res][31:0];
        end
    end
endmodule
