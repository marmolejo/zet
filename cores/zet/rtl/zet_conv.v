/*
 *  Integer conversion module for Zet
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

module zet_conv (
    input  [15:0] x,
    input  [ 2:0] func,
    output [31:0] out,
    input  [ 1:0] iflags, // afi, cfi
    output [ 2:0] oflags  // afo, ofo, cfo
  );

  // Net declarations
  wire        afi, cfi;
  wire        ofo, afo, cfo;
  wire [15:0] aaa, aas;
  wire [ 7:0] daa, tmpdaa, das, tmpdas;
  wire [15:0] cbw, cwd;

  wire        acond, dcond;
  wire        tmpcf;

  // Module instances
  zet_mux8_16 mux8_16 (func, cbw, aaa, aas, 16'd0,
                       cwd, {x[15:8], daa}, {x[15:8], das}, 16'd0, out[15:0]);

  // Assignments
  assign aaa = (acond ? (x + 16'h0106) : x) & 16'hff0f;
  assign aas = (acond ? (x - 16'h0106) : x) & 16'hff0f;

  assign tmpdaa = acond ? (x[7:0] + 8'h06) : x[7:0];
  assign daa    = dcond ? (tmpdaa + 8'h60) : tmpdaa;
  assign tmpdas = acond ? (x[7:0] - 8'h06) : x[7:0];
  assign das    = dcond ? (tmpdas - 8'h60) : tmpdas;

  assign               cbw   = { { 8{x[ 7]}}, x[7:0] };
  assign { out[31:16], cwd } = { {16{x[15]}}, x      };

  assign acond = ((x[7:0] & 8'h0f) > 8'h09) | afi;
  assign dcond = (x[7:0] > 8'h99) | cfi;

  assign afi = iflags[1];
  assign cfi = iflags[0];

  assign afo = acond;
  assign ofo = 1'b0;
  assign tmpcf = (x[7:0] < 8'h06) | cfi;
  assign cfo = func[2] ? (dcond ? 1'b1 : (acond & tmpcf))
             : acond;

  assign oflags = { afo, ofo, cfo };
endmodule
