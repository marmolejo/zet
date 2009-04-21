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

/*
 * Glue logic for synchronizing wb_stb_i and wb_cyc_i to a different
 * clock domain
 */
module domain_sync  #(
    parameter wait_cyc = 5  // wait cycles for the next strobe
  )
  (
    input      clk0,
    input      clk1,
    input      rst,
    input      stb0,
    input      ack1,
    output reg stb1,
    output     ack0
  );

  // Registers and nets
  reg [1:0] sync;
  reg [1:0] state, next_state;
  reg [wait_cyc-1:0] wack;

  localparam
    IDLE      = 2'd0,
    STB_NOACK = 2'd1,
    STB_ACK   = 2'd2;

  // Module instantiation
  flag_sync ack_sync (
    .clk0  (clk1),
    .flagi (ack1),
    .clk1  (clk0),
    .flago (ack0)
  );

  // Behaviour
  // sync
  always @(posedge clk1)
    sync <= rst ? 2'b00 : { sync[0], stb0 };

  // wack
  always @(posedge clk1)
    wack <= rst ? 0 : (next_state==STB_ACK ? {wack[wait_cyc-2:0],1'b1} : 0);

  // state
  always @(posedge clk1)
    state <= rst ? IDLE : next_state;

  // next_state
  always @(*)
    case (state)
      IDLE:
        begin
          next_state <= sync[1] ? STB_NOACK : IDLE;
          stb1 <= 1'b0;
        end
      STB_NOACK:
        begin
          next_state <= ack1 ? STB_ACK : STB_NOACK;
          stb1 <= 1'b1;
        end
      STB_ACK:
        begin
          next_state <= (&wack) ? (sync[1] ? STB_NOACK : IDLE) : STB_ACK;
          stb1 <= 1'b0;
        end
    endcase

endmodule


module flag_sync(
	input clk0,
	input flagi,

	input clk1,
	output flago
);

/* Turn the flag into a level change */
reg toggle;
initial toggle = 1'b0;
always @(posedge clk0)
	if(flagi) toggle <= ~toggle;

/* Synchronize the level change to clk1.
 * We add a third flip-flop to be able to detect level changes. */
reg [2:0] sync;
initial sync = 3'b000;
always @(posedge clk1)
	sync <= {sync[1:0], toggle};

/* Recreate the flag from the level change into the clk1 domain */
assign flago = sync[2] ^ sync[1];

endmodule
