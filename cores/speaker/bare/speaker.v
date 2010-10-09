/*
 *  PC speaker module without any codec
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

module speaker (
    // Clocks
    input clk,
    input rst,

    // Wishbone slave interface
    input      [7:0] wb_dat_i,
    output reg [7:0] wb_dat_o,
    input            wb_we_i,
    input            wb_stb_i,
    input            wb_cyc_i,
    output           wb_ack_o,

    // Timer clock
    input timer2,

    // Speaker pad signal
    output speaker_
  );

  // Net declarations
  wire        write;
  wire        spk;

  // Combinatorial logic
  // System speaker
  assign speaker_ = timer2 & wb_dat_o[1];

  // Wishbone signals
  assign wb_ack_o = wb_stb_i && wb_cyc_i;
  assign write    = wb_stb_i && wb_cyc_i && wb_we_i;

  // Sequential logic
  always @(posedge clk)
    wb_dat_o <= rst ? 8'h0 : (write ? wb_dat_i : wb_dat_o);

endmodule
