module test_lcd (
    input        clk_50_,

    output [1:0] tft_lcd_r_,
    output [1:0] tft_lcd_g_,
    output [1:0] tft_lcd_b_,
    output       tft_lcd_hsync_,
    output       tft_lcd_vsync_,

    input  [1:0] sw_,

    // Pad signals
    output [17:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output        sram_ce_n_,
    output [ 1:0] sram_bw_n_
  );

  // Net declarations
  wire        lock;
  wire        rst;
  wire        tft_lcd_clk_;

  wire [17:1] csr_adr;
  wire [15:0] csr_dat_i;

  // Module instantiations
  pll pll0 (
    .inclk0 (clk_50_),
    .c0     (tft_lcd_clk_),
    .locked (lock)
  );

  lcd lcd0 (
    // Wishbone common signals
    .rst    (rst),
    .clk    (tft_lcd_clk_),     // 25MHz	VDU clock

    .shift_reg_1    (sw_[0]),
    .graphics_alpha (sw_[1]),

    // CSR slave interface for reading
    .csr_adr_o (csr_adr),
    .csr_dat_i (csr_dat_i),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  csr_sram sram (
    .sys_clk (tft_lcd_clk_),

    // CSR slave interface
    .csr_adr_i (csr_adr),
    .csr_sel_i (2'b11),
    .csr_we_i  (1'b0),
    .csr_dat_i (16'h0),
    .csr_dat_o (csr_dat_i),

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
//  assign tft_lcd_b_ = 2'b10;
endmodule
