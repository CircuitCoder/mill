//this module is similar with regfile
`timescale 1ns / 1ps
module regfile_exp(
    input wire reg_write,
    input wire [11:0] waddr,
    input wire [11:0] raddr,
    input wire [31:0] wdata,

    output logic [31:0] rdata,
    output logic [2:0] update_register_id,
    output logic [31:0] update_register_val,
    output logic [31:0] m_status,

    //get rid of mip and mie
    //resigters[6] can not be used, for reduce branch
    input wire [31:0] registers[6:0]
);

    `include "constants.vh"

    wire [2:0] waddr_reg;
    wire [2:0] raddr_reg;

    reg_exp_convertor csr_read(
        .csr(raddr),
        .csr_reg(raddr_reg)
    );

    reg_exp_convertor csr_write(
        .csr(waddr),
        .csr_reg(waddr_reg)
    );

    always_comb begin
        //write first, similar to regfile
        if(reg_write) begin
            update_register_id = waddr_reg;
            update_register_val = wdata;
        end
        else begin
            update_register_val = 32'h00000000;
            update_register_id  = 3'b110;
        end

        if(reg_write && raddr_reg == waddr_reg) begin
            rdata = wdata;
        end
        else begin
            rdata = registers[raddr_reg];
        end

        //confirm that always read m_status register
        if(reg_write && waddr_reg == 3'b000) begin
            m_status = wdata;
        end
        else begin
            m_status = registers[0];
        end
    end
endmodule