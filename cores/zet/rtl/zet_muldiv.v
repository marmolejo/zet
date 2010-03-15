/*
 *  Integer multiply/divide module for Zet
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

module zet_muldiv (
    input  [31:0] x,  // 16 MSb for division
    input  [15:0] y,
    output [31:0] o,
    input  [ 2:0] f,
    input         word_op,
    output        cfo,
    output        ofo,
    input         clk,
    output        exc
  );

  // Net declarations
  wire as, bs, cfs, cfu;
  wire [16:0] a, b;
  wire [33:0] p;
  wire div0, over, ovf, mint;

  wire [33:0] zi;
  wire [16:0] di;
  wire [17:0] q;
  wire [17:0] s;

  // Module instantiations
  zet_signmul17 signmul17 (
    .clk (clk),
    .a   (a),
    .b   (b),
    .p   (p)
  );

  zet_div_su #(
    .z_width(34)
    ) div_su (
    .clk  (clk),
    .ena  (1'b1),
    .z    (zi),
    .d    (di),
    .q    (q),
    .s    (s),
    .ovf  (ovf),
    .div0 (div0)
  );

  // Sign ext. for imul
  assign as  = f[0] & (word_op ? x[15] : x[7]);
  assign bs  = f[0] & (word_op ? y[15] : y[7]);
  assign a   = word_op ? { as, x[15:0] }
                       : { {9{as}}, x[7:0] };
  assign b   = word_op ? { bs, y } : { {9{bs}}, y[7:0] };

  assign zi  = f[2] ? { 26'h0, x[7:0] }
               : (word_op ? (f[0] ? { {2{x[31]}}, x }
                               : { 2'b0, x })
                       : (f[0] ? { {18{x[15]}}, x[15:0] }
                               : { 18'b0, x[15:0] }));

  assign di  = word_op ? (f[0] ? { y[15], y } : { 1'b0, y })
                       : (f[0] ? { {9{y[7]}}, y[7:0] }
                               : { 9'h000, y[7:0] });

  assign o   = f[2] ? { 16'h0, q[7:0], s[7:0] }
               : (f[1] ? ( word_op ? {s[15:0], q[15:0]}
                                : {16'h0, s[7:0], q[7:0]})
                    : p[31:0]);

  assign ofo = f[1] ? 1'b0 : cfo;
  assign cfo = f[1] ? 1'b0 : !(f[0] ? cfs : cfu);
  assign cfu = word_op ? (o[31:16] == 16'h0)
                       : (o[15:8] == 8'h0);
  assign cfs = word_op ? (o[31:16] == {16{o[15]}})
                       : (o[15:8] == {8{o[7]}});

  // Exceptions
  assign over = f[2] ? 1'b0
              : (word_op ? (f[0] ? (q[17:16]!={2{q[15]}})
                                : (q[17:16]!=2'b0) )
                        : (f[0] ? (q[17:8]!={10{q[7]}})
                                : (q[17:8]!=10'h000)));
  assign mint = f[0] & (word_op ? (x==32'h80000000)
                                : (x==16'h8000));
  assign exc  = div0 | (!f[2] & ovf) | over | mint;
endmodule
