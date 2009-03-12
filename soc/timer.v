 /*
  *  Phase accumulator clock:
  *   Fo = Fc * N / 2^bits
  *   here N: 12507 and bits: 32
  *   it gives a frequency of 18.200080376 Hz
  */

module timer (
    // Wishbone slave interface
    input      wb_clk_i,
    input      wb_rst_i,
    output reg wb_tgc_o   // intr
  );

  // Registers and nets
  reg [31:0] cnt;
  reg        old_clk2;
  wire       clk2;

  // Continuous assignments
  assign clk2 = cnt[31];

  // Behaviour
  // cnt
  always @(posedge wb_clk_i)
    cnt <= wb_rst_i ? 32'h0 : (cnt + 32'd12507);

  // old_clk2
  always @(posedge wb_clk_i)
    old_clk2 <= wb_rst_i ? 1'b0 : clk2;

  // intr
  always @(posedge wb_clk_i)
    wb_tgc_o <= wb_rst_i ? 1'b0 : (!old_clk2 & clk2);

endmodule
