/*
 *  8-bit rotate module for Zet
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

module zet_rxr8 (
    input      [7:0] x,
    input            ci,
    input      [3:0] y,
    input            e,
    output reg [7:0] w,
    output reg       co
  );

  always @(x or ci or y or e)
    case (y)
      default: {co,w} <= {ci,x};
      5'd01: {co,w} <= e ? {x[0], ci, x[7:1]} : {ci, x[0], x[7:1]};
      5'd02: {co,w} <= e ? {x[1:0], ci, x[7:2]} : {ci, x[1:0], x[7:2]};
      5'd03: {co,w} <= e ? {x[2:0], ci, x[7:3]} : {ci, x[2:0], x[7:3]};
      5'd04: {co,w} <= e ? {x[3:0], ci, x[7:4]} : {ci, x[3:0], x[7:4]};
      5'd05: {co,w} <= e ? {x[4:0], ci, x[7:5]} : {ci, x[4:0], x[7:5]};
      5'd06: {co,w} <= e ? {x[5:0], ci, x[7:6]} : {ci, x[5:0], x[7:6]};
      5'd07: {co,w} <= e ? {x[6:0], ci, x[7]} : {ci, x[6:0], x[7]};
      5'd08: {co,w} <= {x,ci};
    endcase
endmodule
