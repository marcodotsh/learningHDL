`timescale 1ns / 100ps

`include "barrelshifter.sv"

module barrelshifter_tb;

  import barrelshifter_pkg::*;

  localparam int T = 10;  // Clock period

  logic clk;
  logic [2**W-1:0] in;
  logic [W-1:0] offset;
  logic [2**W-1:0] out;

  barrelshifter u_barrelshifter (
      .in    (in),
      .offset(offset),
      .out   (out)
  );


  // Clock generation
  always begin
    clk = 1'b1;
    #(T / 2.0);
    clk = 1'b0;
    #(T / 2.0);
  end

  // Test stimulus
  initial begin
    in <= 0;  //No requests
    offset <= 0;  //Default priority

    for (int i = 0; i < 2 ** 10; i++) begin
      #1 begin
        in <= $urandom;
        offset <= $urandom;
      end
    end

    $finish;
  end

  initial begin
    $monitor("in=%b offset=%b out=%b", in, offset, out);
    $dumpfile("barrelshifter_tb.vcd");
    $dumpvars(0, barrelshifter_tb);
  end

endmodule
