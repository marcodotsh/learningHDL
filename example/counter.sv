module counter #(
    parameter int N = 8
) (
    input logic clk,
    input logic rst,
    input logic en,
    output logic [N-1:0] count
);

  always_ff @(posedge clk, posedge rst) begin
    if (rst) count <= 0;
    else if (en) count <= count + 1;
  end

endmodule
