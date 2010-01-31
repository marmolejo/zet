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

module hpdmc_banktimer(
	input sys_clk,
	input sdram_rst,
	
	input tim_cas,
	input [1:0] tim_wr,
	
	input read,
	input write,
	output reg precharge_safe
);

reg [3:0] counter;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		counter <= 4'd0;
		precharge_safe <= 1'b1;
	end else begin
		if(read) begin
			/* see p.26 of datasheet :
			 * "A Read burst may be followed by, or truncated with, a Precharge command
			 * to the same bank. The Precharge command should be issued x cycles after
			 * the Read command, where x equals the number of desired data element
			 * pairs"
			 */
			counter <= 4'd8;
			precharge_safe <= 1'b0;
		end else if(write) begin
			counter <= {2'b10, tim_wr};
			precharge_safe <= 1'b0;
		end else begin
			if(counter == 4'b1)
				precharge_safe <= 1'b1;
			if(~precharge_safe)
				counter <= counter - 4'b1;
		end
	end
end

endmodule
