/*
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
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

module test_sdspi (
    input            clk_50_,
    input            sw0_,
    output reg [7:0] ledg_,

    // SD card signals
    output        sd_sclk_,
    input         sd_miso_,
    output        sd_mosi_,
    output        sd_ss_
  );

  // Registers and nets
  wire       clk;
  wire       sys_clk;
  reg  [1:0] clk_div;
  wire       lock;
  wire       rst;
  reg  [8:0] dat_i;
  wire [7:0] dat_o;
  reg        we;
  reg  [1:0] sel;
  reg        stb;
  wire       ack;

  reg  [7:0] st;
  reg  [7:0] cnt;

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c2     (sys_clk),
    .locked (lock)
  );

  sdspi sdspi (
    // Serial pad signal
    .sclk (sd_sclk_),
    .miso (sd_miso_),
    .mosi (sd_mosi_),
    .ss   (sd_ss_),

    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_we_i  (we),
    .wb_sel_i (sel),
    .wb_stb_i (stb),
    .wb_cyc_i (stb),
    .wb_ack_o (ack)
  );

  // Continuous assignments
  assign clk = clk_div[1];
  assign rst = sw0_ | !lock;

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        dat_i <= 9'h0;
        we    <= 1'b0;
        sel   <= 2'b00;
        stb   <= 1'b0;
        st    <= 8'h0;
        cnt   <= 8'd90;
      end
    else
      case (st)
        8'h0:
          begin
            dat_i <= 9'hff;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h1;
          end
        8'h1:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= (cnt==8'd0) ? 8'h2 : 8'h1;
            cnt   <= cnt - 8'd1;
          end
        8'h2:
          if (ack) begin
            dat_i <= 9'h0ff;
            we    <= 1'b1;
            sel   <= 2'b11;
            stb   <= 1'b1;
            st    <= 8'h3;
          end
        8'h3:
          if (ack) begin
            dat_i <= 9'h40;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h4;
          end
        8'h4:
          if (ack) begin
            dat_i <= 9'h00;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h5;
          end
        8'h5:
          if (ack) begin
            dat_i <= 9'h00;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h6;
          end
        8'h6:
          if (ack) begin
            dat_i <= 9'h00;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h7;
          end
        8'h7:
          if (ack) begin
            dat_i <= 9'h00;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h8;
          end
        8'h8:
          if (ack) begin
            dat_i <= 9'h95;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h49;
          end
        8'h49:
          if (ack) begin
            dat_i <= 9'h95;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b0;
            st    <= 8'h50;
            cnt   <= 8'd4;
          end
        8'h50:
          begin
            dat_i <= 9'h95;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b0;
            st    <= (cnt==8'd0) ? 8'h9 : 8'h50;
            cnt   <= cnt - 8'd1;
          end
        8'h9:
          begin
            dat_i <= 9'hff;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'h52;
          end
        8'h52:
          if (ack) begin
            dat_i <= 9'h95;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b0;
            st    <= 8'h53;
            cnt   <= 8'd7;
          end
        8'h53:
          begin
            dat_i <= 9'h95;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b0;
            st    <= (cnt==8'd0) ? 8'd10 : 8'h53;
            cnt   <= cnt - 8'd1;
          end
        8'd10:
          begin
            dat_i <= 9'hff;
            we    <= 1'b0;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd11;
          end
        8'd11:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b0;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd12;
          end
        8'd12:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b0;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd13;
          end
        8'd13:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b0;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd14;
          end
        8'd14:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b0;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd15;
          end
      endcase
/*
  always #5 clk <= !clk;

  initial
    begin
      clk <= 1'b0;
      rst <= 1'b1;
      miso <= 1'b1;

      #100 rst  <= 1'b0;

      #935 miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b0;
      #10  miso <= 1'b1;
    end
 */

  // clk_div
  always @(posedge sys_clk) clk_div <= clk_div + 2'd1;

endmodule
