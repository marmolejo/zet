/*
 *  PAL/DAC controller for VGA
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

module vga_pal_dac_fml (
    input clk,              // 100 Mhz clock
    input rst,
    
    input enable_pal_dac,
    
    // VGA PAL/DAC input signals
    
    input        horiz_sync_pal_dac_i,
    input        vert_sync_pal_dac_i,
    input        video_on_h_pal_dac_i,
    input        video_on_v_pal_dac_i,
    input [7:0]  character_pal_dac_i,
    
    // VGA PAL/DAC configuration signals
    
    input shift_reg1,       // if set: 320x200
    input graphics_alpha,   // if not set: 640x400 text mode

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
    
    // VGA PAL/DAC output signals

    // VGA pad signals
    output reg [3:0] vga_red_o,
    output reg [3:0] vga_green_o,
    output reg [3:0] vga_blue_o,
    output reg       horiz_sync,
    output           vert_sync,

    // retrace signals
    output v_retrace,
    output vh_retrace
  );

  // Registers and nets
  wire       video_on_v;
  reg [1:0]  video_on_h_p;
  
  wire       video_on;

  wire [3:0] attr;
  wire [7:0] index;
  wire [7:0] index_pal;
  reg  [7:0] index_gm;

  wire video_on_h;

  reg [1:0] horiz_sync_p;
  
  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  // Module instances
  
  vga_palette_regs_fml palette_regs (
    .clk (clk),

    .attr  (attr),
    .index (index_pal),

    .address    (pal_addr),
    .write      (pal_we),
    .read_data  (pal_read),
    .write_data (pal_write)
  );

  vga_dac_regs_fml dac_regs (
    .clk (clk),

    .index (index),
    .red   (red),
    .green (green),
    .blue  (blue),

    .write (dac_we),

    .read_data_cycle    (dac_read_data_cycle),
    .read_data_register (dac_read_data_register),
    .read_data          (dac_read_data),

    .write_data_cycle    (dac_write_data_cycle),
    .write_data_register (dac_write_data_register),
    .write_data          (dac_write_data)
  );

  // Continuous assignments
  assign video_on_v   = video_on_v_pal_dac_i;
  assign vert_sync    = vert_sync_pal_dac_i;
  
  assign video_on     = video_on_h && video_on_v;
  
  assign attr  = character_pal_dac_i[3:0];
  assign index = (graphics_alpha & shift_reg1) ? index_gm : index_pal;

  assign video_on_h    = video_on_h_p[1];

  assign v_retrace   = !video_on_v;
  assign vh_retrace  = v_retrace | !video_on_h;

  // index_gm
  always @(posedge clk)
    if (rst)
      begin
        index_gm <= 8'h0;
      end
    else
      if (enable_pal_dac)
        begin
          index_gm <= character_pal_dac_i;
        end
  
  // Horiz sync
  always @(posedge clk)
    if (rst)
      begin
        { horiz_sync, horiz_sync_p } <= 3'b0;
      end
    else
      if (enable_pal_dac)
        begin
          { horiz_sync, horiz_sync_p } <= { horiz_sync_p[1:0], horiz_sync_pal_dac_i };    
        end
  
  // Video_on pipe
  always @(posedge clk)
    if (rst)
      begin
        video_on_h_p <= 2'b0;
      end
    else
      if (enable_pal_dac)
        begin
          video_on_h_p <= { video_on_h_p[0], video_on_h_pal_dac_i };
        end
  
  // Colour signals
  always @(posedge clk)
    if (rst)
      begin
        vga_red_o     <= 4'b0;
        vga_green_o   <= 4'b0;
        vga_blue_o    <= 4'b0;
      end
    else
      if (enable_pal_dac)
        begin
          vga_blue_o  <= video_on ? blue : 4'h0;
          vga_green_o <= video_on ? green : 4'h0;
          vga_red_o   <= video_on ? red : 4'h0;
        end

endmodule
