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

module yadmc_spram #(
	parameter address_depth = 10,
	parameter data_width = 8
) (
	input clk,
	input [address_depth-1:0] adr,
	input we,
	input [data_width-1:0] di,
	output reg [data_width-1:0] dout
);

reg [data_width-1:0] storage[0:(1 << address_depth)-1];

always @(posedge clk) begin
	if(we) storage[adr] <= di;
	dout <= storage[adr];
end

integer i;
initial begin
	for(i=0;i<(1 << address_depth);i=i+1)
		storage[i] <= 0;
end

endmodule

