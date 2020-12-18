`default_nettype none

`timescale 1ns / 1ps

module core(
    input wire clk,
    input wire clkshift,
    input wire rst,
    /*
    output wire uart_rdn,
    output wire uart_wrn,*/
    input wire uart_ready,
    input wire uart_tbre,
    input wire uart_tsre,

    inout wire[31:0] base_data,
    output wire[19:0] base_adr,
    output wire [3:0] base_be,
    output wire base_ce,
    output wire base_oe,
    output wire base_we,

    inout wire[31:0] ext_data,
    output wire[19:0] ext_adr,
    output wire [3:0] ext_be,
    output wire ext_ce,
    output wire ext_oe,
    output wire ext_we
    /*
    output logic [7:0] vga_data,
    output logic [12:0] vga_adr,
    output logic vga_we*/
    );
    
    `include "frame.vh"
    `include "constants.vh"

    logic IF_valid;
    logic IF2_valid;
    logic ID_valid;
    logic EX_valid;
    logic MEM_valid;

    logic IF_ready;
    logic IF2_ready;
    logic ID_ready;
    logic EX_ready;
    logic MEM_ready;

    // uart stall variable
    logic [2:0] uart_countdown;
    wire [2:0] uart_countdown_wire;
    wire uart_not_stall;
    assign uart_not_stall = (uart_countdown == 3'b000);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            uart_countdown <= 3'b000;
        end
        else begin
            uart_countdown <= uart_countdown_wire;
        end
    end
    
    // currently they are always true
    assign IF_ready = IF2_ready || !IF_valid;
    assign IF2_ready = ID_ready || !IF2_valid;
    assign ID_ready = EX_ready || !ID_valid;
    assign EX_ready = MEM_ready || !EX_valid;
    assign MEM_ready = (1'b1) || !MEM_valid;

    IF_struct IF_data;
    IF2_struct IF2_data;
    ID_struct ID_data;
    EX_struct EX_data;
    MEM_struct MEM_data;

    wire [31:0] WB_selector_result;
    wire [31:0] WB_selector_exp_result;
    wire branch_is_taken;
    wire is_branch;
    wire RAW_conflict;
    wire if_mem_conflict;

    wire IF2_conflict_control;
    wire ID_conflict_control;

    wire [31:0] ID_data_rs1value;
    wire [31:0] ID_data_rs2value;

    wire [31:0] ID_data_rexpvalue;
    wire [11:0] csr_r_res;
    wire [11:0] csr_w_res;
    logic [31:0] m_status;

    wire [4:0] update_register_id;
    wire [2:0] update_exp_register_id;
    wire [31:0] update_register_value;
    wire [31:0] update_exp_resigter_value;

    logic [31:0] registers[31:0];
    logic [31:0] exp_registers[6:0];

    wire inst_illegal;

    regfile _regfile(
        .reg_write(MEM_data.WB_enable),
        .waddr(MEM_data.rd),
        .raddr1(IF2_data.ins[19:15]),
        .raddr2(IF2_data.ins[24:20]),
        .wdata(WB_selector_result),
        .rdata1(ID_data_rs1value),
        .rdata2(ID_data_rs2value),

        .update_register_id(update_register_id),
        .update_register_val(update_register_value),

        .registers(registers)
    );

    csr_selector _csr_selector(
        .csr(IF2_data.ins[31:20]),
        .funct3(IF2_data.ins[14:12]),
        .opcode(IF2_data.ins[6:0]),

        .csr_r_output(csr_r_res),
        .csr_w_output(csr_w_res)
    );

    regfile_exp _regfile_exp(
        .reg_write(MEM_data.WB_exp_enable),
        .waddr(MEM_data.csr_w),
        .raddr(csr_r_res),
        .wdata(WB_selector_exp_result),
        .rdata(ID_data_rexpvalue),

        .update_register_id(update_exp_register_id),
        .update_register_val(update_exp_resigter_value),
        .m_status(m_status),

        .registers(exp_registers)
    );

    ill_inst_detector _ill_inst_detector(
        .inst(IF2_data.ins),
        .inst_illegal(inst_illegal)
    );

    wire [31:0] IF_data_pc;
    wire [31:0] IF2_data_pcbias;
    wire IF_data_stop_next_time;
    wire [31:0] brancher_imm_out;

    wire [31:0] mepc_change;
    wire [31:0] mcause_change;
    wire [31:0] m_status_change;
    wire exp_occur;
    wire mret_occur;
    wire [31:0] bypasser3_output;

    wire inst_addr_misaligned;
    
    // predictor register 21 + 32 = 53
    logic [52:0] predictor[7:0];
    logic [1:0] bht[7:0];
    wire predictor_update_signal;
    wire [2:0] predictor_update_adr;
    wire [52:0] predictor_update_val;

    PC_controller _pc_controller(
        .currentpc(IF_data.pc),
        .IDpc(ID_data.pc),
        .IDimm(brancher_imm_out),
        .IDtaken(branch_is_taken),
        .IDbias(ID_data.pcbias),
        .if_mem_conflict(if_mem_conflict),
        .RAW_conflict(RAW_conflict),
        .stop_this_time(IF_data.stop_next_time),
        .IDvalid(ID_valid),
        .IF2_shutdown(IF2_conflict_control),
        .ID_shutdown(ID_conflict_control),
        .newPC(IF_data_pc),
        .IF2bias(IF2_data_pcbias),
        .stop_next_time(IF_data_stop_next_time),
        .exp_occur(exp_occur),
        .mret_occur(mret_occur),
        .exp_jump_addr(bypasser3_output),
        .inst_addr_misaligned(inst_addr_misaligned),
        .predictor(predictor),
        .update_predictor(predictor_update_signal),
        .update_adr(predictor_update_adr),
        .update_val(predictor_update_val)
    );

    // update predictor
    always_ff @(posedge clk)
    begin
        if (rst) begin
            predictor[0]  <= {53{1'b1}};
            predictor[1]  <= {53{1'b1}};
            predictor[2]  <= {53{1'b1}};
            predictor[3]  <= {53{1'b1}};
            predictor[4]  <= {53{1'b1}};
            predictor[5]  <= {53{1'b1}};
            predictor[6]  <= {53{1'b1}};
            predictor[7]  <= {53{1'b1}};
            bht[0] <= 2'b01;
            bht[1] <= 2'b01;
            bht[2] <= 2'b01;
            bht[3] <= 2'b01;
            bht[4] <= 2'b01;
            bht[5] <= 2'b01;
            bht[6] <= 2'b01;
            bht[7] <= 2'b01;
        end
        else if (uart_not_stall && is_branch) begin
            if (predictor_update_signal && (!(branch_is_taken && bht[predictor_update_adr] == 2'b00
                || !branch_is_taken && bht[predictor_update_adr] == 2'b11))) begin
                predictor[1] <= predictor[0];
                predictor[2] <= predictor[1];
                predictor[3] <= predictor[2];
                predictor[4] <= predictor[3];
                predictor[5] <= predictor[4];
                predictor[6] <= predictor[5];
                predictor[7] <= predictor[6];
                bht[1] <= bht[0];
                bht[2] <= bht[1];
                bht[3] <= bht[2];
                bht[4] <= bht[3];
                bht[5] <= bht[4];
                bht[6] <= bht[5];
                bht[7] <= bht[6];
                case(bht[predictor_update_adr])
                    2'b00: begin
                        if (branch_is_taken) begin
                            bht[0] <= 2'b01;
                        end
                    end
                    2'b01: begin
                        if (branch_is_taken) begin
                            bht[0] <= 2'b10;
                        end
                        else begin
                            bht[0] <= 2'b00;
                        end
                    end
                    2'b10: begin
                        if (branch_is_taken) begin
                            bht[0] <= 2'b11;
                        end
                        else begin
                            bht[0] <= 2'b01;
                        end
                    end
                    default: begin
                        if (!branch_is_taken) begin
                            bht[0] <= 2'b10;
                        end
                    end
                endcase
                predictor[0] <= predictor_update_val;
            end
            else begin
                case(bht[predictor_update_adr])
                    2'b00: begin
                        if (branch_is_taken) begin
                            bht[predictor_update_adr] <= 2'b01;
                        end
                    end
                    2'b01: begin
                        if (branch_is_taken) begin
                            bht[predictor_update_adr] <= 2'b10;
                        end
                        else begin
                            bht[predictor_update_adr] <= 2'b00;
                        end
                    end
                    2'b10: begin
                        if (branch_is_taken) begin
                            bht[predictor_update_adr] <= 2'b11;
                        end
                        else begin
                            bht[predictor_update_adr] <= 2'b01;
                        end
                    end
                    default: begin
                        if (!branch_is_taken) begin
                            bht[predictor_update_adr] <= 2'b10;
                        end
                    end
                endcase
            end
        end
    end

    // update register
    always_ff @(posedge clk)
    begin
        if (rst) begin
            registers[0] <= 0;
            registers[1] <= 0;
            registers[2] <= 0;
            registers[3] <= 0;
            registers[4] <= 0;
            registers[5] <= 0;
            registers[6] <= 0;
            registers[7] <= 0;
            registers[8] <= 0;
            registers[9] <= 0;
            registers[10] <= 0;
            registers[11] <= 0;
            registers[12] <= 0;
            registers[13] <= 0;
            registers[14] <= 0;
            registers[15] <= 0;
            registers[16] <= 0;
            registers[17] <= 0;
            registers[18] <= 0;
            registers[19] <= 0;
            registers[20] <= 0;
            registers[21] <= 0;
            registers[22] <= 0;
            registers[23] <= 0;
            registers[24] <= 0;
            registers[25] <= 0;
            registers[26] <= 0;
            registers[27] <= 0;
            registers[28] <= 0;
            registers[29] <= 0;
            registers[30] <= 0;
            registers[31] <= 0;
        end
        else if (uart_not_stall) begin
            registers[update_register_id] <= update_register_value;
        end
    end

    //update exp_registers
    always_ff @(posedge clk)
    begin
        if(rst) begin
            exp_registers[0] <= 0;
            exp_registers[1] <= 0;
            exp_registers[2] <= 0;
            exp_registers[3] <= 0;
            exp_registers[4] <= 0;
            exp_registers[5] <= 0;
            exp_registers[6] <= 0;
        end
        else if (uart_not_stall) begin
            if(exp_occur) begin
                exp_registers[4] <= mcause_change;
                exp_registers[3] <= mepc_change;
            end
            if(exp_occur | mret_occur) begin
                exp_registers[0] <= m_status_change;
            end
            exp_registers[update_exp_register_id] <= update_exp_resigter_value;
        end
    end

    // IF
    always_ff @(posedge clk)
    begin
        if (rst) begin
            IF_valid <= 1'b0;
            IF_data.pc <= 32'h7ffffffc;
            IF_data.stop_next_time <= 0;
            //IF_data.issue_on <= 0;
        end
        else if (uart_not_stall && IF_ready) begin
            IF_data.pc <= IF_data_pc;
            IF_data.stop_next_time <= IF_data_stop_next_time;
            //IF_data.issue_on <= !if_mem_conflict;
            IF_valid <= !if_mem_conflict;
        end
    end

    // IF2
    always_ff @(posedge clk)
    begin
        if (rst) begin
            IF2_valid <= 1'b0;
            IF2_data <= 0;
        end
        else if (uart_not_stall && IF2_ready) begin
            IF2_valid <= (IF_valid && (!IF2_conflict_control));
            if ((IF_valid && (!IF2_conflict_control))) begin
                IF2_data.pcbias <= IF2_data_pcbias;
                IF2_data.ins <= base_data;
                IF2_data.pc <= IF_data.pc;
            end
            else begin
                IF2_data <= 0;
            end
        end
    end

    // ID
    wire [6:0] ID_data_opcode;
    wire [4:0] ID_data_rs1;
    wire [4:0] ID_data_rs2;
    wire [4:0] ID_data_rd;
    wire [2:0] ID_data_funct3;
    wire [6:0] ID_data_funct7;
    wire [31:0] ID_data_imm;
    wire [11:0] cbm_detect;
    ID_module _ID_module(
        .ins(IF2_data.ins),
        .opcode(ID_data_opcode),
        .rs1(ID_data_rs1),
        .rs2(ID_data_rs2),
        .rd(ID_data_rd),
        .funct3(ID_data_funct3),
        .funct7(ID_data_funct7),
        .imm(ID_data_imm),
        .cbm_detect(cbm_detect)
    );

    always_ff @(posedge clk)
    begin
        if (rst) begin
            ID_data <= 0;
            ID_valid <= 1'b0;
        end
        else if (uart_not_stall && ID_ready) begin
            ID_valid <= (IF2_valid && (!ID_conflict_control));
            if ((IF2_valid && (!ID_conflict_control))) begin
                ID_data.opcode <= ID_data_opcode;
                ID_data.rs1 <= ID_data_rs1;
                ID_data.rs2 <= ID_data_rs2;
                ID_data.rd <= ID_data_rd;
                ID_data.funct3 <= ID_data_funct3;
                ID_data.funct7 <= ID_data_funct7;
                ID_data.imm <= ID_data_imm;
                ID_data.pcbias <= IF2_data.pcbias;
                ID_data.pc <= IF2_data.pc;
                ID_data.rs1value <= ID_data_rs1value;
                ID_data.rs2value <= ID_data_rs2value;
                ID_data.csr_r <= csr_r_res;
                ID_data.csr_w <= csr_w_res;
                ID_data.m_status <= m_status;
                ID_data.cbm_detect <= cbm_detect;
                ID_data.inst_illegal <= inst_illegal;
                ID_data.inst_addr_misaligned <= inst_addr_misaligned;
                ID_data.rexpvalue <= ID_data_rexpvalue;
            end
            else begin
                ID_data <= 0;
            end
        end
    end

    // EX
    RAW_predictor _raw_predictor(
        .IF2ins(IF2_data.ins),
        .IDopcode(ID_data.opcode),
        .IDrd(ID_data.rd),
        .RAW_conflict(RAW_conflict)
    );

    wire [31:0] bypasser1_output;
    wire [31:0] bypasser2_output;
    wire [31:0] bypasser4_output;

    wire [31:0] selector1_output;
    wire [31:0] selector2_output;

    wire memory_read_error;

    Bypasser _bypasser1(
        .rs(ID_data.rs1),
        .rsvalue(ID_data.rs1value),
        .e_bypass_r(EX_data.rd),
        .e_bypass_v(EX_data.alu_result),
        .w_bypass_r(MEM_data.rd),
        .w_bypass_v(WB_selector_result),
        .bypasser_output(bypasser1_output)
    );

    Bypasser _bypasser2(
        .rs(ID_data.rs2),
        .rsvalue(ID_data.rs2value),
        .e_bypass_r(EX_data.rd),
        .e_bypass_v(EX_data.alu_result),
        .w_bypass_r(MEM_data.rd),
        .w_bypass_v(WB_selector_result),
        .bypasser_output(bypasser2_output)
    );

    Bypasser_exp _bypasser3(
        .rs(ID_data.csr_r),
        .rsvalue(ID_data.rexpvalue),
        .e_bypass_r(EX_data.csr_w),
        .e_bypass_v(EX_data.alu_exp_result),
        .w_bypass_r(MEM_data.csr_w),
        .w_bypass_v(WB_selector_exp_result),
        .bypasser_output(bypasser3_output)
    );

    Bypasser_exp _bypasser4(
        .rs(12'h300),
        .rsvalue(ID_data.m_status),
        .e_bypass_r(EX_data.csr_w),
        .e_bypass_v(EX_data.alu_exp_result),
        .w_bypass_r(MEM_data.csr_w),
        .w_bypass_v(WB_selector_exp_result),
        .bypasser_output(bypasser4_output)
    );

    exp_detector _exp_detector(
        .opcode(ID_data.opcode),
        .funct3(ID_data.funct3),
        .csr(ID_data.cbm_detect),
        .rs1value(bypasser1_output),
        .imm(ID_data.imm),
        .PCnow(ID_data.pc),
        .m_status(bypasser4_output),
        .mepc_change(mepc_change),
        .mcause_change(mcause_change),
        .m_status_change(m_status_change),
        .inst_illegal(ID_data.inst_illegal),
        .inst_addr_misaligned(ID_data.inst_addr_misaligned),
        .exp_occur(exp_occur),
        .mret_occur(mret_occur),
        .EX_shutdown(memory_read_error)
    );

    Selector1 _selector1(
        .opcode(ID_data.opcode),
        .rs1value(bypasser1_output),
        .PC(ID_data.pc),
        .oprand_1(selector1_output)
    );

    Selector2 _selector2(
        .opcode(ID_data.opcode),
        .rs2value(bypasser2_output),
        .imm(ID_data.imm),
        .rexpvalue(bypasser3_output),
        .oprand_2(selector2_output)
    );

    wire [31:0] EX_data_alu_result;
    wire [31:0] EX_data_alu_exp_result;

    ALU_module _alu_module(
        .rs1value(selector1_output),
        .rs2value(selector2_output),
        .opcode(ID_data.opcode),
        .funct3(ID_data.funct3),
        .funct7(ID_data.funct7),
        .alu_result(EX_data_alu_result),
        .alu_exp_result(EX_data_alu_exp_result)
    );

    brancher _brancher(
        .oprand1(bypasser1_output),
        .oprand2(bypasser2_output),
        .opcode(ID_data.opcode),
        .funct3(ID_data.funct3),
        .is_taken(branch_is_taken),
        .is_branch(is_branch),
        .imm_out(brancher_imm_out),
        .imm_in(ID_data.imm),
        .IDpc(ID_data.pc)
    );

    wire EX_data_base_read;
    wire EX_data_base_write;
    wire EX_data_ext_read;
    wire EX_data_ext_write;
    wire EX_data_uart_read;
    wire EX_data_uart_write;
    wire EX_data_uart_lsr_read;
    wire EX_data_base_dataz;
    wire EX_data_base_ram_en;
    wire [19:0] EX_data_adr;
    wire [3:0] EX_data_byte_en;
    wire [31:0] EX_data_mem_val;
    wire EX_data_val_signed;
    wire [19:0] EX_data_base_adr_val;
    wire [3:0] EX_data_base_be_val;
    /*
    wire EX_data_vga_write;
    wire [12:0] EX_data_vga_adr;
    wire [7:0] EX_data_vga_data;*/
    
    pre_MEM_module _pre_mem_module(
        .rs1value(bypasser1_output),
        .rs2value(bypasser2_output),
        .opcode(ID_data.opcode),
        .funct3(ID_data.funct3),
        .imm(ID_data.imm),
        .base_read(EX_data_base_read),
        .base_write(EX_data_base_write),
        .ext_read(EX_data_ext_read),
        .ext_write(EX_data_ext_write),
        .uart_read(EX_data_uart_read),
        .uart_write(EX_data_uart_write),
        .uart_lsr_read(EX_data_uart_lsr_read),
        .base_dataz(EX_data_base_dataz),
        .base_ram_en(EX_data_base_ram_en),
        .adr(EX_data_adr),
        .byte_en(EX_data_byte_en),
        .mem_val(EX_data_mem_val),
        .val_signed(EX_data_val_signed),
        .if_stop(if_mem_conflict),
        .base_adr_val(EX_data_base_adr_val),
        .pc_wire(IF_data_pc),
        .base_be_val(EX_data_base_be_val),
        /*
        .vga_write(EX_data_vga_write),
        .vga_adr(EX_data_vga_adr),
        .vga_data(EX_data_vga_data),*/
        
        .uart_countdown(uart_countdown),
        .uart_countnext(uart_countdown_wire)
    );
    
    always_ff @(posedge clk)
    begin
        if (rst) begin
            EX_data <= 0;
            EX_valid <= 1'b0;
        end
        else if (uart_not_stall && EX_ready) begin
            EX_valid <= (ID_valid && (!memory_read_error));
            EX_data.base_adr_val <= EX_data_base_adr_val;
            EX_data.base_be_val <= EX_data_base_be_val; // these two should always work
            if ((ID_valid && (!memory_read_error))) begin
                EX_data.alu_result <= EX_data_alu_result;
                EX_data.alu_exp_result <= EX_data_alu_exp_result;
                EX_data.opcode <= ID_data.opcode;
                EX_data.rd <= ID_data.rd;
                EX_data.csr_w <= ID_data.csr_w;
                EX_data.base_read <= EX_data_base_read;
                EX_data.base_write <= EX_data_base_write;
                EX_data.ext_read <= EX_data_ext_read;
                EX_data.ext_write <= EX_data_ext_write;
                EX_data.uart_read <= EX_data_uart_read;
                EX_data.uart_write <= EX_data_uart_write;
                EX_data.uart_lsr_read <= EX_data_uart_lsr_read;
                EX_data.base_dataz <= EX_data_base_dataz;
                EX_data.base_ram_en <= EX_data_base_ram_en;
                EX_data.adr <= EX_data_adr;
                EX_data.byte_en <= EX_data_byte_en;
                EX_data.mem_val <= EX_data_mem_val;
                EX_data.val_signed <= EX_data_val_signed;
                EX_data.pc <= ID_data.pc;
                /*
                EX_data.vga_write <= EX_data_vga_write;
                EX_data.vga_adr <= EX_data_vga_adr;
                EX_data.vga_data <= EX_data_vga_data;*/
            end
            else begin
                EX_data.alu_result <= 0;
                EX_data.alu_exp_result <= 0;
                EX_data.opcode <= 0;
                EX_data.rd <= 0;
                EX_data.csr_w <= 0;
                EX_data.base_read <= 0;
                EX_data.base_write <= 0;
                EX_data.ext_read <= 0;
                EX_data.ext_write <= 0;
                EX_data.uart_read <= 0;
                EX_data.uart_write <= 0;
                EX_data.uart_lsr_read <= 0;
                EX_data.base_dataz <= 1'b1;
                EX_data.base_ram_en <= 0;
                EX_data.adr <= 0;
                EX_data.byte_en <= 0;
                EX_data.mem_val <= 0;
                EX_data.val_signed <= 0;
                //EX_data.pc <= 0;
                /*
                EX_data.vga_write <= 0;
                EX_data.vga_adr <= 0;
                EX_data.vga_data <= 0;*/
            end
        end
    end

    // MEM
    assign base_ce = EX_data.base_ram_en;
    assign base_oe = EX_data.base_ram_en;
    assign base_we = !(EX_data.base_write & clkshift); // combine with clkshift to enable continuous 1 cycle write
    assign base_adr = EX_data.base_adr_val;
    assign base_be = EX_data.base_be_val;

    assign ext_ce = 1'b0;
    assign ext_oe = 1'b0;
    assign ext_we = !(EX_data.ext_write & clkshift);
    assign ext_adr = EX_data.adr;
    assign ext_be = EX_data.byte_en;

    assign base_data = EX_data.base_dataz ? 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz : EX_data.mem_val;
    assign ext_data = EX_data.ext_write ? EX_data.mem_val : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    /*
    assign uart_rdn = ! (EX_data.uart_read && base_ce);
    assign uart_wrn = ! (EX_data.uart_write && base_ce);
    
    assign vga_we = EX_data.vga_write;
    assign vga_adr = EX_data.vga_adr;
    assign vga_data = EX_data.vga_data;*/
    
    always_ff @(posedge clk)
    begin
        if (rst) begin
            MEM_data <= 0;
            MEM_valid <= 1'b0;
        end
        else if (uart_not_stall && MEM_ready) begin
            MEM_valid <= EX_valid;
            if (EX_valid) begin
                MEM_data.val_signed <= EX_data.val_signed;
                MEM_data.uart_read <= EX_data.uart_read;
                MEM_data.rd <= EX_data.rd;
                MEM_data.csr_w <= EX_data.csr_w;
                MEM_data.base_mem_val <= base_data;
                MEM_data.ext_mem_val <= ext_data;
                MEM_data.base_read <= EX_data.base_read;
                MEM_data.ext_read <= EX_data.ext_read;
                MEM_data.byte_en <= EX_data.byte_en;
                MEM_data.alu_result <= EX_data.alu_result;
                MEM_data.alu_exp_result <= EX_data.alu_exp_result;
                MEM_data.uart_lsr_read <= EX_data.uart_lsr_read;
                MEM_data.WB_enable <= !(EX_data.opcode == B_opcode || EX_data.opcode == S_opcode);
                MEM_data.WB_exp_enable <= (EX_data.opcode == E_opcode);
                MEM_data.uart_lsr_val <= { 2'b0, (uart_tbre & uart_tsre), 4'b0, uart_ready};
            end
            else begin
                MEM_data <= 0;
            end
        end
    end

    // WB
    WBselector _wbselector(
        .base_read(MEM_data.base_read),
        .ext_read(MEM_data.ext_read),
        .uart_lsr_read(MEM_data.uart_lsr_read),
        .val_signed(MEM_data.val_signed),
        .byte_en(MEM_data.byte_en),
        .uart_read(MEM_data.uart_read),
        .base_mem_val(MEM_data.base_mem_val),
        .ext_mem_val(MEM_data.ext_mem_val),
        .alu_result(MEM_data.alu_result),
        .alu_exp_result(MEM_data.alu_exp_result),
        .uart_lsr_val({24'b0, MEM_data.uart_lsr_val}),
        .WB_result(WB_selector_result),
        .WB_exp_result(WB_selector_exp_result)
    );
endmodule
