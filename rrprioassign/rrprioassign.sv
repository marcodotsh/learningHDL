module rrprioassign (
    r,
    p,
    res
);

  import rrprioassign_pkg::*;

  //Vector of requests - 1 at position i if and only if requestor i wants access
  input logic [N-1:0] r;
  //Vector of priorities - exactly a 1 in position i, requestor i has the highest priority,
  //then following requestors have decreasing priority (at the end rewind at 0th requestor)
  input logic [N-1:0] p;
  //Vector containing at most a 1 in the position of the allowed requestor
  output logic [N-1:0] res;

  logic [N-1:0][N-1:0] blkd;

  rrprioassign_blocked u_blocked (
      .p  (p),
      .res(blkd)
  );


  genvar i;
  generate
    for (i = 0; i < N; i++) begin : gen_single_exit
      assign res[i] = r[i] & !(|(r & blkd[i]));
    end
  endgenerate


endmodule
