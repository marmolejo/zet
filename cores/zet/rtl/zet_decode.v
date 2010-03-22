/*
 *  Instruction decoder for Zet
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

module zet_decode (
    input clk,
    input rst,
    input [7:0] opcode,
    input [7:0] modrm,
    input       rep,
    input block,
    input exec_st,
    input div_exc,
    input ld_base,
    input div,

    output need_modrm,
    output need_off,
    output need_imm,
    output off_size,
    output imm_size,

    input  [2:0] sop_l,

    input        intr,
    input        ifl,
    output reg   inta,
    output reg   ext_int,

    // to microcode
    output [`MICRO_ADDR_WIDTH-1:0] seq_addr,
    output [3:0] src,
    output [3:0] dst,
    output [3:0] base,
    output [3:0] index,
    output [1:0] seg,
    output [2:0] f,

    // from microcode
    input  end_seq
  );

  // Net declarations
  wire [`MICRO_ADDR_WIDTH-1:0] base_addr;
  reg  [`MICRO_ADDR_WIDTH-1:0] seq;
  reg  dive;
  reg  old_ext_int;

  reg [4:0] div_cnt;

  // Module instantiations
  zet_opcode_deco opcode_deco (opcode, modrm, rep, sop_l, base_addr, need_modrm,
                             need_off, need_imm, off_size, imm_size, src, dst,
                             base, index, seg);

  // Assignments
  assign seq_addr = (dive ? `INTD
    : (ext_int ? (rep ? `EINTP : `EINT) : base_addr)) + seq;

  assign f = opcode[7] ? modrm[5:3] : opcode[5:3];

  // Behaviour
  // seq
  always @(posedge clk)
    seq <= rst ? `MICRO_ADDR_WIDTH'd0
         : block ? seq
         : end_seq ? `MICRO_ADDR_WIDTH'd0
         : |div_cnt ? seq
         : exec_st ? (seq + `MICRO_ADDR_WIDTH'd1) : `MICRO_ADDR_WIDTH'd0;

  // div_cnt - divisor counter
  always @(posedge clk)
    div_cnt <= rst ? 5'd0
       : ((div & exec_st) ? (div_cnt==5'd0 ? 5'd18 : div_cnt - 5'd1) : 5'd0);

  // dive
  always @(posedge clk)
    if (rst) dive <= 1'b0;
    else dive <= block ? dive
     : (div_exc ? 1'b1 : (dive ? !end_seq : 1'b0));

  // ext_int
  always @(posedge clk)
    if (rst) ext_int <= 1'b0;
    else ext_int <= block ? ext_int
      : ((intr & ifl & exec_st & end_seq) ? 1'b1
        : (ext_int ? !end_seq : 1'b0));

  // old_ext_int
  always @(posedge clk) old_ext_int <= rst ? 1'b0 : ext_int;

  // inta
  always @(posedge clk)
    inta <= rst ? 1'b0 : (!old_ext_int & ext_int);

endmodule
