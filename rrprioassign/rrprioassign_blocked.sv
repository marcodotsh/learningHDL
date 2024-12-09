module rrprioassign_blocked (
    p,
    res
);

  import rrprioassign_pkg::*;

  input logic [N-1:0] p;
  output logic [N-1:0][N-1:0] res;

  genvar i;
  genvar j;
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_row
      for (j = 0; j < N; j = j + 1) begin : gen_col
        if (i == j) assign res[i][j] = 0;
        else if (i < j) assign res[i][j] = |p[i+1+:j-i];
        else if (i > j) assign res[i][j] = !(|p[j+1+:i-j]);
      end
    end
  endgenerate

endmodule
