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

//
// Multiplexor 8:1 de 16 bits d'amplada
//
module mux8_16(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  [15:0] in0, in1, in2, in3, in4, in5, in6, in7;
  output [15:0] out;

  reg    [15:0] out;

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


//
// Multiplexor 8:1 de 8 bits d'amplada
//
/*
module mux8_8(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  [7:0] in0, in1, in2, in3, in4, in5, in6, in7;
  output [7:0] out;

  reg    [7:0] out;

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
*/
//
// Multiplexor 8:1 de 17 bits d'amplada
//
module mux8_17(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  [16:0] in0, in1, in2, in3, in4, in5, in6, in7;
  output [16:0] out;

  reg    [16:0] out;

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

//
// Multiplexor 8:1 d'1 bit d'amplada
//
module mux8_1(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
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

//
// Multiplexor 4:1 de 32 bits d'amplada
//

module mux4_32(sel, in0, in1, in2, in3, out);
  input  [1:0]  sel;
  input  [31:0] in0, in1, in2, in3;
  output [31:0] out;

  reg    [31:0] out;

  always @(sel or in0 or in1 or in2 or in3)
    case(sel)
     2'd0:  out = in0;
     2'd1:  out = in1;
     2'd2:  out = in2;
     2'd3:  out = in3;
    endcase
endmodule


//
// Multiplexor 4:1 de 16 bits d'amplada
//
module mux4_16(sel, in0, in1, in2, in3, out);
  input  [1:0]  sel;
  input  [15:0] in0, in1, in2, in3;
  output [15:0] out;

  reg    [15:0] out;

  always @(sel or in0 or in1 or in2 or in3)
    case(sel)
     2'd0:  out = in0;
     2'd1:  out = in1;
     2'd2:  out = in2;
     2'd3:  out = in3;
    endcase
endmodule

//
// Multiplexor 2:1 de 8 bits d'amplada
//
module mux2_8(sel, in0, in1, out);
  input        sel;
  input  [7:0] in0, in1;
  output [7:0] out;

  reg    [7:0] out;

  always @(sel or in0 or in1)
    case(sel)
     1'd0:  out = in0;
     1'd1:  out = in1;
    endcase
endmodule

//
// Multiplexor 4:1 de 1 bits d'amplada
//
module mux4_1(sel, in0, in1, in2, in3, out);
  input  [1:0]  sel;
  input  in0, in1, in2, in3;
  output out;

  reg    out;

  always @(sel or in0 or in1 or in2 or in3)
    case(sel)
     2'd0:  out = in0;
     2'd1:  out = in1;
     2'd2:  out = in2;
     2'd3:  out = in3;
    endcase
endmodule