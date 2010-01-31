/*
 *  Character ROM for text mode fonts
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

// altera message_off 10030
//  get rid of the warning about
//  not initializing the ROM
module char_rom (
    input             clk,
    input      [11:0] addr,
    output reg [ 7:0] q
  );

  // Registers, nets and parameters
  reg [7:0] rom[0:4095];

  // Behaviour
  always @(posedge clk) q <= rom[addr];

  initial $readmemh("char_rom.dat", rom);
endmodule
