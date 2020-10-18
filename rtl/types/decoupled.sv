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
    input ready,

    import fire
  );

  modport in (
    input data,
    input valid,
    output ready,

    import fire
  );

  function automatic bit fire();
    fire = valid && ready;
  endfunction
endinterface : decoupled
/* verilator lint_on UNOPTFLAT */

`endif // __DECOUPLED_SV__
