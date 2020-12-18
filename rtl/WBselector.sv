`timescale 1ns / 1ps
module WBselector(
    input wire base_read,
    input wire ext_read,
    input wire uart_read,
    input wire uart_lsr_read,
    input wire [3:0] byte_en,
    input wire val_signed,
    input wire [31:0] base_mem_val,
    input wire [31:0] ext_mem_val,
    input wire [31:0] alu_result,
    input wire [31:0] alu_exp_result,
    input wire [31:0] uart_lsr_val,
    output logic [31:0] WB_result,
    output logic [31:0] WB_exp_result
);

    `include "frame.vh"
    `include "constants.vh"

    always_comb begin
        case({base_read | uart_read, ext_read, uart_lsr_read})
            3'b100: begin
                case(byte_en)
                    4'b0011: begin
                        WB_result = {{16{val_signed&base_mem_val[31]}}, base_mem_val[31:16]};
                    end
                    4'b1100: begin
                        WB_result = {{16{val_signed&base_mem_val[15]}}, base_mem_val[15:0]};
                    end
                    4'b0111: begin
                        WB_result = {{24{val_signed&base_mem_val[31]}}, base_mem_val[31:24]};
                    end
                    4'b1011: begin
                        WB_result = {{24{val_signed&base_mem_val[23]}}, base_mem_val[23:16]};
                    end
                    4'b1101: begin
                        WB_result = {{24{val_signed&base_mem_val[15]}}, base_mem_val[15:8]};
                    end
                    4'b1110: begin
                        WB_result = {{24{val_signed&base_mem_val[7]}}, base_mem_val[7:0]};
                    end
                    default: begin
                        WB_result = base_mem_val;
                    end
                endcase
            end
            3'b010: begin
                case(byte_en)
                    4'b0011: begin
                        WB_result = {{16{val_signed&ext_mem_val[31]}}, ext_mem_val[31:16]};
                    end
                    4'b1100: begin
                        WB_result = {{16{val_signed&ext_mem_val[15]}}, ext_mem_val[15:0]};
                    end
                    4'b0111: begin
                        WB_result = {{24{val_signed&ext_mem_val[31]}}, ext_mem_val[31:24]};
                    end
                    4'b1011: begin
                        WB_result = {{24{val_signed&ext_mem_val[23]}}, ext_mem_val[23:16]};
                    end
                    4'b1101: begin
                        WB_result = {{24{val_signed&ext_mem_val[15]}}, ext_mem_val[15:8]};
                    end
                    4'b1110: begin
                        WB_result = {{24{val_signed&ext_mem_val[7]}}, ext_mem_val[7:0]};
                    end
                    default: begin
                        WB_result = ext_mem_val;
                    end
                endcase
            end
            3'b001: begin
                WB_result = uart_lsr_val;
            end
            default: begin
                WB_result = alu_result;
            end
        endcase
    end

    always_comb begin
        WB_exp_result = alu_exp_result;
    end
endmodule