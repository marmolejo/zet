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
    // Wishbone common signals
    input         wb_clk_i,
    input         wb_rst_i,

    // Wishbone slave interface 0 - higher priority
    input  [15:0] wb0_dat_i,
    output [15:0] wb0_dat_o,
    input  [18:1] wb0_adr_i,
    input         wb0_we_i,
    input  [ 1:0] wb0_sel_i,
    input         wb0_stb_i,
    input         wb0_cyc_i,
    output        wb0_ack_o,

    // Wishbone slave interface 1 - lower priority
    input  [15:0] wb1_dat_i,
    output [15:0] wb1_dat_o,
    input  [18:1] wb1_adr_i,
    input         wb1_we_i,
    input  [ 1:0] wb1_sel_i,
    input         wb1_stb_i,
    input         wb1_cyc_i,
    output        wb1_ack_o,

    // Pad signals
    output [17:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output        sram_ce_n_,
    output [ 1:0] sram_bw_n_
  );

  // Nets
  wire arb;  // Arbitrer
  wire op0;
  wire op1;

  wire [15:0] ww;

  // Continuous assingments
  assign op0 = wb0_stb_i & wb0_cyc_i;
  assign op1 = wb1_stb_i & wb1_cyc_i;
  assign arb = op1 & !op0;

  assign wb0_dat_o = sram_data_;
  assign wb1_dat_o = sram_data_;
  assign wb0_ack_o = op0;
  assign wb1_ack_o = arb;

  assign sram_data_ = sram_we_n_ ? 16'hzzzz : ww;
  assign ww         = arb ? wb1_dat_i : wb0_dat_i;
  assign sram_addr_ = arb ? wb1_adr_i : wb0_adr_i;
  assign sram_we_n_ = arb ? ~wb1_we_i : !(wb0_we_i & op0);
  assign sram_bw_n_ = arb ? ~wb1_sel_i : ~wb0_sel_i;
  assign sram_oe_n_ = arb ? wb1_we_i : (wb0_we_i & op0);
  assign sram_ce_n_ = 1'b0;

endmodule
