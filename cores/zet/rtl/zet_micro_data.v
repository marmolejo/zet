/*
 *  Microcode instruction generator for Zet
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

module zet_micro_data (
    input  [`MICRO_ADDR_WIDTH-1:0] n_micro,
    input  [15:0] off_i,
    input  [15:0] imm_i,
    input  [ 3:0] src,
    input  [ 3:0] dst,
    input  [ 3:0] base,
    input  [ 3:0] index,
    input  [ 1:0] seg,
    input  [ 2:0] frot,
    output        end_seq,

    output [`IR_SIZE-1:0] ir,
    output [15:0]         off_o,
    output [15:0]         imm_o
  );

  // Net declarations
  wire [`MICRO_DATA_WIDTH-1:0] micro_o;
  wire [ 6:0] ir1;
  wire [ 3:0] ir0;
  wire var_s, var_off;
  wire [1:0] var_a, var_b, var_c, var_d;
  wire [2:0] var_imm;

  wire [3:0] addr_a, addr_b, addr_c, addr_d;
  wire [3:0] micro_a, micro_b, micro_c, micro_d;
  wire [1:0] addr_s, micro_s;
  wire [2:0] t;
  wire [2:0] f;
  wire [2:0] f_rom;
  wire       wr_flag;

  // Module instantiations
  zet_micro_rom micro_rom (n_micro, micro_o);

  // Assignments
  assign micro_s = micro_o[1:0];
  assign micro_a = micro_o[5:2];
  assign micro_b = micro_o[9:6];
  assign micro_c = micro_o[13:10];
  assign micro_d = micro_o[17:14];
  assign wr_flag = micro_o[18];
  assign ir0     = micro_o[22:19];
  assign t       = micro_o[25:23];
  assign f_rom   = micro_o[28:26];
  assign ir1     = micro_o[35:29];
  assign var_s   = micro_o[36];
  assign var_a   = micro_o[38:37];
  assign var_b   = micro_o[40:39];
  assign var_c   = micro_o[42:41];
  assign var_d   = micro_o[44:43];
  assign var_off = micro_o[45];
  assign var_imm = micro_o[48:46];
  assign end_seq = micro_o[49];

  assign imm_o = var_imm == 3'd0 ? (16'h0000)
               : (var_imm == 3'd1 ? (16'h0002)
               : (var_imm == 3'd2 ? (16'h0004)
               : (var_imm == 3'd3 ? off_i
               : (var_imm == 3'd4 ? imm_i
               : (var_imm == 3'd5 ? 16'hffff
               : (var_imm == 3'd6 ? 16'b11 : 16'd1))))));

  assign off_o = var_off ? off_i : 16'h0000;

  assign addr_a = var_a == 2'd0 ? micro_a
                : (var_a == 2'd1 ? base
                : (var_a == 2'd2 ? dst : src ));
  assign addr_b = var_b == 2'd0 ? micro_b
                : (var_b == 2'd1 ? index : src);
  assign addr_c = var_c == 2'd0 ? micro_c
                : (var_c == 2'd1 ? dst : src);
  assign addr_d = var_d == 2'd0 ? micro_d
                : (var_d == 2'd1 ? dst : src);
  assign addr_s = var_s ? seg : micro_s;

  assign f = (t==3'd6 && wr_flag) ? /* shifts/rotates */ frot : f_rom;

  assign ir = { ir1, f, t, ir0, wr_flag, addr_d,
                addr_c, addr_b, addr_a, addr_s };
endmodule
