/*
 *  Memory arbitrer for VGA
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

module vga_mem_arbitrer (
    input clk_i,
    input rst_i,

    // Wishbone slave 1
    input  [17:1] wb_adr_i,
    input  [ 1:0] wb_sel_i,
    input         wb_we_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input         wb_stb_i,
    output        wb_ack_o,

    // CSR slave 1
    input  [17:1] csr_adr_i,
    output [15:0] csr_dat_o,
    input         csr_stb_i,

    // CSR master
    output [17:1] csrm_adr_o,
    output [ 1:0] csrm_sel_o,
    output        csrm_we_o,
    output [15:0] csrm_dat_o,
    input  [15:0] csrm_dat_i
  );

  // Registers
  reg  [1:0] wb_ack;
  wire       wb_ack_r;
  wire       wb_ack_w;

  // Continous assignments
  assign csrm_adr_o = csr_stb_i ? csr_adr_i : wb_adr_i;
  assign csrm_sel_o = csr_stb_i ? 2'b11 : wb_sel_i;
  assign csrm_we_o  = wb_stb_i & !csr_stb_i & wb_we_i;
  assign csrm_dat_o = wb_dat_i;

  assign wb_dat_o  = csrm_dat_i;
  assign csr_dat_o = csrm_dat_i;

  assign wb_ack_r = wb_ack[1];
  assign wb_ack_w = wb_stb_i & !csr_stb_i;
  assign wb_ack_o = wb_we_i ? wb_ack_w : wb_ack_r;

  // Behaviour
  always @(posedge clk_i)
    wb_ack <= rst_i ? 2'b00
      : { wb_ack[0], (wb_stb_i & !csr_stb_i & !(|wb_ack)) };

endmodule
