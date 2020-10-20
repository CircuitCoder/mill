`ifndef __DECOUPLED_SV__
`define __DECOUPLED_SV__

/* verilator lint_off UNOPTFLAT */
// TODO: eliminate false circular path to increase performance
interface decoupled #(
  parameter type Data = bit
);
  Data data;
  bit valid;
  bit ready;

  modport out (
    output data,
    output valid,
    input ready
  );

  modport in (
    input data,
    input valid,
    output ready
  );
endinterface : decoupled
/* verilator lint_on UNOPTFLAT */

`endif // __DECOUPLED_SV__
