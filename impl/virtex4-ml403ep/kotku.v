`include "defines.v"

module kotku_ml403 (
`ifdef DEBUG
    output        rs_,
    output        rw_,
    output        e_,
    output  [7:4] db_,

`endif

    output        tft_lcd_clk_,
    output        tft_lcd_r_,
    output        tft_lcd_g_,
    output        tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,

    input         sys_clk_in_,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        sram_adv_ld_n_,
    output        flash_ce2_,

    input         but_
  );

  // Net declarations
  wire        clk;
  wire        rst_lck;
  wire [15:0] dat_i;
  wire [15:0] dat_o;
  wire [19:0] adr;
  wire        we;
  wire        mio;
  wire        stb;
  wire        ack;
  wire        byte_o;
  wire [15:0] dat_io;
  wire [15:0] dat_mem;

`ifdef DEBUG
  wire [35:0] control0;
  wire [ 5:0] funct;
  wire [ 2:0] state, next_state;
  wire [15:0] x, y;
  wire [15:0] imm;
  wire        clk_100M;
  wire [63:0] f1, f2;
  wire [15:0] m1, m2;
  wire [19:0] pc;
  wire [15:0] cs, ip;
  wire [15:0] aluo;
  wire [ 2:0] curr_st;
  reg         dbg;
`endif

  // Register declarations
  reg  [15:0] io_reg;
  reg         rst;

  // Module instantiations
  clock c0 (
`ifdef DEBUG
    .clk_100M    (clk_100M),
`endif
    .sys_clk_in_ (sys_clk_in_),
    .clk         (clk),
    .vdu_clk     (tft_lcd_clk_),
    .rst         (rst_lck)
  );

  mem_map mem_map0 (
`ifdef DEBUG
    .curr_st (curr_st),
`endif
    // VGA pad signals
    .vdu_clk     (tft_lcd_clk_),
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_),

    // Wishbone signals
    .clk_i  (clk),
    .rst_i  (rst_lck),
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
    .sram_adv_ld_n_   (sram_adv_ld_n_),
    .flash_ce2_       (flash_ce2_)
  );

  cpu zet_proc (
`ifdef DEBUG
    .cs         (cs),
    .ip         (ip),
    .state      (state),
    .next_state (next_state),
    .iralu      (funct),
    .x          (x),
    .y          (y),
    .imm        (imm),
    .aluo       (aluo),
`endif

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
    .ack_i  (ack)
  );

`ifdef DEBUG
  // Module instantiations
  icon icon0 (
    .CONTROL0 (control0)
  );

  ila ila0 (
    .CONTROL (control0),
    .CLK     (clk_100M),
    .TRIG0   (adr),
    .TRIG1   ({dat_o,dat_i}),
    .TRIG2   (pc),
    .TRIG3   ({clk,we,mio,byte_o,stb,ack}),
    .TRIG4   (funct),
    .TRIG5   ({state,next_state}),
    .TRIG6   (io_reg),
    .TRIG7   (imm),
    .TRIG8   ({x,y}),
    .TRIG9   (aluo),
    .TRIG10  (sram_flash_addr_),
    .TRIG11  (sram_flash_data_),
    .TRIG12  ({sram_flash_oe_n_, sram_flash_we_n_, sram_bw_,
               sram_cen_, sram_adv_ld_n_, flash_ce2_}),
    .TRIG13  (curr_st)
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

  // Continuous assignments
  assign f1 = { 3'b0, rst, 4'h0, dat_i, 4'h0, dat_o, 7'h0, mio, 7'h0, ack, 4'h0 };
  assign f2 = { adr, 7'h0, we, 3'h0, stb, 3'h0, byte_o, 8'h0, pc };
  assign m1 = 16'b1011110111101010;
  assign m2 = 16'b1111101110011111;

  assign pc = (cs << 4) + ip;
`endif

  assign dat_io = (adr[15:0]==16'hb7) ? io_reg : 16'd0;
  assign dat_i  = mio ? dat_io : dat_mem;

  // Behaviour
  // IO Stub
  always @(posedge clk)
    if (adr==20'hb7 & we & mio)
      io_reg <= byte_o ? { io_reg[15:8], dat_o[7:0] } : dat_o;

  // rst
  always @(posedge clk)
    rst <= rst_lck ? 1'b1 : (but_ ? 1'b0 : rst );

  // dbg
`ifdef DEBUG
  always @(posedge clk)
    dbg <= rst_lck ? 1'b1 : (pc==20'hf005a ? 1'b0 : dbg);
`endif
endmodule
