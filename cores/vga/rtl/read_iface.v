/*
 *  Read memory interface for VGA
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module read_iface (
    // Wishbone common signals
    input         wb_clk_i,
    input         wb_rst_i,

    // Wishbone slave read interface
    input  [16:1] wbs_adr_i,
    input  [ 1:0] wbs_sel_i,
    output [15:0] wbs_dat_o,
    input         wbs_stb_i,
    output        wbs_ack_o,

    // Wishbone master read to SRAM
    output     [17:1] wbm_adr_o,
    input      [15:0] wbm_dat_i,
    output reg        wbm_stb_o,
    input             wbm_ack_i,

    // VGA configuration registers
    input        memory_mapping1,
    input        read_mode,
    input  [1:0] read_map_select,
    input  [3:0] color_compare,
    input  [3:0] color_dont_care,

    output [7:0] latch0,
    output [7:0] latch1,
    output [7:0] latch2,
    output [7:0] latch3
  );

  // Registers and nets
  reg [ 1:0] plane;
  reg        latch_sel;
  reg [15:0] latch [0:3];

  wire [15:1] offset;
  wire [15:0] dat_o0, dat_o1;
  wire [15:0] out_l0, out_l1, out_l2, out_l3;
  wire        cont;

  // Continous assignments
  assign latch0 = latch_sel ? latch[0][15:8] : latch[0][7:0];
  assign latch1 = latch_sel ? latch[1][15:8] : latch[1][7:0];
  assign latch2 = latch_sel ? latch[2][15:8] : latch[2][7:0];
  assign latch3 = latch_sel ? latch[3][15:8] : latch[3][7:0];

  assign wbm_adr_o = { plane, offset };
  assign wbs_ack_o = (plane==2'b11 && wbm_ack_i);
  assign offset    = memory_mapping1 ? { 1'b0, wbs_adr_i[14:1] }
                                     : wbs_adr_i[15:1];
  assign wbs_dat_o = read_mode ? dat_o1 : dat_o0;
  assign dat_o0    = (read_map_select==2'b11) ? wbm_dat_i
                                              : latch[read_map_select];
  assign dat_o1    = ~(out_l0 | out_l1 | out_l2 | out_l3);

  assign out_l0 = (latch[0] ^ { 16{color_compare[0]} })
                            & { 16{color_dont_care[0]} };
  assign out_l1 = (latch[1] ^ { 16{color_compare[1]} })
                            & { 16{color_dont_care[1]} };
  assign out_l2 = (latch[2] ^ { 16{color_compare[2]} })
                            & { 16{color_dont_care[2]} };
  assign out_l3 = (wbm_dat_i ^ { 16{color_compare[3]} })
                            & { 16{color_dont_care[3]} };

  assign cont = wbm_ack_i && wbs_stb_i;

  // Behaviour
  // latch_sel
  always @(posedge wb_clk_i)
    latch_sel <= wb_rst_i ? 1'b0
      : (wbs_stb_i ? wbs_sel_i[1] : latch_sel);

  // wbm_stb_o
  always @(posedge wb_clk_i)
    wbm_stb_o <= wb_rst_i ? 1'b0 : (wbm_stb_o ? ~wbs_ack_o : wbs_stb_i);

  // plane
  always @(posedge wb_clk_i)
    plane <= wb_rst_i ? 2'b00 : (cont ? (plane + 2'b01) : plane);

  // Latch load
  always @(posedge wb_clk_i)
    if (wb_rst_i)
      begin
        latch[0] <= 8'h0;
        latch[1] <= 8'h0;
        latch[2] <= 8'h0;
        latch[3] <= 8'h0;
      end
    else if (wbm_ack_i && wbm_stb_o) latch[plane] <= wbm_dat_i;

endmodule
