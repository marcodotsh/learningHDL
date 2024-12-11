module barrelshifter (
    in,
    offset,
    out
);

  import barrelshifter_pkg::*;

  input logic [2**W-1:0] in;
  input logic [W-1:0] offset;
  output logic [2**W-1:0] out;

  logic [W:0][2**W-1:0] partial;

  assign partial[0] = in;

  genvar i;
  genvar j;
  generate
    for (i = 0; i < W; i++) begin : gen_shiftAndDouble
      assign partial[i+1] = offset[i] ? 
      {partial[i][2**W-1-2**i:0],partial[i][2**W-1:2**W-2**i]} :
       partial[i];
    end
  endgenerate

  assign out = partial[W];


endmodule
