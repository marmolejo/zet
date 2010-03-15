/*
 *  Add / substract unit for Zet
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

module zet_addsub (
    input  [15:0] x,
    input  [15:0] y,
    output [15:0] out,
    input  [ 2:0] f,
    input         word_op,
    input         cfi,
    output        cfo,
    output        afo,
    output        ofo
  );

  // Net declarations
  wire [15:0] op2;

  wire ci;
  wire cfoadd;
  wire xs, ys, os;

  // Module instances
  zet_fulladd16 fulladd16 ( // We instantiate only one adder
    .x  (x),                //  to have less hardware
    .y  (op2),
    .ci (ci),
    .co (cfoadd),
    .z  (out),
    .s  (f[2])
  );

  // Assignments
  assign op2 = f[2] ? ~y
             : ((f[1:0]==2'b11) ? { 8'b0, y[7:0] } : y);
  assign ci  = f[2] & f[1] | f[2] & ~f[0] & ~cfi
             | f[2] & f[0] | (f==3'b0) & cfi;
  assign afo = f[1] ? (f[2] ? &out[3:0] : ~|out[3:0] )
                    : (x[4] ^ y[4] ^ out[4]);
  assign cfo = f[1] ? cfi /* inc, dec */
             : (word_op ? cfoadd : (x[8]^y[8]^out[8]));

  assign xs  = word_op ? x[15] : x[7];
  assign ys  = word_op ? y[15] : y[7];
  assign os  = word_op ? out[15] : out[7];
  assign ofo = f[2] ? (~xs & ys & os | xs & ~ys & ~os)
                    : (~xs & ~ys & os | xs & ys & ~os);
endmodule
