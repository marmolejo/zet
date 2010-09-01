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

    // UMI slave interface - fetch
    output [19:0] umif_adr_o,
    input  [15:0] umif_dat_i,
    output        umif_stb_o,
    output        umif_by_o,
    input         umif_ack_i,

    // UMI slave interface - exec
    output [19:0] umie_adr_o,
    input  [15:0] umie_dat_i,
    output [15:0] umie_dat_o,
    output        umie_we_o,
    output        umie_by_o,
    output        umie_stb_o,
    input         umie_ack_i,
    output        umie_tga_o,

    // interrupts
    input        intr,
    output       inta,
    input  [3:0] iid
  );

  // Net declarations
  reg [`IR_SIZE-1:0] ir;
  reg [15:0] off;
  reg [15:0] imm;
  reg        wr_ip0;

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
  wire [2:0] fdec;

  wire       end_seq;
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
  wire [15:0] off_d;
  wire        wr_ip0_f;
  wire [15:0] imm_l;
  wire [15:0] imm_d;
  wire [`IR_SIZE-1:0] rom_ir;
  wire [5:0] ftype;

  // wires fetch - exec
  wire [15:0] imm_f;

  // wires control - fetch
  wire stall_f;

  reg [`MICRO_ADDR_WIDTH-1:0] seq_addr_l;
  reg [ 3:0] src_l;
  reg [ 3:0] dst_l;
  reg [ 3:0] base_l;
  reg [ 3:0] index_l;
  reg [ 1:0] seg_l;
  reg [ 2:0] fdec_l;

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
    .off (off_l),
    .imm (imm_l),

    // from microcode
    .ftype (ftype),

    // to exec
    .imm_f  (imm_f),
    .wr_ip0 (wr_ip0_f),

    // from exec
    .of      (of),
    .zf      (zf),
    .ifl     (ifl),
//    .cx_zero (cx_zero), // still to resolve jumps
    .div_exc (div_exc),

    // from control
    .stall_f (stall_f),

    // to wb
    .data      (umif_dat_i),
    .pc        (umif_adr_o),
    .bytefetch (umif_by_o),
    .stb       (umif_stb_o),
    .ack       (umif_ack_i),
    .intr      (intr)
  );

  zet_decode decode (
    .clk (clk),
    .rst (rst),

    .opcode  (opcode),
    .modrm   (modrm),
    .rep     (rep),
    .block   (stall_f),
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
    // from fetch
    .off_i   (off_l),
    .imm_i   (imm_l),

    // from decode
    .n_micro (seq_addr_l),
    .src     (src_l),
    .dst     (dst_l),
    .base    (base_l),
    .index   (index_l),
    .seg     (seg_l),
    .fdec    (fdec_l),

    .div     (div),
    .end_seq (end_seq),

    // to exec
    .ir    (rom_ir),
    .off_o (off_d),
    .imm_o (imm_d)
  );

  zet_exec exec (
    .clk     (clk),
    .rst     (rst),

    // from fetch
    .ir      (ir),
    .off     (off),
    .imm     (imm),
    .wrip0   (1'b0),

    // to fetch
    .cs      (cs),
    .ip      (ip),
    .of      (of),
    .zf      (zf),
    .ifl     (ifl),
    .cx_zero (cx_zero),
    .div_exc (div_exc),

    // from wb
    .iid     (iid),
    .memout  (umie_dat_i),
    .wr_data (umie_dat_o),
    .addr    (umie_adr_o),
    .we      (umie_we_o),
    .m_io    (umie_tga_o),
    .byteop  (umie_by_o),
    .stb     (umie_stb_o),
    .ack     (umie_ack_i)
  );

  // Assignments
//  assign cpu_mem_op = ir[`MEM_OP];

  assign ftype   = rom_ir[28:23];
  assign stall_f = umie_stb_o & !umie_ack_i;

  // Behaviour
  // microcode - exec registers
  always @(posedge clk)
    if (rst)
      begin
        ir  <= 'd0;
        imm <= 'd0;
        off <= 'd0;
      end
    else
      begin
        ir  <= ld_base ? rom_ir : `NOP_IR;
        imm <= imm_d;
        off <= off_d;
      end

  // decode - microcode registers
  always @(posedge clk)
    if (rst)
      begin
        seq_addr_l <= 'd0;
        src_l      <= 'd0;
        dst_l      <= 'd0;
        base_l     <= 'd0;
        index_l    <= 'd0;
        seg_l      <= 'd0;
        fdec_l     <= 'd0;
      end
    else
      begin
        seq_addr_l <= seq_addr;
        src_l      <= src;
        dst_l      <= dst;
        base_l     <= base;
        index_l    <= index;
        seg_l      <= seg;
        fdec_l     <= fdec;
      end

endmodule
