/*
 *  Bitwise 8 and 16 bit shifter and rotator for Zet
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

module zet_shrot (
    input  [15:0] x,
    input  [ 7:0] y,
    output [15:0] out,
    input  [ 2:0] func,  // 0: rol, 1: ror, 2: rcl, 3: rcr,
                         // 4: shl/sal, 5: shr, 6: sar
    input         word_op,
    input         cfi,
    input         ofi,
    output        cfo,
    output        ofo
  );

  // Net declarations
  wire [4:0] ror16;
  wire [4:0] rol16;
  wire [4:0] rcr16;
  wire [4:0] rcl16;
  wire [4:0] rot16;

  wire [15:0] sal;
  wire [15:0] sar;
  wire [15:0] shr;
  wire [15:0] sal16;
  wire [15:0] sar16;
  wire [15:0] shr16;

  wire [7:0] sal8;
  wire [7:0] sar8;
  wire [7:0] shr8;

  wire [3:0] ror8;
  wire [3:0] rol8;
  wire [3:0] rcr8;
  wire [3:0] rcl8;
  wire [3:0] rot8;

  wire [ 7:0] outr8;
  wire [15:0] outr16;
  wire [15:0] rot;

  wire cor8;
  wire cor16;
  wire unchanged;

  wire ofo_sal;
  wire ofo_sar;
  wire ofo_shr;
  wire cfo_sal;
  wire cfo_sal8;
  wire cfo_sal16;
  wire cfo_sar;
  wire cfo_sar8;
  wire cfo_sar16;
  wire cfo_shr;
  wire cfo_shr8;
  wire cfo_shr16;

  wire ofor;
  wire cfor;

  // Module instantiation
  zet_rxr8 rxr8 (
    .x  (x[7:0]),
    .ci (cfi),
    .y  (rot8),
    .e  (func[1]),
    .w  (outr8),
    .co (cor8)
  );

  zet_rxr16 rxr16 (
    .x  (x),
    .ci (cfi),
    .y  (rot16),
    .e  (func[1]),
    .w  (outr16),
    .co (cor16)
  );

  // Continous assignments
  assign unchanged = word_op ? (y[4:0]==8'b0)
                             : (y[3:0]==4'b0);

  // rotates
  assign ror16 = { 1'b0, y[3:0] };
  assign rol16 = { 1'b0, -y[3:0] };
  assign ror8  = { 1'b0, y[2:0] };
  assign rol8  = { 1'b0, -y[2:0] };

  assign rcr16 = (y[4:0] <= 5'd16) ? y[4:0] : { 1'b0, y[3:0] - 4'b1 };
  assign rcl16 = (y[4:0] <= 5'd17) ? 5'd17 - y[4:0] : 6'd34 - y[4:0];
  assign rcr8  = y[3:0] <= 4'd8 ? y[3:0] : { 1'b0, y[2:0] - 3'b1 };
  assign rcl8  = y[3:0] <= 4'd9 ? 4'd9 - y[3:0] : 5'd18 - y[3:0];

  assign rot8 = func[1] ? (func[0] ? rcr8 : rcl8 )
                        : (func[0] ? ror8 : rol8 );
  assign rot16 = func[1] ? (func[0] ? rcr16 : rcl16 )
                         : (func[0] ? ror16 : rol16 );

  assign rot = word_op ? outr16 : { x[15:8], outr8 };

  // shifts
  assign { cfo_sal16, sal16 } = x << y;
  assign { sar16, cfo_sar16 } = (y > 5'd16) ? 17'h1ffff
    : (({x,1'b0} >> y) | (x[15] ? (17'h1ffff << (17 - y))
                                     : 17'h0));
  assign { shr16, cfo_shr16 } = ({x,1'b0} >> y);

  assign { cfo_sal8, sal8 } = x[7:0] << y;
  assign { sar8, cfo_sar8 } = (y > 5'd8) ? 9'h1ff
    : (({x[7:0],1'b0} >> y) | (x[7] ? (9'h1ff << (9 - y))
                                         : 9'h0));
  assign { shr8, cfo_shr8 } = ({x[7:0],1'b0} >> y);

  assign sal     = word_op ? sal16 : { 8'd0, sal8 };
  assign shr     = word_op ? shr16 : { 8'd0, shr8 };
  assign sar     = word_op ? sar16 : { {8{sar8[7]}}, sar8 };

  // overflows
  assign ofor = func[0] ? // right
                  (word_op ? out[15]^out[14] : out[7]^out[6])
              : // left
                  (word_op ? cfo^out[15] : cfo^out[7]);

  assign ofo_sal = word_op ? (out[15] != cfo) : (out[7] != cfo);
  assign ofo_sar = 1'b0;
  assign ofo_shr = word_op ? x[15] : x[7];

  assign ofo = unchanged ? ofi
             : (func[2] ? (func[1] ? ofo_sar : (func[0] ? ofo_shr : ofo_sal))
                        : ofor);

  // carries
  assign cfor = func[1] ? (word_op ? cor16 : cor8)
                        : (func[0] ? (word_op ? out[15] : out[7])
                                   : out[0]);

  assign cfo_sal = word_op ? cfo_sal16 : cfo_sal8;
  assign cfo_shr = word_op ? cfo_shr16 : cfo_shr8;
  assign cfo_sar = word_op ? cfo_sar16 : cfo_sar8;

  assign cfo = unchanged ? cfi
    : (func[2] ? (func[1] ? cfo_sar
                          : (func[0] ? cfo_shr : cfo_sal))
                : cfor);

  // output
  assign out = func[2] ? (func[1] ? sar : (func[0] ? shr : sal)) : rot;
endmodule
