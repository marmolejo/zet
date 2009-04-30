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

module sdspi (
    // Serial pad signal
    output reg sclk,
    input      miso,
    output reg mosi,
    output reg ss,
    input      clk2x,

    // Wishbone slave interface
    input            wb_clk_i,
    input            wb_rst_i,
    input      [8:0] wb_dat_i,
    output reg [7:0] wb_dat_o,
    input            wb_we_i,
    input      [1:0] wb_sel_i,
    input            wb_stb_i,
    input            wb_cyc_i,
    output reg       wb_ack_o
  );

  // Registers and nets
  wire       op;
  wire       start;
  reg  [7:0] tr;
  reg        st;
  reg  [6:0] sft;

  // Continuous assignments
  assign op    = wb_stb_i & wb_cyc_i;
  assign start = !st & op;

  // Behaviour
  // mosi
  always @(posedge wb_clk_i)
    mosi <= wb_rst_i ? 1'b1 : (start ? wb_dat_i[7] : tr[7]);

  // tr
  always @(posedge wb_clk_i)
    tr <= wb_rst_i ? 8'hff
        : { ((start & wb_we_i & wb_sel_i[0]) ?
            wb_dat_i[6:0] : tr[6:0]), 1'b1 };

  // sft, wb_ack_o
  always @(posedge wb_clk_i)
    { sft, wb_ack_o } <= wb_rst_i ? 8'h0 : { start, sft };

  // st
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 1'b0 : (st ? !wb_ack_o : op);

  // wb_dat_o
  always @(negedge wb_clk_i)
    wb_dat_o <= wb_rst_i ? 8'h0
      : op ? { wb_dat_o[6:0], miso } : wb_dat_o;

  // sclk
  always @(posedge clk2x)
    sclk <= wb_rst_i ? 1'b1 : !(op & !wb_ack_o & wb_clk_i);

  // ss
  always @(negedge wb_clk_i)
    ss <= wb_rst_i ? 1'b1
        : ((op & wb_we_i & wb_sel_i[1]) ? wb_dat_i[8] : ss);
endmodule
