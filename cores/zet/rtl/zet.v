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

module zet (
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
    output [15:0] ax,
    output [15:0] dx,
    output [15:0] bp,
    output [15:0] si,
    output [15:0] es,
    input         dbg_block,
    output [15:0] c,
    output [ 3:0] addr_c,
    output [ 3:0] addr_a,
    output [15:0] cpu_dat_o,
    output [15:0] d,
    output [ 3:0] addr_d,
    output        byte_exec,
    output [ 8:0] flags,
    output        end_seq,
    output        ext_int,
    output        cpu_block,
    output [19:0] cpu_adr_o,
    output [`SEQ_DATA_WIDTH-2:0] micro_addr,
`endif

    // Wishbone master interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output [19:1] wb_adr_o,
    output        wb_we_o,
    output        wb_tga_o,  // io/mem
    output [ 1:0] wb_sel_o,
    output        wb_stb_o,
    output        wb_cyc_o,
    input         wb_ack_i,
    input         wb_tgc_i,  // intr
    output        wb_tgc_o   // inta
  );

  // Net declarations
`ifndef DEBUG
  wire [15:0] cs, ip;
  wire [15:0] imm;
  wire [15:0] cpu_dat_o;
  wire        byte_exec;
  wire        cpu_block;
  wire [19:0] cpu_adr_o;
`endif
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off;

  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, fetch_or_exec;
  wire of, zf, cx_zero;
  wire div_exc;
  wire wr_ip0;
  wire ifl;

  wire        cpu_byte_o;
  wire        cpu_m_io;
  wire        wb_block;
  wire [15:0] cpu_dat_i;
  wire        cpu_we_o;
  wire [15:0] iid_dat_i;

  // Module instantiations
  zet_fetch fetch (
`ifdef DEBUG
    .state      (state),
    .next_state (next_state),
    .ext_int    (ext_int),
    .end_seq    (end_seq),
    .micro_addr (micro_addr),
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

    .wr_ip0  (wr_ip0),

    .intr (wb_tgc_i),
    .ifl  (ifl),
    .inta (wb_tgc_o)
  );

  zet_exec exec (
`ifdef DEBUG
    .x    (x),
    .y    (y),
    .aluo (aluo),
    .ax   (ax),
    .dx   (dx),
    .bp   (bp),
    .si   (si),
    .es   (es),
    .c    (c),
    .addr_c (addr_c),
    .addr_a (addr_a),
    .omemalu (d),
    .addr_d (addr_d),
    .flags  (flags),
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
    .memout  (iid_dat_i),
    .wr_data (cpu_dat_o),
    .addr    (addr_exec),
    .we      (cpu_we_o),
    .m_io    (cpu_m_io),
    .byteop  (byte_exec),
    .block   (cpu_block),
    .div_exc (div_exc),
    .wrip0   (wr_ip0),

    .ifl     (ifl)
  );

  zet_wb_master wb_master (
    .cpu_byte_o (cpu_byte_o),
    .cpu_memop  (ir[`MEM_OP]),
    .cpu_m_io   (cpu_m_io),
    .cpu_adr_o  (cpu_adr_o),
    .cpu_block  (wb_block),
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
  assign iid_dat_i  = wb_tgc_o ? wb_dat_i : cpu_dat_i;

`ifdef DEBUG
  assign iralu = ir[28:23];
  assign cpu_block = wb_block | dbg_block;
`else
  assign cpu_block = wb_block;
`endif
endmodule
