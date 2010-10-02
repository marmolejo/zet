/*
 *  Phase accumulator clock generator:
 *   Output Frequency Fo = Fc * N / 2^bits
 *   Output Jitter = 1/Fc
 *
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

module clk_gen #(
    parameter res,    // bits - bit resolution
    parameter phase   // N - phase value for the counter
  )(
    input      clk_i, // Fc - input frequency
    input      rst_i,
    output     clk_o  // Fo - output frequency
  );

  // Registers and nets
  reg [res-1:0] cnt;

  // Continuous assignments
  assign clk_o = cnt[res-1];

  // Behaviour
  always @(posedge clk_i)
    cnt <= rst_i ? {res{1'b0}} : (cnt + phase);

endmodule
