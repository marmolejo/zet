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

    // Wishbone signals
    input         clk_i,
    input         rst_i,
    input  [15:0] dat_i,
    output [15:0] dat_o,
    output [19:0] adr_o,
    output        we_o,
    output        mio_o,
    output        byte_o,
    output        stb_o,
    input         ack_i
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
  wire inopco_st;

  // Module instantiations
  fetch fetch0 (
`ifdef DEBUG
    .state      (state),
    .next_state (next_state),
`endif
    .clk  (clk_i),
    .rst  (rst_i),
    .cs   (cs),
    .ip   (ip),
    .of   (of),
    .zf   (zf),
    .data (dat_i),
    .ir   (ir),
    .off  (off),
    .imm  (imm),
    .pc   (addr_fetch),

    .cx_zero       (cx_zero),
    .bytefetch     (byte_fetch),
    .fetch_or_exec (fetch_or_exec),
    .mem_rdy       (ack_i),
    .div_exc       (div_exc),
    .inopco_st     (inopco_st)
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
    .clk     (clk_i),
    .rst     (rst_i),
    .memout  (dat_i),
    .wr_data (dat_o),
    .addr    (addr_exec),
    .we      (we_o),
    .m_io    (mio_o),
    .byteop  (byte_exec),
    .mem_rdy (ack_i),
    .div_exc (div_exc),
    .wrip0   (inopco_st)
  );

  // Assignments
  assign adr_o  = fetch_or_exec ? addr_exec : addr_fetch;
  assign byte_o = fetch_or_exec ? byte_exec : byte_fetch;
  assign stb_o  = rst_i ? 1'b1 : ir[`MEM_OP];

`ifdef DEBUG
  assign iralu = ir[28:23];
`endif
endmodule
