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

`timescale 1ns/10ps

`include "defines.v"

module zet_fetch (
    input clk,
    input rst,

    // to decode
    output     [7:0] opcode,
    output     [7:0] modrm,
    output           rep,
    output           exec_st,
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
    output reg [15:0] off_l,
    output reg [15:0] imm_l,

    // from microcode
    input [5:0] ftype,

    // to exec
    output [15:0] imm_f,

    input [15:0] cs,
    input [15:0] ip,
    input of,
    input zf,
    input cx_zero,
    input [15:0] data,
    output [19:0] pc,
    output bytefetch,
    input  block,
    input  div_exc,
    output wr_ip0,
    input  intr,
    input  ifl
  );

  // Registers, nets and parameters
  parameter opcod_st = 3'h0;
  parameter modrm_st = 3'h1;
  parameter offse_st = 3'h2;
  parameter immed_st = 3'h3;
  parameter execu_st = 3'h4;

  reg  [2:0] state;
  wire [2:0] next_state;

  wire prefix, repz_pr, sovr_pr;
  wire next_in_opco, next_in_exec;

  reg [7:0] opcode_l, modrm_l;
  reg [1:0] pref_l;

  // Module instantiation
  zet_next_or_not next_or_not(pref_l, opcode[7:1], cx_zero, zf, ext_int, next_in_opco,
                  next_in_exec);
  zet_nstate nstate (state, prefix, need_modrm, need_off, need_imm, end_seq,
             ftype, of, next_in_opco, next_in_exec, block, div_exc,
             intr, ifl, next_state);

  // Assignments
  assign pc = (cs << 4) + ip;

  assign opcode = (state == opcod_st) ? data[7:0] : opcode_l;
  assign modrm  = (state == modrm_st) ? data[7:0] : modrm_l;
  assign bytefetch = (state == offse_st) ? ~off_size
                   : ((state == immed_st) ? ~imm_size : 1'b1);
  assign exec_st = (state == execu_st);
  assign imm_f = ((state == offse_st) & off_size
                | (state == immed_st) & imm_size) ? 16'd2
               : 16'd1;
  assign wr_ip0 = (state == opcod_st) && !pref_l[1] && !sop_l[2];

  assign sovr_pr = (opcode[7:5]==3'b001 && opcode[2:0]==3'b110);
  assign repz_pr = (opcode[7:1]==7'b1111_001);
  assign prefix  = sovr_pr || repz_pr;
  assign ld_base = (next_state == execu_st);
  assign rep     = pref_l[1];

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        state <= execu_st;
        opcode_l <= `OP_NOP;
      end
    else if (!block)
      case (next_state)
        default:  // opcode or prefix
          begin
            case (state)
              opcod_st:
                begin // There has been a prefix
                  pref_l <= repz_pr ? { 1'b1, opcode[0] } : pref_l;
                  sop_l  <= sovr_pr ? { 1'b1, opcode[4:3] } : sop_l;
                end
              default: begin pref_l <= 2'b0; sop_l <= 3'b0; end
            endcase
            state <= opcod_st;
            off_l <= 16'd0;
            modrm_l <= 8'b0000_0110;
          end

        modrm_st:  // modrm
          begin
            opcode_l  <= data[7:0];
            state <= modrm_st;
          end

        offse_st:  // offset
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              default: modrm_l <= data[7:0];
            endcase
            state <= offse_st;
          end

        immed_st:  // immediate
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              default: off_l <= data;
            endcase
            state <= immed_st;
          end

        execu_st:  // execute
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              offse_st: off_l <= data;
              immed_st: imm_l <= data;
            endcase
            state <= execu_st;
          end
      endcase
endmodule
