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

`timescale 1ns / 1ps

module yadmc_test;

reg sys_clk;
reg sys_rst;
reg sdram_clk;

reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
reg [3:0] wb_sel_i;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

wire sdram_cke;
wire sdram_cs_n;
wire sdram_we_n;
wire sdram_cas_n;
wire sdram_ras_n;
wire [1:0] sdram_dqm;
wire [11:0] sdram_adr;
wire [1:0] sdram_ba;
wire [15:0] sdram_dq;

  yadmc #(
    .sdram_depth       (23),
    .sdram_columndepth (8),
    .sdram_adrwires    (12),
    .cache_depth       (4)
    ) yadmc (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_sel_i(wb_sel_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_ack_o(wb_ack_o),

	.sdram_clk(sdram_clk),
	
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_dqm(sdram_dqm),
	.sdram_adr(sdram_adr),
	.sdram_ba(sdram_ba),
	.sdram_dq(sdram_dq)
);

mt48lc16m16a2 sdram(
	.Dq(sdram_dq),
	.Addr(sdram_adr),
	.Ba(sdram_ba),
	.Clk(sdram_clk),
	.Cke(sdram_cke),
	.Cs_n(sdram_cs_n),
	.Ras_n(sdram_ras_n),
	.Cas_n(sdram_cas_n),
	.We_n(sdram_we_n),
	.Dqm(sdram_dqm)
);

/* Generate 125 MHz SDRAM clock */
initial sdram_clk <= 0;
always #4 sdram_clk <= ~sdram_clk;

task wbwrite;
	input [31:0] address;
	input [31:0] data;
	integer i;
	begin
		wb_adr_i = address;
		wb_dat_i = data;
		wb_sel_i = 4'hF;
		wb_cyc_i = 1'b1;
		wb_stb_i = 1'b1;
		wb_we_i = 1'b1;
		
		i = 1;
		while(~wb_ack_o) begin
			#10 sys_clk = 1'b1;
			#10 sys_clk = 1'b0;
			i = i + 1;
		end
		
		$display("Write address %h completed in %d cycles", address, i);
		
		/* Let the core release its ack */
		#10 sys_clk = 1'b1;
		#10 sys_clk = 1'b0;
		
		wb_we_i = 1'b1;
		wb_cyc_i = 1'b0;
		wb_stb_i = 1'b0;
		
	end
endtask

task wbread;
	input [31:0] address;
	integer i;
	begin
		wb_adr_i = address;
		wb_sel_i = 4'hF;
		wb_cyc_i = 1'b1;
		wb_stb_i = 1'b1;
		wb_we_i = 1'b0;
		
		i = 1;
		while(~wb_ack_o) begin
			#10 sys_clk = 1'b1;
			#10 sys_clk = 1'b0;
			i = i + 1;
		end
		
		$display("Read address %h completed in %d cycles, result %h", address, i, wb_dat_o);
		
		/* Let the core release its ack */
		#10 sys_clk = 1'b1;
		#10 sys_clk = 1'b0;
		
		wb_cyc_i = 1'b0;
		wb_stb_i = 1'b0;
	end
endtask

integer i;
initial begin
	sys_rst = 1'b1;
	sys_clk = 1'b0;
	
	wb_adr_i = 32'h00044000;
	wb_dat_i = 32'h00000000;
	wb_sel_i = 4'hf;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b1;

	#10 sys_clk = 1'b1;
	#10 sys_clk = 1'b0;
	#10 sys_clk = 1'b1;
	#10 sys_clk = 1'b0;
	#10 sys_clk = 1'b1;
	#10 sys_clk = 1'b0;
	#10 sys_clk = 1'b1;
	#10 sys_clk = 1'b0;
	
	sys_rst = 1'b0;
	
	for(i=0;i<6000;i=i+1) begin
		#10 sys_clk = 1'b1;
		#10 sys_clk = 1'b0;
	end
	
	wbwrite(32'h00044000, 32'hcafebabe);
	wbwrite(32'h00044004, 32'hdeadbeef);
	wbwrite(32'h00064000, 32'h12345678);
	wbwrite(32'h00064004, 32'habcd4241);
	wbread(32'h00044000);
	wbread(32'h00044004);
	$display("Contents of the cache line:");
	wbread(32'h00044000);
	wbread(32'h00044004);
	wbread(32'h00044008);
	wbread(32'h0004400c);
	
	for(i=0;i<800;i=i+1)
		wbwrite(4*i, i);

	//wbread(32'b000000000000000000010110000);
	
	//wbwrite(32'h00000010, 32'hcafebabe);
	//wbwrite(32'h00000050, 32'hcafebabe);
	//wbwrite(32'h00000090, 32'hcafebabe);
	
	$finish;
end

endmodule

