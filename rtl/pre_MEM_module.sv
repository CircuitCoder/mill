`timescale 1ns / 1ps
// prepare address, data, control for MEM stage
module pre_MEM_module(
    input wire [31:0] rs1value,
    input wire [31:0] rs2value,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [31:0] imm,
    output logic base_read,
    output logic base_write,
    output logic ext_read,
    output logic ext_write,
    output logic uart_read,
    output logic uart_write,
    output logic uart_lsr_read,
    output logic base_dataz,
    output logic base_ram_en,
    output logic [19:0] adr,
    output logic [3:0] byte_en,
    output logic [31:0] mem_val,
    output logic val_signed,
    output logic if_stop,

    output logic [19:0] base_adr_val,
    input wire [31:0] pc_wire,
    output logic [3:0] base_be_val,
    /*
    output logic vga_write,
    output logic [12:0] vga_adr,
    output logic [7:0] vga_data,*/
    
    input wire [2:0] uart_countdown,
    output logic [2:0] uart_countnext
    );

    logic [31:0] addr_reg;

    `include "frame.vh"
    `include "constants.vh"

    assign addr_reg = imm + rs1value;

    always_comb begin
        uart_read = addr_reg == 32'h1000_0000 && opcode == I_2_opcode 
            && (funct3 == LB_funct3 || funct3 == LBU_funct3);
        uart_write = addr_reg == 32'h1000_0000 && opcode == S_opcode 
            && funct3 == SB_funct3;
        uart_lsr_read = addr_reg == 32'h1000_0005 && opcode == I_2_opcode 
            && (funct3 == LB_funct3 || funct3 == LBU_funct3);
    end

    assign adr = addr_reg[21:2];
    /*
    assign vga_adr = addr_reg[12:0];
    assign vga_data = rs2value[7:0];*/
    always_comb begin
        case({opcode, funct3})
            {S_opcode, SH_funct3}: begin
                if (addr_reg[1]) begin
                    mem_val = {rs2value[15:0], 16'b0};
                end
                else begin
                    mem_val = {16'b0, rs2value[15:0]};
                end
            end
            {S_opcode, SB_funct3}: begin
                case(addr_reg[1:0])
                    2'b00: begin
                        mem_val = {24'b0, rs2value[7:0]};
                    end
                    2'b01: begin
                        mem_val = {16'b0, rs2value[7:0], 8'b0};
                    end
                    2'b10: begin
                        mem_val = {8'b0, rs2value[7:0], 16'b0};
                    end
                    default: begin
                        mem_val = {rs2value[7:0], 24'b0};
                    end
                endcase
            end
            default: begin
                mem_val = rs2value;
            end
        endcase
    end

    always_comb begin
        base_write = addr_reg[31:22] == 10'b1000_0000_00 && opcode == S_opcode 
            && (funct3 == SW_funct3 || funct3 == SH_funct3 || funct3 == SB_funct3);
        base_read = addr_reg[31:22] == 10'b1000_0000_00 && opcode == I_2_opcode 
            && (funct3 == LW_funct3 || funct3 == LH_funct3 || funct3 == LHU_funct3 || funct3 == LB_funct3 || funct3 == LBU_funct3);
        ext_write = addr_reg[31:22] == 10'b1000_0000_01 && opcode == S_opcode 
            && (funct3 == SW_funct3 || funct3 == SH_funct3 || funct3 == SB_funct3);
        ext_read = addr_reg[31:22] == 10'b1000_0000_01 && opcode == I_2_opcode 
            && (funct3 == LW_funct3 || funct3 == LH_funct3 || funct3 == LHU_funct3 || funct3 == LB_funct3 || funct3 == LBU_funct3);
        /*
        vga_write = addr_reg[31:13] == 19'b0100_0000_0000_0000_000 && opcode == S_opcode 
            && funct3 == SB_funct3;*/
    end

    always_comb begin
        case({opcode, funct3})
            {I_2_opcode, LW_funct3}, {S_opcode, SW_funct3}: begin
                byte_en = 4'b0000;
            end
            {I_2_opcode, LH_funct3}, {I_2_opcode, LHU_funct3}, {S_opcode, SH_funct3}: begin
                if (addr_reg[1]) begin
                    byte_en = 4'b0011;
                end
                else begin
                    byte_en = 4'b1100;
                end
            end
            {I_2_opcode, LB_funct3}, {I_2_opcode, LBU_funct3}, {S_opcode, SB_funct3}: begin
                case(addr_reg[1:0])
                    2'b00: begin
                        byte_en = 4'b1110;
                    end
                    2'b01: begin
                        byte_en = 4'b1101;
                    end
                    2'b10: begin
                        byte_en = 4'b1011;
                    end
                    default: begin
                        byte_en = 4'b0111;
                    end
                endcase
            end
            default: begin
                byte_en = 4'b0000;
            end
        endcase
    end

    assign val_signed = opcode == I_2_opcode && (funct3 == LW_funct3 || funct3 == LH_funct3 || funct3 == LB_funct3); // signed or unsigned
    assign base_dataz = ~(base_write | uart_write);
    assign if_stop = uart_read | uart_write | base_read | base_write | ext_read | ext_write; // IF stage stop for 1 cycle
    assign base_ram_en = uart_read | uart_write;

    assign base_adr_val = if_stop ? adr : pc_wire[21:2];
    assign base_be_val = if_stop ? byte_en : 4'b0000;
    
    // stop pipeline for 8 cycles to guarantee uart timing requirement
    always_comb begin
        if (uart_read || uart_write) begin
            uart_countnext = 3'b111;
        end
        else begin
            if(uart_countdown != 3'b000) begin
                uart_countnext = uart_countdown - 3'b001;
            end
            else begin
                uart_countnext = 3'b000;
            end
        end
    end
endmodule
