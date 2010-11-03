/*
 *  Wishbone asynchronous bridge with slave register slice
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module wb_abrg_reg (
    input sys_rst,

    // Wishbone slave interface
    input         wbs_clk_i,
    input  [19:1] wbs_adr_i,
    input  [15:0] wbs_dat_i,
    output [15:0] wbs_dat_o,
    input  [ 1:0] wbs_sel_i,
    input         wbs_tga_i,
    input         wbs_stb_i,
    input         wbs_cyc_i,
    input         wbs_we_i,
    output        wbs_ack_o,

    // Wishbone master interface
    input             wbm_clk_i,
    output reg [19:1] wbm_adr_o,
    output reg [15:0] wbm_dat_o,
    input      [15:0] wbm_dat_i,
    output reg [ 1:0] wbm_sel_o,
    output reg        wbm_tga_o,
    output            wbm_stb_o,
    output            wbm_cyc_o,
    output reg        wbm_we_o,
    input             wbm_ack_i
  );

  // Registers and nets
  wire       wbs_stb;
  wire       init_tr;
  reg        wbm_stb;
  reg  [2:0] sync_stb;
  reg  [2:0] sync_ack;
  reg        ft_stb;
  reg        ft_ack;
  reg        stb_r;
  reg        ack_r;

  reg [19:1] wbm_adr_o_r;
  reg [15:0] wbm_dat_o_r;
  reg [ 1:0] wbm_sel_o_r;
  reg        wbs_tga_i_r;
  reg        wbm_tga_o_r;
  reg        wbs_we_i_r;
  reg        wbm_we_o_r;
  reg [15:0] wbs_dat_o_r;
  reg [15:0] wbm_dat_i_r;

  wire [19:1] wbs_adr_i_reg;
  wire [15:0] wbs_dat_i_reg;
  reg  [15:0] wbs_dat_o_reg;
  wire [ 1:0] wbs_sel_i_reg;
  wire        wbs_tga_i_reg;
  wire        wbs_stb_i_reg;
  wire        wbs_cyc_i_reg;
  wire        wbs_we_i_reg;
  wire        wbs_ack_o_reg;

  // Instances
  wb_regslice wb_slave_regslice (
    .clk (wbs_clk_i),
    .rst (sys_rst),

    // Wishbone slave interface
    .wbs_adr_i (wbs_adr_i),
    .wbs_dat_i (wbs_dat_i),
    .wbs_dat_o (wbs_dat_o),
    .wbs_sel_i (wbs_sel_i),
    .wbs_tga_i (wbs_tga_i),
    .wbs_stb_i (wbs_stb_i),
    .wbs_cyc_i (wbs_cyc_i),
    .wbs_we_i  (wbs_we_i),
    .wbs_ack_o (wbs_ack_o),

    // Wishbone master interface
    .wbm_adr_o (wbs_adr_i_reg),
    .wbm_dat_o (wbs_dat_i_reg),
    .wbm_dat_i (wbs_dat_o_reg),
    .wbm_sel_o (wbs_sel_i_reg),
    .wbm_tga_o (wbs_tga_i_reg),
    .wbm_stb_o (wbs_stb_i_reg),
    .wbm_cyc_o (wbs_cyc_i_reg),
    .wbm_we_o  (wbs_we_i_reg),
    .wbm_ack_i (wbs_ack_o_reg)
  );


  // Continous assignments
  assign wbs_stb = wbs_stb_i_reg & wbs_cyc_i_reg;

  // recreate the flag from the level change
  assign wbs_ack_o_reg = (sync_ack[2] ^ sync_ack[1]);
  assign wbm_stb_o = wbm_stb;
  assign wbm_cyc_o = wbm_stb;

  /*
   * A new wishbone transaction is issued:
   * . by changing stb from 0 to 1
   * . by continue asserting stb after ack is received
   */
  assign init_tr = ~stb_r & wbs_stb | ack_r & ~wbs_ack_o_reg & wbs_stb;

  // Behaviour
  // wbm_stb
  always @(posedge wbm_clk_i)
    wbm_stb <= sys_rst ? 1'b0
      : (wbm_stb ? ~wbm_ack_i : sync_stb[2] ^ sync_stb[1]);

  // old stb and ack state
  always @(posedge wbs_clk_i) stb_r <= wbs_stb;
  always @(posedge wbs_clk_i) ack_r <= wbs_ack_o_reg;

  always @(posedge wbs_clk_i)
    ft_stb <= sys_rst ? 1'b0 : (init_tr ? ~ft_stb : ft_stb);

  // synchronize the last level change
  always @(posedge wbm_clk_i)
    sync_stb <= sys_rst ? 3'h0 : {sync_stb[1:0], ft_stb};

  // this changes level when a flag is seen
  always @(posedge wbm_clk_i)
    ft_ack <= sys_rst ? 1'b0 : (wbm_ack_i ? ~ft_ack : ft_ack);

  // which can then be synched to wbs_clk_i
  always @(posedge wbs_clk_i)
    sync_ack <= sys_rst ? 3'h0 : {sync_ack[1:0], ft_ack};

  // rest of the wishbone signals
  always @(posedge wbm_clk_i)
    {wbm_adr_o, wbm_adr_o_r} <= {wbm_adr_o_r, wbs_adr_i_reg};

  always @(posedge wbm_clk_i)
    {wbm_dat_o, wbm_dat_o_r} <= {wbm_dat_o_r, wbs_dat_i_reg};

  always @(posedge wbm_clk_i)
    {wbm_sel_o, wbm_sel_o_r} <= {wbm_sel_o_r, wbs_sel_i_reg};

  always @(posedge wbs_clk_i) wbs_we_i_r <= wbs_we_i_reg;
  always @(posedge wbm_clk_i)
    {wbm_we_o, wbm_we_o_r} <= {wbm_we_o_r, wbs_we_i_r};

  always @(posedge wbs_clk_i) wbs_tga_i_r <= wbs_tga_i_reg;
  always @(posedge wbm_clk_i)
    {wbm_tga_o, wbm_tga_o_r} <= {wbm_tga_o_r, wbs_tga_i_r};

  /*
   * Register input coming from the slave as that can change
   * after the ack is received
   */
  always @(posedge wbm_clk_i)
    wbm_dat_i_r <= wbm_ack_i ? wbm_dat_i : wbm_dat_i_r;

  always @(posedge wbs_clk_i)
    {wbs_dat_o_reg, wbs_dat_o_r} <= {wbs_dat_o_r, wbm_dat_i_r};

endmodule
