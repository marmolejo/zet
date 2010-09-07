/*
 *  8254 timer simplified for Zet SoC
 *  Copyright (c) 2010  YS <ys05@mail.ru>
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
 *  This module uses:
 *   - Wishbone interface
 *   - Modes (binary) 2 and 3 only
 *   - Common clock for all 3 Timers (tclk_i)
 *   - Gate input for Timer2 only (gate2_i)
 *  Assumptions:
 *   1. tclk_i is asynchronous simple wire (1.193182 MHz by default)
 *   2. gate2_i is synchronous (comes from Wishbone controlled register)
 *   3. Wishbone clock wb_clk_i is running always and it has much higher
 *      frequency than tclk_i
 */

`define WB_UNBUFFERED_8254

module timer
  (
    // Wishbone slave interface
    input             wb_clk_i,
    input             wb_rst_i,
    input             wb_adr_i,
    input      [1:0]  wb_sel_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    input             wb_stb_i,
    input             wb_cyc_i,
    input             wb_we_i,
    output            wb_ack_o,
    output reg        wb_tgc_o,   // intr

    // CLK 
    input             tclk_i,     // 1.193182 MHz = (14.31818/12) MHz
    // SPEAKER
    input             gate2_i,
    output            out2_o
  );

`ifdef WB_UNBUFFERED_8254
  wire [15:0] data_ib;
  wire wr_cyc1;
  wire rd_cyc1;
  wire [1:0] datasel;
