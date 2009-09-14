module ram_2k (
    input             clk,
    input             rst,
    input             cs,
    input             we,
    input      [10:0] addr,
    output reg [ 7:0] rdata,
    input      [ 7:0] wdata
  );

  // Registers and nets
  reg [7:0] mem[0:2047];

  always @(posedge clk)
    rdata <= rst ? 8'h0 : mem[addr];

  always @(posedge clk)
    if (we && cs) mem[addr] <= wdata;

endmodule
