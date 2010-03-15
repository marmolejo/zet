/*
 *  16-bit bitwise rotate module for Zet
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

module zet_rxr16 (
    input      [15:0] x,
    input             ci,
    input      [ 4:0] y,
    input             e,
    output reg [15:0] w,
    output reg        co
  );

  always @(x or ci or y or e)
    case (y)
      default: {co,w} <= {ci,x};
      5'd01: {co,w} <= e ? {x[0], ci, x[15:1]} : {ci, x[0], x[15:1]};
      5'd02: {co,w} <= e ? {x[ 1:0], ci, x[15: 2]} : {ci, x[ 1:0], x[15: 2]};
      5'd03: {co,w} <= e ? {x[ 2:0], ci, x[15: 3]} : {ci, x[ 2:0], x[15: 3]};
      5'd04: {co,w} <= e ? {x[ 3:0], ci, x[15: 4]} : {ci, x[ 3:0], x[15: 4]};
      5'd05: {co,w} <= e ? {x[ 4:0], ci, x[15: 5]} : {ci, x[ 4:0], x[15: 5]};
      5'd06: {co,w} <= e ? {x[ 5:0], ci, x[15: 6]} : {ci, x[ 5:0], x[15: 6]};
      5'd07: {co,w} <= e ? {x[ 6:0], ci, x[15: 7]} : {ci, x[ 6:0], x[15: 7]};
      5'd08: {co,w} <= e ? {x[ 7:0], ci, x[15: 8]} : {ci, x[ 7:0], x[15: 8]};
      5'd09: {co,w} <= e ? {x[ 8:0], ci, x[15: 9]} : {ci, x[ 8:0], x[15: 9]};
      5'd10: {co,w} <= e ? {x[ 9:0], ci, x[15:10]} : {ci, x[ 9:0], x[15:10]};
      5'd11: {co,w} <= e ? {x[10:0], ci, x[15:11]} : {ci, x[10:0], x[15:11]};
      5'd12: {co,w} <= e ? {x[11:0], ci, x[15:12]} : {ci, x[11:0], x[15:12]};
      5'd13: {co,w} <= e ? {x[12:0], ci, x[15:13]} : {ci, x[12:0], x[15:13]};
      5'd14: {co,w} <= e ? {x[13:0], ci, x[15:14]} : {ci, x[13:0], x[15:14]};
      5'd15: {co,w} <= e ? {x[14:0], ci, x[15]} : {ci, x[14:0], x[15]};
      5'd16: {co,w} <= {x,ci};
    endcase
endmodule
