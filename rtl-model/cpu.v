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

`timescale 1ns/10ps

`include "defines.v"

module cpu (
`ifdef DEBUG
    output [15:0] cs,
    output [15:0] ip,
    output [ 2:0] state,
    output [ 2:0] next_state,
    output [ 5:0] iralu,
    output [15:0] x,
    output [15:0] y,
    output [15:0] imm,
    output [15:0] aluo,
`endif

    // Wishbone master interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output [19:1] wb_adr_o,
    output        wb_we_o,
    output        wb_tga_o,
    output [ 1:0] wb_sel_o,
    output        wb_stb_o,
    output        wb_cyc_o,
    input         wb_ack_i
  );

  // Net declarations
`ifndef DEBUG
  wire [15:0] cs, ip;
  wire [15:0] imm;
`endif
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off;

  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, byte_exec, fetch_or_exec;
  wire of, zf, cx_zero;
  wire div_exc;
  wire wr_ip0;

  wire        cpu_byte_o;
  wire        cpu_m_io;
  wire [19:0] cpu_adr_o;
  wire        cpu_block;
  wire [15:0] cpu_dat_i;
  wire [15:0] cpu_dat_o;
  wire        cpu_we_o;

  // Module instantiations
  fetch fetch0 (
`ifdef DEBUG
    .state      (state),
    .next_state (next_state),
`endif
    .clk  (wb_clk_i),
    .rst  (wb_rst_i),
    .cs   (cs),
    .ip   (ip),
    .of   (of),
    .zf   (zf),
    .data (cpu_dat_i),
    .ir   (ir),
    .off  (off),
    .imm  (imm),
    .pc   (addr_fetch),

    .cx_zero       (cx_zero),
    .bytefetch     (byte_fetch),
    .fetch_or_exec (fetch_or_exec),
    .block         (cpu_block),
    .div_exc       (div_exc),

    .wr_ip0 (wr_ip0)
  );

  exec exec0 (
`ifdef DEBUG
    .x    (x),
    .y    (y),
    .aluo (aluo),
`endif
    .ir      (ir),
    .off     (off),
    .imm     (imm),
    .cs      (cs),
    .ip      (ip),
    .of      (of),
    .zf      (zf),
    .cx_zero (cx_zero),
    .clk     (wb_clk_i),
    .rst     (wb_rst_i),
    .memout  (cpu_dat_i),
    .wr_data (cpu_dat_o),
    .addr    (addr_exec),
    .we      (cpu_we_o),
    .m_io    (cpu_m_io),
    .byteop  (byte_exec),
    .block   (cpu_block),
    .div_exc (div_exc),
    .wrip0   (wr_ip0)
  );

  wb_master wm0 (
    .cpu_byte_o (cpu_byte_o),
    .cpu_memop  (ir[`MEM_OP]),
    .cpu_m_io   (cpu_m_io),
    .cpu_adr_o  (cpu_adr_o),
    .cpu_block  (cpu_block),
    .cpu_dat_i  (cpu_dat_i),
    .cpu_dat_o  (cpu_dat_o),
    .cpu_we_o   (cpu_we_o),

    .wb_clk_i  (wb_clk_i),
    .wb_rst_i  (wb_rst_i),
    .wb_dat_i  (wb_dat_i),
    .wb_dat_o  (wb_dat_o),
    .wb_adr_o  (wb_adr_o),
    .wb_we_o   (wb_we_o),
    .wb_tga_o  (wb_tga_o),
    .wb_sel_o  (wb_sel_o),
    .wb_stb_o  (wb_stb_o),
    .wb_cyc_o  (wb_cyc_o),
    .wb_ack_i  (wb_ack_i)
  );

  // Assignments
  assign cpu_adr_o  = fetch_or_exec ? addr_exec : addr_fetch;
  assign cpu_byte_o = fetch_or_exec ? byte_exec : byte_fetch;

`ifdef DEBUG
  assign iralu = ir[28:23];
`endif
endmodule

module wb_master (
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
    output     [15:0] wb_dat_o,
    output reg [19:1] wb_adr_o,
    output            wb_we_o,
    output            wb_tga_o,
    output reg [ 1:0] wb_sel_o,
    output reg        wb_stb_o,
    output reg        wb_cyc_o,
    input             wb_ack_i
  );

  // Register and nets declarations
  reg  [ 1:0] cs; // current state

  wire        op; // in an operation
  wire        odd_word; // unaligned word
  wire        a0;  // address 0 pin
  wire [15:0] blw; // low byte (sign extended)
  wire [15:0] bhw; // high byte (sign extended)
  wire [19:1] adr1; // next address (for unaligned acc)
  wire [ 1:0] sel_o; // bus byte select

  // Declare the symbolic names for states
  parameter [1:0]
    cyc0_lo = 3'd0,
    stb1_hi = 3'd1,
    stb1_lo = 3'd2,
    stb2_hi = 3'd3;

  // Assignments
  assign op       = (cpu_memop | cpu_m_io);
  assign odd_word = (cpu_adr_o[0] & !cpu_byte_o);
  assign a0       = cpu_adr_o[0];
  assign blw      = { {8{wb_dat_i[7]}}, wb_dat_i[7:0] };
  assign bhw      = { {8{wb_dat_i[15]}}, wb_dat_i[15:8] };
  assign adr1     = a0 ? (cpu_adr_o[19:1] + 1'b1)
                       : cpu_adr_o[19:1];
  assign wb_dat_o = a0 ? { cpu_dat_o[7:0], cpu_dat_o[15:8] }
                       : cpu_dat_o;
  assign wb_we_o  = cpu_we_o;
  assign wb_tga_o = cpu_m_io;
  assign sel_o    = a0 ? 2'b10 : (cpu_byte_o ? 2'b01 : 2'b11);

  // Behaviour
  // cpu_dat_i
  always @(posedge wb_clk_i)
    cpu_dat_i <= (cs == cyc0_lo) ?
                   (wb_ack_i ?
                     (a0 ? bhw : (cpu_byte_o ? blw : wb_dat_i))
                   : cpu_dat_i)
                 : ((cs == stb1_lo && wb_ack_i) ?
                     { wb_dat_i[7:0], cpu_dat_i[7:0] }
                   : cpu_dat_i);

  // outputs setup
  always @(*)
    case (cs)
      default:
        begin
          cpu_block <= op;
          wb_adr_o  <= cpu_adr_o[19:1];
          wb_sel_o  <= sel_o;
          wb_stb_o  <= op;
          wb_cyc_o  <= op;
        end
      stb1_hi:
        begin
          cpu_block <= odd_word | wb_ack_i;
          wb_adr_o  <= cpu_adr_o[19:1];
          wb_sel_o  <= sel_o;
          wb_stb_o  <= 1'b0;
          wb_cyc_o  <= odd_word;
        end
      stb1_lo:
        begin
          cpu_block <= 1'b1;
          wb_adr_o  <= adr1;
          wb_sel_o  <= 2'b01;
          wb_stb_o  <= 1'b1;
          wb_cyc_o  <= 1'b1;
        end
      stb2_hi:
        begin
          cpu_block <= wb_ack_i;
          wb_adr_o  <= adr1;
          wb_sel_o  <= 2'b01;
          wb_stb_o  <= 1'b0;
          wb_cyc_o  <= 1'b0;
        end
    endcase

  // state machine
  always @(posedge wb_clk_i)
    if (wb_rst_i) cs <= cyc0_lo;
    else
      case (cs)
        default:  cs <= wb_ack_i ? (op ? stb1_hi : cyc0_lo)
                                 : cyc0_lo;
        stb1_hi:  cs <= wb_ack_i ? stb1_hi
                                 : (odd_word ? stb1_lo : cyc0_lo);
        stb1_lo:  cs <= wb_ack_i ? stb2_hi : stb1_lo;
        stb2_hi:  cs <= wb_ack_i ? stb2_hi : cyc0_lo;
      endcase

endmodule
