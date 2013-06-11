/*
 *  Planar mode graphics for VGA
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

module vga_planar_fml (
    input clk,
    input rst,
    
    input enable,

    // CSR slave interface for reading
    output [17:1] fml_adr_o,
    input  [15:0] fml_dat_i,
    output        fml_stb_o,

    // Controller registers
    input [3:0] attr_plane_enable,
    input       x_dotclockdiv2,

    input [9:0] h_count,
    input [9:0] v_count,
    input       horiz_sync_i,
    input       video_on_h_i,
    output      video_on_h_o,

    output reg [3:0] attr,
    output           horiz_sync_o
  );

  // Registers and net
  reg [11:0] row_addr;
  reg [ 5:0] col_addr;
  reg [14:0] word_offset;
  reg [ 1:0] plane_addr0;
  reg [ 1:0] plane_addr;
  reg [15:0] plane0;
  reg [15:0] plane0_tmp;
  reg [15:0] plane1;
  reg [15:0] plane1_tmp;
  reg [15:0] plane2;
  reg [15:0] plane2_tmp;
  reg [15:0] plane3;
  reg [ 7:0] bit_mask0;
  reg [ 7:0] bit_mask1;

  wire [15:0] bit_mask;
  wire        v_count0;

  wire bit3, bit2, bit1, bit0;

  reg [9:0] video_on_h;
  reg [9:0] horiz_sync;
  reg [7:0] pipe;

  // Continous assignments
  assign fml_adr_o = { plane_addr, word_offset };
  assign bit_mask  = { bit_mask1, bit_mask0 };

  assign bit0 = |(bit_mask & plane0);
  assign bit1 = |(bit_mask & plane1);
  assign bit2 = |(bit_mask & plane2);
  assign bit3 = |(bit_mask & plane3);

  assign video_on_h_o = video_on_h[9];
  assign horiz_sync_o = horiz_sync[9];
  assign fml_stb_o    = |pipe[4:1];
  assign v_count0     = x_dotclockdiv2 ? 1'b0 : v_count[0];

  // Behaviour
  // Pipeline count
  always @(posedge clk)
    if (rst)
      begin
        pipe <= 8'b0;
      end
    else
      if (enable)
        begin
          pipe <= { pipe[6:0],
            x_dotclockdiv2 ? (h_count[4:0]==5'h0) : (h_count[3:0]==4'h0) };    
        end
  
  // video_on_h
  always @(posedge clk)
    if (rst)
      begin
        video_on_h <= 10'b0;
      end
    else
      if (enable)
        begin
          video_on_h <= { video_on_h[8:0], video_on_h_i };
        end
  
  // horiz_sync
  always @(posedge clk)
    if (rst)
      begin
        horiz_sync <= 10'b0;
      end
    else
      if (enable)
        begin
          horiz_sync <= { horiz_sync[8:0], horiz_sync_i };
        end
  
  // Address generation
  always @(posedge clk)
    if (rst)
      begin
        row_addr    <= 12'h0;
        col_addr    <= 6'h0;
        plane_addr0 <= 2'b00;
        word_offset <= 15'h0;
        plane_addr  <= 2'b00;
      end
    else
      if (enable)
        begin
          // Loading new row_addr and col_addr when h_count[3:0]==4'h0
          // v_count * 40 or 22 (depending on x_dotclockdiv2)
          row_addr <= { v_count[9:1], v_count0, 2'b00 } + { v_count[9:1], v_count0 }
                    + (x_dotclockdiv2 ? v_count[9:1] : 9'h0);
          col_addr <= x_dotclockdiv2 ? h_count[9:5] : h_count[9:4];
          plane_addr0 <= h_count[1:0];

          // Load new word_offset at +1
          word_offset <= (x_dotclockdiv2 ? { row_addr, 1'b0 }
                                         : { row_addr, 3'b000 }) + col_addr;
          plane_addr  <= plane_addr0;
        end
      
  // Temporary plane data
  always @(posedge clk)
    if (rst)
      begin
        plane0_tmp <= 16'h0;
        plane1_tmp <= 16'h0;
        plane2_tmp <= 16'h0;
      end
    else
      if (enable)
        begin
          // Load plane0 when pipe == 4
          plane0_tmp <= pipe[4] ? fml_dat_i : plane0_tmp;
          plane1_tmp <= pipe[5] ? fml_dat_i : plane1_tmp;
          plane2_tmp <= pipe[6] ? fml_dat_i : plane2_tmp;    
        end

  // Plane data
  always @(posedge clk)
    if (rst)
      begin
        plane0 <= 16'h0;
        plane1 <= 16'h0;
        plane2 <= 16'h0;
        plane3 <= 16'h0;
      end
    else
      if (enable)        
        begin
          plane0 <= pipe[7] ? plane0_tmp : plane0;
          plane1 <= pipe[7] ? plane1_tmp : plane1;
          plane2 <= pipe[7] ? plane2_tmp : plane2;
          plane3 <= pipe[7] ? fml_dat_i : plane3;
        end

  // Bit masks
  always @(posedge clk)
    if (rst)
      begin
        bit_mask0 <= 8'h0;
        bit_mask1 <= 8'h0;
      end
    else
      if (enable)    
        begin
          bit_mask0 <= (h_count[0] & x_dotclockdiv2) ? bit_mask0
                     : { pipe[7], bit_mask0[7:1] };
          bit_mask1 <= (h_count[0] & x_dotclockdiv2) ? bit_mask1
                     : { bit_mask0[0], bit_mask1[7:1] };
        end

  // attr
  always @(posedge clk)
    if (rst)
      begin
        attr <= 4'h0; 
      end
    else
      if (enable)
        begin
          attr <= (attr_plane_enable & { bit3, bit2, bit1, bit0 });
        end  

endmodule
