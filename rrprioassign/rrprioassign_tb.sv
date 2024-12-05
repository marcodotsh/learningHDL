`timescale 1ns / 1ps

module rrprioassign_tb;

  localparam int N = 4;  // Component bit width
  localparam int T = 10;  // Clock period in ns

  logic clk;
  logic en;
  logic [N-1:0] r;
  logic [N-1:0] p;
  logic [N-1:0] res;

  // Instantiate the module under test
  rrprioassign #(
      .N(N)
  ) u_rrprioassign (
      .clk(clk),
      .en (en),
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
    en = 0;
    r  = 4'b0000;
    p  = 4'b0001;  // Default priority

    // Wait for a few clock cycles
    repeat (3) @(negedge clk);
    en = 1;

    // Apply multiple test cases
    @(negedge clk);
    // Test Case 1
    r = 4'b0101;
    p = 4'b0010;
    @(negedge clk);

    // Test Case 2
    r = 4'b1010;
    p = 4'b1000;
    @(negedge clk);

    // Test Case 3
    r = 4'b1111;
    p = 4'b0001;
    @(negedge clk);

    // Test Case 4
    r = 4'b0011;
    p = 4'b0100;
    @(negedge clk);

    // Test Case 5
    r = 4'b0001;
    p = 4'b0001;

    $finish;
  end

  // Monitor and dump signals
  initial begin
    $timeformat(-9, 1, " ns", 8);
    $monitor("time=%t clk=%b en=%b r=%b p=%b res=%b", $time, clk, en, r, p, res);
    $dumpfile("rrprioassign_tb.vcd");
    $dumpvars(0, rrprioassign_tb);
  end

endmodule
