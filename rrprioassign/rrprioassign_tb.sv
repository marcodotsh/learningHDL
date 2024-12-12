`timescale 1ns / 100ps

`include "rrprioassign.sv"

module rrprioassign_tb;

  import rrprioassign_pkg::*;

  localparam int T = 10;  // Clock period

  logic clk;
  logic [N-1:0] r;
  logic [N-1:0] p;
  logic [N-1:0] res;

  int initialValue;

  // Instantiate the module under test
  rrprioassign u_rrprioassign (
      .r  (r),
      .p  (p),
      .res(res)
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
    r <= 0;  //No requests
    p <= 1;  //Default priority

    for (int i = 0; i < 2 ** 10; i++) begin
      #1 begin
        r <= $urandom;
        p <= 1 << ($urandom % N);
      end
    end

    $finish;
  end

  initial begin
    $monitor("r=%b p=%b res=%b", r, p, res);
    $dumpfile("rrprioassign_tb.vcd");
    $dumpvars(0, rrprioassign_tb);
  end

endmodule
