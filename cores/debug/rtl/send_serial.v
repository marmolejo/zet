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

module send_serial (
    // Serial pad signal
    output reg  trx_,

    // Wishbone slave interface
    input       wb_clk_i,
    input       wb_rst_i,
    input [7:0] wb_dat_i,
    input       wb_we_i,
    input       wb_stb_i,
    input       wb_cyc_i,
    output reg  wb_ack_o
  );

  // Registers and nets
  wire       op;
  wire       start;
  reg  [8:0] tr;
  reg        st;
  reg  [7:0] sft;

  // Continuous assignments
  assign op    = wb_we_i & wb_stb_i & wb_cyc_i;
  assign start = !st & op;

  // Behaviour
  // trx_
  always @(posedge wb_clk_i)
    trx_ <= wb_rst_i ? 1'b1 : (start ? 1'b0 : tr[0]);

  // tr
  always @(posedge wb_clk_i)
    tr <= wb_rst_i ? 9'h1ff
        : { 1'b1, (start ? wb_dat_i : tr[8:1]) };

  // sft, wb_ack_o
  always @(posedge wb_clk_i)
    { sft, wb_ack_o } <= wb_rst_i ? 9'h0 : { start, sft };

  // st
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 1'b0 : (st ? !wb_ack_o : op);
endmodule
