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

/*******************************************************/
/* USER CONFIGURATION                                  */
/*******************************************************/

/*
 * Uncomment this if the SDRAM clock is not the system clock.
 * The low-level part has been made simple in order to
 * reach high clock speeds (and cope with DRAM latencies).
 * When uncommented, no frequency or phase relationship is required
 * between the SDRAM and the system clocks, and you can (and should)
 * run the SDRAM at a higher frequency than the system.
 */
`define SDRAM_ASYNCHRONOUS

module yadmc #(
	/*
	 * The depth of the SDRAM array, in bytes.
	 * Capacity (in bytes) is 2^sdram_depth.
	 */
	parameter sdram_depth = 25,
	
	/*
	 * The number of column address bits of the SDRAM.
	 */
	parameter sdram_columndepth = 9,
	
	/*
	 * The number of address lines on the SDRAM chips.
	 */
	parameter sdram_adrwires = 13,
	
	/*
	 * The log2 of the number of data bytes of the SDRAM,
	 * ie. 0 = 8-bit SDRAM
	 *     1 = 16-bit SDRAM
	 *     2 = 32-bit SDRAM
	 * Other configurations are not supported (some architectural changes are needed
	 * to support SDRAMs with word widths larger than the cache's).
	 */
	parameter sdram_bytes_depth = 1,
	
	/*
	 * The log2 of the cache size, in cache lines.
	 */
	parameter cache_depth = 10,
	
	/*******************************************************/
	/*
	 * The number of data bits of the SDRAM
	 */
	parameter sdram_bits = (8 << sdram_bytes_depth),
	
	/*
	 * The cache line depth, in 32-bit words.
	 * We always run at burst length 8, and a burst is always exactly one cache line.
	 */
	parameter cache_linedepth = sdram_bytes_depth + 1,
	
	parameter cache_linelength = (4 << cache_linedepth),
	
	/*
	 * The number of bits of the cache tags.
	 */
	parameter cache_tagdepth = sdram_depth - cache_depth - cache_linedepth - 2
	
) (
  output reg [1:0] state,
  output [4:0] statey,
	/* WISHBONE interface */
	input sys_clk,
	input sys_rst,
	
	input [31:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output [15:0] wb_dat_o,
	input [3:0] wb_sel_i,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output reg wb_ack_o,

	/* SDRAM interface */
	input sdram_clk,
	
	output sdram_cke,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [(sdram_bits/8)-1:0] sdram_dqm,
	output [sdram_adrwires-1:0] sdram_adr,
	output [1:0] sdram_ba,
	inout [sdram_bits-1:0] sdram_dq
);

// synthesis translate_off
initial begin
	$display("=== YADMC parameters ===");
	
	$display("SDRAM depth\t\t\t%d", sdram_depth);
	$display("SDRAM capacity (MB)\t\t%d", (1 << sdram_depth)/(1024*1024));
	$display("SDRAM data lines\t\t%d", sdram_bits);

	$display("Cache depth\t\t\t%d", cache_depth);
	$display("Cache size (KB)\t\t\t%d", (cache_linelength << cache_depth)/1024);

	$display("Cache line depth\t\t%d", cache_linedepth);
	$display("Cache line length\t\t%d", cache_linelength);
	
	$display("Cache tag depth\t\t\t%d", cache_tagdepth);
end
// synthesis translate_on

/* Address in words */
wire [sdram_depth-1-2:0] address = wb_adr_i[sdram_depth-1:2];

/*
 * For the direct-mapped cache, the linear SDRAM address is split as follows :
 * TTTTTIIIIILL
 * with
 * T..T: tag			length: cache_tagdepth		range: sdram_depth-1-2			cache_depth+cache_linedepth
 * I..I: index in the cache	length: cache_depth		range: cache_depth+cache_linedepth-1	cache_linedepth
 * L..L: index in the line	length: cache_linedepth		range: cache_linedepth-1		0
 */

wire [cache_tagdepth-1:0] cache_tag = address[sdram_depth-1-2:cache_depth+cache_linedepth];
wire [cache_depth-1:0] cache_index = address[cache_depth+cache_linedepth-1:cache_linedepth];
wire [cache_linedepth-1:0] cache_lindex = address[cache_linedepth-1:0];

//always @(address) $display("tag %h index %h lindex %h", cache_tag, cache_index, cache_lindex);

wire [cache_depth+cache_linedepth-1:0] sca_adr;
wire [31:0] sca_di;
wire [31:0] sca_do;
wire [3:0] sca_we;


yadmc_dpram #(
	.address_depth(cache_depth+cache_linedepth),
	.data_width(8)
) cacheline0 (
	.clk0(sys_clk),
	.adr0({cache_index, cache_lindex}),
	.we0(wb_ack_o & wb_we_i & wb_sel_i[0]),
	.di0(wb_dat_i[7:0]),
	.do0(wb_dat_o[7:0]),

	.clk1(sdram_clk),
	.adr1(sca_adr),
	.we1(sca_we[0]),
	.di1(sca_do[7:0]),
	.do1(sca_di[7:0])
);

/*
  dpram cacheline0 (
    .clock_a   (sys_clk),
    .address_a ({cache_index, cache_lindex}),
    .wren_a    (wb_ack_o & wb_we_i & wb_sel_i[0]),
    .data_a    (wb_dat_i[7:0]),
    .q_a       (wb_dat_o[7:0]),
    //.clock_b   (sdram_clk),
    .address_b (sca_adr),
    .wren_b    (sca_we[0]),
    .data_b    (sca_do[7:0]),
    .q_b       (sca_di[7:0])
  );
*/

yadmc_dpram #(
	.address_depth(cache_depth+cache_linedepth),
	.data_width(8)
) cacheline1 (
	.clk0(sys_clk),
	.adr0({cache_index, cache_lindex}),
	.we0(wb_ack_o & wb_we_i & wb_sel_i[1]),
	.di0(wb_dat_i[15:8]),
	.do0(wb_dat_o[15:8]),

	.clk1(sdram_clk),
	.adr1(sca_adr),
	.we1(sca_we[1]),
	.di1(sca_do[15:8]),
	.do1(sca_di[15:8])
);
/*
  dpram cacheline1 (
    .clock_a   (sys_clk),
    .address_a ({cache_index, cache_lindex}),
    .wren_a    (wb_ack_o & wb_we_i & wb_sel_i[1]),
    .data_a    (wb_dat_i[15:8]),
    .q_a       (wb_dat_o[15:8]),
    .clock_b   (sdram_clk),
    .address_b (sca_adr),
    .wren_b    (sca_we[1]),
    .data_b    (sca_do[15:8]),
    .q_b       (sca_di[15:8])
  );
*/
/*
yadmc_dpram #(
	.address_depth(cache_depth+cache_linedepth),
	.data_width(8)
) cacheline2 (
	.clk0(sys_clk),
	.adr0({cache_index, cache_lindex}),
	.we0(wb_ack_o & wb_we_i & wb_sel_i[2]),
	.di0(wb_dat_i[23:16]),
	.do0(wb_dat_o[23:16]),

	.clk1(sdram_clk),
	.adr1(sca_adr),
	.we1(sca_we[2]),
	.di1(sca_do[23:16]),
	.do1(sca_di[23:16])
);

yadmc_dpram #(
	.address_depth(cache_depth+cache_linedepth),
	.data_width(8)
) cacheline3 (
	.clk0(sys_clk),
	.adr0({cache_index, cache_lindex}),
	.we0(wb_ack_o & wb_we_i & wb_sel_i[3]),
	.di0(wb_dat_i[31:24]),
	.do0(wb_dat_o[31:24]),

	.clk1(sdram_clk),
	.adr1(sca_adr),
	.we1(sca_we[3]),
	.di1(sca_do[31:24]),
	.do1(sca_di[31:24])
);
*/
reg cachetags_we;
wire [cache_tagdepth:0] cachetags_di;
wire [cache_tagdepth:0] cachetags_do;

yadmc_spram #(
	.address_depth(cache_depth),
	.data_width(cache_tagdepth+1) /* LSB is the dirty bit */
) cachetags (
	.clk(sys_clk),
	.adr(cache_index),
	.we(cachetags_we),
	.di(cachetags_di),
	.dout(cachetags_do)
);

reg cachetags_write_dirty;
assign cachetags_di = {cache_tag, cachetags_write_dirty};
wire cache_hit = cachetags_do[cache_tagdepth:1] == cache_tag;
wire cache_is_dirty = cachetags_do[0];

/* SDRAM low-level controller and synchronizers */

`ifdef SDRAM_ASYNCHRONOUS
reg command_evict;
wire sdram_command_evict;
yadmc_sync sync_evict(
	.clk0(sys_clk),
	.flagi(command_evict),

	.clk1(sdram_clk),
	.flago(sdram_command_evict)
);
`else
reg command_evict;
reg sdram_command_evict;
always @(posedge sdram_clk) sdram_command_evict <= command_evict;
`endif

