`timescale 1ns / 1ps

module test_vdu (
    input        clk_50_,

    // VGA signals
    output [1:0] tft_lcd_r_,
    output [1:0] tft_lcd_g_,
    output [1:0] tft_lcd_b_,
    output       tft_lcd_hsync_,
    output       tft_lcd_vsync_,

    // sram signals
    output [17:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output        sram_ce_n_,
    output [ 1:0] sram_bw_n_
  );

  // Net declarations
  wire        clk;
  wire        lock;
  wire        rst;
  wire [11:1] adr_o;
  wire [15:0] dat_i;
  wire        we_o;
  wire [ 1:0] sel_o;
  wire        stb_o;
  wire        cyc_o;
  wire        ack_i;
  wire [ 6:0] h_adr;

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c0     (clk),
    .locked (lock)
  );

  vdu vdu (
    // Wishbone common signals
    .wb_rst_i    (rst),
    .wb_clk_i    (clk), // 25MHz	VDU clock

    // Wishbone master interface
    .wbm_adr_o (adr_o),
    .wbm_dat_i (dat_i),
    .wbm_we_o  (we_o),
    .wbm_sel_o (sel_o),
    .wbm_stb_o (stb_o),
    .wbm_cyc_o (cyc_o),
    .wbm_ack_i (ack_i),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  wb_sram sram (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_o (dat_i),
    .wb_adr_i ({h_adr,adr_o}),
    .wb_we_i  (we_o),
    .wb_sel_i (sel_o),
    .wb_stb_i (stb_o),
    .wb_cyc_i (cyc_o),
    .wb_ack_o (ack_i),

    // Pad signals
    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  // Continuous assignments
  assign rst = !lock;

  assign h_adr = 7'b111_1000;
endmodule
