/*
 *  LCD controller for VGA
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  VGA SDRAM support added by Charley Picker <charleypicker@yahoo.com>
 *
 *  Portions of code borrowed from Milkymist SoC  
 *  Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module vga_lcd_fml #(
    parameter fml_depth = 20  // 1MB Video Memory
)  (
    input clk,              // 100 Mhz clock
    input rst,

    input shift_reg1,       // if set: 320x200
    input graphics_alpha,   // if not set: 640x400 text mode

    // VGA LCD FML master interface
    output reg [fml_depth-1:0] fml_adr,
    output reg                 fml_stb,
    input                      fml_we,
    input                      fml_ack,
    output               [1:0] fml_sel,
    output              [15:0] fml_do,
    input               [15:0] fml_di,
    
    // VGA LCD Direct Cache Bus
	output reg                 dcb_stb,
	output     [fml_depth-1:0] dcb_adr,
	input               [15:0] dcb_dat,
	input                      dcb_hit,
	
    // attribute_ctrl
    input  [3:0] pal_addr,
    input        pal_we,
    output [7:0] pal_read,
    input  [7:0] pal_write,

    // dac_regs
    input        dac_we,
    input  [1:0] dac_read_data_cycle,
    input  [7:0] dac_read_data_register,
    output [3:0] dac_read_data,
    input  [1:0] dac_write_data_cycle,
    input  [7:0] dac_write_data_register,
    input  [3:0] dac_write_data,

    // VGA pad signals
    output [3:0] vga_red_o,
    output [3:0] vga_green_o,
    output [3:0] vga_blue_o,
    output       horiz_sync,
    output       vert_sync,
    
    // Base address of video memory
    input [fml_depth-1:0] baseaddress,

    // CRTC
    input [5:0] cur_start,
    input [5:0] cur_end,
    input [4:0] vcursor,
    input [6:0] hcursor,

    input [6:0] horiz_total,
    input [6:0] end_horiz,
    input [6:0] st_hor_retr,
    input [4:0] end_hor_retr,
    input [9:0] vert_total,
    input [9:0] end_vert,
    input [9:0] st_ver_retr,
    input [3:0] end_ver_retr,

    input x_dotclockdiv2,

    // retrace signals
    output v_retrace,
    output vh_retrace
  );

  // Registers and nets
  // Hookup crtc output stage to sequencer input stage 
  wire [9:0] h_count;   // Horizontal pipeline delay is 2 cycles
  wire horiz_sync_i;
  wire [9:0] v_count;   // 0 to VER_SCAN_END
  wire vert_sync_crtc_o;
  wire video_on_h_i;
  wire video_on_v;
    
  // Hookup sequencer output stage to fifo input stage 
  wire [11:0] fb_dat_i;
  wire horiz_sync_seq_o;
  wire vert_sync_seq_o;
  wire video_on_h_seq_o;
  wire video_on_v_seq_o;
  wire [7:0] character_seq_o;
  
  // Hookup fifo output stage to pal_dac input stage
  wire [11:0] fb_dat_o;
  wire fb_horiz_sync_seq_o;
  wire fb_vert_sync_seq_o;
  wire fb_video_on_h_seq_o;
  wire fb_video_on_v_seq_o;
  wire [7:0] fb_character_seq_o;
  
  // Pixel buffer control
  reg read_fifo;
  wire fill_fifo;
  // Number of words stored in the FIFO, 0-63 (64 possible values)
  wire [6:0] fifo_level;
    
  // Each stage is controlled by enable signals
  wire en_crtc;
  wire en_sequencer;
  wire en_pal_dac;
  
  reg next_crtc_seq_cyc;
  reg next_pal_dac_cyc;
  
  // Pixel clock counter 
  reg [1:0] pixel_clk_counter;
  
  // LCD FSM Registers
  reg fifo_source_cache;
  wire can_burst;
  wire [17:1] lcd_adr;
  wire lcd_stb;
      
  // Module instances
  vga_crtc_fml crtc (
    .clk (clk),              // 100 Mhz clock
    .rst (rst),
    
    .enable_crtc (en_crtc),
    
    // CRTC configuration signals
    
    .cur_start (cur_start),
    .cur_end (cur_end),
    .vcursor (vcursor),
    .hcursor (hcursor),

    .horiz_total (horiz_total),
    .end_horiz (end_horiz),
    .st_hor_retr (st_hor_retr),
    .end_hor_retr (end_hor_retr),
    .vert_total (vert_total),
    .end_vert (end_vert),
    .st_ver_retr (st_ver_retr),
    .end_ver_retr (end_ver_retr),
    
    // CRTC output signals
    
    .h_count (h_count),
    .horiz_sync_i (horiz_sync_i),
    
    .v_count (v_count),
    .vert_sync (vert_sync_crtc_o),
    
    .video_on_h_i (video_on_h_i),
    .video_on_v (video_on_v)
    
  );
  
  vga_sequencer_fml sequencer (
    .clk (clk),              // 100 Mhz clock
    .rst (rst),
    
    .enable_sequencer (en_sequencer),
    
    // Sequencer input signals
    
    .h_count (h_count),
    .horiz_sync_i (horiz_sync_i),
    
    .v_count (v_count),
    .vert_sync (vert_sync_crtc_o),
    
    .video_on_h_i (video_on_h_i),
    .video_on_v (video_on_v),
    
    // Sequencer configuration signals
    
    .shift_reg1 (shift_reg1),       // if set: 320x200
    .graphics_alpha (graphics_alpha),   // if not set: 640x400 text mode

    // CSR slave interface for reading
    .fml_adr_o (lcd_adr),
    .fml_dat_i (fifo_source_cache ? dcb_dat : fml_di),
    .fml_stb_o (lcd_stb),

    // CRTC
    .cur_start (cur_start),
    .cur_end (cur_end),
    .vcursor (vcursor),
    .hcursor (hcursor),

    .x_dotclockdiv2 (x_dotclockdiv2),
    
    // Sequencer output signals
    
    .horiz_sync_seq_o (horiz_sync_seq_o),
    .vert_sync_seq_o (vert_sync_seq_o),
    .video_on_h_seq_o (video_on_h_seq_o),
    .video_on_v_seq_o (video_on_v_seq_o),
    .character_seq_o (character_seq_o)  
    
  );
  
  // video-data buffer (temporary store data read from video memory)
  // We want to store at least one scan line (800 pixels x 12 bits per pixel) in the buffer
  vga_fifo #(6, 12) data_fifo (
    .clk    ( clk                ),
	.aclr   ( 1'b1               ),
	.sclr   ( rst                ),
	.d      ( fb_dat_i           ),
	.wreq   ( fill_fifo          ),
	.q      ( fb_dat_o           ),
	.rreq   ( read_fifo          ),
	.nword  ( fifo_level ),
	.empty  ( ),
	.full   ( ),
	.aempty ( ),
	.afull  ( )
  );
  
  vga_pal_dac_fml pal_dac (
    .clk (clk),              // 100 Mhz clock
    .rst (rst),
    
    .enable_pal_dac (en_pal_dac),
    
    // VGA PAL/DAC input signals
    
    .horiz_sync_pal_dac_i (fb_horiz_sync_seq_o),
    .vert_sync_pal_dac_i (fb_vert_sync_seq_o),
    .video_on_h_pal_dac_i (fb_video_on_h_seq_o),
    .video_on_v_pal_dac_i (fb_video_on_v_seq_o),
    .character_pal_dac_i (fb_character_seq_o),
    
    // VGA PAL/DAC configuration signals
    
    .shift_reg1 (shift_reg1),       // if set: 320x200
    .graphics_alpha (graphics_alpha),   // if not set: 640x400 text mode

    // attribute_ctrl
    .pal_addr (pal_addr),
    .pal_we (pal_we),
    .pal_read (pal_read),
    .pal_write (pal_write),

    // dac_regs
    .dac_we (dac_we),
    .dac_read_data_cycle (dac_read_data_cycle),
    .dac_read_data_register (dac_read_data_register),
    .dac_read_data (dac_read_data),
    .dac_write_data_cycle (dac_write_data_cycle),
    .dac_write_data_register (dac_write_data_register),
    .dac_write_data (dac_write_data),
    
    // VGA PAL/DAC output signals

    // VGA pad signals
    .vga_red_o (vga_red_o),
    .vga_green_o (vga_green_o),
    .vga_blue_o (vga_blue_o),
    .horiz_sync (horiz_sync),
    .vert_sync (vert_sync),

    // retrace signals
    .v_retrace (v_retrace),
    .vh_retrace (vh_retrace)
  );
  
  // Continuous assignments
  
  // The lcd is read only device and these control signals are not used
  assign fml_sel = 2'b11;
  assign fml_do = 16'b0;
  
  // Pack sequencer stage output into one wire group
  assign fb_dat_i = { horiz_sync_seq_o,
                      vert_sync_seq_o,
                      video_on_h_seq_o,
                      video_on_v_seq_o,
                      character_seq_o[7:0] };
  
  // Unpack fb_dat_o back into seperate wires
  assign fb_horiz_sync_seq_o = fb_dat_o [11];
  assign fb_vert_sync_seq_o = fb_dat_o [10];
  assign fb_video_on_h_seq_o = fb_dat_o [9];
  assign fb_video_on_v_seq_o = fb_dat_o [8];
  assign fb_character_seq_o = fb_dat_o [7:0];
  
  // Wait until the fifo level is 128 - 96 = 32 (enough room for a 11 pixel burst)
  assign can_burst = fifo_level <= 7'd32;
  
  // These signals enable and control when the next crtc/sequencer cycle should occur
  assign en_crtc = next_crtc_seq_cyc;
  assign en_sequencer = next_crtc_seq_cyc;
  
  // When the next_crtc_seq_cyc occurs we should place another pixel in fifo
  assign fill_fifo = next_crtc_seq_cyc;
  
  // This signal enables and controls when the next pal_dac cycle should occure
  assign en_pal_dac = next_pal_dac_cyc;  // 100 Mhz version
  
  // Behaviour
  
/* FML ADDRESS GENERATOR */
wire next_address;

