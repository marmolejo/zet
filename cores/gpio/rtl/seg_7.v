/*
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
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

module seg_7 (
    input      [3:0] num,
    input            en,
    output reg [6:0] seg
  );

  // Behaviour
  always @(num or en)
    if (!en) seg <= 7'h3f;
    else
      case (num)
      4'h0: seg <= {1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
      4'h1: seg <= {1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b1};
      4'h2: seg <= {1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0};
      4'h3: seg <= {1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0};
      4'h4: seg <= {1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1};
      4'h5: seg <= {1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0};
      4'h6: seg <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0};
      4'h7: seg <= {1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0};
      4'h8: seg <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
      4'h9: seg <= {1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0};
      4'ha: seg <= {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0};
      4'hb: seg <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1};
      4'hc: seg <= {1'b0,1'b1,1'b0,1'b0,1'b1,1'b1,1'b1};
      4'hd: seg <= {1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1};
      4'he: seg <= {1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0};
      4'hf: seg <= {1'b0,1'b0,1'b0,1'b1,1'b1,1'b1,1'b0};
      endcase

endmodule
