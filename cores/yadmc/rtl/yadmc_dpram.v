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

module yadmc_dpram #(
	parameter address_depth = 10,
	parameter data_width = 8
) (
	input clk0,
	input [address_depth-1:0] adr0,
	input we0,
	input [data_width-1:0] di0,
	output reg [data_width-1:0] do0,
	
	input clk1,
	input [address_depth-1:0] adr1,
	input we1,
	input [data_width-1:0] di1,
	output reg [data_width-1:0] do1
);

 reg [data_width-1:0] storage[0:(1 << address_depth)-1];

/*
always @(posedge clk0)
  begin
    if (we0) storage[adr0] <= di0;
    do0 <= storage[adr0];
    if (we1) storage[adr1] <= di1;
    do1 <= storage[adr1];
  end
*/
	always @ (posedge clk0)
	begin
		// Port A 
		if (we0) 
		begin
			storage[adr0] <= di0;
			do0 <= di0;
		end
		else 
		begin
			do0 <= storage[adr0];
		end 
	end

	always @ (posedge clk1)
	begin
		// Port B 
		if (we1) 
		begin
			storage[adr1] <= di1;
			do1 <= di1;
		end
		else 
		begin
			do1 <= storage[adr1];
		end 
	end
/*
always @(posedge clk0) begin
	if(we0) storage[adr0] <= di0;
	do0 <= storage[adr0];
end

always @(posedge clk1) begin
	if(we1) storage[adr1] <= di1;
	do1 <= storage[adr1];
end
*/
integer i;
initial begin
	for(i=0;i<(1 << address_depth);i=i+1)
		storage[i] <= 0;
end

endmodule

