`ifndef __DECOUPLED_SV_
`define __DECOUPLED_SV_

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
endinterface

`endif // __DECOUPLED_SV_