`ifdef SDRAM_ASYNCHRONOUS
reg command_refill;
wire sdram_command_refill;
yadmc_sync sync_refill(
	.clk0(sys_clk),
	.flagi(command_refill),

	.clk1(sdram_clk),
	.flago(sdram_command_refill)
);
`else
//`warning Use asynchronous SDRAM controller for best performance
reg command_refill;
reg sdram_command_refill;
always @(posedge sdram_clk) sdram_command_refill <= command_refill;
`endif

`ifdef SDRAM_ASYNCHRONOUS
wire sdram_command_ack;
wire command_ack;
yadmc_sync sync_ack(
	.clk0(sdram_clk),
	.flagi(sdram_command_ack),

	.clk1(sys_clk),
	.flago(command_ack)
);
`else
//`warning Use asynchronous SDRAM controller for best performance
wire sdram_command_ack;
reg command_ack;
always @(posedge sdram_clk) command_ack <= sdram_command_ack;
`endif

reg [sdram_depth-cache_linedepth-2-1:0] evict_adr;
reg [sdram_depth-cache_linedepth-2-1:0] refill_adr;

always @(posedge sys_clk) begin
	if(command_evict | command_refill) begin
		evict_adr <= {cachetags_do[cache_tagdepth:1], cache_index};
		refill_adr <= {cache_tag, cache_index};
	end
end

/* Synchronize sys_rst into sdram_clk domain */
reg sdram_rst0;
reg sdram_rst;
initial sdram_rst0 <= 1'b1;
initial sdram_rst <= 1'b1;
always @(posedge sdram_clk) begin
	sdram_rst0 <= sys_rst;
	sdram_rst <= sdram_rst0;
end

yadmc_sdram16 #(
	.sdram_depth(sdram_depth),
	.sdram_columndepth(sdram_columndepth),
	.cache_depth(cache_depth)
) sdramc (
  .state (statey),
	.sdram_clk(sdram_clk),
	.sdram_rst(sdram_rst),
	
	/* Command port */
	.command_evict(sdram_command_evict),
	.command_refill(sdram_command_refill),
	.command_ack(sdram_command_ack),
	.evict_adr(evict_adr),
	.refill_adr(refill_adr),
	
	/* Cache interface */
	.cache_adr(sca_adr),
	.cache_dat_o(sca_do),
	.cache_we(sca_we),
	.cache_dat_i(sca_di),
	
	/* SDRAM interface */
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


/* Wishbone and cache management state machine */

// reg [1:0] state;
reg [1:0] next_state;

localparam [1:0] IDLE = 0, CHECK_HIT = 1, WAIT_ACK = 2;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

// synthesis translate_off
always @(posedge sys_clk) begin
	if(state == CHECK_HIT)
		$display("cache: [wb adr %h] hit %b  tag(wanted) %b tag(cached) %b index %b line %b", wb_adr_i, cache_hit, cache_tag, cachetags_do[cache_tagdepth:1], cache_index, cache_lindex);
end
// synthesis translate_on

always @(state or wb_cyc_i or wb_stb_i or wb_we_i or cache_hit or cache_is_dirty or command_ack) begin
	next_state = state;
	wb_ack_o = 0;
	
	cachetags_we = 0;
	cachetags_write_dirty = 1'bx;
	
	command_evict = 0;
	command_refill = 0;
	
	case(state)
		default: begin
			//$display("IDLE");
			if(wb_cyc_i & wb_stb_i)
				next_state = CHECK_HIT;
		end

		CHECK_HIT: begin
			//$display("CHECK_HIT");
			if(cache_hit) begin
				wb_ack_o = 1;
				if(wb_we_i) begin
					cachetags_we = 1;
					cachetags_write_dirty = 1;
				end
				next_state = IDLE;
			end else begin
				if(cache_is_dirty) begin
					/* The low-level controller automatically refills following an eviction.
					 * (this reduces the number of crossings of clock domains which are slow)
					 */
					command_evict = 1;
					next_state = WAIT_ACK;
				end else begin
					command_refill = 1;
					next_state = WAIT_ACK;
				end
			end
		end

		WAIT_ACK: begin 
			//$display("WAIT_ACK");
			if(command_ack) begin
				wb_ack_o = 1;
				cachetags_we = 1;
				cachetags_write_dirty = wb_we_i;
				next_state = IDLE;
			end
		end
	endcase
end

endmodule

