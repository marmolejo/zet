/*
 *  1-bit 8-way multiplexor
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

module zet_mux8_1(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  in0, in1, in2, in3, in4, in5, in6, in7;
  output out;

  reg    out;

  always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7)
    case(sel)
     3'd0:  out = in0;
     3'd1:  out = in1;
     3'd2:  out = in2;
     3'd3:  out = in3;
     3'd4:  out = in4;
     3'd5:  out = in5;
     3'd6:  out = in6;
     3'd7:  out = in7;
    endcase
endmodule
