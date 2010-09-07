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
    output        cpu_we_o,

    output [19:0] pc  // for debugging purposes
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

  wire [19:0] addr_exec;
  wire        byte_fetch;
  wire        byte_exec;

  // wire decode - microcode
  wire [`MICRO_ADDR_WIDTH-1:0] seq_addr;
  wire [3:0] src;
  wire [3:0] dst;
  wire [3:0] base;
  wire [3:0] index;
  wire [1:0] seg;
  wire       end_seq;
  wire [2:0] fdec;
  wire       div;

  // wires fetch - decode
  wire [7:0] opcode;
  wire [7:0] modrm;
  wire       rep;
  wire       exec_st;
  wire       ld_base;
  wire [2:0] sop_l;

  wire need_modrm;
  wire need_off;
  wire need_imm;
  wire off_size;
  wire imm_size;
  wire ext_int;

  // wires fetch - microcode
  wire [15:0] off_l;
  wire [15:0] imm_l;
  wire [15:0] imm_d;
  wire [`IR_SIZE-1:0] rom_ir;
  wire [5:0] ftype;

  // wires fetch - exec
  wire [15:0] imm_f;

  // wires and regs for hlt
  wire block_or_hlt;
  wire hlt_op;
  wire hlt_in;
  wire hlt_out;

  reg hlt_op_old;
  reg hlt;

  // Module instantiations
  zet_fetch fetch (
    .clk  (clk),
    .rst  (rst),

    // to decode
    .opcode  (opcode),
    .modrm   (modrm),
    .rep     (rep),
    .exec_st (exec_st),
    .ld_base (ld_base),
    .sop_l   (sop_l),

    // from decode
    .need_modrm (need_modrm),
    .need_off   (need_off),
    .need_imm   (need_imm),
    .off_size   (off_size),
    .imm_size   (imm_size),
    .ext_int    (ext_int),
    .end_seq    (end_seq),

    // to microcode
    .off_l (off_l),
    .imm_l (imm_l),

    // from microcode
    .ftype (ftype),

    // to exec
    .imm_f  (imm_f),
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
    .block         (block_or_hlt),
    .intr          (intr)
  );

  zet_decode decode (
    .clk (clk),
    .rst (rst),

    .opcode  (opcode),
    .modrm   (modrm),
    .rep     (rep),
    .block   (block_or_hlt),
    .exec_st (exec_st),
    .div_exc (div_exc),
    .ld_base (ld_base),
    .div     (div),

    .need_modrm (need_modrm),
    .need_off   (need_off),
    .need_imm   (need_imm),
    .off_size   (off_size),
    .imm_size   (imm_size),

    .sop_l   (sop_l),
    .intr    (intr),
    .ifl     (ifl),
    .inta    (inta),
    .ext_int (ext_int),

    .seq_addr (seq_addr),
    .src      (src),
    .dst      (dst),
    .base     (base),
    .index    (index),
    .seg      (seg),
    .f        (fdec),

    .end_seq  (end_seq)
  );

  zet_micro_data micro_data (
    // from decode
    .n_micro (seq_addr),
    .off_i   (off_l),
    .imm_i   (imm_l),
    .src     (src),
    .dst     (dst),
    .base    (base),
    .index   (index),
    .seg     (seg),
    .fdec    (fdec),
    .div     (div),
    .end_seq (end_seq),

    // to exec
    .ir    (rom_ir),
    .off_o (off),
    .imm_o (imm_d)
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
    .block   (block_or_hlt)
  );

  // Assignments
  assign cpu_adr_o  = exec_st ? addr_exec : pc;
  assign cpu_byte_o = exec_st ? byte_exec : byte_fetch;
  assign cpu_mem_op = ir[`MEM_OP];

  assign ir    = exec_st ? rom_ir : `ADD_IP;
  assign imm   = exec_st ? imm_d  : imm_f;
  assign ftype = rom_ir[28:23];

  assign hlt_op = ((opcode == `OP_HLT) && exec_st); 
  assign hlt_in = (hlt_op && !hlt_op_old && !hlt_out);
  assign hlt_out = intr & ifl;
  assign block_or_hlt = cpu_block | hlt | hlt_in;

  // Behaviour
  always @(posedge clk)
    if (rst)
      hlt_op_old <= 1'b0;
    else
      if (hlt_op)
        hlt_op_old <= 1'b1;
      else
        hlt_op_old <= 1'b0;

  always @(posedge clk)
    if (rst)
      hlt <= 1'b0;
    else
      if (hlt_in)
        hlt <= 1'b1;
      else if (hlt_out)
        hlt <= 1'b0;

endmodule
