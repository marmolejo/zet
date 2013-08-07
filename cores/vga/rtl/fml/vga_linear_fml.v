/*
 *  Linear mode graphics for VGA
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module vga_linear_fml (
    input clk,
    input rst,
    
    input enable,

    // CSR slave interface for reading
    output [17:1] fml_adr_o,
    input  [15:0] fml_dat_i,
    output        fml_stb_o,

    input [9:0] h_count,
    input [9:0] v_count,
    input       horiz_sync_i,
    input       video_on_h_i,
    output      video_on_h_o,

    output [7:0] color,
    output       horiz_sync_o
  );

  // Registers
  reg [ 9:0] row_addr;
  reg [ 6:0] col_addr;
  reg [14:1] word_offset;
  reg [ 1:0] plane_addr;
  reg [ 1:0] plane_addr0;
  reg [ 7:0] color_l;
  
  reg  [ 15:0] fml1_dat;
  reg  [ 15:0] fml2_dat;
  reg  [ 15:0] fml3_dat;
  reg  [ 15:0] fml4_dat;
  reg  [ 15:0] fml5_dat;
  reg  [ 15:0] fml6_dat;
  reg  [ 15:0] fml7_dat;
  
  reg [4:0] video_on_h;
  reg [4:0] horiz_sync;
  reg [18:0] pipe;  

  // Continous assignments  
  assign fml_adr_o = { 1'b0, word_offset, plane_addr };
  assign fml_stb_o = pipe[1];
  
  assign color = pipe[4] ? fml_dat_i[7:0] : color_l;    
  
  assign video_on_h_o = video_on_h[4];
  assign horiz_sync_o = horiz_sync[4];

  // Behaviour
  // FML 8x16 pipeline count
  always @(posedge clk)
    if (rst)
      begin
        pipe <= 18'b0;    
      end
    else
      if (enable)
        begin
          pipe <= { pipe[17:0], (h_count[3:0]==4'h0) };
        end

  // Load FML 8x16 burst
  always @(posedge clk)
    if (enable)
      begin
        fml1_dat <= pipe[5]  ? fml_dat_i[15:0] : fml1_dat;
        fml2_dat <= pipe[6]  ? fml_dat_i[15:0] : fml2_dat;
        fml3_dat <= pipe[7]  ? fml_dat_i[15:0] : fml3_dat;
        fml4_dat <= pipe[8]  ? fml_dat_i[15:0] : fml4_dat;
        fml5_dat <= pipe[9]  ? fml_dat_i[15:0] : fml5_dat;
        fml6_dat <= pipe[10] ? fml_dat_i[15:0] : fml6_dat;
        fml7_dat <= pipe[11] ? fml_dat_i[15:0] : fml7_dat;
      end

  // video_on_h
  always @(posedge clk)
    if (rst)
      begin
        video_on_h <= 5'b0;
      end
    else
      if (enable)
        begin
          video_on_h <= { video_on_h[3:0], video_on_h_i };
        end

  // horiz_sync
  always @(posedge clk)
    if (rst)
      begin
        horiz_sync <= 5'b0;
      end
    else
      if (enable)
        begin
          horiz_sync <= { horiz_sync[3:0], horiz_sync_i };
        end

  // Address generation
  always @(posedge clk)
    if (rst)
      begin
        row_addr    <= 10'h0;
        col_addr    <= 7'h0;
        plane_addr0 <= 2'b00;
        word_offset <= 14'h0;
        plane_addr  <= 2'b00;
      end
    else
      if (enable)
        begin
          // Loading new row_addr and col_addr when h_count[3:0]==4'h0
          // v_count * 5 * 32
          row_addr    <= { v_count[8:1], 2'b00 } + v_count[8:1];
          col_addr    <= h_count[9:3];
          plane_addr0 <= h_count[2:1];

          word_offset <= { row_addr + col_addr[6:4], col_addr[3:0] };
          plane_addr  <= plane_addr0;
        end
 
 // color_l
  always @(posedge clk)
    if (rst)
      begin
        color_l <= 8'h0;
      end
    else
      if (enable)
        begin
          if (pipe[4])
            color_l <= fml_dat_i[7:0];
          else
          if (pipe[5])
            color_l <= fml_dat_i[7:0];
          else
          if (pipe[7])
            color_l <= fml2_dat[7:0];
          else
          if (pipe[9])
            color_l <= fml3_dat[7:0];
          else
          if (pipe[11])
            color_l <= fml4_dat[7:0];
          else
          if (pipe[13])
            color_l <= fml5_dat[7:0];
          else
          if (pipe[15])
            color_l <= fml6_dat[7:0];
          else
          if (pipe[17])
            color_l <= fml7_dat[7:0];
        end

endmodule
