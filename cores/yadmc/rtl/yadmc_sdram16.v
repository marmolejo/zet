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

/*
 * This is for using 16-bit wide SDR SDRAM with YADMC,
 * with sequential bursts of length 8.
 * If using DDR or other bus widths, adapt/replace this file.
 * Also, some parameters are hardcoded for MT48LC16M16A2 at CL2.
 * Review this file before using with other configurations.
 */

module yadmc_sdram16 #(
	parameter sdram_depth = 25,
	parameter sdram_columndepth = 9,
	parameter cache_depth = 10,
	
	/*
	 * Cache line depth is always 2 for 16-bit SDRAM:
	 * burst length is 8, which means 16 bytes are transferred per burst.
	 * with a cache word size of 4 bytes, this yields 4 cache words per burst.
	 * Thus the depth of 2 (to make FSMs simpler, we use cache line length = burst length).
	 */
	parameter cache_linedepth = 2,
	
	parameter sdram_rowdepth = sdram_depth-1-sdram_columndepth-2 /* -2 for the banks */
) (
  output reg [4:0] state,
	input sdram_clk,
	input sdram_rst,
	
	/* Command port */
	input command_evict,
	input command_refill,
	output reg command_ack,
	input [sdram_depth-cache_linedepth-2-1:0] evict_adr,  /* unregistered */
	input [sdram_depth-cache_linedepth-2-1:0] refill_adr, /* unregistered */
	
	/* Cache interface */
	output [cache_depth+cache_linedepth-1:0] cache_adr,
	output [31:0] cache_dat_o,
	output reg [3:0] cache_we,
	input [31:0] cache_dat_i,
	
	/* SDRAM interface */
	output reg sdram_cke,
	output reg sdram_cs_n,
	output reg sdram_we_n,
	output reg sdram_cas_n,
	output reg sdram_ras_n,
	output reg [1:0] sdram_dqm,
	output reg [11:0] sdram_adr,
	output reg [1:0] sdram_ba,
	inout [15:0] sdram_dq
);

/* Generate address parts */

/*
 * The address is split as follows to help reduce the probability of row switches :
 * row address, then column address, then bank number.
 *
 * The three LSBs (cache_linedepth+1) of the column address are always 0, since we always use the same burst ordering.
 * The MSBs are from the address input, decoded as above.
 */

