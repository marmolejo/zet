/*
 *  Wishbone Compatible BIOS ROM core using megafunction ROM
 *  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
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

// The following is to get rid of the warning about not initializing the ROM
// altera message_off 10030

module bootrom (
    input clk,
    input rst,

    // Wishbone slave interface
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [19:1] wb_adr_i,
    input         wb_we_i,
    input         wb_tga_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    input  [ 1:0] wb_sel_i,
    output        wb_ack_o
  );

  // Net declarations
  reg  [15:0] rom[0:127];  // Instantiate the ROM

  wire [ 6:0] rom_addr;
  wire        stb;

  // Combinatorial logic
  assign rom_addr = wb_adr_i[7:1];
  assign stb      = wb_stb_i & wb_cyc_i;
  assign wb_ack_o = stb;
  assign wb_dat_o = rom[rom_addr];

  initial $readmemh("bootrom.dat", rom);

endmodule
