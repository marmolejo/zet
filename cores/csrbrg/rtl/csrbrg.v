/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module csrbrg(
	input sys_clk,
	input sys_rst,
	
	/* WB */
	input [3:1] wb_adr_i,
	input [15:0] wb_dat_i,
	output reg [15:0] wb_dat_o,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output reg wb_ack_o,
	
	/* CSR */
	output reg [2:0] csr_a,
	output reg csr_we,
	output reg [15:0] csr_do,
	input [15:0] csr_di
);

/* Datapath: WB <- CSR */
always @(posedge sys_clk) begin
	wb_dat_o <= csr_di;
end

/* Datapath: CSR -> WB */
reg next_csr_we;
always @(posedge sys_clk) begin
	csr_a <= wb_adr_i[3:1];
	csr_we <= next_csr_we;
	csr_do <= wb_dat_i;
end

/* Controller */

reg [1:0] state;
reg [1:0] next_state;

parameter IDLE		= 2'd0;
parameter DELAYACK1	= 2'd1;
parameter DELAYACK2	= 2'd2;
parameter ACK		= 2'd3;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	wb_ack_o = 1'b0;
	next_csr_we = 1'b0;
	
	case(state)
		IDLE: begin
			if(wb_cyc_i & wb_stb_i) begin
				/* We have a request for us */
				next_csr_we = wb_we_i;
				if(wb_we_i)
					next_state = ACK;
				else
					next_state = DELAYACK1;
			end
		end
		DELAYACK1: next_state = DELAYACK2;
		DELAYACK2: next_state = ACK;
		ACK: begin
			wb_ack_o = 1'b1;
			next_state = IDLE;
		end
	endcase
end

endmodule
