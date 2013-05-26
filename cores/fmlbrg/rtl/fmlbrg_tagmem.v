/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * adjusted to FML 8x16 by Zeus Gomez Marmolejo <zeus@aluzina.org>
 * updated to include Direct Cache Bus by Charley Picker <charleypicker@yahoo.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module fmlbrg_tagmem #(
	parameter depth = 2,
	parameter width = 2
) (
	input sys_clk,

	/* Primary port (read-write) */
	input [depth-1:0] a,
	input we,
	input [width-1:0] di,
	output [width-1:0] dout,

	/* Secondary port (read-only) */
	input [depth-1:0] a2,
	output [width-1:0] do2
);

reg [width-1:0] tags[0:(1 << depth)-1];

reg [depth-1:0] a_r;
reg [depth-1:0] a2_r;

always @(posedge sys_clk) begin
	a_r <= a;
	a2_r <= a2;
end

always @(posedge sys_clk) begin
	if(we)
		tags[a] <= di;
end

assign dout = tags[a_r];
assign do2 = tags[a2_r];

// synthesis translate_off
integer i;
initial begin
	for(i=0;i<(1 << depth);i=i+1)
		tags[i] = 0;
end
// synthesis translate_on

endmodule
