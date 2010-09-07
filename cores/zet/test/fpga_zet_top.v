/*
 *  Zet synthesis stub for timing analysis
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

module fpga_zet_top (
    // Wishbone master interface
    input             clk_i,
    input             rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    output reg [19:1] wb_adr_o,
    output reg        wb_we_o,
    output reg        wb_tga_o,  // io/mem
    output reg [ 1:0] wb_sel_o,
    output reg        wb_stb_o,
    output reg        wb_cyc_o,
    input             wb_ack_i,
    input             intr,
    output reg        inta,
    input      [ 3:0] iid,
    output reg [19:0] pc
  );

  // Registers and nets
  reg  [15:0] wb_dat_i_l;
  wire [15:0] wb_dat_o_l;
  wire [19:1] wb_adr_o_l;
  wire        wb_we_o_l;
  wire        wb_tga_o_l;  // io/mem
  wire [ 1:0] wb_sel_o_l;
  wire        wb_stb_o_l;
  wire        wb_cyc_o_l;
  reg         wb_ack_i_l;
  reg         intr_l;  // intr
  wire        inta_l;  // inta
  reg  [ 3:0] iid_l;
  wire [19:0] pc_l;

  // Module instances
  zet zet (
    .clk_i (clk_i),
    .rst_i (rst_i),

    // Wishbone master interface
    .wb_dat_i (wb_dat_i_l),
    .wb_dat_o (wb_dat_o_l),
    .wb_adr_o (wb_adr_o_l),
    .wb_we_o  (wb_we_o_l),
    .wb_tga_o (wb_tga_o_l),  // io/mem
    .wb_sel_o (wb_sel_o_l),
    .wb_stb_o (wb_stb_o_l),
    .wb_cyc_o (wb_cyc_o_l),
    .wb_ack_i (wb_ack_i_l),

    .intr (intr_l),  // intr
    .inta (inta_l),  // inta

    .iid (iid_l),
    .pc  (pc_l)
  );

  always @(posedge clk_i)
    begin
      wb_dat_i_l <= wb_dat_i;
      wb_dat_o <= wb_dat_o_l;
      wb_adr_o <= wb_adr_o_l;
      wb_we_o  <= wb_we_o_l;
      wb_tga_o <= wb_tga_o_l;
      wb_sel_o <= wb_sel_o_l;
      wb_stb_o <= wb_stb_o_l;
      wb_cyc_o <= wb_cyc_o_l;
      wb_ack_i_l <= wb_ack_i;
      intr_l <= intr;
      inta   <= inta_l;
      iid_l  <= iid;
      pc     <= pc_l;
    end

endmodule
