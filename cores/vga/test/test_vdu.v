`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    02:05:46 08/01/2008
// Design Name:
// Module Name:    test_vdu
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module test_vdu (
    input        sys_clk_in,

    output       tft_lcd_clk_,
    output [1:0] tft_lcd_r,
    output [1:0] tft_lcd_g,
    output [1:0] tft_lcd_b,
    output       tft_lcd_hsync,
    output       tft_lcd_vsync,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [31:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        sram_adv_ld_n_,
    output        flash_ce2_,

    output led
  );

  // Net declarations
  wire        lock;
  wire        rst;
  wire [11:1] adr_o;
  wire [15:0] dat_i;
  wire        we_o;
  wire [ 1:0] sel_o;
  wire        stb_o;
  wire        cyc_o;
  wire        ack_i;
  wire [ 7:0] h_adr;

  // Module instantiations
  clock clk0 (
    .CLKIN_IN   (sys_clk_in),
    .CLKDV_OUT  (tft_lcd_clk_),
    .LOCKED_OUT (lock)
  );

  vdu vdu0 (
    // Wishbone common signals
    .wb_rst_i    (rst),
    .wb_clk_i    (tft_lcd_clk_),     // 25MHz	VDU clock

    // Wishbone master interface

    .wbm_adr_o (adr_o),
    .wbm_dat_i (dat_i),
    .wbm_we_o  (we_o),
    .wbm_sel_o (sel_o),
    .wbm_stb_o (stb_o),
    .wbm_cyc_o (cyc_o),
    .wbm_ack_i (ack_i),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r),
    .vga_green_o (tft_lcd_g),
    .vga_blue_o  (tft_lcd_b),
    .horiz_sync  (tft_lcd_hsync),
    .vert_sync   (tft_lcd_vsync)
  );

  zbt_cntrl zbt0 (
    // Wishbone slave interface
    .wb_clk_i (tft_lcd_clk_),
    .wb_rst_i (rst),

    .wb_dat_o (dat_i),
    .wb_adr_i ({h_adr,adr_o}),
    .wb_we_i  (we_o),
    .wb_sel_i (sel_o),
    .wb_stb_i (stb_o),
    .wb_cyc_i (cyc_o),
    .wb_ack_o (ack_i),

    // Pad signals
    .sram_clk_      (sram_clk_),
    .sram_addr_     (sram_flash_addr_),
    .sram_data_     (sram_flash_data_),
    .sram_we_n_     (sram_flash_we_n_),
    .sram_bw_       (sram_bw_),
    .sram_cen_      (sram_cen_),
    .sram_adv_ld_n_ (sram_adv_ld_n_)
  );

  // Continuous assignments
  assign rst = !lock;
  assign led = 1'b1;

  assign sram_flash_oe_n_ = 1'b0;
  assign flash_ce2_       = 1'b0;

  assign h_adr = 8'b1011_1000;
endmodule
