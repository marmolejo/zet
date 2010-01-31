/*
 *  Write memory interface for VGA
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

module write_iface (
    // Wishbone common signals
    input wb_clk_i,
    input wb_rst_i,

    // Wishbone slave write interface
    input [16:1] wbs_adr_i,
    input [ 1:0] wbs_sel_i,
    input [15:0] wbs_dat_i,
    input        wbs_stb_i,
    output       wbs_ack_o,

    // Wishbone master write to SRAM
    output [17:1] wbm_adr_o,
    output [ 1:0] wbm_sel_o,
    output [15:0] wbm_dat_o,
    output        wbm_stb_o,
    input         wbm_ack_i,

    // VGA configuration registers
    input        memory_mapping1,
    input [ 1:0] write_mode,
    input [ 1:0] raster_op,
    input [ 7:0] bitmask,
    input [ 3:0] set_reset,
    input [ 3:0] enable_set_reset,
    input [ 3:0] map_mask,

    input [7:0] latch0,
    input [7:0] latch1,
    input [7:0] latch2,
    input [7:0] latch3
  );

  // Registers and nets
  wire [15:0] latch0_16;
  wire [15:0] latch1_16;
  wire [15:0] latch2_16;
  wire [15:0] latch3_16;

  wire [15:0] lb0;
  wire [15:0] lb1;
  wire [15:0] lb2;
  wire [15:0] lb3;

  wire [15:0] nlb0;
  wire [15:0] nlb1;
  wire [15:0] nlb2;
  wire [15:0] nlb3;

  wire [15:0] alb0;
  wire [15:0] alb1;
  wire [15:0] alb2;
  wire [15:0] alb3;

  wire [15:0] olb0;
  wire [15:0] olb1;
  wire [15:0] olb2;
  wire [15:0] olb3;

  wire [15:0] xlb0;
  wire [15:0] xlb1;
  wire [15:0] xlb2;
  wire [15:0] xlb3;

  wire [15:0] set0;
  wire [15:0] set1;
  wire [15:0] set2;
  wire [15:0] set3;

  wire [15:0] no_set0;
  wire [15:0] no_set1;
  wire [15:0] no_set2;
  wire [15:0] no_set3;

  wire [15:0] no_en0;
  wire [15:0] no_en1;
  wire [15:0] no_en2;
  wire [15:0] no_en3;

  wire [15:0] new_val0;
  wire [15:0] new_val1;
  wire [15:0] new_val2;
  wire [15:0] new_val3;

  wire [ 7:0] wr2_d0_0;
  wire [ 7:0] wr2_d0_1;
  wire [ 7:0] wr2_d0_2;
  wire [ 7:0] wr2_d0_3;

  wire [ 7:0] wr2_d1_0;
  wire [ 7:0] wr2_d1_1;
  wire [ 7:0] wr2_d1_2;
  wire [ 7:0] wr2_d1_3;

  wire [15:0] val0_write0, val0_write1, val0_write2, val0_write3;
  wire [15:0] val1_write0, val1_write1, val1_write2, val1_write3;
  wire [15:0] val0_or0, val0_or1, val0_or2, val0_or3;
  wire [15:0] val1_or0, val1_or1, val1_or2, val1_or3;
  wire [15:0] final_wr0, final_wr1, final_wr2, final_wr3;

  wire [15:1] offset;
  wire [15:0] bitmask16;
  wire [15:0] dat_mask;
  wire        write_en;
  wire        cont;

  reg  [ 1:0] plane;
  reg  [ 3:0] plane_dec;

  // Continuous assignments
  assign bitmask16 = { bitmask, bitmask };
  assign dat_mask  = wbs_dat_i & bitmask16;

  assign latch0_16 = { latch0, latch0 };
  assign latch1_16 = { latch1, latch1 };
  assign latch2_16 = { latch2, latch2 };
  assign latch3_16 = { latch3, latch3 };

  assign new_val0 = latch0_16 & ~bitmask16;
  assign new_val1 = latch1_16 & ~bitmask16;
  assign new_val2 = latch2_16 & ~bitmask16;
  assign new_val3 = latch3_16 & ~bitmask16;

  assign lb0  = latch0_16 & bitmask16;
  assign lb1  = latch1_16 & bitmask16;
  assign lb2  = latch2_16 & bitmask16;
  assign lb3  = latch3_16 & bitmask16;

  assign nlb0 = ~latch0_16 & bitmask16;
  assign nlb1 = ~latch1_16 & bitmask16;
  assign nlb2 = ~latch2_16 & bitmask16;
  assign nlb3 = ~latch3_16 & bitmask16;

  assign alb0 = (wbs_dat_i & latch0_16) & bitmask16;
  assign alb1 = (wbs_dat_i & latch1_16) & bitmask16;
  assign alb2 = (wbs_dat_i & latch2_16) & bitmask16;
  assign alb3 = (wbs_dat_i & latch3_16) & bitmask16;

  assign olb0 = (wbs_dat_i | latch0_16) & bitmask16;
  assign olb1 = (wbs_dat_i | latch1_16) & bitmask16;
  assign olb2 = (wbs_dat_i | latch2_16) & bitmask16;
  assign olb3 = (wbs_dat_i | latch3_16) & bitmask16;

  assign xlb0 = (wbs_dat_i ^ latch0_16) & bitmask16;
  assign xlb1 = (wbs_dat_i ^ latch1_16) & bitmask16;
  assign xlb2 = (wbs_dat_i ^ latch2_16) & bitmask16;
  assign xlb3 = (wbs_dat_i ^ latch3_16) & bitmask16;

  // write mode 0
  assign set0 = raster_op[0] ? (raster_op[1] ? nlb0 : lb0 ) : bitmask16;
  assign set1 = raster_op[0] ? (raster_op[1] ? nlb1 : lb1 ) : bitmask16;
  assign set2 = raster_op[0] ? (raster_op[1] ? nlb2 : lb2 ) : bitmask16;
  assign set3 = raster_op[0] ? (raster_op[1] ? nlb3 : lb3 ) : bitmask16;

  assign no_set0 = raster_op[1] ? lb0 : 16'h0;
  assign no_set1 = raster_op[1] ? lb1 : 16'h0;
  assign no_set2 = raster_op[1] ? lb2 : 16'h0;
  assign no_set3 = raster_op[1] ? lb3 : 16'h0;

  assign no_en0 = raster_op[1] ? (raster_op[0] ? xlb0 : olb0)
                               : (raster_op[0] ? alb0 : dat_mask);
  assign no_en1 = raster_op[1] ? (raster_op[0] ? xlb1 : olb1)
                               : (raster_op[0] ? alb1 : dat_mask);
  assign no_en2 = raster_op[1] ? (raster_op[0] ? xlb2 : olb2)
                               : (raster_op[0] ? alb2 : dat_mask);
  assign no_en3 = raster_op[1] ? (raster_op[0] ? xlb3 : olb3)
                               : (raster_op[0] ? alb3 : dat_mask);

  assign val0_or0 = enable_set_reset[0] ?
    (set_reset[0] ? set0 : no_set0) : no_en0;
  assign val0_or1 = enable_set_reset[1] ?
    (set_reset[1] ? set1 : no_set1) : no_en1;
  assign val0_or2 = enable_set_reset[2] ?
    (set_reset[2] ? set2 : no_set2) : no_en2;
  assign val0_or3 = enable_set_reset[3] ?
    (set_reset[3] ? set3 : no_set3) : no_en3;

  assign val0_write0 = new_val0 | val0_or0;
  assign val0_write1 = new_val1 | val0_or1;
  assign val0_write2 = new_val2 | val0_or2;
  assign val0_write3 = new_val3 | val0_or3;

  // write mode 2
  assign wr2_d0_0 = raster_op[1] ? lb0[7:0] : 8'h0;
  assign wr2_d0_1 = raster_op[1] ? lb1[7:0] : 8'h0;
  assign wr2_d0_2 = raster_op[1] ? lb2[7:0] : 8'h0;
  assign wr2_d0_3 = raster_op[1] ? lb3[7:0] : 8'h0;

  assign wr2_d1_0 = raster_op[0] ? (raster_op[1] ? nlb0[7:0] : lb0[7:0])
                                 : bitmask;
  assign wr2_d1_1 = raster_op[0] ? (raster_op[1] ? nlb1[7:0] : lb1[7:0])
                                 : bitmask;
  assign wr2_d1_2 = raster_op[0] ? (raster_op[1] ? nlb2[7:0] : lb2[7:0])
                                 : bitmask;
  assign wr2_d1_3 = raster_op[0] ? (raster_op[1] ? nlb3[7:0] : lb3[7:0])
                                 : bitmask;
/*
  assign val1_or0[ 7:0] = wbs_dat_i[ 0] ? wr2_d1_0 : wr2_d0_0;
  assign val1_or1[ 7:0] = wbs_dat_i[ 1] ? wr2_d1_1 : wr2_d0_1;
  assign val1_or2[ 7:0] = wbs_dat_i[ 2] ? wr2_d1_2 : wr2_d0_2;
  assign val1_or3[ 7:0] = wbs_dat_i[ 3] ? wr2_d1_3 : wr2_d0_3;
  assign val1_or0[15:8] = wbs_dat_i[ 8] ? wr2_d1_0 : wr2_d0_0;
  assign val1_or1[15:8] = wbs_dat_i[ 9] ? wr2_d1_1 : wr2_d0_1;
  assign val1_or2[15:8] = wbs_dat_i[10] ? wr2_d1_2 : wr2_d0_2;
  assign val1_or3[15:8] = wbs_dat_i[11] ? wr2_d1_3 : wr2_d0_3;
*/
  assign val1_or0[ 7:0] = wbs_dat_i[ 0] ? bitmask : 8'h0;
  assign val1_or1[ 7:0] = wbs_dat_i[ 1] ? bitmask : 8'h0;
  assign val1_or2[ 7:0] = wbs_dat_i[ 2] ? bitmask : 8'h0;
  assign val1_or3[ 7:0] = wbs_dat_i[ 3] ? bitmask : 8'h0;
  assign val1_or0[15:8] = wbs_dat_i[ 8] ? bitmask : 8'h0;
  assign val1_or1[15:8] = wbs_dat_i[ 9] ? bitmask : 8'h0;
  assign val1_or2[15:8] = wbs_dat_i[10] ? bitmask : 8'h0;
  assign val1_or3[15:8] = wbs_dat_i[11] ? bitmask : 8'h0;

  assign val1_write0 = new_val0 | val1_or0;
  assign val1_write1 = new_val1 | val1_or1;
  assign val1_write2 = new_val2 | val1_or2;
  assign val1_write3 = new_val3 | val1_or3;

  // Final write

  assign final_wr0 = write_mode[1] ? val1_write0
                   : (write_mode[0] ? latch0_16 : val0_write0);
  assign final_wr1 = write_mode[1] ? val1_write1
                   : (write_mode[0] ? latch1_16 : val0_write1);
  assign final_wr2 = write_mode[1] ? val1_write2
                   : (write_mode[0] ? latch2_16 : val0_write2);
  assign final_wr3 = write_mode[1] ? val1_write3
                   : (write_mode[0] ? latch3_16 : val0_write3);

  assign offset = memory_mapping1 ? { 1'b0, wbs_adr_i[14:1] }
                                  : wbs_adr_i[15:1];

  assign wbm_adr_o = { plane, offset };
  assign wbs_ack_o = (plane==2'b11 && cont);
  assign wbm_dat_o = plane[1] ? (plane[0] ? final_wr3 : final_wr2)
                              : (plane[0] ? final_wr1 : final_wr0);

  assign write_en = plane[1] ? (plane[0] ? map_mask[3] : map_mask[2])
                             : (plane[0] ? map_mask[1] : map_mask[0]);

  assign wbm_sel_o = wbs_sel_i;
  assign cont      = (wbm_ack_i | !write_en) & wbs_stb_i;
  assign wbm_stb_o = write_en & wbs_stb_i;

  // plane
  always @(posedge wb_clk_i)
    plane <= wb_rst_i ? 2'b00 : (cont ? (plane + 2'b01) : plane);

endmodule
