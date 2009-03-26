/*
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

//`define DEBUG 1

module kotku (
    input        clk_50_,
    output [9:0] ledr_,
    output [7:0] ledg_,
    input  [9:0] sw_,

    // flash signals
    output [21:0] flash_addr_,
    input  [ 7:0] flash_data_,
    output        flash_we_n_,
    output        flash_oe_n_,
    output        flash_rst_n_,

    // sdram signals
    output [11:0] sdram_addr_,
    inout  [15:0] sdram_data_,
    output [ 1:0] sdram_ba_,
    output [ 1:0] sdram_dqm_,
    output        sdram_ras_n_,
    output        sdram_cas_n_,
    output        sdram_ce_,
    output        sdram_clk_,
    output        sdram_we_n_,
    output        sdram_cs_n_,

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
  wire        clk;
  wire        rst;
  wire [15:0] dat_o;
  wire [15:0] dat_i;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire [ 1:0] sel;
  wire        stb;
  wire        flash_stb;
  wire        cyc;
  wire        ack;
  wire        flash_ack;
  wire        flash_arena;
  wire        flash_mem_arena;
  wire [15:0] flash_dat_o;
  wire        lock;
  reg  [15:0] io_reg;
  wire [15:0] ip;
  wire [15:0] imm;
  reg         dbg_block;

  wire [31:0] sdram_dat_o;
  wire        sdram_stb;
  wire        sdram_ack;
  wire        sdram_mem_arena;
  wire        sdram_arena;
  wire        sdram_clk;
  wire [1:0]  state0;
  wire [4:0]  state1;

  wire [15:0] sram_dat_o;
  wire        sram_stb;
  wire        sram_ack;
  wire        sram_mem_arena;
  wire        sram_arena;

  wire        vdu_clk;
  wire [15:0] vdu_dat_i;
  wire [ 6:0] h_vdu_adr;
  wire [11:1] vdu_adr_o;
  wire        vdu_we_o;
  wire [ 1:0] vdu_sel_o;
  wire        vdu_stb_o;
  wire        vdu_cyc_o;
  wire        vdu_ack_i;

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c0     (sdram_clk),
    .c1     (vdu_clk),
    .c2     (clk),
    .locked (lock)
  );

  flash flash (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_o (flash_dat_o),
    .wb_adr_i (adr[16:1]),
    .wb_stb_i (flash_stb),
    .wb_cyc_i (flash_stb),
    .wb_sel_i (sel),
    .wb_ack_o (flash_ack),

    // Pad signals
    .flash_addr_  (flash_addr_),
    .flash_data_  (flash_data_),
    .flash_we_n_  (flash_we_n_),
    .flash_oe_n_  (flash_oe_n_),
    .flash_rst_n_ (flash_rst_n_)
  );

  yadmc #(
    .sdram_depth       (23),
    .sdram_columndepth (8),
    .sdram_adrwires    (12),
    .cache_depth       (4)
    ) yadmc (
    // Wishbone slave interface
`ifdef DEBUG
    .state (state0),
    .statey (state1),
`endif
    .sys_clk  (clk),
    .sys_rst  (rst),
    .wb_adr_i ({11'h0,adr,2'b00}),
    .wb_dat_i ({16'h0,dat_o}),
    .wb_dat_o (sdram_dat_o),
    .wb_sel_i ({2'b00,sel}),
    .wb_cyc_i (sdram_stb),
    .wb_stb_i (sdram_stb),
    .wb_we_i  (we),
    .wb_ack_o (sdram_ack),

    // SDRAM interface
    .sdram_clk   (sdram_clk),
    .sdram_cke   (sdram_ce_),
    .sdram_cs_n  (sdram_cs_n_),
    .sdram_we_n  (sdram_we_n_),
    .sdram_cas_n (sdram_cas_n_),
    .sdram_ras_n (sdram_ras_n_),
    .sdram_dqm   (sdram_dqm_),
    .sdram_adr   (sdram_addr_),
    .sdram_ba    (sdram_ba_),
    .sdram_dq    (sdram_data_)
  );

  wb_sram sram (
    // Wishbone common signals
    .wb_clk_i (clk),
    .wb_rst_i (rst),

    // Wishbone slave interface 0 - higher priority
    .wb0_dat_i (16'h0),
    .wb0_dat_o (vdu_dat_i),
    .wb0_adr_i ({h_vdu_adr,vdu_adr_o}),
    .wb0_we_i  (vdu_we_o),
    .wb0_sel_i (vdu_sel_o),
    .wb0_stb_i (vdu_stb_o),
    .wb0_cyc_i (vdu_cyc_o),
    .wb0_ack_o (vdu_ack_i),

    // Wishbone slave interface 1 - lower priority
    .wb1_dat_i (dat_o),
    .wb1_dat_o (sram_dat_o),
    .wb1_adr_i ({adr[19],adr[17:1]}),
    .wb1_we_i  (we),
    .wb1_sel_i (sel),
    .wb1_stb_i (sram_stb),
    .wb1_cyc_i (sram_stb),
    .wb1_ack_o (sram_ack),

    // Pad signals
    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  vdu vdu (
    // Wishbone common signals
    .wb_rst_i (rst),
    .wb_clk_i (vdu_clk), // 25MHz	VDU clock

    // Wishbone master interface
    .wbm_adr_o (vdu_adr_o),
    .wbm_dat_i (vdu_dat_i),
    .wbm_we_o  (vdu_we_o),
    .wbm_sel_o (vdu_sel_o),
    .wbm_stb_o (vdu_stb_o),
    .wbm_cyc_o (vdu_cyc_o),
    .wbm_ack_i (vdu_ack_i),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  cpu zet_proc (
`ifdef DEBUG
    .ip (ip),
    .dbg_block (1'b0),
    .imm (imm),
`endif
    // Wishbone master interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_adr_o (adr),
    .wb_we_o  (we),
    .wb_tga_o (tga),
    .wb_sel_o (sel),
    .wb_stb_o (stb),
    .wb_cyc_o (cyc),
    .wb_ack_i (ack),
    .wb_tgc_i (1'b0)
  );

  // Continuous assignments
  assign flash_mem_arena = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign flash_arena     = !tga & flash_mem_arena;
  assign flash_stb       = flash_arena & stb & cyc;

  assign sram_mem_arena  = !adr[18];
  assign sram_arena      = !tga & sram_mem_arena;
  assign sram_stb        = sram_arena & stb & cyc;

  assign sdram_mem_arena = !flash_mem_arena & !sram_mem_arena;
  assign sdram_arena     = !tga & sdram_mem_arena;
  assign sdram_stb       = sdram_arena & stb & cyc;

  assign ack             = tga ? (stb & cyc)
                         : (flash_mem_arena ? flash_ack
                         : (sram_mem_arena ? sram_ack : sdram_ack));
  assign { ledr_,ledg_ } = { 2'b0, io_reg };
  assign rst             = !lock;
  assign sdram_clk_      = sdram_clk;

  assign dat_i     = flash_mem_arena ? flash_dat_o
                   : (sram_mem_arena ? sram_dat_o
                   : sdram_dat_o[15:0]);

  assign h_vdu_adr = 7'b111_1000;

  // Behaviour
  // leds
  always @(posedge clk)
    io_reg <= rst ? 16'h0
      : ((tga && stb && cyc && we && adr[15:8]==8'hf1) ?
        dat_o : io_reg );

`ifdef DEBUG
  // dbg_block
  always @(posedge clk)
    dbg_block <= rst ? 1'b0 : (ip[9:0]==sw_);
`endif

endmodule
