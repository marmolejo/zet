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

 /*
  *  Phase accumulator clock:
  *   Fo = Fc * N / 2^bits
  *   here N: 154619 and bits: 26
  */

module clk_uart #(
    parameter bits  = 26,    // counter bits
    parameter value = 154619 // phase counter
  ) (
    input  clk_i,
    input  rst_i,
    output clk_o,
    output rst_o
  );

  // Registers
  reg [bits-1:0] cnt;
  reg [     2:0] init;

  // Continuous assignments
  assign clk_o = cnt[bits-1];
  assign rst_o = init[2];

  // Behaviour
  // cnt
  always @(posedge clk_i)
    cnt <= rst_i ? 0 : cnt + value;

  // init[0]
  always @(posedge clk_i)
    init[0] <= rst_i ? 1'b1 : (clk_o ? 1'b0 : init[0]);

  // init[2:1]
  always @(posedge clk_o)
    init[2:1] <= init[0] ? 2'b11 : init[1:0];
endmodule
