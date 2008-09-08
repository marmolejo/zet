module kotku_ml403 (
    input         sys_clk_in_,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        flash_ce2_,

    output        tft_lcd_clk_,
    output        tft_lcd_r_,
    output        tft_lcd_g_,
    output        tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,

    output        rs_,
    output        rw_,
    output        e_,
    output  [7:4] db_
  );

  // Net declarations
  wire        clk;
  wire        rst;
  wire [15:0] dat_i;
  wire [15:0] dat_o;
  wire [19:0] adr;
  wire        we;
  wire        mio;
  wire        stb;
  wire        ack;
  wire        byte_o;
  wire        clk_100M;
  wire [63:0] f1, f2;
  wire [15:0] m1, m2;
  wire [19:0] pc;
  wire [15:0] cs, ip;
  wire [15:0] dat_io;
  wire [15:0] dat_mem;

  // Register declarations
  reg  [15:0] io_reg;

  // Module instantiations
  clock c0 (
    .sys_clk_in_ (sys_clk_in_),
    .clk         (clk),
    .clk_100M    (clk_100M),
    .vdu_clk     (tft_lcd_clk_),
    .rst         (rst)
  );

  lcd_display lcd0 (
    .f1 (f1),  // 1st row
    .f2 (f2),  // 2nd row
    .m1 (m1),  // 1st row mask
    .m2 (m2),  // 2nd row mask

    .clk (clk_100M),  // 100 Mhz clock

    // Pad signals
    .lcd_rs_  (rs_),
    .lcd_rw_  (rw_),
    .lcd_e_   (e_),
    .lcd_dat_ (db_)
  );

  mem_map mem_map0 (
    // Wishbone signals
    .clk_i  (clk),
    .rst_i  (rst),
    .adr_i  (adr),
    .dat_i  (dat_o),
    .dat_o  (dat_mem),
    .we_i   (we),
    .ack_o  (ack),
    .stb_i  (stb & !mio),
    .byte_i (byte_o),

    // Pad signals
    .sram_clk_        (sram_clk_),
    .sram_flash_addr_ (sram_flash_addr_),
    .sram_flash_data_ (sram_flash_data_),
    .sram_flash_oe_n_ (sram_flash_oe_n_),
    .sram_flash_we_n_ (sram_flash_we_n_),
    .sram_bw_         (sram_bw_),
    .sram_cen_        (sram_cen_),
    .flash_ce2_       (flash_ce2_),

    // VGA pad signals
    .vdu_clk     (tft_lcd_clk_),
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  cpu zet_proc (
    // Wishbone signals
    .clk_i  (clk),
    .rst_i  (rst),
    .dat_i  (dat_i),
    .dat_o  (dat_o),
    .adr_o  (adr),
    .we_o   (we),
    .mio_o  (mio),
    .byte_o (byte_o),
    .stb_o  (stb),
    .ack_i  (ack),
    .cs     (cs),
    .ip     (ip)
  );

  // Continuous assignments
  assign f1 = { 3'b0, rst, 4'h0, dat_i, 4'h0, dat_o, 7'h0, mio, 7'h0, ack, 4'h0 };
  assign f2 = { adr, 7'h0, we, 3'h0, stb, 3'h0, byte_o, 8'h0, pc };
  assign m1 = 16'b1011110111101010;
  assign m2 = 16'b1111101110011111;

  assign pc = (cs << 4) + ip;

  assign dat_io = (adr[15:0]==16'hb7) ? io_reg : 16'd0;
  assign dat_i  = mio ? dat_io : dat_mem;

  // Behaviour
  // IO Stub
  always @(posedge clk)
    if (adr==20'hb7 & we & mio)
      io_reg <= byte_o ? { io_reg[15:8], dat_o[7:0] } : dat_o;

endmodule
