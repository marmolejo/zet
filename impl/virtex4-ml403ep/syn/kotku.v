/*
 *  Copyright (c) 2008  Zeus Gomez Marmolejo <zeus@opencores.org>
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

`timescale 1ns/10ps
`include "defines.v"

module kotku_ml403 (
`ifdef DEBUG
    output        rs_,
    output        rw_,
    output        e_,
    output  [7:4] db_,
    input         but_,
`endif

    output        tft_lcd_clk_,
    output [ 1:0] tft_lcd_r_,
    output [ 1:0] tft_lcd_g_,
    output [ 1:0] tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,

    input         sys_clk_in_,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [31:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        sram_adv_ld_n_,
    output        flash_ce2_,

    input         but2_
  );

  // Net declarations
  wire        clk;
  wire        rst_lck;
  wire [15:0] dat_i;
  wire [15:0] dat_o;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire        stb;
  wire        ack;
  wire [15:0] io_dat_i;
  wire [ 1:0] sel;
  wire        cyc;
  wire [15:0] vdu_dat_o;
  wire        vdu_ack_o;
  wire        vdu_mem_arena;
  wire        vdu_io_arena;
  wire        vdu_arena;
  wire [15:0] flash_dat_o;
  wire        flash_stb;
  wire        flash_ack;
  wire        flash_mem_arena;
  wire        flash_io_arena;
  wire        flash_arena;
  wire [15:0] zbt_dat_o;
  wire        zbt_stb;
  wire        zbt_ack;
  wire [20:0] flash_addr_;
  wire [20:0] sram_addr_;
  wire        flash_we_n_;
  wire        sram_we_n_;
  wire        intr;
  wire        inta;

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
  wire [ 2:0] cnt;
  wire        op;
  wire [15:0] r1, r2;
  reg         rst;
`else
  wire        rst;
`endif

  // Register declarations
  reg  [15:0] io_reg;
  reg  [ 1:0] vdu_stb_sync;
  reg  [ 1:0] vdu_ack_sync;

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

  vdu vdu0 (
    // Wishbone signals
    .wb_clk_i (tft_lcd_clk_), // 25 Mhz VDU clock
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (vdu_dat_o),
    .wb_adr_i (adr[11:1]),
    .wb_we_i  (we),
    .wb_tga_i (tga),
    .wb_sel_i (sel),
    .wb_stb_i (vdu_stb_sync[1]),
    .wb_cyc_i (vdu_stb_sync[1]),
    .wb_ack_o (vdu_ack_o),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  flash_cntrl fc0 (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (flash_dat_o),
    .wb_adr_i (adr[17:1]),
    .wb_we_i  (we),
    .wb_tga_i (tga),
    .wb_stb_i (flash_stb),
    .wb_cyc_i (flash_stb),
    .wb_ack_o (flash_ack),

    // Pad signals
    .flash_addr_ (flash_addr_),
    .flash_data_ (sram_flash_data_[15:0]),
    .flash_we_n_ (flash_we_n_),
    .flash_ce2_  (flash_ce2_)
  );

  zbt_cntrl zbt0 (
`ifdef DEBUG
    .cnt    (cnt),
    .op     (op),
`endif
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (zbt_dat_o),
    .wb_adr_i (adr),
    .wb_we_i  (we),
    .wb_sel_i (sel),
    .wb_stb_i (zbt_stb),
    .wb_cyc_i (zbt_stb),
    .wb_ack_o (zbt_ack),

    // Pad signals
    .sram_clk_      (sram_clk_),
    .sram_addr_     (sram_addr_),
    .sram_data_     (sram_flash_data_),
    .sram_we_n_     (sram_we_n_),
    .sram_bw_       (sram_bw_),
    .sram_cen_      (sram_cen_),
    .sram_adv_ld_n_ (sram_adv_ld_n_)
  );

  but_int but0 (
    .clk  (clk),
    .rst  (rst),
    .but_ (but2_),
    .intr (intr),
    .inta (inta)
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
    .r1         (r1),
    .r2         (r2),
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
    .wb_tgc_i (intr),
    .wb_tgc_o (inta)
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
    .TRIG3   ({clk,we,tga,cyc,stb,ack}),
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
    .TRIG13  (cnt),
    .TRIG14  ({vdu_mem_arena,flash_mem_arena,flash_stb,zbt_stb,op}),
    .TRIG15  ({r1,r2})
  );

  lcd_display lcd0 (
    .f1 (f1),  // 1st row
    .f2 (f2),  // 2nd row
    .m1 (m1),  // 1st row mask
    .m2 (m2),  // 2nd row mask

    .clk (clk_100M),  // 100 Mhz clock
    .rst (rst_lck),

    // Pad signals
    .lcd_rs_  (rs_),
    .lcd_rw_  (rw_),
    .lcd_e_   (e_),
    .lcd_dat_ (db_)
  );

  // Continuous assignments
  assign f1 = { 3'b0, rst, 4'h0, io_reg, 4'h0, dat_o, 7'h0, tga, 7'h0, ack, 4'h0 };
  assign f2 = { adr, 7'h0, we, 3'h0, stb, 3'h0, cyc, 8'h0, pc };
  assign m1 = 16'b1011110111101010;
  assign m2 = 16'b1111101110011111;

  assign pc = (cs << 4) + ip;
`endif

  assign io_dat_i = flash_io_arena ? flash_dat_o
                  : (vdu_io_arena ? vdu_dat_o : 16'h0);
  assign dat_i    = inta ? 16'd3 : (tga ? io_dat_i
                  : (vdu_mem_arena ? vdu_dat_o
                  : (flash_mem_arena ? flash_dat_o : zbt_dat_o)));

  assign flash_mem_arena = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign flash_io_arena  = (adr[15:9]==7'b1110_000);
  assign flash_arena = (!tga & flash_mem_arena)
                     | (tga & flash_io_arena);
  assign vdu_mem_arena = (adr[19:12]==8'hb8);
  assign vdu_io_arena  = (adr[15:8]==8'hb8 && we) ||
                         (adr[15:1]==15'h01ed && !we);
  assign vdu_arena = (!tga & vdu_mem_arena)
                   | (tga & vdu_io_arena);
  assign flash_stb = flash_arena & stb & cyc;
  assign zbt_stb   = !vdu_mem_arena & !flash_mem_arena
                   & !tga & stb & cyc;

  assign ack    = tga ? (flash_io_arena ? flash_ack
                      : (vdu_io_arena ? vdu_ack_sync[1] : (stb & cyc)))
                : (vdu_mem_arena ? vdu_ack_sync[1]
                : (flash_mem_arena ? flash_ack : zbt_ack));

  assign sram_flash_oe_n_ = 1'b0;
  assign sram_flash_addr_ = flash_arena ? flash_addr_
                                        : sram_addr_;
  assign sram_flash_we_n_ = flash_arena ? flash_we_n_
                                        : sram_we_n_;

  // Behaviour
  // vdu_stb_sync[0]
  always @(posedge tft_lcd_clk_)
    vdu_stb_sync[0] <= stb & cyc & vdu_arena;

  // vdu_stb_sync[1]
  always @(posedge clk)
    vdu_stb_sync[1] <= vdu_stb_sync[0];

  // vdu_ack_sync[0]
  always @(posedge clk) vdu_ack_sync[0] <= vdu_ack_o;

  // vdu_ack_sync[1]
  always @(posedge clk) vdu_ack_sync[1] <= vdu_ack_sync[0];

  // io_reg
  always @(posedge clk)
    io_reg <= rst ? 16'h0
	   : ((tga && stb && cyc && we && adr[15:8]==8'hf1) ?
		  dat_o : io_reg );

`ifdef DEBUG
  // rst
  always @(posedge clk)
    rst <= rst_lck ? 1'b1 : (but_ ? 1'b0 : rst );
`else
  assign rst = rst_lck;
`endif
endmodule
