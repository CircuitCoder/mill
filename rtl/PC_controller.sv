`timescale 1ns / 1ps
module PC_controller(
    input wire [31:0] currentpc,
    input wire [31:0] IDpc,
    input wire [31:0] IDimm,
    input wire IDtaken,
    input wire [31:0] IDbias,
    input wire if_mem_conflict,
    input wire RAW_conflict,
    input wire stop_this_time,
    input wire IDvalid,
    output logic IF2_shutdown,
    output logic ID_shutdown,
    output logic [31:0] newPC,
    output logic [31:0] IF2bias,
    output logic stop_next_time,

    input wire [52:0] predictor[7:0],
    output logic update_predictor,
    output logic [2:0] update_adr,
    output logic [52:0] update_val,

    input wire exp_occur,
    input wire mret_occur,
    input wire [31:0] exp_jump_addr,
    output logic inst_addr_misaligned
);

    wire [31:0] bias_should_be;
    wire branch_error;
    wire [31:0] predictor_result;
    logic [31:0] PC_correct;

    // when the PC is not correct, take currentpc twice and flow the error.
    assign newPC = PC_correct[1:0] == 2'b00 ? PC_correct : currentpc;
    assign inst_addr_misaligned = PC_correct[1:0] != 2'b00;
    assign bias_should_be = IDtaken ? IDimm : {29'b0, 3'b100};
    assign branch_error = IDvalid && (IDbias != bias_should_be);

    // next line of BTB to edit
    predictor_processor _predictor_processor(
        .predictor(predictor),
        .currentPC({1'b0, currentpc[21:2]}),
        .update_adr(update_adr),
        .predictor_result(predictor_result)
    );

    always_comb begin
        if ((exp_occur | mret_occur) & exp_jump_addr != 0) begin
            IF2_shutdown = 1'b1;
            ID_shutdown = 1'b1;
            PC_correct = exp_jump_addr;
            IF2bias = 32'b0;
        end
        else if (RAW_conflict | branch_error) begin
            IF2_shutdown = 1'b1;
            ID_shutdown = 1'b1;
            PC_correct = IDpc + bias_should_be;
            IF2bias = 32'b0;
        end
        else begin
            IF2_shutdown = 1'b0;
            ID_shutdown = 1'b0;
            if(stop_this_time) begin
                PC_correct = currentpc;
                IF2bias = 32'b0;
            end
            else begin
                PC_correct = currentpc + predictor_result;
                IF2bias = predictor_result;
            end
        end
    end

    always_comb begin
        if (if_mem_conflict) begin
            stop_next_time = 1'b1;
        end
        else begin
            stop_next_time = 1'b0;
        end
    end

    // BTB to be edited below
    always_comb begin
        if (branch_error) begin
            update_predictor = 1'b1;
            update_val = {1'b0, IDpc[21:2], bias_should_be};
        end
        else begin
            update_predictor = 1'b0;
            update_val = 0;
        end
    end

endmodule
