/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

`timescale 1ns / 1ps

`define ENABLE_VCD

module tb_fmlbrg();

reg clk;
initial clk = 1'b0;
always #5 clk = ~clk;

reg rst;

reg [22:1] wb_adr_i;
reg [2:0] wb_cti_i;
reg [15:0] wb_dat_i;
wire [15:0] wb_dat_o;
reg [1:0] wb_sel_i;
reg wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;

wire [22:0] fml_adr;
wire fml_stb;
wire fml_we;
reg fml_ack;
wire [1:0] fml_sel;
wire [15:0] fml_dw;
reg [15:0] fml_dr;

reg dcb_stb;
reg [22:0] dcb_adr;
wire [15:0] dcb_dat;
wire dcb_hit;

/* Process FML requests */
reg [2:0] fml_wcount;
reg [2:0] fml_rcount;
initial begin
	fml_ack = 1'b0;
	fml_wcount = 0;
	fml_rcount = 0;
end

always @(posedge clk) begin
	if(fml_stb & (fml_wcount == 0) & (fml_rcount == 0)) begin
		fml_ack <= 1'b1;
		if(fml_we) begin
			$display("%t FML W addr %x data %x", $time, fml_adr, fml_dw);
			fml_wcount <= 7;
		end else begin
			fml_dr = 16'hbeef;
			$display("%t FML R addr %x data %x", $time, fml_adr, fml_dr);
			fml_rcount <= 7;
		end
	end else
		fml_ack <= 1'b0;
	if(fml_wcount != 0) begin
		#1 $display("%t FML W continuing %x / %d", $time, fml_dw, fml_wcount);
		fml_wcount <= fml_wcount - 1;
	end
	if(fml_rcount != 0) begin
		fml_dr = #1 {13'h1eba, fml_rcount};
		$display("%t FML R continuing %x / %d", $time, fml_dr, fml_rcount);
		fml_rcount <= fml_rcount - 1;
	end
end

fmlbrg #(
  .fml_depth   (23),  // 8086 can only address 1 MB
  .cache_depth (10)   // 1 Kbyte cache
  ) dut (
	.sys_clk(clk),
	.sys_rst(rst),
	
	.wb_adr_i(wb_adr_i),
	.wb_cti_i(wb_cti_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_sel_i(wb_sel_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_ack_o(wb_ack_o),
	
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_we(fml_we),
	.fml_ack(fml_ack),
	.fml_sel(fml_sel),
	.fml_do(fml_dw),
	.fml_di(fml_dr),
  
	.dcb_stb(dcb_stb),
	.dcb_adr(dcb_adr),
	.dcb_dat(dcb_dat),
	.dcb_hit(dcb_hit)
	
);

task waitclock;
begin
	@(posedge clk);
	#1;
end
endtask

task wbwrite;
input [22:1] address;
input [1:0] sel;
input [15:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_dat_i = data;
	wb_sel_i = sel;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x sel=%b acked in %d clocks", address, data, sel, i);
	wb_adr_i = 22'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [22:1] address;
integer i;
begin
	wb_adr_i = address;	
	wb_cti_i = 3'b000;
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
	wb_adr_i = 22'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbwriteburst;
input [22:1] address;
input [15:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b010;
	wb_dat_i = data;
	wb_sel_i = 2'b11;
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
	wb_dat_i = data+1;
	waitclock;
	wb_dat_i = data+2;
	waitclock;
	wb_dat_i = data+3;
	wb_cti_i = 3'b111;
	waitclock;
	wb_adr_i = 22'hx;
	wb_cti_i = 3'b000;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbreadburst;
input [22:1] address;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b010;
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
	$display("read burst(1): %x", wb_dat_o);
	waitclock;
	$display("read burst(2): %x", wb_dat_o);
	waitclock;
	wb_cti_i = 3'b111;
	$display("read burst(3): %x", wb_dat_o);
	waitclock;
	wb_adr_i = 22'hx;
	wb_cti_i = 3'b000;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

always begin
`ifdef ENABLE_VCD
	$dumpfile("fmlbrg.vcd");
	$dumpvars(0, dut);
`endif
	rst = 1'b1;
	
	wb_adr_i = 22'd0;
	wb_dat_i = 16'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;

	dcb_stb = 1'b0;
	dcb_adr = 22'd0;
	
	waitclock;
	
	rst = 1'b0;
	
	waitclock;
	
	$display("Testing: read miss");
	wbread(22'h0);
	$display("Testing: write hit");
	wbwrite(22'h0, 2'b11, 16'h5678);
	wbread(22'h0);
	$display("Testing: read miss on a dirty line");
	wbread(22'h01000);
	
	$display("Testing: read hit");
	wbread(22'h01004);
	
	$display("Testing: write miss");
	wbwrite(22'h0, 2'b11, 16'hface);
	wbread(27'h0);
	wbread(27'h4);
	
	$display("Testing: read burst");
	wbreadburst(22'h40);
	
	$display("Testing: write burst");
	wbwriteburst(22'h40, 16'hcaf0);
	
	$display("Testing: read burst");
	wbreadburst(22'h40);

	$display("Testing: DCB miss");
	dcb_adr = 22'hfeba;
	dcb_stb = 1'b1;
	waitclock;
	$display("Result: hit=%b dat=%x", dcb_hit, dcb_dat);

	$display("Testing: DCB hit");
	dcb_adr = 22'h0;
	dcb_stb = 1'b1;
	waitclock;
	$display("Result: hit=%b dat=%x", dcb_hit, dcb_dat);
	
	$stop;
end


endmodule
