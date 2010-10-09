/*
 *  PS2 Wishbone 8042 compatible keyboard controller synthesis test
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module test_ps2_keyb (
    input        clk_,
    output [8:0] led_,
    inout        ps2_clk_,
    inout        ps2_data_


  );

  // Net declarations
  wire        sys_clk_0;
  wire        lock;
  wire        rst;

  // Module instances
  clock c0 (
    .CLKIN_IN   (clk_),
    .CLKDV_OUT  (sys_clk_0),
    .LOCKED_OUT (lock)
  );

  ps2_keyb #(2950, // number of clks for 60usec.
             12,   // number of bits needed for 60usec. timer
             63,   // number of clks for debounce
             6,    // number of bits needed for debounce timer
             0     // Trap the shift keys, no event generated
            ) keyboard0 (      // Instance name
    .wb_clk_i (sys_clk_0),
    .wb_rst_i (rst),
    .wb_dat_o (led_[7:0]),
    .test     (led_[8]),

    .ps2_clk_  (ps2_clk_),
    .ps2_data_ (ps2_data_)
  );

  // Continuous assignments
  assign rst = !lock;
endmodule
