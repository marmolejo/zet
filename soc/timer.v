module timer (
    // Wishbone slave interface
    input      wb_clk_i,
    input      wb_rst_i,
    output reg wb_tgc_o,   // intr
    input      wb_tgc_i    // inta
  );

  // Registers and nets
  reg [17:0] cnt;
  reg        old_clk2;
  reg        pulse;
  wire       clk2;

  // Continuous assignments
  assign clk2 = cnt[17];

  // Behaviour
  // cnt
  always @(posedge wb_clk_i)
    cnt <= wb_rst_i ? 18'h00 : (cnt + 18'h1);

  // old_clk2
  always @(posedge wb_clk_i)
    old_clk2 <= wb_rst_i ? 1'b0 : clk2;

  // pulse
  always @(posedge wb_clk_i)
    pulse <= wb_rst_i ? 1'b0 : (clk2!=old_clk2);

  // intr
  always @(posedge wb_clk_i)
    wb_tgc_o <= wb_rst_i ? 1'b0
      : ((pulse & !wb_tgc_i) ? 1'b1
      : (wb_tgc_o ? !wb_tgc_i : 1'b0));
endmodule
