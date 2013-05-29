/*
 *  DUT VGA Address Generation
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  with modifications by Charley Picker <charleypicker@yahoo.com>
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

`timescale 1ns/10ps

module test_vga_address;

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
  wire        csr_stb_o;
  
  // FML slave interface for reading
  wire [17:1] fml_adr_o;
  reg  [15:0] fml_dat_i;
  wire        fml_stb_o;

  
  
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
  
  
  
  // Module instantiations
    vga_text_mode text_mode (
    .clk (clk_50),
    .rst (rst),
    
    .enable (enable_sequencer),

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
  
  vga_fml_text_mode fml_text_mode (
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
    
    .enable (enable_sequencer),

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
    
    .enable (enable_sequencer),

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
  always #10 clk_50 <= !clk_50;
  
  always @(posedge clk_50)
    if (rst)
      begin
        h_count      <= 10'b0;
        horiz_sync_i <= 1'b1;
        v_count      <= 10'b0;
        vert_sync    <= 1'b1;
        video_on_h_i <= 1'b1;
        video_on_v   <= 1'b1;
      end
    else
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
                
  // Initialize to a known state
  initial
    begin
      clk_50 <= 1'b0;  // at time 0
      rst <= 1'b1;      // reset is active
      
      enable_crtc <= 1'b1;       // Enable crtc
      enable_sequencer <= 1'b1;  // Enable sequencer
      
      // CRTC configuration signals
    
      cur_start    <= 5'd0;   // reg [5:0]   cur_start,
      cur_end      <= 5'd0;   // reg [5:0]   cur_end,
      vcursor      <= 4'd0;   // reg [4:0]   vcursor,
      hcursor      <= 6'd0;   // reg [6:0]   hcursor,

      horiz_total  <= 7'd639; // reg [6:0]   horiz_total,
      end_horiz    <= 7'd750; // reg [6:0]   end_horiz,
      // st_hor_retr  <= 7'd760; // reg [6:0]   st_hor_retr,
      st_hor_retr  <= 7'd656; // reg [6:0]   st_hor_retr,
      // end_hor_retr <= 5'd10;  // reg [4:0]   end_hor_retr,
      end_hor_retr <= 5'd752;  // reg [4:0]   end_hor_retr,
      vert_total   <= 10'd399; // reg [9:0]   vert_total,
      end_vert     <= 10'd550; // reg [9:0]   end_vert,
      st_ver_retr  <= 10'd560; // reg [9:0]   st_ver_retr,
      end_ver_retr <= 4'd10;  // reg [3:0]   end_ver_retr,
      
      x_dotclockdiv2 <= 1'b0;  // reg x_dotclockdiv2
      
      #20 rst <= 1'b0;  // at time 20 release reset
      
    end
  
  // Test how the csr text mode data is processed
  initial
    begin    
      // Initialize to zero just to be sure
      csr_dat_i      <= 16'b0;  // reg  [15:0] csr_dat_i;  
                  
      #130 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'hd, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
      #160 csr_dat_i <= { 8'h1, 8'h0 };
      #160 csr_dat_i <= { 8'h3, 8'h2 };
      #160 csr_dat_i <= { 8'h5, 8'h4 };
      #160 csr_dat_i <= { 8'h7, 8'h6 };
      
      #160 csr_dat_i <= { 8'h9, 8'h8 };
      #160 csr_dat_i <= { 8'hb, 8'ha };
      #160 csr_dat_i <= { 8'd5, 8'hc };
      #160 csr_dat_i <= { 8'hf, 8'he };
      
    
    end
    
  // Test how the fml text mode data is processed
  initial
    begin
      // Initialize to zero just to be sure
      fml_dat_i      <= 16'b0;  // reg  [15:0] csr_dat_i;
      
      #90 fml_dat_i <= { 8'h1, 8'h0 };
      #20 fml_dat_i <= { 8'h3, 8'h2 };
      #20 fml_dat_i <= { 8'h5, 8'h4 };
      #20 fml_dat_i <= { 8'h7, 8'h6 };
      
      #20 fml_dat_i <= { 8'h9, 8'h8 };
      #20 fml_dat_i <= { 8'hb, 8'ha };
      #20 fml_dat_i <= { 8'hd, 8'hc };
      #20 fml_dat_i <= { 8'hf, 8'he };      
    end

endmodule