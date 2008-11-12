`timescale 1ns / 1ps

module vdu_tb;

  reg clk;
  reg rst;

  wire [1:0] tft_lcd_r;
  wire [1:0] tft_lcd_g;
  wire [1:0] tft_lcd_b;
  wire       tft_lcd_hsync;
  wire       tft_lcd_vsync;

  vdu vdu0 (
    .wb_rst_i    (rst),
    .wb_clk_i    (clk),     // 25MHz	VDU clock
    .vga_red_o   (tft_lcd_r),
    .vga_green_o (tft_lcd_g),
    .vga_blue_o  (tft_lcd_b),
    .horiz_sync  (tft_lcd_hsync),
    .vert_sync   (tft_lcd_vsync)
  );

  always #20 clk <= ~clk;

  initial
    begin
      rst <= 1'b0;
      clk <= 1'b0;
      #25 rst <= 1'b1;
      #50 rst <= 1'b0;
    end

endmodule
