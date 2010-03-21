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
    output        cfo,
    output        ofo
  );

  // Assignemnts
  assign o   = f[2] ? (f[1] ? x^y : x&y) : x|y;

  assign cfo = 1'b0;
  assign ofo = 1'b0;

endmodule
