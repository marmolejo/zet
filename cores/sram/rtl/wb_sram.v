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

module wb_sram (
    // Wishbone slave interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [18:1] wb_adr_i,
    input         wb_we_i,
    input  [ 1:0] wb_sel_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    output reg    wb_ack_o,


    // Pad signals
    output reg [17:0] sram_addr_,
    inout      [15:0] sram_data_,
    output reg        sram_we_n_,
    output reg        sram_oe_n_,
    output            sram_ce_n_,
    output reg [ 1:0] sram_bw_n_
  );

  // Nets
  wire op;

  reg [15:0] ww;

  // Continuous assingments
  assign op = wb_stb_i & wb_cyc_i;

  assign wb_dat_o = sram_data_;

  assign sram_data_ = sram_we_n_ ? 16'hzzzz : ww;
  assign sram_ce_n_ = 1'b0;

  // Behaviour
  // sram_addr_
  always @(posedge wb_clk_i)
    sram_addr_ <= wb_adr_i;

  // sram_we_n_
  always @(posedge wb_clk_i)
    sram_we_n_ <= !(wb_we_i & op);

  // ww
  always @(posedge wb_clk_i) ww <= wb_dat_i;

  // sram_bw_n_
  always @(posedge wb_clk_i)
    sram_bw_n_ = ~wb_sel_i;

  // sram_oe_n_
  always @(posedge wb_clk_i)
    sram_oe_n_ <= (wb_we_i & op);

  // wb_ack_o
  always @(posedge wb_clk_i)
    wb_ack_o <= wb_rst_i ? 1'b0 : (wb_ack_o ? 1'b0 : op);

endmodule
