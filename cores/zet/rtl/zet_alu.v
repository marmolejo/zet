/*
 *  Arithmetic Logic Unit for Zet
 *  Copyright (C) 2008-2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module zet_alu (
    input  [31:0] x,
    input  [15:0] y,
    output [31:0] out,
    input  [ 2:0] t,
    input  [ 2:0] func,
    input  [15:0] iflags,
    output [ 8:0] oflags,
    input         word_op,
    input  [15:0] seg,
    input  [15:0] off,
    input         clk,
    output        div_exc
  );

  // Net declarations
  wire [15:0] add, log, rot;
  wire [15:0] arl;
  wire  [8:0] othflags;
  wire [19:0] oth;
  wire [31:0] cnv, mul;
  wire af_add, af_cnv, af_arl;
  wire cf_cnv, cf_add, cf_mul, cf_log, cf_arl, cf_rot;
  wire of_cnv, of_add, of_mul, of_log, of_arl, of_rot;
  wire ofi, sfi, zfi, afi, pfi, cfi;
  wire ofo, sfo, zfo, afo, pfo, cfo;
  wire flags_unchanged;
  wire dexc;

  // Module instances
  zet_addsub addsub (x[15:0], y, add, func, word_op, cfi, cf_add, af_add, of_add);

  zet_conv conv (
    .x      (x[15:0]),
    .func   (func),
    .out    (cnv),
    .iflags ({afi, cfi}),
    .oflags ({af_cnv, of_cnv, cf_cnv})
  );

  zet_muldiv muldiv (
    .x       (x),
    .y       (y),
    .o       (mul),
    .f       (func),
    .word_op (word_op),
    .cfo     (cf_mul),
    .ofo     (of_mul),
    .clk     (clk),
    .exc     (dexc)
  );

  zet_bitlog bitlog (
    .x   (x[15:0]),
    .o   (log),
    .cfo (cf_log),
    .ofo (of_log)
  );

  zet_arlog arlog (
    .x       (x[15:0]),
    .y       (y),
    .f       (func),
    .o       (arl),
    .word_op (word_op),
    .cfi     (cfi),
    .cfo     (cf_arl),
    .afo     (af_arl),
    .ofo     (of_arl)
  );

  zet_shrot  shrot (
    .x       (x[15:0]),
    .y       (y[7:0]),
    .out     (rot),
    .func    (func),
    .word_op (word_op),
    .cfi     (cfi),
    .ofi     (ofi),
    .cfo     (cf_rot),
    .ofo     (of_rot)
  );

  zet_othop  othop (x[15:0], y, seg, off, iflags, func, word_op, oth, othflags);

  zet_mux8_16 m0(t, {8'd0, y[7:0]}, add, cnv[15:0],
                 mul[15:0], log, arl, rot, oth[15:0], out[15:0]);
  zet_mux8_16 m1(t, 16'd0, 16'd0, cnv[31:16], mul[31:16],
                 16'd0, 16'd0, 16'd0, {12'b0,oth[19:16]}, out[31:16]);
  zet_mux8_1  a1(t, 1'b0, cf_add, cf_cnv, cf_mul, cf_log, cf_arl, cf_rot, 1'b0, cfo);
  zet_mux8_1  a2(t, 1'b0, af_add, af_cnv, 1'b0, 1'b0, af_arl, afi, 1'b0, afo);
  zet_mux8_1  a3(t, 1'b0, of_add, of_cnv, of_mul, of_log, of_arl, of_rot, 1'b0, ofo);

  // Flags
  assign pfo = flags_unchanged ? pfi : ^~ out[7:0];
  assign zfo = flags_unchanged ? zfi
             : ((word_op && (t!=3'd2)) ? ~|out[15:0] : ~|out[7:0]);
  assign sfo = flags_unchanged ? sfi
             : ((word_op && (t!=3'd2)) ? out[15] : out[7]);

  assign oflags = (t == 3'd7) ? othflags 
                 : { ofo, iflags[10:8], sfo, zfo, afo, pfo, cfo };

  assign ofi = iflags[11];
  assign sfi = iflags[7];
  assign zfi = iflags[6];
  assign afi = iflags[4];
  assign pfi = iflags[2];
  assign cfi = iflags[0];

  assign flags_unchanged = (t == 3'd4
                         || t == 3'd6 && (!func[2] || func[2]&&y[4:0]==5'h0));

  assign div_exc = func[1] && (t==3'd3) && dexc;

endmodule
