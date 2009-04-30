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

module test_sdspi;

  // Registers and nets
  wire sclk;
  reg  miso;
  wire mosi;
  wire ss;

  reg        clk;
  reg        rst;
  reg  [8:0] dat_i;
  wire [7:0] dat_o;
  reg        we;
  reg  [1:0] sel;
  reg        stb;
  wire       ack;
  reg  [7:0] data;

  reg  [7:0] st;

  // Module instantiations
  sdspi sdspi (
    // Serial pad signal
    .sclk (sclk),
    .miso (miso),
    .mosi (mosi),
    .ss   (ss),

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

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        dat_i <= 9'h0;
        we    <= 1'b0;
        sel   <= 2'b00;
        stb   <= 1'b0;
        st    <= 8'h0;
      end
    else
      case (st)
        8'h0:
          begin
            dat_i <= 9'h55;
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
            st    <= 8'h2;
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
            st    <= 8'h14;
          end
        8'h14:
          if (ack) begin
            dat_i <= 9'h00;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b0;
            st    <= 8'h5;
          end
        8'h5:
          begin
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
            st    <= 8'h9;
          end
        8'h9:
          if (ack) begin
            dat_i <= 9'hff;
            we    <= 1'b1;
            sel   <= 2'b01;
            stb   <= 1'b1;
            st    <= 8'd10;
          end
        8'd10:
          if (ack) begin
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
            stb   <= 1'b0;
            st    <= 8'd12;
            data  <= dat_o;
          end
      endcase

  always #40 clk <= !clk;

  initial
    begin
      clk   <= 1'b0;
      rst   <= 1'b1;
      miso  <= 1'b1;
      sdspi.clk_div <= 2'b00;

      #400 rst  <= 1'b0;
    end

  initial
    begin
      #26440 miso <= 1'b1;
      #320   miso <= 1'b1;
      #320   miso <= 1'b1;
      #320   miso <= 1'b0;
      #320   miso <= 1'b1;
      #320   miso <= 1'b0;
      #320   miso <= 1'b1;
      #320   miso <= 1'b1;

    end
endmodule
