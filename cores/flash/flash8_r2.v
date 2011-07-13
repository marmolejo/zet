/*
 *  Wishbone Flash RAM core for Altera DE2 board (90ns registered)
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

module flash8_r2 (
    // Wishbone slave interface
    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    input             wb_we_i,
    input      [19:1] wb_adr_i,
    input      [ 1:0] wb_sel_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    output reg        wb_ack_o,

    // Pad signals
    output reg [22:0] flash_addr_,
    input      [ 7:0] flash_data_,
    output            flash_we_n_,
    output reg        flash_oe_n_,
    output reg        flash_ce_n_,
    output            flash_rst_n_
  );

  // Registers and nets
  wire        op;
  wire        wr_command;
  wire        flash_addr0;
  reg  [21:0] address;

  wire        word;
  wire        op_word;
  reg  [ 3:0] st;
  reg  [ 7:0] lb;

  // Combinatorial logic
  assign op      = wb_stb_i & wb_cyc_i;
  assign word    = wb_sel_i==2'b11;
  assign op_word = op & word & !wb_we_i;

  assign flash_rst_n_ = 1'b1;
  assign flash_we_n_  = 1'b1;

  assign flash_addr0 = (wb_sel_i==2'b10) | (word & |st[2:1]);
  assign wr_command  = op & wb_we_i;  // Wishbone write access Signal

  // Behaviour
  // flash_addr_
  always @(posedge wb_clk_i)
    flash_addr_ <= { address, flash_addr0 };

  // flash_oe_n_
  always @(posedge wb_clk_i)
    flash_oe_n_ <= !(op & !wb_we_i);

  // flash_ce_n_
  always @(posedge wb_clk_i)
    flash_ce_n_ <= !(op & !wb_we_i);

  // wb_dat_o
  always @(posedge wb_clk_i)
    wb_dat_o <= wb_rst_i ? 16'h0
      : (st[2] ? (wb_sel_i[1] ? { flash_data_, lb }
                              : { 8'h0, flash_data_ })
               : wb_dat_o);

  // wb_ack_o
  always @(posedge wb_clk_i)
    wb_ack_o <= wb_rst_i ? 1'b0
      : (wb_ack_o ? 1'b0 : (op & (wb_we_i ? 1'b1 : st[2])));

  // st - state
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 4'h0
      : (op & st==4'h0 ? (word ? 4'b0001 : 4'b0100)
                         : { st[2:0], 1'b0 });

  // lb - low byte
  always @(posedge wb_clk_i)
    lb <= wb_rst_i ? 8'h0 : (op_word & st[1] ? flash_data_ : 8'h0);

  // --------------------------------------------------------------------
  // Register addresses and defaults
  // --------------------------------------------------------------------
  `define FLASH_ALO   1'h0    // Lower 16 bits of address lines
  `define FLASH_AHI   1'h1    // Upper  6 bits of address lines
  always @(posedge wb_clk_i)  // Synchrounous
    if(wb_rst_i)
      address <= 22'h000000;  // Interupt Enable default
    else
      if(wr_command)          // If a write was requested
        case(wb_adr_i[1])     // Determine which register was writen to
            `FLASH_ALO: address[15: 0] <= wb_dat_i;
            `FLASH_AHI: address[21:16] <= wb_dat_i[5:0];
            default:    ;     // Default
        endcase               // End of case

endmodule
