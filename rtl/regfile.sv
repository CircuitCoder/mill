`timescale 1ns / 1ps
module regfile(
    input wire reg_write,
    input wire [4:0] waddr,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [31:0] wdata,

    output logic [31:0] rdata1,
    output logic [31:0] rdata2,

    output logic [4:0] update_register_id,
    output logic [31:0] update_register_val,

    input wire [31:0] registers[31:0]
);

always_comb begin
    if(reg_write) begin
        update_register_id = waddr;
        update_register_val = wdata;
    end
    else begin
        update_register_id = 5'b0;
        update_register_val = 32'b0;
    end

    // x0 is special
    if (raddr1 == 5'b0) begin
        rdata1 = 32'b0;
    end
    // guarantee write first
    else if (reg_write && raddr1 == waddr) begin
        rdata1 = wdata;
    end
    else begin
        rdata1 = registers[raddr1];
    end

    if (raddr2 == 5'b0) begin
        rdata2 = 32'b0;
    end
    else if (reg_write && raddr2 == waddr) begin
        rdata2 = wdata;
    end
    else begin
        rdata2 = registers[raddr2];
    end
end
endmodule
