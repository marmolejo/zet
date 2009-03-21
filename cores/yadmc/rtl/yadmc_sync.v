/*
 * Yet Another Dynamic Memory Controller
 * Copyright (C) 2008 Sebastien Bourdeauducq - http://lekernel.net
 * This file is part of Milkymist.
 *
 * Milkymist is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
 * USA.
 */

/* Flag synchronizer from clock domain 0 to 1
 * See http://www.fpga4fun.com/CrossClockDomain.html
 */

module yadmc_sync(
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
