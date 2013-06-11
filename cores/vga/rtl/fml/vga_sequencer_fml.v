/*
 *  Sequencer controller for VGA
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

module vga_sequencer_fml (
    input clk,              // 100 Mhz clock
    input rst,
    
    input enable_sequencer,
    
    // Sequencer input signals
    
    input [9:0]   h_count,
    input         horiz_sync_i,
    
    input  [9:0]  v_count,
    input         vert_sync,
    
    input         video_on_h_i,
    input         video_on_v,
    
    // Sequencer configuration signals
    
    input shift_reg1,       // if set: 320x200
    input graphics_alpha,   // if not set: 640x400 text mode

    // CSR slave interface for reading
    output [17:1] fml_adr_o,
    input  [15:0] fml_dat_i,
    output        fml_stb_o,

    // CRTC
    input [5:0] cur_start,
    input [5:0] cur_end,
    input [4:0] vcursor,
    input [6:0] hcursor,

    input x_dotclockdiv2,
    
    // Sequencer output signals
    
    output        horiz_sync_seq_o,
    output        vert_sync_seq_o,
    output        video_on_h_seq_o,
    output        video_on_v_seq_o,
    output [7:0]  character_seq_o  
    
  );

  // Registers and nets  
  reg  [1:0]  video_on_h_p;
    
  wire [3:0]  attr_wm;
  wire [3:0]  attr_tm;
  wire [7:0]  color;
  
  wire        video_on_h_tm;
  wire        video_on_h_wm;
  wire        video_on_h_gm;
  wire        video_on_h;
  
  wire        horiz_sync_tm;
  wire        horiz_sync_wm;
  wire        horiz_sync_gm;

  wire [16:1] csr_tm_adr_o;
  wire        csr_tm_stb_o;
  wire [17:1] csr_wm_adr_o;
  wire        csr_wm_stb_o;
  wire [17:1] csr_gm_adr_o;
  wire        csr_gm_stb_o;
  wire        fml_stb_o_tmp;
  
  // Module instances
  vga_text_mode_fml text_mode (
    .clk (clk),
    .rst (rst),
    
    .enable (enable_sequencer),

    // CSR slave interface for reading
    .fml_adr_o (csr_tm_adr_o),
    .fml_dat_i (fml_dat_i),
    .fml_stb_o (csr_tm_stb_o),

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

  vga_planar_fml planar (
    .clk (clk),
    .rst (rst),
    
    .enable (enable_sequencer),

    // CSR slave interface for reading
    .fml_adr_o (csr_wm_adr_o),
    .fml_dat_i (fml_dat_i),
    .fml_stb_o (csr_wm_stb_o),

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

  vga_linear_fml linear (
    .clk (clk),
    .rst (rst),
    
    .enable (enable_sequencer),

    // CSR slave interface for reading
    .fml_adr_o (csr_gm_adr_o),
    .fml_dat_i (fml_dat_i),
    .fml_stb_o (csr_gm_stb_o),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (video_on_h_gm),

    .color        (color),
    .horiz_sync_o (horiz_sync_gm)
  );

  // Continuous assignments
  assign video_on_h   = video_on_h_p[1];
  
  assign fml_adr_o = graphics_alpha ?
    (shift_reg1 ? csr_gm_adr_o : csr_wm_adr_o) : { 1'b0, csr_tm_adr_o };

  assign fml_stb_o_tmp = graphics_alpha ?
    (shift_reg1 ? csr_gm_stb_o : csr_wm_stb_o) : csr_tm_stb_o;
  assign fml_stb_o     = fml_stb_o_tmp & (video_on_h_i | video_on_h) & video_on_v;
  
  // Video mode sequencer horiz_sync that will be passed to next stage
  assign horiz_sync_seq_o = graphics_alpha ?
    (shift_reg1 ? horiz_sync_gm : horiz_sync_wm) : horiz_sync_tm;
    
  // Pass through vert_sync to next stage
  assign vert_sync_seq_o = vert_sync;
  
  // Video mode sequencer video_on_h that will be passed to next stage
  assign video_on_h_seq_o = graphics_alpha ?
    (shift_reg1 ? video_on_h_gm : video_on_h_wm) : video_on_h_tm;
  
  // Pass through video_on_v to next stage
  assign video_on_v_seq_o = video_on_v;
  
  // Video mode sequencer character that will be passed to next stage
  assign character_seq_o = graphics_alpha ?
    (shift_reg1 ? color : { 4'b0, attr_wm }) : { 4'b0, attr_tm };
    
  // Video_on pipe used only for video_on_h signal 
  always @(posedge clk)
    if (rst)
      begin
        video_on_h_p <= 2'b0;
      end
    else
      if (enable_sequencer)
        begin
          video_on_h_p <= { video_on_h_p[0],
            graphics_alpha ? (shift_reg1 ? video_on_h_gm : video_on_h_wm)
                           : video_on_h_tm };  
        end
    
endmodule