always @(posedge clk) begin
	if(rst) begin
		fml_adr <= {fml_depth{1'b0}};
	end else begin
		if(next_address) begin
			fml_adr <= baseaddress + ({2'b0, lcd_adr, 1'b0});			
		end
	end
end

/* DCB ADDRESS GENERATOR */
reg [2:0] dcb_index;

always @(posedge clk) begin
	if(dcb_stb)
		dcb_index <= dcb_index + 3'd1;
	else
		dcb_index <= 3'd0;
end

assign dcb_adr = {fml_adr[fml_depth-1:3], dcb_index};

/* CONTROLLER */
reg [4:0] state;
reg [4:0] next_state;
  localparam [4:0]
    IDLE     = 5'd0,
    DELAY    = 5'b1,    
    TRYCACHE = 5'd2,
    CACHE1   = 5'd3,
    CACHE2   = 5'd4,
    CACHE3   = 5'd5,
    CACHE4   = 5'd6,
    CACHE5   = 5'd7,
    CACHE6   = 5'd8,
    CACHE7   = 5'd9,
    CACHE8   = 5'd10,
    FML1     = 5'd11,
    FML2     = 5'd12,
    FML3     = 5'd13,
    FML4     = 5'd14,
    FML5     = 5'd15,
    FML6     = 5'd16,
    FML7     = 5'd17,
    FML8     = 5'd18;

always @(posedge clk) begin
	if(rst)
	    state <= IDLE; 
	else
	    state <= next_state;
end

reg next_burst;

assign next_address = next_burst;

always @(*) begin
	next_state = state;
	
	next_crtc_seq_cyc = 1'b0;
	next_burst = 1'b0;
	
	fml_stb = 1'b0;
	
	dcb_stb = 1'b0;
	fifo_source_cache = 1'b0;
	
	case(state)
		IDLE: begin
		    if (can_burst) begin
		        if (lcd_stb) begin
		            /* LCD is requesting another fml burst ! */
				    next_burst = 1'b1;  // This also calculates final address
				    next_crtc_seq_cyc = 1'b1;
				    next_state = DELAY;
		        end else
		            next_crtc_seq_cyc = 1'b1;
		    end
		end
		DELAY: begin
		    next_crtc_seq_cyc = 1'b1;
		    next_state = TRYCACHE;
		end		
		/* Try to fetch from L2 first */
		TRYCACHE: begin
			dcb_stb = 1'b1;
			next_crtc_seq_cyc = 1'b1;			
			next_state = CACHE1;
		end
		CACHE1: begin
			fifo_source_cache = 1'b1;
			if(dcb_hit) begin
				dcb_stb = 1'b1;
				next_crtc_seq_cyc = 1'b1;
				next_state = CACHE2;
			end else
				next_state = FML1; /* Not in L2 cache, fetch from DRAM */
		end
		/* No need to check for cache hits anymore:
		 * - we fetched from the beginning of a line
		 * - we fetch exactly a line
		 * - we do not release dcb_stb so the cache controller locks the line
		 * Therefore, next 3 fetchs always are cache hits.
		 */
		CACHE2: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE3;
		end
		CACHE3: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE4;
		end
		CACHE4: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE5;
		end
		CACHE5: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE6;
		end
		CACHE6: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE7;
		end
		CACHE7: begin
			dcb_stb = 1'b1;
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = CACHE8;
		end
		CACHE8: begin
			fifo_source_cache = 1'b1;
			next_crtc_seq_cyc = 1'b1;
			next_state = IDLE;
		end
		FML1: begin
			fml_stb = 1'b1;
			if(fml_ack) begin
				next_crtc_seq_cyc = 1'b1;
				next_state = FML2;
 			end
		end
		FML2: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML3;
		end
		FML3: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML4;
		end
		FML4: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML5;
		end
		FML5: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML6;
		end
		FML6: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML7;
		end
		FML7: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = FML8;
		end
		FML8: begin
			next_crtc_seq_cyc = 1'b1;
			next_state = IDLE;
		end
	endcase
end  
  
  // Provide counter for pal_dac stage
  always @(posedge clk)
  if (rst)
    begin
      pixel_clk_counter <= 2'b00;
    end
  else
    begin
      if (pixel_clk_counter == 2'd01)  // Toggle read_fifo
		  read_fifo <= 1'b1;
		else read_fifo <= 1'b0;
		
		if (pixel_clk_counter == 2'd02)  // Toggle next_pal_dac_cyc
		  next_pal_dac_cyc <=1'b1;
		else next_pal_dac_cyc <= 1'b0;
		
		pixel_clk_counter <= pixel_clk_counter + 2'b01;  // Roll over every four cycles
		  
    end    
    
endmodule
