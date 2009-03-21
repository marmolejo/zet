`timescale 1ns / 1ps

module vdu_tb;

  reg clk;

  wire       tft_lcd_clk_;
  wire [1:0] tft_lcd_r;
  wire [1:0] tft_lcd_g;
  wire [1:0] tft_lcd_b;
  wire       tft_lcd_hsync;
  wire       tft_lcd_vsync;

  wire        s_clk;
  wire [20:0] sf_addr;
  wire [31:0] sf_data;
  wire        sf_oe;
  wire        sf_we;
  wire [ 3:0] s_bw;
  wire        s_ce;
  wire        s_adv;
  wire        f_ce;

  wire        led;

  test_vdu vdu0 (
    .sys_clk_in (clk),

    .tft_lcd_clk_  (tft_lcd_clk_),
    .tft_lcd_r     (tft_lcd_r),
    .tft_lcd_g     (tft_lcd_g),
    .tft_lcd_b     (tft_lcd_b),
    .tft_lcd_hsync (tft_lcd_hsync),
    .tft_lcd_vsync (tft_lcd_vsync),

    .sram_clk_        (s_clk),
    .sram_flash_addr_ (sf_addr),
    .sram_flash_data_ (sf_data),
    .sram_flash_oe_n_ (sf_oe),
    .sram_flash_we_n_ (sf_we),
    .sram_bw_         (s_bw),
    .sram_cen_        (s_ce),
    .sram_adv_ld_n_   (s_adv),
    .flash_ce2_       (f_ce),

    .led (led)
  );

  cy7c1354 zbt (
    .d      (sf_data),
    .clk    (s_clk),
    .a      (sf_addr[17:0]),
    .bws    (s_bw),
    .we_b   (sf_we),
    .adv_lb (s_adv),
    .ce1b   (s_ce),
    .ce2    (1'b1),
    .ce3b   (1'b0),
    .oeb    (sf_oe),
    .cenb   (1'b0),
    .mode   (1'b0)
  );

  always #5 clk <= ~clk;

  initial clk <= 1'b0;

  initial $readmemh("vgamem.dat", zbt.mem, 18'h2e000);

endmodule