wire [sdram_rowdepth-1:0] evict_row = evict_adr[sdram_depth-cache_linedepth-2-1:sdram_columndepth+2-3];
wire [sdram_columndepth-1:0] evict_column = {evict_adr[sdram_columndepth+2-1-3:2], {(cache_linedepth+1){1'b0}}};
wire [1:0] evict_bank = evict_adr[1:0];

wire [sdram_rowdepth-1:0] refill_row = refill_adr[sdram_depth-cache_linedepth-2-1:sdram_columndepth+2-3];
wire [sdram_columndepth-1:0] refill_column = {refill_adr[sdram_columndepth+2-1-3:2], {(cache_linedepth+1){1'b0}}};
wire [1:0] refill_bank = refill_adr[1:0];

/* Register all I/Os to keep Murphy away */

/* Control signals */
reg sdram_cke_r;
reg sdram_cs_n_r;
reg sdram_we_n_r;
reg sdram_cas_n_r;
reg sdram_ras_n_r;
reg sdram_dqm_r;
reg [1:0] sdram_ba_r;

always @(posedge sdram_clk) begin
	sdram_cke <= sdram_cke_r;
	sdram_cs_n <= sdram_cs_n_r;
	sdram_we_n <= sdram_we_n_r;
	sdram_cas_n <= sdram_cas_n_r;
	sdram_ras_n <= sdram_ras_n_r;
	sdram_dqm <= {2{sdram_dqm_r}};
	sdram_ba <= sdram_ba_r;
end

/* Data */
reg [15:0] dq;
assign sdram_dq = dq;

reg sdram_dq_drive;
wire [15:0] sdram_dq_out;
reg [15:0] sdram_dq_in;

always @(posedge sdram_clk) begin
	if(sdram_dq_drive)
		dq <= sdram_dq_out;
	else
		dq <= 16'hzzzz;
	sdram_dq_in <= sdram_dq;
end

/* Address lines */
reg adr_load_mode;
reg adr_load_evictrow;
reg adr_load_evictcolumn;
reg adr_load_refillrow;
reg adr_load_refillcolumn;
reg adr_load_A10;
always @(posedge sdram_clk) begin
	/*
	 * Mode register encoding :
	 * See p. 18 of the Micron datasheet.
	 * A12..A10 reserved, should be 000
	 * A9       burst access, 0 = burst enabled
	 * A8 ..A7  reserved, should be 00
	 * A6 ..A4  CAS latency, 10 = CL2
	 * A3       burst type, 0 = sequential
	 * A2 ..A0  burst length, 011 = 8
	 */
	sdram_adr <=
		 ({12{adr_load_mode  }}       & 12'b000_0_00_10_0_011)
		|({12{adr_load_evictrow   }}  & {{(12-sdram_rowdepth){1'b0}}, evict_row})
		|({12{adr_load_evictcolumn}}  & {{(12-sdram_columndepth){1'b0}}, evict_column})
		|({12{adr_load_refillrow   }} & {{(12-sdram_rowdepth){1'b0}}, refill_row})
		|({12{adr_load_refillcolumn}} & {{(12-sdram_columndepth){1'b0}}, refill_column})
		|({12{adr_load_A10   }}       & 12'd1024);
end

/*
 * Various timing counters.
 * Check that the delays are appropriate for the particular SDRAM chip
 * you're using.
 */

/* The number of clocks before we can use the SDRAM after power-up */
/* This should be 100us */
reg [13:0] init_counter;
reg reload_init_counter;
wire init_done = (init_counter == 14'b0);
always @(posedge sdram_clk) begin
	if(reload_init_counter)
		init_counter <= 14'd12500;
	else if(~init_done)
		init_counter <= init_counter - 4'b1;
end

/* The number of clocks we must wait following a PRECHARGE ALL command */
reg [2:0] prechargeall_counter;
reg reload_prechargeall_counter;
wire prechargeall_done = (prechargeall_counter == 3'b0);
always @(posedge sdram_clk) begin
	if(reload_prechargeall_counter)
		prechargeall_counter <= 3'd4;
	else if(~prechargeall_done)
		prechargeall_counter <= prechargeall_counter - 3'b1;
end

/* The number of clocks we must wait following a PRECHARGE command */
reg [2:0] precharge_counter;
reg reload_precharge_counter;
wire precharge_done = (precharge_counter == 3'b0);
always @(posedge sdram_clk) begin
	if(reload_precharge_counter)
		precharge_counter <= 3'd4;
	else if(~precharge_done)
		precharge_counter <= precharge_counter - 3'b1;
end


/* The number of clocks we must wait following an AUTO REFRESH command */
reg [3:0] autorefresh_counter;
reg reload_autorefresh_counter;
wire autorefresh_done = (autorefresh_counter == 4'b0);
always @(posedge sdram_clk) begin
	if(reload_autorefresh_counter)
		autorefresh_counter <= 4'd9;
	else if(~autorefresh_done)
		autorefresh_counter <= autorefresh_counter - 4'b1;
end

/* The number of clocks we must wait following an ACTIVATE command.
 * This is the (in)famous CAS latency.
 */
reg [2:0] activate_counter;
reg reload_activate_counter;
wire activate_done = (activate_counter == 3'b0);
always @(posedge sdram_clk) begin
	if(reload_activate_counter)
		activate_counter <= 3'd2;
	else if(~activate_done)
		activate_counter <= activate_counter - 3'b1;
end

/* The number of clocks we have left before we must refresh one row in the SDRAM array. */
reg [11:0] refresh_counter;
reg reload_refresh_counter;
wire needs_refresh = (refresh_counter == 12'b0);
always @(posedge sdram_clk) begin
	if(reload_refresh_counter)
		/*
		 * The period between *each* AUTO REFRESH command, in clock cycles.
		 * Must be the refresh period divided by the number of cycles required
		 * to refresh the entire array.
		 * Typically 64ms divided by the number of rows, but check your SDRAM datasheet.
		 */
		refresh_counter <= 12'd740;
	else if(~needs_refresh)
		refresh_counter <= refresh_counter - 12'b1;
end

/* Keep track of the open row for each bank */
reg active0;
reg [sdram_rowdepth-1:0] openrow0;
reg active1;
reg [sdram_rowdepth-1:0] openrow1;
reg active2;
reg [sdram_rowdepth-1:0] openrow2;
reg active3;
reg [sdram_rowdepth-1:0] openrow3;

reg [sdram_rowdepth-1:0] track_row;
reg [1:0] track_bank;
reg track_open;
reg track_close;
reg track_closeall;

always @(posedge sdram_clk) begin
	if(track_closeall) begin
		active0 <= 1'b0;
		active1 <= 1'b0;
		active2 <= 1'b0;
		active3 <= 1'b0;
	end else begin
		if(track_close) begin
			case(track_bank)
				2'b00: active0 <= 1'b0;
				2'b01: active1 <= 1'b0;
				2'b10: active2 <= 1'b0;
				2'b11: active3 <= 1'b0;
			endcase
		end else if(track_open) begin
			case(track_bank)
				2'b00: begin
					active0 <= 1'b1;
					openrow0 <= track_row;
				end
				2'b01: begin
					active1 <= 1'b1;
					openrow1 <= track_row;
				end
				2'b10: begin
					active2 <= 1'b1;
					openrow2 <= track_row;
				end
				2'b11: begin
					active3 <= 1'b1;
					openrow3 <= track_row;
				end
			endcase
		end
	end
end

reg load_track_with_evict;
reg load_track_with_refill;
always @(posedge sdram_clk) begin
	if(load_track_with_evict) begin
		track_row <= evict_row;
		track_bank <= evict_bank;
	end
	if(load_track_with_refill) begin
		track_row <= refill_row;
		track_bank <= refill_bank;
	end
end

/* Check if we need to activate another row.
 * We add registers to improve timing (this is the critical path).
 */
wire evict_needs_rowswitch =
	 ((evict_bank == 2'b00) & ((openrow0 != evict_row) | ~active0))
	|((evict_bank == 2'b01) & ((openrow1 != evict_row) | ~active1))
	|((evict_bank == 2'b10) & ((openrow2 != evict_row) | ~active2))
	|((evict_bank == 2'b11) & ((openrow3 != evict_row) | ~active3));
reg evict_needs_rowswitch_r;
always @(posedge sdram_clk) evict_needs_rowswitch_r <= evict_needs_rowswitch;

wire refill_needs_rowswitch =
	 ((refill_bank == 2'b00) & ((openrow0 != refill_row) | ~active0))
	|((refill_bank == 2'b01) & ((openrow1 != refill_row) | ~active1))
	|((refill_bank == 2'b10) & ((openrow2 != refill_row) | ~active2))
	|((refill_bank == 2'b11) & ((openrow3 != refill_row) | ~active3));
reg refill_needs_rowswitch_r;
always @(posedge sdram_clk) refill_needs_rowswitch_r <= refill_needs_rowswitch;

/* Burst counter */
reg [3:0] burst_counter;
reg reload_burst_counter;
wire burst_finished = burst_counter[3];
wire burst_last = burst_counter[0] & burst_counter[1] & burst_counter[2];
reg [3:0] next_burst_counter;
always @(reload_burst_counter or burst_finished or burst_counter) begin
	if(reload_burst_counter)
		next_burst_counter <= 4'b0000;
	else if(~burst_finished)
		next_burst_counter <= burst_counter + 1'b1;
	else
		next_burst_counter <= burst_counter;
end
always @(posedge sdram_clk) burst_counter <= next_burst_counter;

/* Generate cache addresses */
reg load_cache_msb_evict;
reg load_cache_msb_refill;
reg [cache_depth-1:0] cache_adr_msb;
always @(posedge sdram_clk) begin
	if(load_cache_msb_evict) begin
    // synthesis translate_off
		$display("Reads from the cache begin at address %h", evict_adr[cache_depth-1:0]);
    // synthesis translate_on
		cache_adr_msb <= evict_adr[cache_depth-1:0];
	end else if(load_cache_msb_refill) begin
    // synthesis translate_off
		$display("Writes to the cache begin at address %h", refill_adr[cache_depth-1:0]);
    // synthesis translate_on
		cache_adr_msb <= refill_adr[cache_depth-1:0];
	end
end
assign cache_adr = {cache_adr_msb, next_burst_counter[2:1]};

/* Cache data */
assign cache_dat_o = {sdram_dq_in, sdram_dq_in};
assign sdram_dq_out = burst_counter[0] ? cache_dat_i[15:0] : cache_dat_i[31:16];

/* FSM that runs everything */
// synthesis translate_off
always @(posedge sdram_clk) begin
	if(command_evict) begin
		$display("EVICT  addr %b", evict_adr);
		$display("REFILL addr %b", refill_adr);
	end
	if(command_refill) $display("REFILL addr %b", refill_adr);
	if(command_ack)    $display("ACK    addr %b", refill_adr);
end
// synthesis translate_on

reg command_evict_pending;
reg command_refill_pending;
always @(posedge sdram_clk) begin
	if(sdram_rst | command_ack) begin
		command_evict_pending <= 1'b0;
		command_refill_pending <= 1'b0;
	end else begin
		if(command_evict) command_evict_pending <= 1'b1;
		if(command_refill) command_refill_pending <= 1'b1;
	end
end


//reg [4:0] state;
reg [4:0] next_state;

localparam
	RESET = 5'd0,
	
	INIT_PRECHARGEALL = 5'd1,
	INIT_AUTOREFRESH1 = 5'd2,
	INIT_AUTOREFRESH2 = 5'd3,
	INIT_LOADMODE = 5'd4,
	
	IDLE = 5'd5,
	
	PRECHARGE_BEFORE_REFRESH = 5'd6,
	AUTOREFRESH = 5'd7,
	WAIT_REFRESH = 5'd8,
	
	PRECHARGE_BEFORE_WRITE = 5'd9,
	ACTIVATE_BEFORE_WRITE = 5'd10,
	WRITE = 5'd11,
	WRITEBURST = 5'd12,
	
	PRECHARGE_BEFORE_READ = 5'd13,
	ACTIVATE_BEFORE_READ = 5'd14,
	READ = 5'd15,
	READREG1 = 5'd16,
	READREG2 = 5'd17,
	READREG3 = 5'd18,
	READFIRST = 5'd19,
	READBURST = 5'd20;

always @(posedge sdram_clk) begin
	if(sdram_rst) begin
		state <= RESET;
	end else begin
    // synthesis translate_off
		if(state != next_state) $display("state:%d->%d", state, next_state);
    // synthesis translate_on
		state <= next_state;
	end
end

always @(state
	or init_done or prechargeall_done or precharge_done or autorefresh_done or activate_done
	or evict_needs_rowswitch_r or refill_needs_rowswitch_r
	or needs_refresh or command_evict or command_refill or command_evict_pending or command_refill_pending
	or evict_bank or refill_bank
	or burst_last or burst_finished or burst_counter) begin
	next_state = state;

	/* Do nothing with the SDRAM by default */
	sdram_cke_r = 1'b1;
	sdram_cs_n_r = 1'b0;
	sdram_we_n_r = 1'b1;
	sdram_cas_n_r = 1'b1;
	sdram_ras_n_r = 1'b1;
	sdram_dqm_r = 1'b1;
	sdram_ba_r = 2'b00;
	sdram_dq_drive = 1'b0;
	adr_load_mode = 1'b0;
	adr_load_evictrow = 1'b0;
	adr_load_evictcolumn = 1'b0;
	adr_load_refillrow = 1'b0;
	adr_load_refillcolumn = 1'b0;
	adr_load_A10 = 1'b0;

	reload_init_counter = 1'b0;
	reload_prechargeall_counter = 1'b0;
	reload_precharge_counter = 1'b0;
	reload_autorefresh_counter = 1'b0;
	reload_activate_counter = 1'b0;
	reload_refresh_counter = 1'b0;
	
	track_open = 1'b0;
	track_close = 1'b0;
	track_closeall = 1'b0;
	load_track_with_evict = 1'b0;
	load_track_with_refill = 1'b0;
	
	/* Keep the burst counter in reset by default */
	reload_burst_counter = 1'b1;
	
	cache_we = 4'b0000;
	load_cache_msb_evict = 1'b0;
	load_cache_msb_refill = 1'b0;

	command_ack = 1'b0;
	
	case(state)
		default: begin // 0
			reload_init_counter = 1'b1;
			next_state = INIT_PRECHARGEALL;
		end
		
		/* Initialization */
		INIT_PRECHARGEALL: begin // 1
			if(init_done) begin
				/* Issue a PRECHARGE ALL command to the SDRAM array */
				sdram_cke_r = 1'b0;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = 2'b00;
				adr_load_A10 = 1'b1;
				
				track_closeall = 1'b1;
				reload_prechargeall_counter = 1'b1;
				next_state = INIT_AUTOREFRESH1;
			end
		end
		INIT_AUTOREFRESH1: begin // 2
			if(prechargeall_done) begin
				/* Issue a first AUTO REFRESH command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				
				reload_autorefresh_counter = 1'b1;
				next_state = INIT_AUTOREFRESH2;
			end
		end
		INIT_AUTOREFRESH2: begin // 3
			if(autorefresh_done) begin
				/* Issue a second AUTO REFRESH command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				
				reload_autorefresh_counter = 1'b1;
				next_state = INIT_LOADMODE;
			end
		end
		INIT_LOADMODE: begin // 4
			/* Load the Mode Register */
			if(autorefresh_done) begin
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = 2'b00;
				adr_load_mode = 1'b1;
				
				reload_refresh_counter = 1'b1;
				next_state = IDLE;
			end
		end
		
		IDLE: begin // 5
			if(needs_refresh) begin
				next_state = PRECHARGE_BEFORE_REFRESH;
			end else if(command_evict | command_evict_pending) begin
				/* prepare the read from the cache */
				load_cache_msb_evict = 1'b1;
				next_state = PRECHARGE_BEFORE_WRITE;
			end else if(command_refill | command_refill_pending) begin
				/* prepare the write to the cache */
				load_cache_msb_refill = 1'b1;
				next_state = PRECHARGE_BEFORE_READ;
			end
		end
		
		/* Refresh */
		PRECHARGE_BEFORE_REFRESH: begin // 6
				/* Issue a PRECHARGE ALL command to the SDRAM array */
				sdram_cke_r = 1'b0;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = 2'b00;
				adr_load_A10 = 1'b1;
				
				track_closeall = 1'b1;
				reload_prechargeall_counter = 1'b1;
				next_state = AUTOREFRESH;
		end
		AUTOREFRESH: begin // 7
			if(prechargeall_done) begin
				/* Issue an AUTO REFRESH command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				
				reload_autorefresh_counter = 1'b1;
				next_state = WAIT_REFRESH;
			end
		end
		WAIT_REFRESH: begin // 8
			if(autorefresh_done) begin
				reload_refresh_counter = 1'b1;
				next_state = IDLE;
			end
		end
		
		/* Write (evict) */
		PRECHARGE_BEFORE_WRITE: begin // 9
			/* prepare the update of the row tracker */
			load_track_with_evict = 1'b1;
			if(evict_needs_rowswitch_r) begin
				/* Issue a PRECHARGE BANK command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = evict_bank;
				
				reload_precharge_counter = 1'b1;
				next_state = ACTIVATE_BEFORE_WRITE;
			end else begin
				
				next_state = WRITE;
			end
		end
		ACTIVATE_BEFORE_WRITE: begin // 10
			if(precharge_done) begin
				/* Issue an ACTIVATE command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = evict_bank;
				adr_load_evictrow = 1'b1;

				/* update row tracking */
				track_open = 1'b1;
				
				reload_activate_counter = 1'b1;
				next_state = WRITE;
			end
		end
		WRITE: begin // 11
			if(activate_done) begin
				/* Issue a WRITE command to the SDRAM array, without auto precharge */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b1;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = evict_bank;
				adr_load_evictcolumn = 1'b1;
				sdram_dq_drive = 1'b1;
				
				reload_burst_counter = 1'b0;
				next_state = WRITEBURST;
			end
		end
		WRITEBURST: begin // 12
			reload_burst_counter = 1'b0;
			/* Now write the 7 other SDRAM words in a burst */
			if(burst_finished) begin
				/* We leave one idle cycle after the write,
				* check this meets write recovery time requirements for your SDRAM chip. */
				/* Evictions are automatically followed by refills. */
				/* prepare the write to the cache */
				load_cache_msb_refill = 1'b1;
				next_state = PRECHARGE_BEFORE_READ;
			end else begin
				sdram_dq_drive = 1'b1;
				sdram_dqm_r = 1'b0;
			end
		end
		
		/* Read (refill) */
		PRECHARGE_BEFORE_READ: begin // 13
			/* prepare the update of the row tracker */
			load_track_with_refill = 1'b1;
			if(refill_needs_rowswitch_r) begin
				/* Issue a PRECHARGE BANK command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b0;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = refill_bank;
				
				reload_precharge_counter = 1'b1;
				next_state = ACTIVATE_BEFORE_READ;
			end else
				next_state = READ;
		end
		ACTIVATE_BEFORE_READ: begin // 14
			if(precharge_done) begin
				/* Issue an ACTIVATE command to the SDRAM array */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b0;
				sdram_cas_n_r = 1'b1;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = refill_bank;
				adr_load_refillrow = 1'b1;

				/* update row tracking */
				track_open = 1'b1;
				
				reload_activate_counter = 1'b1;
				next_state = READ;
			end
		end
		READ: begin // 15
			if(activate_done) begin
				/* Issue a READ command to the SDRAM array, without auto precharge */
				sdram_cke_r = 1'b1;
				sdram_cs_n_r = 1'b0;
				sdram_ras_n_r = 1'b1;
				sdram_cas_n_r = 1'b0;
				sdram_we_n_r = 1'b1;
				sdram_dqm_r = 1'b0;
				sdram_ba_r = refill_bank;
				adr_load_refillcolumn = 1'b1;
				
				next_state = READREG1;
			end
		end
		READREG1: begin // 16
			/* I/Os are registered, so we must wait one cycle for the READ command to reach SDRAM */
			sdram_dqm_r = 1'b0;
			next_state = READREG2;
		end
		READREG2: begin // 17
			/* We must wait for the SDRAM to drive its DQ pins upon receiving the READ command */
			sdram_dqm_r = 1'b0;
			next_state = READREG3;
		end
		READREG3: begin // 18
			/* We must also wait for the first word of the burst sent by the SDRAM to reach our input register */
			sdram_dqm_r = 1'b0;
			next_state = READFIRST;
		end
		READFIRST: begin // 19
			cache_we = 4'b1100;
			sdram_dqm_r = 1'b0;
			next_state = READBURST;
		end
		READBURST: begin // 20
			reload_burst_counter = 1'b0; /* let the burst counter go up */
			if(burst_last) begin
				command_ack = 1'b1;
				next_state = IDLE;
			end else begin
				sdram_dqm_r = 1'b0;
				cache_we = {burst_counter[0], burst_counter[0], ~burst_counter[0], ~burst_counter[0]};
			end
		end
	endcase
end


endmodule
