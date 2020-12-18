module reg_exp_convertor(
    input wire [11:0] csr,
    output logic [2:0] csr_reg
);

`include "constants.vh"

always_comb begin
    case(csr)
        mstatus : csr_reg = 3'b000;
        mtvec   : csr_reg = 3'b001;
        mscratch: csr_reg = 3'b010;
        mepc    : csr_reg = 3'b011;
        mcause  : csr_reg = 3'b100;
        mtval   : csr_reg = 3'b101;
        default : csr_reg = 3'b110;
    endcase
end
endmodule