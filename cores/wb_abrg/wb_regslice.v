/*
 *  Wishbone register slice
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

module wb_regslice (
    input clk,
    input rst,

    // Wishbone slave interface
    input      [19:1] wbs_adr_i,
    input      [15:0] wbs_dat_i,
    output reg [15:0] wbs_dat_o,
    input      [ 1:0] wbs_sel_i,
    input             wbs_tga_i,
    input             wbs_stb_i,
    input             wbs_cyc_i,
    input             wbs_we_i,
    output reg        wbs_ack_o,

    // Wishbone master interface
    output reg [19:1] wbm_adr_o,
    output reg [15:0] wbm_dat_o,
    input      [15:0] wbm_dat_i,
    output reg [ 1:0] wbm_sel_o,
    output reg        wbm_tga_o,
    output reg        wbm_stb_o,
    output reg        wbm_cyc_o,
    output reg        wbm_we_o,
    input             wbm_ack_i
  );

  // Net declarations
  wire ack_st;

  // Combinational logic
  assign ack_st = wbm_ack_i & wbs_ack_o;

  // Sequential logic
  always @(posedge clk)
    wbm_stb_o <= rst ? 1'b0
      : (ack_st ? 1'b0 : wbs_stb_i);

  always @(posedge clk)
    begin
      wbm_adr_o <= wbs_adr_i;
      wbm_dat_o <= wbs_dat_i;
      wbm_sel_o <= wbs_sel_i;
      wbm_tga_o <= wbs_tga_i;
      wbm_cyc_o <= wbs_cyc_i;
      wbm_we_o  <= wbs_we_i;
    end

  always @(posedge clk)
    begin
      wbs_dat_o <= wbm_dat_i;
      wbs_ack_o <= wbm_ack_i;
    end

endmodule
