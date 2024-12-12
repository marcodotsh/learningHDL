`timescale 1ns / 100ps

module flipflop (
    clk,
    rst,
    d,
    q
);

  import flipflop_pkg::*;

  input logic clk;
  input logic rst;
  input logic [W-1:0] d;
  output logic [W-1:0] q;

  always_ff @(posedge clk) begin : blockName
    if (rst) q <= '0;
    else q <= d;
  end

endmodule
