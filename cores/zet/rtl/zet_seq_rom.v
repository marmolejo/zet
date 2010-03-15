/*
 *  Sequencer ROM for Zet
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

`include "defines.v"

module zet_seq_rom (
    input [`SEQ_ADDR_WIDTH-1:0] addr,
    output [`SEQ_DATA_WIDTH-1:0] q
  );

  // Registers, nets and parameters
  reg [`SEQ_DATA_WIDTH-1:0] rom[0:2**`SEQ_ADDR_WIDTH-1];

  // Assignments
  assign q = rom[addr];

  // Behaviour
  initial $readmemb("seq_rom.dat", rom);
endmodule
