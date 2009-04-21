`timescale 1ns / 1ps

module test_vdu (
    input        clk_50_,

    // Buttons
    input        but0_,
    input        but1_,

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
  reg  [11:1] adr;
  reg  [15:0] dat_i;
  wire [15:0] dat_o;
  reg         we;
  reg         stb;
  reg  [ 1:0] sel;
  wire        ack;
  reg  [ 3:0] st;

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
    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_adr_i (adr),
    .wb_we_i  (we),
    .wb_tga_i (1'b0),
    .wb_sel_i (sel),
    .wb_stb_i (stb),
    .wb_cyc_i (stb),
    .wb_ack_o (ack),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_),

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

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        adr   <= 11'h000;
        dat_i <= 16'h0000;
        we    <= 1'b0;
        stb   <= 1'b0;
        sel   <= 2'b11;
        st    <= 4'h0;
      end
    else
      case (st)
        4'h0:
          if (!but0_) begin
            adr   <= 11'b0000_0000_010;
            dat_i <= 16'h075a;
            we    <= 1'b1;
            stb   <= 1'b1;
            sel   <= 2'b11;
            st    <= 4'h1;
          end
        4'h1:
          if (ack) begin
            adr   <= 11'b0000_0000_010;
            dat_i <= 16'h075a;
            we    <= 1'b1;
            stb   <= 1'b0;
            sel   <= 2'b11;
            st    <= 4'h2;
          end
        4'h2:
          if (!but1_) begin
            adr   <= 11'b0000_0000_011;
            dat_i <= 16'h075a;
            we    <= 1'b1;
            stb   <= 1'b1;
            sel   <= 2'b10;
            st    <= 4'h3;
          end
        4'h3:
          if (ack) begin
            adr   <= 11'b0000_0000_100;
            dat_i <= 16'h0750;
            we    <= 1'b1;
            stb   <= 1'b1;
            sel   <= 2'b01;
            st    <= 4'h4;
          end
        4'h4:
          if (ack) begin
            adr   <= 11'b0000_0000_100;
            dat_i <= 16'h0750;
            we    <= 1'b1;
            stb   <= 1'b0;
            sel   <= 2'b01;
            st    <= 4'h5;
          end
        4'h5:
          if (!but0_) begin
            adr   <= 11'b0000_0000_010;
            dat_i <= 16'h0750;
            we    <= 1'b0;
            stb   <= 1'b1;
            sel   <= 2'b11;
            st    <= 4'h6;
          end
        4'h6:
          if (ack) begin
            adr   <= 11'b0000_0000_110;
            dat_i <= dat_o;
            we    <= 1'b1;
            stb   <= 1'b1;
            sel   <= 2'b01;
            st    <= 4'h7;
          end
        4'h7:
          if (ack) begin
            adr   <= 11'b0000_0000_110;
            dat_i <= dat_o;
            we    <= 1'b1;
            stb   <= 1'b0;
            sel   <= 2'b01;
            st    <= 4'h8;
          end
      endcase

endmodule
