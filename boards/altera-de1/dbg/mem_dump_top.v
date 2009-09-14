module mem_dump_top (
    input        clk_50_,
    input  [9:0] sw_,

    // sram signals
    output [17:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output        sram_ce_n_,
    output [ 1:0] sram_bw_n_,

    // VGA signals
    output [1:0] tft_lcd_r_,
    output [1:0] tft_lcd_g_,
    output [1:0] tft_lcd_b_,
    output       tft_lcd_hsync_,
    output       tft_lcd_vsync_
  );

  // Registers and nets
  wire [17:1] csr_adr_i;
  wire [ 1:0] csr_sel_i;
  wire        csr_we_i;
  wire [15:0] csr_dat_o;

  wire vdu_clk;
  wire lock;
  wire rst;

  wire [15:0] dat_o;
  wire [11:1] adr;
  wire        we;
  wire        stb;
  wire [ 1:0] sel;
  wire        tga;
  wire        ack;

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c1     (vdu_clk),
    .locked (lock)
  );

  mem_dump mem_dump0 (
    .clk (vdu_clk),
    .rst (rst),
    .sw_ (sw_),

    .vdu_dat_o (dat_o),
    .vdu_adr_o (adr),
    .vdu_we_o  (we),
    .vdu_stb_o (stb),
    .vdu_sel_o (sel),
    .vdu_tga_o (tga),
    .vdu_ack_i (ack),

    .csr_adr_o (csr_adr_i),
    .csr_sel_o (csr_sel_i),
    .csr_we_o  (csr_we_i),
    .csr_dat_i (csr_dat_o)
  );

  vdu vdu0 (
    .wb_clk_i (vdu_clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_adr_i (adr),
    .wb_we_i  (we),
    .wb_tga_i (tga),
    .wb_sel_i (sel),
    .wb_stb_i (stb),
    .wb_cyc_i (stb),
    .wb_ack_o (ack),

    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  csr_sram csr_sram0 (
    .sys_clk (vdu_clk),

    .csr_adr_i (csr_adr_i),
    .csr_sel_i (csr_sel_i),
    .csr_we_i  (csr_we_i),
    .csr_dat_i (16'h0),
    .csr_dat_o (csr_dat_o),

    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  // Continuous assignments
  assign rst = !lock;
endmodule
