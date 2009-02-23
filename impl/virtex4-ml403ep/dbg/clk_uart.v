 /*
  *  Phase accumulator clock:
  *   Fo = Fc * N / 2^bits
  *   here N: 154619 and bits: 24
  */

module clk_uart (
    input      clk_100M,
    input      rst,
    output     clk_921600,
    output reg rst2
  );

  // Registers
  reg [23:0] cnt;

  // Continuous assignments
  assign clk_921600 = cnt[23];

  // Behaviour
  // cnt
  always @(posedge clk_100M)
    cnt <= rst ? 21'd0 : cnt + 24'd154619;

  // rst2
  always @(posedge clk_100M)
    rst2 <= rst ? 1'b1 : (clk_921600 ? 1'b0 : rst2);
endmodule
