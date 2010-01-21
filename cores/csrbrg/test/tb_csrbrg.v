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

module tb_csrbrg();

reg sys_clk;
reg sys_rst;

reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

wire [13:0] csr_a;
wire csr_we;
wire [31:0] csr_do;
reg [31:0] csr_di;

/* 100MHz system clock */
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

csrbrg dut(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_ack_o(wb_ack_o),
	
	/* CSR bus master */
	.csr_a(csr_a),
	.csr_we(csr_we),
	.csr_do(csr_do),
	.csr_di(csr_di)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_dat_i = data;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	waitclock;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask


/* Simulate CSR slave */
reg [31:0] csr1;
reg [31:0] csr2;
wire csr_selected = (csr_a[13:10] == 4'ha);
always @(posedge sys_clk) begin
	if(csr_selected) begin
		if(csr_we) begin
			$display("Writing %x to CSR %x", csr_do, csr_a[0]);
			case(csr_a[0])
				1'b0: csr1 <= csr_do;
				1'b1: csr2 <= csr_do;
			endcase
		end
		case(csr_a[0])
			1'b0: csr_di <= csr1;
			1'b1: csr_di <= csr2;
		endcase
	end else
		/* we must set data to 0 to be able to use a distributed OR topology
		 * in the slaves->master datapath.
		 */
		csr_di <= 32'd0;
end

always begin
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	
	wb_adr_i = 32'd0;
	wb_dat_i = 32'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
	
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	/* Try some transfers */
	wbwrite(32'h0000a000, 32'hcafebabe);
	wbwrite(32'h0000a004, 32'habadface);
	wbread(32'h0000a000);
	wbread(32'h0000a004);
	
	$finish;
end

endmodule
