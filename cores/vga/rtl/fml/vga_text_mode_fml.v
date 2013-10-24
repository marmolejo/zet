/*
 *  Text mode graphics for VGA
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

/*
 * Pipeline description
 *  h_count[3:0]
 *   000
 *   001  col_addr, row_addr
 *   010  ver_addr, hor_addr
 *   011  csr_adr_o
 *   100  csr_adr_i
 *   101  sram_addr_
 *   110  csr_dat_o
 *   111  char_data_out, attr_data_out
 *   000  vga_shift
 *   001  vga_blue_o <= vga_shift[7]
 */

module vga_text_mode_fml (
    input clk,
    input rst,
    
    input enable,

    // CSR slave interface for reading
    output reg [16:1] fml_adr_o,
    input      [15:0] fml_dat_i,
    output            fml_stb_o,

    input [9:0] h_count,
    input [9:0] v_count,
    input       horiz_sync_i,
    input       video_on_h_i,
    output      video_on_h_o,

    // CRTC
    input [5:0] cur_start,
    input [5:0] cur_end,
    input [4:0] vcursor,
    input [6:0] hcursor,

    output reg [3:0] attr,
    output           horiz_sync_o
  );

  // Registers and nets
  reg  [ 6:0] col_addr;
  reg  [ 4:0] row_addr;
  reg  [ 6:0] hor_addr;
  reg  [ 6:0] ver_addr;
  wire [10:0] vga_addr;

  reg  [ 15:0] fml1_dat;

  wire [11:0] char_addr;
  wire [ 7:0] char_data_out;
  reg  [ 7:0] attr_data_out;
  reg  [ 7:0] char_addr_in;

  reg  [15:0] pipe;
  wire       load_shift;

  reg  [7:0] video_on_h;
  reg  [7:0] horiz_sync;

  wire fg_or_bg;
  wire brown_bg;
  wire brown_fg;

  reg [ 7:0] vga_shift;
  reg [ 3:0] fg_colour;
  reg [ 2:0] bg_colour;
  reg [22:0] blink_count;

  // Cursor
  reg  cursor_on_v;
  reg  cursor_on_h;
  reg  cursor_on;
  wire cursor_on1;

  // Module instances
  vga_char_rom char_rom (
    .clk  (clk),
    .addr (char_addr),
    .q    (char_data_out)
  );

  // Continuous assignments
  assign vga_addr     = { 4'b0, hor_addr } + { ver_addr, 4'b0 };
  assign char_addr    = { char_addr_in, v_count[3:0] };
  assign load_shift   = pipe[7] | pipe[15];
  assign video_on_h_o = video_on_h[7];
  assign horiz_sync_o = horiz_sync[7];
  assign fml_stb_o    = pipe[2];

  assign fg_or_bg = vga_shift[7] ^ cursor_on;

  assign cursor_on1 = cursor_on_h && cursor_on_v;

  // Behaviour
  // Address generation
  always @(posedge clk)
    if (rst)
      begin
        col_addr  <= 7'h0;
        row_addr  <= 5'h0;
        ver_addr  <= 7'h0;
        hor_addr  <= 7'h0;
        fml_adr_o <= 16'h0;
      end
    else
      if (enable)
        begin
          // h_count[2:0] == 001
          col_addr  <= h_count[9:3];
          row_addr  <= v_count[8:4];

          // h_count[2:0] == 010
          ver_addr  <= { 2'b00, row_addr } + { row_addr, 2'b00 };
          // ver_addr = row_addr x 5
          hor_addr  <= col_addr;

          // h_count[2:0] == 011
          // vga_addr = row_addr * 80 + hor_addr
          fml_adr_o <= { 3'h0, vga_addr, 2'b00 };
        end

  // cursor
  always @(posedge clk)
    if (rst)
      begin
        cursor_on_v <= 1'b0;
        cursor_on_h <= 1'b0;
      end
    else
      if (enable)
        begin
          cursor_on_h <= (h_count[9:3] == hcursor[6:0]);
          cursor_on_v <= (v_count[8:4] == vcursor[4:0])
                      && ({2'b00, v_count[3:0]} >= cur_start)
                      && ({2'b00, v_count[3:0]} <= cur_end);
        end

  // FML 8x16 pipeline count
  always @(posedge clk)
    if (rst)
      begin
        pipe <= 15'b0;
      end
    else
      if (enable)
        begin
          pipe <= { pipe[14:0], (h_count[3:0]==3'b0) };
        end

  // Load FML 8x16 burst
  always @(posedge clk)
    if (enable)
      begin
        fml1_dat <= pipe[9]  ? fml_dat_i[15:0] : fml1_dat;
      end

 // attr_data_out
  always @(posedge clk)
    if (enable)
      begin
        if (pipe[5])
          attr_data_out <= fml_dat_i[15:8];
        else
        if (pipe[13])
          attr_data_out <= fml1_dat[15:8];
      end

  // char_addr_in
  always @(posedge clk)
    if (enable)
      begin
        if (pipe[5])
          char_addr_in <= fml_dat_i[7:0];
        else
        if (pipe[13])
          char_addr_in <= fml1_dat[7:0];
      end

  // video_on_h
  always @(posedge clk)
    if (rst)
      begin
        video_on_h <= 8'b0;
      end
    else
      if (enable)
        begin
          video_on_h <= { video_on_h[6:0], video_on_h_i };
        end

  // horiz_sync
  always @(posedge clk)
    if (rst)
      begin
        horiz_sync <= 8'b0;
      end
    else
      if (enable)
        begin
          horiz_sync <= { horiz_sync[6:0], horiz_sync_i };
        end

  // blink_count
  always @(posedge clk)
    if (rst)
      begin
        blink_count <= 23'h0;
      end
    else
      if (enable)
        begin
          blink_count <= (blink_count + 23'h1);
        end

  // Video shift register
  always @(posedge clk)
    if (rst)
      begin
        fg_colour <= 4'b0;
        bg_colour <= 3'b0;
        vga_shift <= 8'h0;
      end
    else
      if (enable)
        begin
          if (load_shift)
            begin
              fg_colour <= attr_data_out[3:0];
              bg_colour <= attr_data_out[6:4];
              cursor_on <= (cursor_on1 | attr_data_out[7]) & blink_count[22];
              vga_shift <= char_data_out;
            end
          else vga_shift <= { vga_shift[6:0], 1'b0 };
        end

  // pixel attribute
  always @(posedge clk)
    if (rst)
      begin
        attr <= 4'h0;
      end
    else
      if (enable)
        begin
          attr <= fg_or_bg ? fg_colour : { 1'b0, bg_colour };
        end

endmodule
