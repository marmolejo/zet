/*
 *  Fetch & Decode module for Zet
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

module zet_fetch (
    input clk,
    input rst,

    // to decode
    output     [7:0] opcode,
    output     [7:0] modrm,
    output           rep,
    output           exec_st,
    output           exec_ns,
    output           ld_base,
    output reg [2:0] sop_l,

    // from decode
    input need_modrm,
    input need_off,
    input need_imm,
    input off_size,
    input imm_size,
    input ext_int,
    input end_seq,

    // to microcode
    output [15:0] off,
    output [15:0] imm,

    // from microcode
    input [5:0] ftype,

    // to exec
    output [15:0] imm_f,
    output wr_ip0,

    // from exec
    input of,
    input zf,
    input ifl,
    input cx_zero,
    input div_exc,

    // from control
    input stall_f,

    // to wb
    input  [15:0] data,
    output [19:0] pc,
    output        bytefetch,
    output        stb,
    input         ack,

    input intr
  );

  // Registers, nets and parameters
  // cs and ip
  reg [15:0] cs;
  reg [15:0] ip;

  // symbolic names for sts
  localparam [2:0]
    OPCOD = 3'd0,
    MODRM = 3'd1,
    OFFSE = 3'd2,
    IMMED = 3'd3,
    EXECU = 3'd4;

  reg  [2:0] st;  // current state
  wire [2:0] ns;  // next state

  wire prefix, repz_pr, sovr_pr;
  wire next_in_opco, next_in_exec;

  reg [ 7:0] opcode_l;
  reg [ 7:0] modrm_l;
  reg [15:0] off_l;
  reg [15:0] imm_l;
  reg [ 1:0] pref_l;
  wire       block;

  // Module instantiation
  zet_next_or_not next_or_not(pref_l, opcode[7:1], cx_zero, zf, ext_int, next_in_opco,
                  next_in_exec);
  zet_nstate nstate (
    .state        (st),
    .prefix       (prefix),
    .need_modrm   (need_modrm),
    .need_off     (need_off),
    .need_imm     (need_imm),
    .end_seq      (end_seq),
    .ftype        (ftype),
    .of           (of),
    .next_in_opco (next_in_opco),
    .next_in_exec (next_in_exec),
    .block        (block),
    .div_exc      (div_exc),
    .intr         (intr),
    .ifl          (ifl),
    .next_state   (ns)
  );

  // Assignments
  assign pc = (cs << 4) + ip;

  assign opcode = (st == OPCOD) ? data[7:0] : opcode_l;
  assign modrm  = (st == MODRM) ? data[7:0] : modrm_l;
  assign off    = (st == OFFSE) ? data : off_l;
  assign imm    = (st == IMMED) ? data : imm_l;

  assign bytefetch = (st == OFFSE) ? ~off_size
                   : ((st == IMMED) ? ~imm_size : 1'b1);
  assign exec_st = (st == EXECU);
  assign exec_ns = (ns == EXECU);
  assign imm_f = ((st == OFFSE) & off_size
                | (st == IMMED) & imm_size) ? 16'd2
               : 16'd1;
  assign wr_ip0 = (st == OPCOD) && !pref_l[1] && !sop_l[2];

  assign sovr_pr = (opcode[7:5]==3'b001 && opcode[2:0]==3'b110);
  assign repz_pr = (opcode[7:1]==7'b1111_001);
  assign prefix  = sovr_pr || repz_pr;
  assign ld_base = (ns == EXECU);
  assign rep     = pref_l[1];
  assign stb     = !exec_st;
  assign block   = (stb & !ack) | stall_f;

  // Behaviour
  // cs and ip logic
  always @(posedge clk)
    if (rst)
      begin
        cs <= 16'hf000;
        ip <= 16'hfff0;
      end
    else
      begin
        cs <= cs; // we don't change cs at the moment
        ip <= ack ? (ip + imm_f) : ip;
      end

  // machine state
  always @(posedge clk) st <= rst ? EXECU : ns;

  always @(posedge clk)
    if (rst) opcode_l <= `OP_NOP;
    else if (!block)
      case (ns)
        default:  // opcode or prefix
          begin
            case (st)
              OPCOD:
                begin // There has been a prefix
                  pref_l <= repz_pr ? { 1'b1, opcode[0] } : pref_l;
                  sop_l  <= sovr_pr ? { 1'b1, opcode[4:3] } : sop_l;
                end
              default: begin pref_l <= 2'b0; sop_l <= 3'b0; end
            endcase
            off_l <= 16'd0;
            modrm_l <= 8'b0000_0110;
          end

        MODRM:  // modrm
          begin
            opcode_l  <= data[7:0];
          end

        OFFSE:  // offset
          begin
            case (st)
              OPCOD: opcode_l <= data[7:0];
              default: modrm_l <= data[7:0];
            endcase
          end

        IMMED:  // immediate
          begin
            case (st)
              OPCOD: opcode_l <= data[7:0];
              MODRM: modrm_l <= data[7:0];
              default: off_l <= data;
            endcase
          end

        EXECU:  // execute
          begin
            case (st)
              OPCOD: opcode_l <= data[7:0];
              MODRM: modrm_l <= data[7:0];
              OFFSE: off_l <= data;
              IMMED: imm_l <= data;
            endcase
          end
      endcase
endmodule
