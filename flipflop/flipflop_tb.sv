`timescale 1ns / 100ps

`include "flipflop.sv"

module flipflop_tb;

  import flipflop_pkg::*;

  localparam int T = 10;  // Clock period

  logic tb_clk;
  logic tb_rst;
  logic [W-1:0] tb_d;
  logic [W-1:0] tb_q;

  flipflop u_flipflop0 (
      .clk(tb_clk),
      .rst(tb_rst),
      .d  (tb_d),
      .q  (tb_q)
  );

  // Clock generation
  always begin
    tb_clk = 1'b1;
    #(T / 2.0);
    tb_clk = 1'b0;
    #(T / 2.0);
  end

  // Test stimulus
  initial begin

    tb_rst = 1;
    tb_d   = 0;

    @(posedge tb_clk);
    tb_rst <= 0;

    @(posedge tb_clk);
    tb_d <= 1;


    $finish;
  end

  initial begin
    $monitor("tb_d=%b tb_q=%b", tb_d, tb_q);
    $dumpfile("flipflop_tb.vcd");
    $dumpvars(0, flipflop_tb);
  end

endmodule
