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
    input         ack_i,
    output [15:0] cs,
    output [15:0] ip
  );

  // Net declarations
  // wire [15:0] cs, ip;
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off, imm;
  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, byte_exec, fetch_or_exec;
  wire of, zf, cx_zero;

  // Module instantiations
  fetch   fetch0(clk_i, rst_i, cs, ip, of, zf, cx_zero, dat_i, ir, off, 
                 imm, addr_fetch, byte_fetch, fetch_or_exec, ack_i);
  exec    exec0(ir, off, imm, cs, ip, of, zf, cx_zero, clk_i, rst_i, 
                dat_i, dat_o, addr_exec, we_o, mio_o, byte_exec, ack_i);

  // Assignments 
  assign adr_o   = fetch_or_exec ? addr_exec : addr_fetch;
  assign byte_o = fetch_or_exec ? byte_exec : byte_fetch;
  assign stb_o = rst_i ? 1'b1 : ir[`MEM_OP];
endmodule
