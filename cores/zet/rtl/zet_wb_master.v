/*
 *  Wishbone master interface module for Zet
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

module zet_wb_master (
    input             cpu_byte_o,
    input             cpu_memop,
    input             cpu_m_io,
    input      [19:0] cpu_adr_o,
    output reg        cpu_block,
    output reg [15:0] cpu_dat_i,
    input      [15:0] cpu_dat_o,
    input             cpu_we_o,

    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    output reg [19:1] wb_adr_o,
    output            wb_we_o,
    output            wb_tga_o,
    output reg [ 1:0] wb_sel_o,
    output reg        wb_stb_o,
    output            wb_cyc_o,
    input             wb_ack_i
  );

  // Register and nets declarations
  reg  [ 1:0] cs; // current state
  reg  [ 1:0] ns; // next state
  reg  [19:1] adr1; // next address (for unaligned acc)

  wire        op; // in an operation
  wire        odd_word; // unaligned word
  wire        a0;  // address 0 pin
  wire [15:0] blw; // low byte (sign extended)
  wire [15:0] bhw; // high byte (sign extended)
  wire [ 1:0] sel_o; // bus byte select

  // Declare the symbolic names for states
  localparam [1:0]
    IDLE    = 2'd0,
    stb1_hi = 2'd1,
    stb2_hi = 2'd2,
    bloc_lo = 2'd3;

  // Assignments
  assign op        = (cpu_memop | cpu_m_io);
  assign odd_word  = (cpu_adr_o[0] & !cpu_byte_o);
  assign a0        = cpu_adr_o[0];
  assign blw       = { {8{wb_dat_i[7]}}, wb_dat_i[7:0] };
  assign bhw       = { {8{wb_dat_i[15]}}, wb_dat_i[15:8] };
  assign wb_we_o   = cpu_we_o;
  assign wb_tga_o  = cpu_m_io;
  assign sel_o     = a0 ? 2'b10 : (cpu_byte_o ? 2'b01 : 2'b11);
  assign wb_cyc_o  = wb_stb_o;

  // Behaviour
  // cpu_dat_i
  always @(posedge wb_clk_i)
    cpu_dat_i <= cpu_we_o ? cpu_dat_i : ((cs == stb1_hi) ?
                   (wb_ack_i ?
                     (a0 ? bhw : (cpu_byte_o ? blw : wb_dat_i))
                   : cpu_dat_i)
                 : ((cs == stb2_hi && wb_ack_i) ?
                     { wb_dat_i[7:0], cpu_dat_i[7:0] }
                   : cpu_dat_i));

  // adr1
  always @(posedge wb_clk_i)
    adr1 <= cpu_adr_o[19:1] + 1'b1;

  // wb_adr_o
  always @(posedge wb_clk_i)
    wb_adr_o <= (ns==stb2_hi) ? adr1 : cpu_adr_o[19:1];

  // wb_sel_o
  always @(posedge wb_clk_i)
    wb_sel_o <= (ns==stb1_hi) ? sel_o : 2'b01;

  // wb_stb_o
  always @(posedge wb_clk_i)
    wb_stb_o <= (ns==stb1_hi || ns==stb2_hi);

  // wb_dat_o
  always @(posedge wb_clk_i)
    wb_dat_o <= a0 ? { cpu_dat_o[7:0], cpu_dat_o[15:8] }
                       : cpu_dat_o;

  // cpu_block
  always @(*)
    case (cs)
      IDLE:    cpu_block <= op;
      default: cpu_block <= 1'b1;
      bloc_lo: cpu_block <= wb_ack_i;
    endcase

  // state machine
  // cs - current state
  always @(posedge wb_clk_i)
    cs <= wb_rst_i ? IDLE : ns;

  // ns - next state
  always @(*)
    case (cs)
      default: ns <= wb_ack_i ? IDLE : (op ? stb1_hi : IDLE);
      stb1_hi: ns <= wb_ack_i ? (odd_word ? stb2_hi : bloc_lo) : stb1_hi;
      stb2_hi: ns <= wb_ack_i ? bloc_lo : stb2_hi;
      bloc_lo: ns <= wb_ack_i ? bloc_lo : IDLE;
    endcase

endmodule
