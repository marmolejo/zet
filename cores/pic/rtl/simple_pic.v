/*
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
 *  Copyright (c) 2009  Mark McDougall (tcdev) <msmcdoug@iinet.net.au>
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

module simple_pic (
    input             clk,
    input             rst,
    input       [7:0] intv,
    input             inta,
    output            intr,
    output reg  [2:0] iid
  );

  // Registers
  reg [7:0] irr;
  reg       inta_r;
  reg       int4_r;

  // Continuous assignments
  // - note that only IRQs 0,1&4 are driven atm
  assign intr = irr[4]|irr[1]|irr[0];

  // Behaviour
  // inta_r
  always @(posedge clk)
    inta_r <= inta;

  // irr
  always @(posedge clk)
    irr[0] <= rst ? 1'b0 : (intv[0] | irr[0] & !(iid == 3'b000 && inta_r && !inta));

  always @(posedge clk)
    irr[1] <= rst ? 1'b0 : (intv[1] | irr[1] & !(iid == 3'b001 && inta_r && !inta));

  always @(posedge clk)
    irr[4] <= rst ? 1'b0
      : ((intv[4] && !int4_r) | irr[4] & !(iid == 3'b100 && inta_r && !inta));

  // int4_r
  always @(posedge clk)
    int4_r <= rst ? 1'b0 : intv[4];

  // iid
  always @(posedge clk)
    iid <= rst ? 3'b0 : (inta ? iid :
                        (irr[0] ? 3'b000 :
                        (irr[1] ? 3'b001 :
                        (irr[4] ? 3'b100 : 3'b000))));
endmodule
