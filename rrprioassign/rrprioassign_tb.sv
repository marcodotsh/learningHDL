`timescale 1ns / 1ps

module rrprioassign_tb;

  import rrprioassign_pkg::*;

  localparam int T = 10;  // Clock period in ns

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
    #(T / 2);
    clk = 1'b0;
    #(T / 2);
  end

  // Test stimulus
  initial begin
    // Initialize signals
    r = 4'b0000;
    p = 4'b0001;  // Default priority

    initialValue = 1;

    for (r = 0; initialValue || r != 0; r = r + 1) begin
      for (p = 1; p != 0; p = p << 1) begin
        @(negedge clk);
      end
      initialValue = 0;
    end

    $finish;
  end

  // Monitor and dump signals
  initial begin
    $timeformat(-9, 1, " ns", 8);
    $monitor("time=%t clk=%b r=%b p=%b res=%b", $time, clk, r, p, res);
    $dumpfile("rrprioassign_tb.vcd");
    $dumpvars(0, rrprioassign_tb);
  end

endmodule
