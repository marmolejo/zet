/*
 *  Arithmetic and logical operations for Zet
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

module zet_arlog (
    input  [15:0] x,
    input  [15:0] y,
    input  [ 2:0] f,
    output [15:0] o,
    input         word_op,
    input         cfi,
    output        cfo,
    output        afo,
    output        ofo
  );

  // Net declarations
  wire [15:0] op2;
  wire [15:0] outadd;
  wire [15:0] outlog;

  wire ci;
  wire cfoadd;
  wire log;
  wire xs;
  wire ys;
  wire os;

  // Module instances
  zet_fulladd16 fulladd16 ( // We instantiate only one adder
    .x  (x),                //  to have less hardware
    .y  (op2),
    .ci (ci),
    .co (cfoadd),
    .z  (outadd),
    .s  (f[0])
  );

  // Assignemnts
  assign op2 = f[0] ? ~y  /* sbb,sub,cmp */
                    : y;  /* add, adc */

  assign ci  = f[2] | ~f[2] & f[1] & (!f[0] & cfi
             | f[0] & ~cfi);

  assign log = f[2:0]==3'd1 || f[2:0]==3'd4 || f[2:0]==3'd6;
  assign afo   = !log & (x[4] ^ y[4] ^ outadd[4]);
  assign cfo   = !log & (word_op ? cfoadd : (x[8]^y[8]^outadd[8]));

  assign xs  = word_op ? x[15] : x[7];
  assign ys  = word_op ? y[15] : y[7];
  assign os  = word_op ? outadd[15] : outadd[7];
  assign ofo = !log &
    (f[0] ? (~xs & ys & os | xs & ~ys & ~os)
          : (~xs & ~ys & os | xs & ys & ~os));

  assign outlog = f[2] ? (f[1] ? x^y : x&y) : x|y;
  assign o      = log ? outlog : outadd;

endmodule
