/*
 *  Internal RAM for VGA
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

module ram_2k (
    input             clk,
    input             rst,
    input             cs,
    input             we,
    input      [10:0] addr,
    output reg [ 7:0] rdata,
    input      [ 7:0] wdata
  );

  // Registers and nets
  reg [7:0] mem[0:2047];

  always @(posedge clk)
    rdata <= rst ? 8'h0 : mem[addr];

  always @(posedge clk)
    if (we && cs) mem[addr] <= wdata;

endmodule
