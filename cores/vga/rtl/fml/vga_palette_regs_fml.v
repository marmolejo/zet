/*
 *  Palette register file for VGA
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 *  VGA FML support
 *  Copyright (C) 2013 Charley Picker <charleypicker@yahoo.com>
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

module vga_palette_regs_fml (
    input clk,

    // VGA read interface
    input      [3:0] attr,
    output reg [7:0] index,

    // CPU interface
    input      [3:0] address,
    input            write,
    output reg [7:0] read_data,
    input      [7:0] write_data
  );

  // Registers
  reg [7:0] palette [0:15];

  // Behaviour
  // VGA read interface
  always @(posedge clk) index <= palette[attr];

  // CPU read interface
  always @(posedge clk) read_data <= palette[address];

  // CPU write interface
  always @(posedge clk)
    if (write) palette[address] <= write_data;

endmodule
