`ifndef __DECOUPLED_SV__
`define __DECOUPLED_SV__

interface decoupled #(
  parameter type Data = bit
);
  Data data;
  bit valid;
  bit ready;

  modport out (output data, output valid, input ready);
  modport in (input data, input valid, output ready);

  function bit fire();
    fire = valid && ready;
  endfunction
endinterface : decoupled

`endif // __DECOUPLED_SV__
