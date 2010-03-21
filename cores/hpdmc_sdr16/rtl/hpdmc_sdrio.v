/*
 * Milkymist VJ SoC
 * Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module hpdmc_sdrio(
	input             sys_clk,
	
	input             direction,
	input             direction_r,
	input      [ 1:0] mo,
	input      [15:0] dout,
	output reg [15:0] di,
	
	output     [ 1:0] sdram_dqm,
	inout      [15:0] sdram_dq
);

wire [15:0] sdram_data_out;
assign sdram_dq = direction ? sdram_data_out : 16'hzzzz;

/*
 * In this case, without DDR primitives and delays, this block
 * is extremely simple
 */
assign sdram_dqm      = mo;
assign sdram_data_out = dout;

 // Behaviour
 always @(posedge sys_clk) di <= sdram_dq;

endmodule
