`timescale 1ns / 100ps

`include "barrelshifter.sv"

module barrelshifter_tb;

  import barrelshifter_pkg::*;

  logic [2**W-1:0] in;
  logic [W-1:0] offset;
  logic [2**W-1:0] out;

  barrelshifter u_barrelshifter (
      .in    (in),
      .offset(offset),
      .out   (out)
  );

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
    $monitor("in=%b offset=%d out=%b", in, offset, out);
    $dumpfile("barrelshifter_tb.vcd");
    $dumpvars(0, barrelshifter_tb);
  end

endmodule
