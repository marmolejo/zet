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

module exec (
    // IO Ports
`ifdef DEBUG
    output [15:0] x,
    output [15:0] y,
`endif
    input [`IR_SIZE-1:0] ir,
    input [15:0]  off,
    input [15:0]  imm,
    output [15:0] cs,
    output [15:0] ip,
    output        of,
    output        zf,
    output        cx_zero,
    input         clk,
    input         rst,
    input [15:0]  memout,

    output [15:0] wr_data,
    output [19:0] addr,
    output        we,
    output        m_io,
    output        byteop,
    input         mem_rdy
  );

  // Net declarations
  wire [15:0] a, b, c, s, alu_iflags, omemalu, bus_b;
  wire [31:0] aluout;
  wire [3:0]  addr_a, addr_b, addr_c, addr_d;
  wire [2:0]  t, func;
  wire [1:0]  addr_s;
  wire        wrfl, high, memalu, a_byte, c_byte;
  wire        wr, wr_reg, block;
  wire        wr_cnd;
  wire        jmp;
  wire        mem_op, b_imm;
  wire  [8:0] flags, iflags, oflags;
  wire  [4:0] logic_flags;

  // Module instances
  alu     alu0( {c, a }, bus_b, aluout, t, func, alu_iflags, oflags, 
               ~byteop, s, off);
  regfile reg0( a, b, c, cs, ip, {aluout[31:16], omemalu}, s, flags, wr_reg, wrfl,
                high, clk, rst, addr_a, addr_b, addr_c, addr_d, addr_s, iflags,
                ~byteop, a_byte, c_byte, cx_zero);
  jmp_cond jc0( logic_flags, addr_b, addr_c[0], c, jmp);

  // Assignments
  assign addr_s = ir[1:0];
  assign addr_a = ir[5:2];
  assign addr_b = ir[9:6];
  assign addr_c = ir[13:10];
  assign addr_d = ir[17:14];
  assign wrfl   = ir[18];
  assign we     = ir[19];
  assign wr     = ir[20];
  assign wr_cnd = ir[21]; 
  assign high   = ir[22];
  assign t      = ir[25:23];
  assign func   = ir[28:26];
  assign byteop = ir[29];
  assign memalu = ir[30];
  assign mem_op = ir[31];
  assign m_io   = ir[32];
  assign b_imm  = ir[33];
  assign a_byte = ir[34];
  assign c_byte = ir[35];

  assign omemalu = memalu ? aluout[15:0] : memout;
  assign bus_b   = b_imm ? imm : b;

  assign addr = aluout[19:0];
  assign wr_data = c;
  assign wr_reg = (wr | (jmp & wr_cnd)) && !block;
  assign of = flags[8];
  assign zf = flags[3];
  assign block = mem_op && !mem_rdy;

  assign iflags = oflags;
  assign alu_iflags = { 4'b0, flags[8:3], 1'b0, flags[2], 1'b0, flags[1], 
                        1'b1, flags[0] };
  assign logic_flags = { flags[8], flags[4], flags[3], flags[1], flags[0] };
`ifdef DEBUG
  assign x        = a;
  assign y        = bus_b;
`endif
endmodule
