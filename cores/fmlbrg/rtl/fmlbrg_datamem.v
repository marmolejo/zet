/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * adjusted to FML 8x16 by Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module fmlbrg_datamem #(
	parameter depth = 8
) (
	input sys_clk,
	
	input [depth-1:0] a,
	input [1:0] we,
	input [15:0] di,
	output [15:0] do
);

reg [7:0] ram0[0:(1 << depth)-1];
reg [7:0] ram1[0:(1 << depth)-1];

wire [7:0] ram0di;
wire [7:0] ram1di;

reg [7:0] ram0do;
reg [7:0] ram1do;

/*
 * Workaround for a strange Xst 11.4 bug with Spartan-6
 * We must specify the RAMs in this order, otherwise,
 * ram1 "disappears" from the netlist. The typical
 * first symptom is a Bitgen DRC failure because of
 * dangling I/O pins going to the SDRAM.
 * Problem reported to Xilinx.
 */
always @(posedge sys_clk) begin
	if(we[1]) begin
		ram1[a] <= ram1di;
		ram1do <= ram1di;
	end else
		ram1do <= ram1[a];
end
always @(posedge sys_clk) begin
	if(we[0]) begin
		ram0[a] <= ram0di;
		ram0do <= ram0di;
	end else
		ram0do <= ram0[a];
end

assign ram0di = di[7:0];
assign ram1di = di[15:8];

assign do = {ram1do, ram0do};

endmodule
