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

`timescale 1ns/10ps

`include "defines.v"

module zet (
    // Wishbone master interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output [19:1] wb_adr_o,
    output        wb_we_o,
    output        wb_tga_o,  // io/mem
    output [ 1:0] wb_sel_o,
    output        wb_stb_o,
    output        wb_cyc_o,
    input         wb_ack_i,
    input         wb_tgc_i,  // intr
    output        wb_tgc_o,  // inta

    output [19:0] pc  // for debugging purposes
  );

  // Net declarations
  wire [15:0] cpu_dat_o;
  wire        cpu_block;
  wire [19:0] cpu_adr_o;

  wire        cpu_byte_o;
  wire        cpu_mem_op;
  wire        cpu_m_io;
  wire [15:0] cpu_dat_i;
  wire        cpu_we_o;
  wire [15:0] iid_dat_i;

  // Module instantiations
  zet_core core (
    .clk (wb_clk_i),
    .rst (wb_rst_i),

    .intr (wb_tgc_i),
    .inta (wb_tgc_o),

    .cpu_adr_o  (cpu_adr_o),
    .iid_dat_i  (iid_dat_i),
    .cpu_dat_i  (cpu_dat_i),
    .cpu_dat_o  (cpu_dat_o),
    .cpu_byte_o (cpu_byte_o),
    .cpu_block  (cpu_block),
    .cpu_mem_op (cpu_mem_op),
    .cpu_m_io   (cpu_m_io),
    .cpu_we_o   (cpu_we_o),

    .pc (pc)
  );

  zet_wb_master wb_master (
    .cpu_byte_o (cpu_byte_o),
    .cpu_memop  (cpu_mem_op),
    .cpu_m_io   (cpu_m_io),
    .cpu_adr_o  (cpu_adr_o),
    .cpu_block  (cpu_block),
    .cpu_dat_i  (cpu_dat_i),
    .cpu_dat_o  (cpu_dat_o),
    .cpu_we_o   (cpu_we_o),

    .wb_clk_i  (wb_clk_i),
    .wb_rst_i  (wb_rst_i),
    .wb_dat_i  (wb_dat_i),
    .wb_dat_o  (wb_dat_o),
    .wb_adr_o  (wb_adr_o),
    .wb_we_o   (wb_we_o),
    .wb_tga_o  (wb_tga_o),
    .wb_sel_o  (wb_sel_o),
    .wb_stb_o  (wb_stb_o),
    .wb_cyc_o  (wb_cyc_o),
    .wb_ack_i  (wb_ack_i)
  );

  // Assignments
  assign iid_dat_i  = wb_tgc_o ? wb_dat_i : cpu_dat_i;

endmodule
