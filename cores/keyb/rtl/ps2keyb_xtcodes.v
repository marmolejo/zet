/*
 *  PS2 Wishbone 8042 compatible keyboard controller
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  adapted from the opencores keyboard controller from John Clayton
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

module ps2keyb_xtcodes (
  //  input            clk,
    input      [6:0] at_code,
    output     [6:0] xt_code
  );

  // Registers, nets and parameters
  reg [7:0] rom[0:2**7-1];

  assign xt_code = rom[at_code][6:0];

  // Behaviour
/*
  always @(posedge clk)
    xt_code <= rom[at_code][6:0];
*/
  initial $readmemh("xt_codes.dat", rom);
endmodule
