/*
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
 *  h_count[2:0]
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

module text_mode (
    input clk,
    input rst,

    // CSR slave interface for reading
    output reg [16:1] csr_adr_o,
    input      [15:0] csr_dat_i,
    output            csr_stb_o,

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

  wire [11:0] char_addr;
  wire [ 7:0] char_data_out;
  reg  [ 7:0] attr_data_out;
  reg  [ 7:0] char_addr_in;

  reg  [7:0] pipe;
  wire       load_shift;

  reg  [9:0] video_on_h;
  reg  [9:0] horiz_sync;

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
  char_rom vdu_char_rom (
    .clk  (clk),
    .addr (char_addr),
    .q    (char_data_out)
  );

  // Continuous assignments
  assign vga_addr     = { 4'b0, hor_addr } + { ver_addr, 4'b0 };
  assign char_addr    = { char_addr_in, v_count[3:0] };
  assign load_shift   = pipe[7];
  assign video_on_h_o = video_on_h[9];
  assign horiz_sync_o = horiz_sync[9];
  assign csr_stb_o    = pipe[2];

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
        csr_adr_o <= 16'h0;
      end
    else
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
        csr_adr_o <= { 5'h0, vga_addr };
      end

  // cursor
  always @(posedge clk)
    if (rst)
      begin
        cursor_on_v <= 1'b0;
        cursor_on_h <= 1'b0;
      end
    else
      begin
        cursor_on_h <= (h_count[9:3] == hcursor[6:0]);
        cursor_on_v <= (v_count[8:4] == vcursor[4:0])
                    && ({2'b00, v_count[3:0]} >= cur_start)
                    && ({2'b00, v_count[3:0]} <= cur_end);
      end

  // Pipeline count
  always @(posedge clk)
    pipe <= rst ? 8'b0 : { pipe[6:0], (h_count[2:0]==3'b0) };

  // attr_data_out
  always @(posedge clk) attr_data_out <= pipe[5] ? csr_dat_i[15:8]
                                                 : attr_data_out;

  // char_addr_in
  always @(posedge clk) char_addr_in <= pipe[5] ? csr_dat_i[7:0]
                                                : char_addr_in;

  // video_on_h
  always @(posedge clk)
    video_on_h <= rst ? 10'b0 : { video_on_h[8:0], video_on_h_i };

  // horiz_sync
  always @(posedge clk)
    horiz_sync <= rst ? 10'b0 : { horiz_sync[8:0], horiz_sync_i };

  // blink_count
  always @(posedge clk)
    blink_count <= rst ? 23'h0 : (blink_count + 23'h1);

  // Video shift register
  always @(posedge clk)
    if (rst)
      begin
        fg_colour <= 4'b0;
        bg_colour <= 3'b0;
        vga_shift <= 8'h0;
      end
    else
      if (load_shift)
        begin
          fg_colour <= attr_data_out[3:0];
          bg_colour <= attr_data_out[6:4];
          cursor_on <= (cursor_on1 | attr_data_out[7]) & blink_count[22];
          vga_shift <= char_data_out;
        end
      else vga_shift <= { vga_shift[6:0], 1'b0 };

  // pixel attribute
  always @(posedge clk)
    if (rst) attr <= 4'h0;
    else attr <= fg_or_bg ? fg_colour : { 1'b0, bg_colour };

endmodule