`else
  reg [15:0] data_ib;
  reg wr_cyc1;
  reg rd_cyc1, rd_cyc2;
  reg [1:0] datasel;
`endif

  wire intr, refresh;
  reg intr1;
  //reg [7:0] dat_o;

  wire wrc, wrd0, wrd1, wrd2, rdd0, rdd1, rdd2;
  wire [7:0] data0;
  wire [7:0] data1;
  wire [7:0] data2;

  // Making 1 clock pulse on wb_tgc_o from intr
  // unnecessary for real 8259A -> subj to remove later
  always @(posedge wb_clk_i)
  begin
    intr1 <= wb_rst_i ? 1'b0 : intr;
    wb_tgc_o <= wb_rst_i ? 1'b0 : (!intr1 & intr);
  end

  // 8-bit interface via wb_dat low byte (2-bit [2:1]??? wb_addr_i , no wb_sel_i)
  /*
  assign wb_ack_o = wb_stb_i & wb_cyc_i;

  assign wrc = wb_ack_o & wb_we_i & (wb_adr_i == 2'b11);

  assign wrd0 = wb_ack_o & wb_we_i & (wb_adr_i == 2'b00);
  assign wrd1 = wb_ack_o & wb_we_i & (wb_adr_i == 2'b01);
  assign wrd2 = wb_ack_o & wb_we_i & (wb_adr_i == 2'b10);

  assign rdd0 = wb_ack_o & ~wb_we_i & (wb_adr_i == 2'b00);
  assign rdd1 = wb_ack_o & ~wb_we_i & (wb_adr_i == 2'b01);
  assign rdd2 = wb_ack_o & ~wb_we_i & (wb_adr_i == 2'b10);

  always @(wb_adr_i or data0 or data1 or data2)
    case (wb_adr_i)
      2'b00: wb_dat_o = { 8'h0, data0 };
      2'b01: wb_dat_o = { 8'h0, data1 };
      2'b10: wb_dat_o = { 8'h0, data2 };
    endcase

  timer_counter cnt0(0, 6'h36, 16'hFFFF, wb_clk_i, wb_rst_i, wrc, wrd0, rdd0, wb_dat_i, data0, tclk_i, 1'b1, intr);    // 16-bit 55 ms Mode 3
  timer_counter cnt1(1, 6'h14, 16'h0012, wb_clk_i, wb_rst_i, wrc, wrd1, rdd1, wb_dat_i, data1, tclk_i, 1'b1, refresh); // 8-bit  15 us Mode 2
  timer_counter cnt2(2, 6'h36, 16'h04A9, wb_clk_i, wb_rst_i, wrc, wrd2, rdd2, wb_dat_i, data2, tclk_i, gate2_i, out2_o);  // 16-bit  1 ms Mode 3
  */

  // 16-bit interface via wb_dat both bytes (1-bit wb_addr_i, 2-bit [1:0] wb_sel_i)
  // assumes opposite wb_sel_i only: 2'b10 or 2'b01

  reg [7:0] data_i;
  reg [15:0] data_ob;

  always @(datasel or data0 or data1 or data2)
    case (datasel)
      2'b00: data_ob = { 8'h0, data0 };
      2'b01: data_ob = { data1, 8'h0 };
      2'b10: data_ob = { 8'h0, data2 };
      2'b11: data_ob = { 8'h0, 8'h0 }; // not checked yet!
    endcase

  always @(datasel or data_ib)
    case (datasel)
      2'b00: data_i = data_ib[7:0];
      2'b01: data_i = data_ib[15:8];
      2'b10: data_i = data_ib[7:0];
      2'b11: data_i = data_ib[15:8];
    endcase

  assign wrc = wr_cyc1 & (datasel == 2'b11);

  assign wrd0 = wr_cyc1 & (datasel == 2'b00);
  assign wrd1 = wr_cyc1 & (datasel == 2'b01);
  assign wrd2 = wr_cyc1 & (datasel == 2'b10);

  assign rdd0 = rd_cyc1 & (datasel == 2'b00);
  assign rdd1 = rd_cyc1 & (datasel == 2'b01);
  assign rdd2 = rd_cyc1 & (datasel == 2'b10);

  `ifdef WB_UNBUFFERED_8254
  // 1 clock write, 1 clock read

  assign wb_ack_o = wb_stb_i & wb_cyc_i;

  assign wr_cyc1 = wb_ack_o & wb_we_i;
  assign rd_cyc1 = wb_ack_o & ~wb_we_i;
  assign datasel = {wb_adr_i,wb_sel_i[1]};

  //assign wb_dat_o = data_ob;
  always @(data_ob)
    wb_dat_o = data_ob;
  assign data_ib = wb_dat_i;

  `else
  // 2 clocks write, 3 clocks read

  assign wb_ack_o = wr_cyc1 | rd_cyc2;

  always @(posedge wb_clk_i)
  begin
    wr_cyc1 <= (wr_cyc1) ? 1'b0 : wb_stb_i & wb_cyc_i & wb_we_i;            // single clock write pulse
    rd_cyc1 <= (rd_cyc1 | rd_cyc2) ? 1'b0 : wb_stb_i & wb_cyc_i & ~wb_we_i; // single clock read pulse
    rd_cyc2 <= rd_cyc1;                                                     // delayed single clock read pulse
    datasel <= {wb_adr_i,wb_sel_i[1]};

    wb_dat_o <= data_ob;
    data_ib <= wb_dat_i;
  end

  `endif //def WB_UNBUFFERED_8254

  // Module instantiations

  timer_counter cnt0 (
    .cntnum (0),
    .cw0    (6'h36),      // 16-bit Mode 3
    .cr0    (16'hFFFF),   // 55 ms
    .clkrw  (wb_clk_i),
    .rst    (wb_rst_i),
    .wrc    (wrc),
    .wrd    (wrd0),
    .rdd    (rdd0),
    .data_i (data_i),
    .data_o (data0),
    .clkt   (tclk_i),
    .gate   (1'b1),
    .out    (intr)
    );

  timer_counter cnt1 (
    .cntnum (1),
    .cw0    (6'h14),      // 8-bit Mode 2
    .cr0    (16'h0012),   // 15 us
    .clkrw  (wb_clk_i),
    .rst    (wb_rst_i),
    .wrc    (wrc),
    .wrd    (wrd1),
    .rdd    (rdd1),
    .data_i (data_i),
    .data_o (data1),
    .clkt   (tclk_i),
    .gate   (1'b1),
    .out    (refresh)
    );

  timer_counter cnt2 (
    .cntnum (2),
    .cw0    (6'h36),      // 16-bit Mode 3
    .cr0    (16'h04A9),   // 1 ms
    .clkrw  (wb_clk_i),
    .rst    (wb_rst_i),
    .wrc    (wrc),
    .wrd    (wrd2),
    .rdd    (rdd2),
    .data_i (data_i),
    .data_o (data2),
    .clkt   (tclk_i),
    .gate   (gate2_i),
    .out    (out2_o)
    );

endmodule
