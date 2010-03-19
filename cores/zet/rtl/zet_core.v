/*
 *  Zet processor core
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

`include "defines.v"

module zet_core (
    output [19:0] pc, // for debugging purposes

    input clk,
    input rst,

    // interrupts
    input  intr,
    output inta,

    // interface to wishbone
    output [19:0] cpu_adr_o,
    input  [15:0] iid_dat_i,
    input  [15:0] cpu_dat_i,
    output [15:0] cpu_dat_o,
    output        cpu_byte_o,
    input         cpu_block,
    output        cpu_mem_op,
    output        cpu_m_io,
    output        cpu_we_o
  );

  // Net declarations
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off;
  wire [15:0] imm;
  wire        wr_ip0;

  wire [15:0] cs;
  wire [15:0] ip;
  wire        of;
  wire        zf;
  wire        ifl;
  wire        cx_zero;
  wire        div_exc;

  wire        fetch_or_exec;
  wire [19:0] addr_exec;
  wire        byte_fetch;
  wire        byte_exec;

  // Module instantiations
  zet_fetch fetch (
    .clk  (clk),
    .rst  (rst),

    // to exec
    .ir     (ir),
    .off    (off),
    .imm    (imm),
    .wr_ip0 (wr_ip0),

    // from exec
    .cs      (cs),
    .ip      (ip),
    .of      (of),
    .zf      (zf),
    .ifl     (ifl),
    .cx_zero (cx_zero),
    .div_exc (div_exc),

    // to wb
    .data          (cpu_dat_i),
    .pc            (pc),
    .bytefetch     (byte_fetch),
    .fetch_or_exec (fetch_or_exec),
    .block         (cpu_block),
    .intr          (intr),
    .inta          (inta)
  );

  zet_exec exec (
    .clk     (clk),
    .rst     (rst),

    // from fetch
    .ir      (ir),
    .off     (off),
    .imm     (imm),
    .wrip0   (wr_ip0),

    // to fetch
    .cs      (cs),
    .ip      (ip),
    .of      (of),
    .zf      (zf),
    .ifl     (ifl),
    .cx_zero (cx_zero),
    .div_exc (div_exc),

    // from wb
    .memout  (iid_dat_i),
    .wr_data (cpu_dat_o),
    .addr    (addr_exec),
    .we      (cpu_we_o),
    .m_io    (cpu_m_io),
    .byteop  (byte_exec),
    .block   (cpu_block)
  );

  // Assignments
  assign cpu_adr_o  = fetch_or_exec ? addr_exec : pc;
  assign cpu_byte_o = fetch_or_exec ? byte_exec : byte_fetch;
  assign cpu_mem_op = ir[`MEM_OP];

endmodule
