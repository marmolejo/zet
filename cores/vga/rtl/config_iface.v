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
  *  3b4: 0000_0011_1011_0100 crtc_idx (not used in vdu.v)
  *  3b5: 0000_0011_1011_0101 CRTC     (not used in vdu.v)
  *  3c0: 0000_0011_1100_0000 attribute_ctrl
  *  3c4: 0000_0011_1100_0100 sequencer.index
  *  3c5: 0000_0011_1100_0101 sequencer.map_mask
  *  3c6: 0000_0011_1100_0110 pel.mask
  *  3c7: 0000_0011_1100_0111 pel.dac_state
  *  3c8: 0000_0011_1100_1000 pel.write_data_register
  *  3c9: 0000_0011_1100_1001 pel.data
  *  3ce: 0000_0011_1100_1110 graphics_ctrl.index
  *  3cf: 0000_0011_1100_1111 graphics_ctrl.data
  *  3d4: 0000_0011_1101_0100 crtc_idx
  *  3d5: 0000_0011_1101_0101 CRTC
  *  3da: 0000_0011_1101_1010 Input Status 1 (color emulation modes)
  *  3db: 0000_0011_1101_1011 not used
  */

module config_iface (
    // Wishbone slave signals
    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    input      [ 4:1] wb_adr_i,
    input             wb_we_i,
    input      [ 1:0] wb_sel_i,
    input             wb_stb_i,
    output            wb_ack_o,

    // VGA configuration registers
    // sequencer
    output reg [3:0] map_mask,     // 3c5 (3c4: 2)

    // graphics_ctrl
    output       shift_reg1,       // 3cf (3ce: 5)
    output       graphics_alpha,   // 3cf (3ce: 6)
    output       memory_mapping1,  // 3cf (3ce: 6)
    output [1:0] write_mode,       // 3cf (3ce: 5)
    output [1:0] raster_op,        // 3cf (3ce: 3)
    output       read_mode,        // 3cf (3ce: 5)
    output [7:0] bitmask,          // 3cf (3ce: 8)
    output [3:0] set_reset,        // 3cf (3ce: 0)
    output [3:0] enable_set_reset, // 3cf (3ce: 1)
    output [1:0] read_map_select,  // 3cf (3ce: 4)
    output [3:0] color_compare,    // 3cf (3ce: 2)
    output [3:0] color_dont_care,  // 3cf (3ce: 7)

    // attribute_ctrl
    output reg [3:0] pal_addr,
    output           pal_we,
    input      [7:0] pal_read,
    output     [7:0] pal_write,

    // dac_regs
    output           dac_we,
    output reg [1:0] dac_read_data_cycle,
    output reg [7:0] dac_read_data_register,
    input      [7:0] dac_read_data,
    output     [1:0] dac_write_data_cycle,    // word bypass
    output     [7:0] dac_write_data_register, // word bypass
    output     [7:0] dac_write_data,

    // CRTC
    output [ 5:0] cur_start,
    output [ 5:0] cur_end,
    output [15:0] start_addr,
    output [ 4:0] vcursor,
    output [ 6:0] hcursor,

    output [ 6:0] horiz_total,
    output [ 6:0] end_horiz,
    output [ 6:0] st_hor_retr,
    output [ 4:0] end_hor_retr,
    output [ 9:0] vert_total,
    output [ 9:0] end_vert,
    output [ 9:0] st_ver_retr,
    output [ 3:0] end_ver_retr,

    input v_retrace,
    input vh_retrace
  );

  // Registers and nets
  reg [7:0] graphics_ctrl[0:8];
  reg [3:0] graph_idx;
  reg [7:0] CRTC[0:23];
  reg [4:0] crtc_idx;
  reg [3:0] seq_idx;
  reg       flip_flop;
  reg       h_pal_addr;
  reg       ack_delay;
  reg [1:0] dac_state;

  reg [1:0] write_data_cycle;
  reg [7:0] write_data_register;

  integer i;

  wire [3:0] graph_idx_wr;
  wire [4:0] crtc_idx_wr;
  wire [3:0] seq_idx_wr;
  wire       wr_graph;
  wire       wr_seq;
  wire       wr_crtc;
  wire       write;
  wire       read;
  wire [7:0] start_hi;
  wire [7:0] start_lo;
  wire       rst_flip_flop;
  wire       wr_attr;
  wire       rd_attr;
  wire       wr_pal_addr;
  wire       attr_ctrl_addr;
  wire       pel_adr_rd;
  wire       pel_adr_wr;
  wire       rd_dac;
  wire       dac_addr;
  wire       acc_dac;
  wire       wr_dac;

  // Continuous assignments
  assign wb_ack_o = (rd_attr | rd_dac) ? ack_delay : wb_stb_i;

  assign seq_idx_wr   = (wr_seq && wb_sel_i[0]) ? wb_dat_i[3:0] : seq_idx;
  assign graph_idx_wr = (wr_graph && wb_sel_i[0]) ? wb_dat_i[3:0] : graph_idx;
  assign crtc_idx_wr  = (wr_crtc && wb_sel_i[0]) ? wb_dat_i[4:0] : crtc_idx;

  assign shift_reg1       = graphics_ctrl[5][6];
  assign graphics_alpha   = graphics_ctrl[6][0];
  assign memory_mapping1  = graphics_ctrl[6][3];
  assign write_mode       = graphics_ctrl[5][1:0];
  assign raster_op        = graphics_ctrl[3][4:3];
  assign read_mode        = graphics_ctrl[5][3];
  assign bitmask          = graphics_ctrl[8];
  assign set_reset        = graphics_ctrl[0][3:0];
  assign enable_set_reset = graphics_ctrl[1][3:0];
  assign read_map_select  = graphics_ctrl[4][1:0];
  assign color_compare    = graphics_ctrl[2][3:0];
  assign color_dont_care  = graphics_ctrl[7][3:0];

  assign cur_start = CRTC[10][5:0];
  assign cur_end   = CRTC[11][5:0];
  assign start_hi  = CRTC[12];
  assign start_lo  = CRTC[13];
  assign vcursor   = CRTC[14][4:0];
  assign hcursor   = CRTC[15][6:0];

  assign horiz_total  = CRTC[0][6:0];
  assign end_horiz    = CRTC[1][6:0];
  assign st_hor_retr  = CRTC[4][6:0];
  assign end_hor_retr = CRTC[5][4:0];
  assign vert_total   = { CRTC[7][5], CRTC[7][0], CRTC[6] };
  assign end_vert     = { CRTC[7][6], CRTC[7][1], CRTC[18] };
  assign st_ver_retr  = { CRTC[7][7], CRTC[7][2], CRTC[16] };
  assign end_ver_retr = CRTC[17][3:0];

  assign write    = wb_stb_i & wb_we_i;
  assign read     = wb_stb_i & !wb_we_i;
  assign wr_seq   = write & (wb_adr_i==4'h2);
  assign wr_graph = write & (wb_adr_i==4'h7);
  assign wr_crtc  = write & (wb_adr_i==4'ha);

  assign start_addr = { start_hi, start_lo };

  assign attr_ctrl_addr = (wb_adr_i==4'h0);
  assign dac_addr       = (wb_adr_i==4'h4);
  assign rst_flip_flop  = read && (wb_adr_i==4'hd) && wb_sel_i[0];
  assign wr_attr        = write && attr_ctrl_addr && wb_sel_i[0];
  assign rd_attr        = read && attr_ctrl_addr && wb_sel_i[1];
  assign wr_pal_addr    = wr_attr && !flip_flop;

  assign pel_adr_rd = write && (wb_adr_i==4'h3) && wb_sel_i[1];
  assign pel_adr_wr = write && dac_addr && wb_sel_i[0];

  assign pal_write = wb_dat_i[7:0];
  assign pal_we    = wr_attr && flip_flop && !h_pal_addr;

  assign acc_dac = dac_addr && wb_sel_i[1];
  assign rd_dac  = (dac_state==2'b11) && read && acc_dac && !wb_ack_o;
  assign wr_dac  = write && acc_dac;

  assign dac_we               = write && (wb_adr_i==4'h4) && wb_sel_i[1];
  assign dac_write_data_cycle = wb_sel_i[0] ? 2'b00 : write_data_cycle;
  assign dac_write_data       = wb_dat_i[15:8];
  assign dac_write_data_register = wb_sel_i[0] ? wb_dat_i[7:0]
                                 : write_data_register;

  // Behaviour
  // write_data_register
  always @(posedge wb_clk_i)
    write_data_register <= wb_rst_i ? 8'h0
      : (pel_adr_wr ? wb_dat_i[7:0]
        : (wr_dac && (write_data_cycle==2'b10)) ?
          (write_data_register + 8'h01) : write_data_register);

  // write_data_cycle
  always @(posedge wb_clk_i)
    write_data_cycle <= (wb_rst_i | pel_adr_wr) ? 2'b00
      : (wr_dac ? (write_data_cycle==2'b10 ? 2'b00
        : write_data_cycle + 2'b01) : write_data_cycle);

  // dac_read_data_register
  always @(posedge wb_clk_i)
    dac_read_data_register <= wb_rst_i ? 8'h00
      : (pel_adr_rd ? wb_dat_i[15:8]
        : (rd_dac && (dac_read_data_cycle==2'b10)) ?
          (dac_read_data_register + 8'h01) : dac_read_data_register);

  // dac_read_data_cycle
  always @(posedge wb_clk_i)
    dac_read_data_cycle <= (wb_rst_i | pel_adr_rd) ? 2'b00
      : (rd_dac ? (dac_read_data_cycle==2'b10 ? 2'b00
        : dac_read_data_cycle + 2'b01) : dac_read_data_cycle);

  // dac_state
  always @(posedge wb_clk_i)
    dac_state <= wb_rst_i ? 2'b01
      : (pel_adr_rd ? 2'b11 : (pel_adr_wr ? 2'b00 : dac_state));

  // attribute_ctrl.flip_flop
  always @(posedge wb_clk_i)
    flip_flop <= (wb_rst_i | rst_flip_flop) ? 1'b0
      : (wr_attr ? !flip_flop : flip_flop);

  // pal_addr
  always @(posedge wb_clk_i)
    { h_pal_addr, pal_addr } <= wb_rst_i ? 5'h0
      : (wr_pal_addr ? wb_dat_i[4:0] : { h_pal_addr, pal_addr });

  // seq_idx
  always @(posedge wb_clk_i)
    seq_idx <= wb_rst_i ? 4'h0 : seq_idx_wr;

  // map_mask
  always @(posedge wb_clk_i)
    map_mask <= wb_rst_i ? 4'h0
      : ((wr_seq && wb_sel_i[1] && seq_idx_wr==4'h2) ?
        wb_dat_i[11:8] : map_mask);

  // graph_idx
  always @(posedge wb_clk_i)
    graph_idx <= wb_rst_i ? 4'h0 : graph_idx_wr;

  // graphics_ctrl
  always @(posedge wb_clk_i)
    if (wr_graph & wb_sel_i[1])
      graphics_ctrl[graph_idx_wr] <= wb_dat_i[15:8];

  // crtc_idx
  always @(posedge wb_clk_i)
    crtc_idx <= wb_rst_i ? 5'h0 : crtc_idx_wr;

  // CRTC
  always @(posedge wb_clk_i)
    if (wr_crtc & wb_sel_i[1])
      CRTC[crtc_idx_wr] <= wb_dat_i[15:8];

  // ack_delay
  always @(posedge wb_clk_i)
    ack_delay <= wb_stb_i;

  // wb_dat_o
  always @(*)
    case (wb_adr_i)
      4'h0: wb_dat_o = { pal_read, 3'b001, h_pal_addr, pal_addr };
      4'h2: wb_dat_o = { 4'h0, seq_idx, map_mask };
      4'h3: wb_dat_o = { 6'h0, dac_state, 8'hff };
      4'h4: wb_dat_o = { dac_read_data, write_data_register };
      4'h7: wb_dat_o = { 4'h0, graph_idx, graphics_ctrl[graph_idx] };
      4'ha: wb_dat_o = { 3'h0, crtc_idx, CRTC[crtc_idx] };
      4'hd: wb_dat_o = { 12'b0, v_retrace, 2'b0, vh_retrace };
      default: wb_dat_o = 16'h0;
    endcase

  initial
    begin
      for (i=0;i<=8 ;i=i+1) graphics_ctrl[i] = 8'h0;
      for (i=0;i<=15;i=i+1) CRTC[i] = 8'h0;
    end
endmodule
