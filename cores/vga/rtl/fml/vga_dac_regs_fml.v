/*
 *  DAC register file for VGA
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

module vga_dac_regs_fml (
    input clk,

    // VGA read interface
    input      [7:0] index,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue,

    // CPU interface
    input       write,

    // CPU read interface
    input      [1:0] read_data_cycle,
    input      [7:0] read_data_register,
    output reg [3:0] read_data,

    // CPU write interface
    input [1:0] write_data_cycle,
    input [7:0] write_data_register,
    input [3:0] write_data
  );

  // Registers, nets and parameters
  reg [3:0] red_dac   [0:255];
  reg [3:0] green_dac [0:255];
  reg [3:0] blue_dac  [0:255];

  // Behaviour
  // VGA read interface
  always @(posedge clk)
    begin
      red   <= red_dac[index];
      green <= green_dac[index];
      blue  <= blue_dac[index];
    end

  // CPU read interface
  always @(posedge clk)
    case (read_data_cycle)
      2'b00:   read_data <= red_dac[read_data_register];
      2'b01:   read_data <= green_dac[read_data_register];
      2'b10:   read_data <= blue_dac[read_data_register];
      default: read_data <= 4'h0;
    endcase

  // CPU write interface
  always @(posedge clk)
    if (write)
      case (write_data_cycle)
        2'b00:   red_dac[write_data_register]   <= write_data;
        2'b01:   green_dac[write_data_register] <= write_data;
        2'b10:   blue_dac[write_data_register]  <= write_data;
      endcase

endmodule
