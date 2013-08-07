/*
 *  DUT VGA Address Generation
 *
 *  VGA FML support
 *  Copyright (C) 2013 Charley Picker <charleypicker@yahoo.com>
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

//`timescale 1ns/10ps
`timescale 1ns/1ps

module tb_vga_address;

  // Registers and nets
  reg       clk_50;
  reg       rst;
  
  reg       enable_sequencer;
  reg       enable_crtc;
    
  // Sequencer input signals
    
  reg [9:0]   h_count;
  reg         horiz_sync_i;
    
  reg [9:0]  v_count;
  reg        vert_sync;
    
  reg        video_on_h_i;
  reg        video_on_v;
  
  // CRTC configuration signals
    
  reg [5:0]   cur_start;
  reg [5:0]   cur_end;
  reg [4:0]   vcursor;
  reg [6:0]   hcursor;

  reg [6:0]   horiz_total;
  reg [6:0]   end_horiz;
  reg [6:0]   st_hor_retr;
  reg [4:0]   end_hor_retr;
  reg [9:0]   vert_total;
  reg [9:0]   end_vert;
  reg [9:0]   st_ver_retr;
  reg [3:0]   end_ver_retr;
  
  reg x_dotclockdiv2;
    
  // CSR slave interface for reading
  wire [17:1] csr_adr_o;
  reg  [15:0] csr_dat_i;
  reg         csr_ack;
  wire        csr_stb_o;
  
  // FML slave interface for reading
  wire [17:1] fml_adr_o;
  reg  [15:0] fml_dat_i;
  wire        fml_stb_o;
  reg         fml_ack;
  wire        fml_we = 1'b0;
  wire        fml_dw = 16'h1234;
  
  wire [3:0]  attr_wm;
  wire [3:0]  attr_tm;
  wire [3:0]  fml_attr_tm;
  wire [7:0]  color;
  
  wire        video_on_h_tm;
  wire        fml_video_on_h_tm;
  wire        video_on_h_wm;
  wire        video_on_h_gm;
    
  wire        horiz_sync_tm;
  wire        fml_horiz_sync_tm;
  wire        horiz_sync_wm;
  wire        horiz_sync_gm;

  wire [16:1] csr_tm_adr_o;
  wire        csr_tm_stb_o;
  wire [16:1] fml_csr_tm_adr_o;
  wire        fml_csr_tm_stb_o;
  wire [17:1] csr_wm_adr_o;
  wire        csr_wm_stb_o;
  wire [17:1] csr_gm_adr_o;
  wire        csr_gm_stb_o;
  
  wire [9:0] hor_disp_end;
  wire [9:0] hor_scan_end;
  wire [9:0] ver_disp_end;
  wire [9:0] ver_sync_beg;
  wire [3:0] ver_sync_end;
  wire [9:0] ver_scan_end;
  
  /* Process FML requests */
  reg [2:0] fml_wcount;
  reg [2:0] fml_rcount;
  reg [3:0] fml_pipe;
  initial begin
	  fml_ack = 1'b0;
	  fml_wcount = 0;
	  fml_rcount = 0;
  end
  
  always @(posedge clk_50)
    fml_pipe <= rst ? 4'b0 : { fml_pipe[2:0], fml_csr_tm_stb_o };

  always @(posedge clk_50) begin
	  if(fml_pipe[1] & (fml_wcount == 0) & (fml_rcount == 0)) begin
		  fml_ack <= 1'b1;
		  if(fml_we) begin
			  //$display("%t FML W addr %x data %x", $time, fml_csr_tm_adr_o, fml_dw);
			  fml_wcount <= 7;
		  end else begin
			  fml_dat_i = 16'hbeef;
			  //$display("%t FML R addr %x data %x", $time, fml_csr_tm_adr_o, fml_dat_i);
			  fml_rcount <= 7;
		  end
	  end else
		  fml_ack <= 1'b0;
	  if(fml_wcount != 0) begin
		  //#1 $display("%t FML W continuing %x / %d", $time, fml_dw, fml_wcount);
		  fml_wcount <= fml_wcount - 1;
	  end
	  if(fml_rcount != 0) begin
		  fml_dat_i = #1 {13'h1eba, fml_rcount};
		  //$display("%t FML R continuing %x / %d", $time, fml_dat_i, fml_rcount);
		  fml_rcount <= fml_rcount - 1;
	  end
  end
  
  /* Process CSR requests */
  reg [15:0] csr_dat;
  reg [2:0] csr_rcount;
  reg [3:0] csr_pipe;
  initial begin
	  csr_ack = 1'b0;	  
	  csr_rcount = 0;
  end
  
  always @(posedge clk_50)
    csr_pipe <= rst ? 4'b0 : { csr_pipe[2:0], csr_tm_stb_o };

  always @(posedge clk_50) begin
    //if (csr_tm_stb_o)
      //$display("%t CSR R addr %x", $time, csr_tm_adr_o);
    if (csr_pipe[1] & (csr_rcount == 0))
         begin
           csr_ack <= 1'b1;
		       csr_dat_i = 16'hbeef;
			     //$display("%t CSR R data %x", $time, csr_dat_i);
			     csr_rcount <= 7;
		     end else
		         csr_ack <= 1'b0;		
	  if(csr_pipe[1] & (csr_rcount != 0)) begin
		         csr_dat_i = #1 {13'h1eba, csr_rcount};
		         //$display("%t CSR R continuing %x / %d", $time, csr_dat_i, csr_rcount);
		         csr_rcount <= csr_rcount - 1;
	  end	  
  end
  
  // Module instantiations
    vga_text_mode text_mode (
    .clk (clk_50),
    .rst (rst),
    
    //.enable (enable_sequencer),

    // CSR slave interface for reading
    .csr_adr_o (csr_tm_adr_o),
    .csr_dat_i (csr_dat_i),
    .csr_stb_o (csr_tm_stb_o),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (video_on_h_tm),

    .cur_start  (cur_start),
    .cur_end    (cur_end),
    .vcursor    (vcursor),
    .hcursor    (hcursor),

    .attr         (attr_tm),
    .horiz_sync_o (horiz_sync_tm)
  );
  
  vga_text_mode_fml text_mode_fml (
    .clk (clk_50),
    .rst (rst),
    
    .enable (enable_sequencer),

    // CSR slave interface for reading
    .fml_adr_o (fml_csr_tm_adr_o),
    .fml_dat_i (fml_dat_i),
    .fml_stb_o (fml_csr_tm_stb_o),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (fml_video_on_h_tm),

    .cur_start  (cur_start),
    .cur_end    (cur_end),
    .vcursor    (vcursor),
    .hcursor    (hcursor),

    .attr         (fml_attr_tm),
    .horiz_sync_o (fml_horiz_sync_tm)
  );
    
  vga_planar planar (
    .clk (clk_50),
    .rst (rst),
    
    //.enable (enable_sequencer),

    // CSR slave interface for reading
    .csr_adr_o (csr_wm_adr_o),
    .csr_dat_i (csr_dat_i),
    .csr_stb_o (csr_wm_stb_o),

    .attr_plane_enable (4'hf),
    .x_dotclockdiv2    (x_dotclockdiv2),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (video_on_h_wm),

    .attr         (attr_wm),
    .horiz_sync_o (horiz_sync_wm)
  );

  vga_linear linear (
    .clk (clk_50),
    .rst (rst),
    
    //.enable (enable_sequencer),

    // CSR slave interface for reading
    .csr_adr_o (csr_gm_adr_o),
    .csr_dat_i (csr_dat_i),
    .csr_stb_o (csr_gm_stb_o),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (video_on_h_gm),

    .color        (color),
    .horiz_sync_o (horiz_sync_gm)
  );
  
  // Continuous assignments
  // assign hor_scan_end = { horiz_total[6:2] + 1'b1, horiz_total[1:0], 3'h7 };
  assign hor_scan_end = 10'd799;
  
  // assign hor_disp_end = { end_horiz, 3'h7 };
  assign hor_disp_end = 10'd639;
  
  // assign ver_scan_end = vert_total + 10'd1;
  assign ver_scan_end = 10'd448;
  
  // assign ver_disp_end = end_vert + 10'd1;
  assign ver_disp_end = 10'd400;
  
  assign ver_sync_beg = st_ver_retr;
    
  assign ver_sync_end = end_ver_retr + 4'd1;
    
  // Behaviour
  // Clock generation
  //always #10 clk_50 <= !clk_50;
  initial clk_50 = 1'b0;
  always #5 clk_50 = ~clk_50;
  
task waitclock;
begin
	@(posedge clk_50);
	#1;
end
endtask

task resetpixel;
begin
  h_count      = 10'b0;
  horiz_sync_i = 1'b1;
  v_count      = 10'b0;
  vert_sync    = 1'b1;
  video_on_h_i = 1'b1;
  video_on_v   = 1'b1;
  $display("Pixel counter reset to zero");
end
endtask

task nextpixel;
begin
  if (enable_crtc)
      begin
        h_count      <= (h_count==hor_scan_end) ? 10'b0 : h_count + 10'b1;
        horiz_sync_i <= horiz_sync_i ? (h_count[9:3]!=st_hor_retr)
                                     : (h_count[7:3]==end_hor_retr);
        v_count      <= (v_count==ver_scan_end && h_count==hor_scan_end) ? 10'b0
                      : ((h_count==hor_scan_end) ? v_count + 10'b1 : v_count);
        vert_sync    <= vert_sync ? (v_count!=ver_sync_beg)
                                  : (v_count[3:0]==ver_sync_end);

        video_on_h_i <= (h_count==hor_scan_end) ? 1'b1
                      : ((h_count==hor_disp_end) ? 1'b0 : video_on_h_i);
        video_on_v   <= (v_count==10'h0) ? 1'b1
                      : ((v_count==ver_disp_end) ? 1'b0 : video_on_v);
      end
  waitclock;
  //$display("h_count = %d, v_count = %d", h_count, v_count);
end    
endtask
  
always begin
  // Initialize to a known state
  rst = 1'b1;  // reset is active  
  resetpixel;  // Reset pixel counter
  enable_crtc = 1'b0;  // Make sure the crtc is not active
  enable_sequencer = 1'b0; // Make sure sequencer is not active
      
  waitclock;  
    
  rst = 1'b0;
  
  enable_crtc = 1'b1;       // Enable crtc
  enable_sequencer = 1'b1;  // Enable sequencer  
  
  waitclock;
      
  // CRTC configuration signals
    
  cur_start    = 5'd0;   // reg [5:0]   cur_start,
  cur_end      = 5'd0;   // reg [5:0]   cur_end,
  vcursor      = 4'd0;   // reg [4:0]   vcursor,
  hcursor      = 6'd0;   // reg [6:0]   hcursor,

  horiz_total  = 7'd639; // reg [6:0]   horiz_total,
  end_horiz    = 7'd750; // reg [6:0]   end_horiz,
  // st_hor_retr  = 7'd760; // reg [6:0]   st_hor_retr,
  st_hor_retr  = 7'd656; // reg [6:0]   st_hor_retr,
  // end_hor_retr = 5'd10;  // reg [4:0]   end_hor_retr,
  end_hor_retr = 5'd752;  // reg [4:0]   end_hor_retr,
  vert_total   = 10'd399; // reg [9:0]   vert_total,
  end_vert     = 10'd550; // reg [9:0]   end_vert,
  st_ver_retr  = 10'd560; // reg [9:0]   st_ver_retr,
  end_ver_retr = 4'd10;  // reg [3:0]   end_ver_retr,
      
  x_dotclockdiv2 = 1'b0;  // reg x_dotclockdiv2
      
  //waitclock;
  
  // Total number of pixels to check
  repeat (1000) begin
    begin
      if (attr_tm != fml_attr_tm) begin        
        $display("Attributes attr_tm = %x and fml_attr_tm = %x did not match at (h_count = %d and v_count = %d) at time index %t" , attr_tm, fml_attr_tm, h_count, v_count, $time);        
      end
      if (csr_tm_adr_o != fml_csr_tm_adr_o) begin
        $display("Address csr_tm_adr_o = %x and fml_csr_tm_adr_o = %x did not match at (h_count = %d and v_count = %d) at time index %t" , csr_tm_adr_o, fml_csr_tm_adr_o, h_count, v_count, $time);        
      end
      if (video_on_h_tm != fml_video_on_h_tm) begin
        $display("Video_on_h video_on_h_tm = %x and fml_video_on_h_tm = %x did not match at (h_count = %d and v_count = %d) at time index %t" , csr_tm_adr_o, fml_video_on_h_tm, h_count, v_count, $time);
      end
      if (horiz_sync_tm != fml_horiz_sync_tm) begin
        $display("Horiz_sync horiz_sync_tm = %x and fml_horiz_sync_tm = %x did not match at (h_count = %d and v_count = %d) at time index %t" , horiz_sync_tm, fml_horiz_sync_tm, h_count, v_count, $time);
      end
    end
    nextpixel;
  end  
  
  $stop;
      
end  

endmodule