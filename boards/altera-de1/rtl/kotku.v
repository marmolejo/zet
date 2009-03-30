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
`ifdef DEBUG
    output       trx_,
`endif

    input        clk_50_,
    output [9:0] ledr_,
    output [7:0] ledg_,
    input  [9:0] sw_,
    output [6:0] hex0_,
    output [6:0] hex1_,
    output [6:0] hex2_,
    output [6:0] hex3_,

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
    output       tft_lcd_vsync_,

    // PS2 signals
    inout         ps2_clk_,
    inout         ps2_data_
  );

  // Registers and nets
  wire        clk;
  wire        sys_clk;
  wire        rst;
  wire        rst_lck;
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
  wire        flash_io_arena;
  wire [15:0] flash_dat_o;
  wire        lock;
  reg  [15:0] io_reg;
  wire [15:0] imm;
  reg         dbg_block;
  wire        block;
  wire [15:0] io_dat_i;

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
  wire [15:0] vdum_dat_i;
  wire [ 6:0] h_vdu_adr;
  wire [11:1] vdum_adr_o;
  wire        vdum_we_o;
  wire [ 1:0] vdum_sel_o;
  wire        vdum_stb_o;
  wire        vdum_cyc_o;
  wire        vdum_ack_i;
  wire [15:0] vdu_dat_o;
  wire        vdu_ack_o;
  wire        vdu_stb;
  wire        vdu_io_arena;
  wire        vdu_arena;

  wire [ 7:0] keyb_dat_o;
  wire        keyb_io_arena;
  wire        keyb_io_status;
  wire        keyb_arena;

  wire [ 1:0] intv;
  wire        iid;
  wire        intr;
  wire        inta;

`ifdef DEBUG
  wire [15:0] ip;
  wire [19:0] pc;
  wire [15:0] cs;
  wire [ 2:0] state;
  wire        clk_s;
  wire        rst_s;
`endif

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c0     (sdram_clk),
    .c1     (vdu_clk),
    .c2     (sys_clk),
    .locked (lock)
  );

  flash flash (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (flash_dat_o),
    .wb_adr_i (adr[16:1]),
    .wb_we_i  (we),
    .wb_tga_i (tga),
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
    .state  (state0),
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
    .wb0_dat_o (vdum_dat_i),
    .wb0_adr_i ({h_vdu_adr,vdum_adr_o}),
    .wb0_we_i  (vdum_we_o),
    .wb0_sel_i (vdum_sel_o),
    .wb0_stb_i (vdum_stb_o /* 1'b0 */),
    .wb0_cyc_i (vdum_cyc_o),
    .wb0_ack_o (vdum_ack_i),

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

    // Wishbone slave interface
    .wbs_dat_i (dat_o),
    .wbs_dat_o (vdu_dat_o),
    .wbs_we_i  (we),
    .wbs_sel_i (sel),
    .wbs_stb_i (vdu_stb),
    .wbs_cyc_i (vdu_stb),
    .wbs_ack_o (vdu_ack_o),

    // Wishbone master interface
    .wbm_adr_o (vdum_adr_o),
    .wbm_dat_i (vdum_dat_i),
    .wbm_we_o  (vdum_we_o),
    .wbm_sel_o (vdum_sel_o),
    .wbm_stb_o (vdum_stb_o),
    .wbm_cyc_o (vdum_cyc_o),
    .wbm_ack_i (vdum_ack_i),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  ps2_keyb #(
    .TIMER_60USEC_VALUE_PP (750),
    .TIMER_60USEC_BITS_PP  (10),
    .TIMER_5USEC_VALUE_PP  (60),
    .TIMER_5USEC_BITS_PP   (6)
    ) keyboard (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_o (keyb_dat_o),
    .wb_tgc_o (intv[1]),

    .ps2_clk_  (ps2_clk_),
    .ps2_data_ (ps2_data_)
  );

  timer #(
    .res   (33),
    .phase (12507)
    ) timer0 (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_tgc_o (intv[0])
  );

  simple_pic pic0 (
    .clk  (clk),
    .rst  (rst),
    .int  (intv),
    .inta (inta),
    .intr (intr),
    .iid  (iid)
  );

  cpu zet_proc (
`ifdef DEBUG
    .ip        (ip),
    .cs        (cs),
    .dbg_block (block),
    .state     (state),
    .imm       (imm),
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
  hex_display hex16 (
    .num (pc[19:4]),
    .en  (1'b1),

    .hex0 (hex0_),
    .hex1 (hex1_),
    .hex2 (hex2_),
    .hex3 (hex3_)
  );

  clk_uart #(
    .bits  (26),
    .value (154619) // phase counter
    ) clk_uart (
    .clk_i (sdram_clk),
    .rst_i (rst_lck),
    .clk_o (clk_s),
    .rst_o (rst_s)
  );

  pc_trace pc0 (
    .trx_     (trx_),

    .clk      (clk),
    .rst      (rst),
    .pc       (pc),
    .zet_st   (state),
    .block    (block)
  );
`endif

  // Continuous assignments
  assign flash_mem_arena = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign flash_io_arena  = (adr[15:9]==7'b1110_000);
  assign flash_arena     = (!tga & flash_mem_arena)
                         | (tga & flash_io_arena);
  assign flash_stb       = flash_arena & stb & cyc;

  assign sram_mem_arena  = !adr[18];
  assign sram_arena      = !tga & sram_mem_arena;
  assign sram_stb        = sram_arena & stb & cyc;

  assign sdram_mem_arena = !flash_mem_arena & !sram_mem_arena;
  assign sdram_arena     = !tga & sdram_mem_arena;
  assign sdram_stb       = sdram_arena & stb & cyc;

  assign vdu_io_arena    = (adr[15:4]==12'h03d) &&
                           ((adr[3:1]==3'h2 && we)
                            || (adr[3:1]==3'h5 && !we));
  assign vdu_arena       = (tga & vdu_io_arena);
  assign vdu_stb         = vdu_arena & stb & cyc;

  // MS-DOS is reading IO address 0x64 to check the inhibit bit
  assign keyb_io_status  = (adr[15:1]==15'h0032 && !we);
  assign keyb_io_arena   = (adr[15:1]==15'h0030 && !we);
  assign keyb_arena      = (tga & keyb_io_arena);

  assign ack             = tga ? (flash_io_arena ? flash_ack
                               : (vdu_io_arena ? vdu_ack_o : (stb & cyc)))
                         : (flash_mem_arena ? flash_ack
                         : (sram_mem_arena ? sram_ack : sdram_ack));
  assign rst_lck         = !lock;
  assign sdram_clk_      = sdram_clk;

  assign io_dat_i  = flash_io_arena ? flash_dat_o
                   : (vdu_io_arena ? vdu_dat_o
                   : (keyb_io_arena ? keyb_dat_o
                   : (keyb_io_status ? 16'h10 : 16'h0)));

  assign dat_i     = inta ? { 15'b0000_0000_0000_100, iid }
                   : (tga ? io_dat_i
                   : (flash_mem_arena ? flash_dat_o
                   : (sram_mem_arena ? sram_dat_o
                   : sdram_dat_o[15:0])));

  assign h_vdu_adr = 7'b111_1000;
`ifdef DEBUG
  assign pc  = (cs << 4) + ip;
  assign clk = clk_s;
  assign rst = rst_s;
  assign { ledr_,ledg_ } = { io_reg[13:0], pc[3:0] };
`else
  assign clk = sys_clk;
  assign rst = rst_lck;
  assign { ledr_,ledg_ } = { 2'b00, io_reg };
`endif

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
