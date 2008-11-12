/*
 *  Copyright (c) 2008  Zeus Gomez Marmolejo <zeus@opencores.org>
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

module flash_cntrl (
    // Wishbone slave interface
    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output     [15:0] wb_dat_o,
    input      [17:1] wb_adr_i,
    input             wb_we_i,
    input             wb_tga_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    output reg        wb_ack_o,

    // Pad signals
    output reg [20:0] flash_addr_,
    input      [15:0] flash_data_,
    output            flash_we_n_,
    output reg        flash_ce2_
  );

  // Registers and nets
  reg  [11:0] base;
  wire        op;
  wire        opbase;

  // Continuous assignments
  assign wb_dat_o    = flash_data_;
  assign flash_we_n_ = 1'b1;
  assign op          = wb_cyc_i & wb_stb_i;
  assign opbase      = op & wb_tga_i & wb_we_i;

  // Behaviour
  // flash_addr, 21 bits
  always @(posedge wb_clk_i)
    flash_addr_ <= wb_tga_i ? { 1'b1, base, wb_adr_i[8:1] }
                            : { 5'h0, wb_adr_i[17],
                                      wb_adr_i[15:1] };

  always @(posedge wb_clk_i) flash_ce2_ <= op;
  always @(posedge wb_clk_i) wb_ack_o   <= op;

  // base
  always @(posedge wb_clk_i)
    base <= wb_rst_i ? 12'h0: ((opbase) ? wb_dat_i[11:0] : base);
endmodule
