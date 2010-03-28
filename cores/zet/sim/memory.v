/*
 *  Zero delay memory module for Zet
 *  Copyright (C) 2008-2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module memory (
    // Wishbone slave interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [19:1] wb_adr_i,
    input         wb_we_i,
    input  [ 1:0] wb_sel_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    output        wb_ack_o
  );

  // Registers and nets
  reg  [15:0] ram[0:2**19-1];

  wire       we;
  wire [7:0] bhw, blw;

  // Assignments
  assign wb_dat_o = ram[wb_adr_i];
  assign wb_ack_o = wb_stb_i;
  assign we       = wb_we_i & wb_stb_i & wb_cyc_i;

  assign bhw = wb_sel_i[1] ? wb_dat_i[15:8]
                           : ram[wb_adr_i][15:8];
  assign blw = wb_sel_i[0] ? wb_dat_i[7:0]
                           : ram[wb_adr_i][7:0];

  // Behaviour
  always @(posedge wb_clk_i)
    if (we) ram[wb_adr_i] <= { bhw, blw };

endmodule
