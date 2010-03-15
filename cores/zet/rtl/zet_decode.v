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
`ifdef DEBUG
    output [`SEQ_DATA_WIDTH-2:0] micro_addr,
`endif
    input [7:0] opcode,
    input [7:0] modrm,
    input [15:0] off_i,
    input [15:0] imm_i,
    input       rep,
    input clk,
    input rst,
    input block,
    input exec_st,
    input div_exc,

    output need_modrm,
    output need_off,
    output need_imm,
    output off_size,
    output imm_size,

    output [`IR_SIZE-1:0] ir,
    output [15:0] off_o,
    output [15:0] imm_o,
    input  ld_base,
    output end_seq,

    input  [2:0] sop_l,

    input        intr,
    input        ifl,
    output reg   inta,
    output reg   ext_int,
    input        repz_pr
  );

  // Net declarations
`ifndef DEBUG
  wire [`SEQ_DATA_WIDTH-2:0] micro_addr;
`endif
  wire [`SEQ_ADDR_WIDTH-1:0] base_addr, seq_addr;
  wire [3:0] src, dst, base, index;
  wire [1:0] seg;
  reg  [`SEQ_ADDR_WIDTH-1:0] seq;
  reg  dive;
  reg  old_ext_int;
//  reg  [`SEQ_ADDR_WIDTH-1:0] base_l;

  // Module instantiations
  zet_opcode_deco opcode_deco (opcode, modrm, rep, sop_l, base_addr, need_modrm,
                             need_off, need_imm, off_size, imm_size, src, dst,
                             base, index, seg);
  zet_seq_rom seq_rom  (seq_addr, {end_seq, micro_addr});
  zet_micro_data micro_data (micro_addr, off_i, imm_i, src, dst, base, index, seg,
                        ir, off_o, imm_o);

  // Assignments
  assign seq_addr = (dive ? `INTD
    : (ext_int ? (repz_pr ? `EINTP : `EINT) : base_addr)) + seq;

  // Behaviour
  // seq
  always @(posedge clk)
    if (rst) seq <= `SEQ_ADDR_WIDTH'd0;
    else if (!block)
      seq <= (exec_st && !end_seq && !rst) ? (seq + `SEQ_ADDR_WIDTH'd1)
                                           : `SEQ_ADDR_WIDTH'd0;

/* In Altera Quartus II, this latch doesn't work properly
  // base_l
  always @(posedge clk)
    base_l <= rst ? `NOP : (ld_base ? base_addr : base_l);
*/
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
