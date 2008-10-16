module clock (
    input  sys_clk_in_,
    output clk,
    output clk_100M,
    output vdu_clk,
    output rst
  );

  // Register declarations
  reg [6:0] count;
  reg [3:0] clock;

  // Net declarations
  wire lock;
  wire clk_60M;
  wire clk_3M;

  // Module instantiations
  clocks c0 (
    .CLKIN_IN   (sys_clk_in_),
    .CLKDV_OUT  (vdu_clk),
    .CLK0_OUT   (clk_100M),
    .CLKFX_OUT  (clk_60M),
    .LOCKED_OUT (lock)
  );

  // Continuous assignments
  assign rst    = (count!=7'h7f);
  assign clk_3M = clock[3];
//  assign clk    = clk_3M;
  assign clk    = clock[1];

  // Behavioral description
  // count
  always @(posedge clk_60M)
    if (!lock) count <= 7'b0;
    else count <= (count==7'h7f || clock!=4'b1111) ? count : (count + 7'h1);

  // clock
  always @(posedge clk_60M) clock <= clock + 4'd1;
endmodule
