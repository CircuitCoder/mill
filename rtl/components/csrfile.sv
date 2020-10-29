`ifndef __CSRFILE_SV__
`define __CSRFILE_SV__

`include "types.sv"

/* CSR file containing mutable CSR variables */
module csrfile #() (
  /* Exported CSR Variables */
  output gpreg csr_mtvec,
  output gpreg csr_mepc,

  /* CSR exec stuff */
  decoupled.in req,
  output csr_resp resp,

  /* CSR external effecvts */
  input csr_effect effect,

  input clk,
  input rst
);

typedef enum {
  STATE_READING,
  STATE_COMMIT
} state_t;

state_t state, state_n;

/* Status */
// FS = XS = SD = 0
// Global interrupt switches
logic mie;
logic mpie;
// MPP = MPRV = 0
// MXR = TVM = TW = TSR = 0

/* Trap */
gpreg mtvec;
gpreg mscratch;
gpreg mepc;
gpreg mcause;
gpreg mtval;

assign csr_mtvec = mtvec;
assign csr_mepc = mepc;

logic msie;
logic mtie;
logic meie;

/* Counters */
logic [63:0] cycle, instret;
logic [31:0] countinhibit;
// TODO: return 0 for other counters

/* Misc */
gpreg misa; // MXL = 1, I
assign misa = (1 << 30) | (1 << 8);

/* R/W in exec */

// Single cycle r/w

assign req.ready = state == STATE_COMMIT;
gpreg read;
gpreg read_pipe;

always_comb begin
  resp.exists = '1;
  case (req.data.a)
    CSR_MVENDORID: read = 'h0;
    CSR_MARCHID: read = 'h0;
    CSR_MIMPID: read = 'h0;
    CSR_MHARTID: read = 'h0; // TODO: change me if MP is implemented

    CSR_MSTATUS: read = (32'(mpie) << 7) | (32'(mie) << 3);
    CSR_MISA: read = misa;
    CSR_MIE: read = (32'(meie) << 11) | (32'(mtie) << 7) | (32'(msie) << 3);
    CSR_MTVEC: read = mtvec;

    CSR_MSCRATCH: read = mscratch;
    CSR_MEPC: read = mepc;
    CSR_MCAUSE: read = mcause;
    CSR_MTVAL: read = mtval;
    CSR_MIP: read = '0; // TODO: impl me

    CSR_MCYCLE: read = cycle[31:0];
    CSR_MINSTRET: read = instret[31:0];

    CSR_MCYCLEH: read = cycle[63:32];
    CSR_MINSTRETH: read = instret[63:32];

    CSR_MCOUNTINHIBIT: read = countinhibit;

    default: begin
      resp.exists = '0;
      read = 'X;
    end
  endcase
end

assign resp.d = read_pipe;

gpreg write, write_pipe;
always_comb begin
  case (req.data.t)
    CSRW: write = req.data.d;
    CSRS: write = read | req.data.d;
    CSRC: write = read & ~(req.data.d);
    default: write = 'X;
  endcase
end

assign state_n = (state == STATE_READING && req.valid) ? STATE_COMMIT : STATE_READING;
csr_addr req_addr_pipe;

always_ff @(posedge clk or posedge rst) begin
  read_pipe <= read;
  write_pipe <= write;
  req_addr_pipe <= req.data.a;

  if(rst) begin
    state <= STATE_READING;
  end else begin
    state <= state_n;
  end
end

always_ff @(posedge clk or posedge rst) begin
  // By default, increment counter
  if(!countinhibit[0]) cycle <= cycle + 1;
  if(effect.t == CSR_EFF_INSTRET && !countinhibit[2]) instret <= instret + 1;

  // Other write logic
  if(rst) begin
    cycle <= '0;
    instret <= '0;

    mpie <= '0;
    mie <= '0;

    mtie <= '0;
    msie <= '0;
    meie <= '0;
    
    mepc <= '0;
    mtvec <= '0;
    mscratch <= '0;
    mcause <= '0;
    mtval <= '0;
    countinhibit <= '0;
  end else if(effect.t == CSR_EFF_EX) begin
    mcause <= 32'(effect.src);
    mepc <= effect.epc;
    mtval <= effect.tval;
    mpie <= mie;
    mie <= '0;
  end else if(effect.t == CSR_EFF_RET) begin
    mie <= mpie;
  end else if(state == STATE_COMMIT) begin // TODO: asserts irrevocable
    case (req_addr_pipe)
      CSR_MSTATUS: begin
        mpie <= write_pipe[7];
        mie <= write_pipe[3];
      end
      CSR_MIE: begin
        meie <= write_pipe[11];
        mtie <= write_pipe[7];
        msie <= write_pipe[3];
      end
      CSR_MTVEC: mtvec <= { write_pipe[31:2], 2'b0 };
      CSR_MSCRATCH: mscratch <= write_pipe;
      CSR_MEPC: mepc <= write_pipe;
      CSR_MCAUSE: mcause <= write_pipe;
      CSR_MTVAL: mtval <= write_pipe;

      CSR_MCYCLE: cycle <= { cycle[63:32], write_pipe };
      CSR_MINSTRET: instret <= { instret[63:32], write_pipe };
      CSR_MCYCLEH: cycle <= { write_pipe, cycle[31:0] };
      CSR_MINSTRETH: instret <= { write_pipe, instret[31:0] };

      CSR_MCOUNTINHIBIT: countinhibit <= write_pipe;
      default: ; // Do nothing
    endcase
  end
end

endmodule

`endif // __CSRFILE_SV__
