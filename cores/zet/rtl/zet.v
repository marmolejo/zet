/*
 *  Zet processor top level file
 *  Copyright (c) 2008-2010  Zeus Gomez Marmolejo <zeus@opencores.org>
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

`include "defines.v"

module zet (
    // Common signals
    input         clk_i,
    input         rst_i,

    // Wishbone master interface
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output [19:1] wb_adr_o,
    output        wb_we_o,
    output        wb_tga_o,  // io/mem
    output [ 1:0] wb_sel_o,
    output        wb_stb_o,
    output        wb_cyc_o,
    input         wb_ack_i,

    // Interrupt line
    input         intr, // interrupt request
    output        inta, // interrupt acknowledge
    input  [ 3:0] iid,  // interrupt id

    output [19:0] pc  // for debugging purposes
  );

  // Net declarations
  wire [19:0] umif_adr_i;
  wire [15:0] umif_dat_o;
  wire        umif_stb_i;
  wire        umif_by_i;
  wire        umif_ack_o;

  wire [19:0] umie_adr_i;
  wire [15:0] umie_dat_o;
  wire [15:0] umie_dat_i;
  wire        umie_we_i;
  wire        umie_by_i;
  wire        umie_stb_i;
  wire        umie_ack_o;
  wire        umie_tga_i;

  // Module instances
  zet_core core (
    .clk (clk_i),
    .rst (rst_i),

    .umif_adr_o (umif_adr_i),
    .umif_dat_i (umif_dat_o),
    .umif_stb_o (umif_stb_i),
    .umif_by_o  (umif_by_i),
    .umif_ack_i (umif_ack_o),

    .umie_adr_o (umie_adr_i),
    .umie_dat_i (umie_dat_o),
    .umie_dat_o (umie_dat_i),
    .umie_we_o  (umie_we_i),
    .umie_by_o  (umie_by_i),
    .umie_stb_o (umie_stb_i),
    .umie_ack_i (umie_ack_o),
    .umie_tga_o (umie_tga_i),

    .intr (intr),
    .inta (inta),
    .iid  (iid)
  );

  zet_wb_master wb_master (
    .clk (clk_i),
    .rst (rst_i),

    .umif_adr_i (umif_adr_i),
    .umif_dat_o (umif_dat_o),
    .umif_stb_i (umif_stb_i),
    .umif_by_i  (umif_by_i),
    .umif_ack_o (umif_ack_o),

    .umie_adr_i (umie_adr_i),
    .umie_dat_o (umie_dat_o),
    .umie_dat_i (umie_dat_i),
    .umie_we_i  (umie_we_i),
    .umie_by_i  (umie_by_i),
    .umie_stb_i (umie_stb_i),
    .umie_ack_o (umie_ack_o),
    .umie_tga_i (umie_tga_i),

    .wb_dat_i (wb_dat_i),
    .wb_dat_o (wb_dat_o),
    .wb_adr_o (wb_adr_o),
    .wb_we_o  (wb_we_o),
    .wb_tga_o (wb_tga_o),
    .wb_sel_o (wb_sel_o),
    .wb_stb_o (wb_stb_o),
    .wb_cyc_o (wb_cyc_o),
    .wb_ack_i (wb_ack_i)
  );

  // Continuous assignments
  assign pc = umif_adr_i;

endmodule
