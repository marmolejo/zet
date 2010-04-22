/*
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

module flash (
    // Wishbone slave interface
    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    input      [16:1] wb_adr_i,
    input             wb_we_i,
    input             wb_tga_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    input      [ 1:0] wb_sel_i,
    output reg        wb_ack_o,

    // Pad signals
    output reg [21:0] flash_addr_,
    input      [ 7:0] flash_data_,
    output            flash_we_n_,
    output reg        flash_oe_n_,
    output reg        flash_ce_n_,
    output            flash_rst_n_
  );

  // Registers and nets
  wire        op;
  wire        opbase;
  wire        word;
  wire        op_word;
  wire   
  reg  [ 2:0] st;
  reg  [ 7:0] lb;
  reg  [11:0] base;

  // Continuous assignments
  assign op      = wb_stb_i & wb_cyc_i;
  assign opbase  = op & wb_tga_i & wb_we_i;
  assign word    = wb_sel_i==2'b11;
  assign op_word = op & word;

  assign flash_rst_n_ = 1'b1;
  assign flash_we_n_  = 1'b1;

  assign flash_addr_[21:1] =
    wb_tga_i ? { 1'b1, base, wb_adr_i[8:1] }
             : { 5'h0, wb_adr_i };

  assign flash_addr_[0] = (wb_sel_i==2'b10) | (word & st[1]);

  assign wb_ack_o = op & st[0] & (word ? st[1] : 1'b1);
  assign wb_dat_o = wb_sel_i[1] ? { flash_data_, lb }
                                : { 8'h0, flash_data_ };

  // Behaviour
  // st - state
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 3'd0 : (op & !wb_ack_o ? st + 3'd1 : 3'd0);

  // lb - low byte
  always @(posedge wb_clk_i)
    lb <= wb_rst_i ? 8'h0 : ((op_word & st[0]) ? flash_data_ : 8'h0);

  // base
  always @(posedge wb_clk_i)
    base <= wb_rst_i ? 12'h0: ((opbase) ? wb_dat_i[11:0] : base);

  // flash_oe_n_ and flash_ce_n_
  always @(posedge wb_clk_i)
    if (wb_rst_i)
      begin
        flash_oe_n_ <= 1'b1;
        flash_ce_n_ <= 1'b1;
      end
    else
      begin
        flash_oe_n_ <= !op;
        flash_ce_n_ <= !op;
      end

  // flash_addr_
  always @(posedge wb_clk_i)
    if (wb_rst_i) flash_addr_ <= 22'h0;
    else if (op)
      flash_addr_ <= wb_tga_i ?
        { 1'b1, base, wb_adr_i[8:1] }
             : { 5'h0, wb_adr_i };


endmodule
