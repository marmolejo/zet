/*
 *  Copyright (c) 2008  Zeus Gomez Marmolejo <zeus@opencores.org>
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

`include "defines.v"

module zbt_cntrl (
`ifdef DEBUG
    output reg [2:0] cnt,
    output           op,
`endif
    // Wishbone common signals
    input             wb_clk_i,
    input             wb_rst_i,

    // Wishbone slave interface 0 - higher priority
    input      [15:0] wb0_dat_i,
    output reg [15:0] wb0_dat_o,
    input      [19:1] wb0_adr_i,
    input             wb0_we_i,
    input      [ 1:0] wb0_sel_i,
    input             wb0_stb_i,
    input             wb0_cyc_i,
    output            wb0_ack_o,

    // Wishbone slave interface 1 - lower priority
    input      [15:0] wb1_dat_i,
    output reg [15:0] wb1_dat_o,
    input      [19:1] wb1_adr_i,
    input             wb1_we_i,
    input      [ 1:0] wb1_sel_i,
    input             wb1_stb_i,
    input             wb1_cyc_i,
    output            wb1_ack_o,

    // Pad signals
    output            sram_clk_,
    output reg [20:0] sram_addr_,
    inout      [31:0] sram_data_,
    output reg        sram_we_n_,
    output reg [ 3:0] sram_bw_,
    output reg        sram_cen_,
    output            sram_adv_ld_n_
  );

  // Registers and nets
  reg  [31:0] wr0;
  reg  [31:0] wr1;
  reg  [ 3:0] cnt0;
  wire        busy0;
  wire        busy1;
  wire        load0;
  wire        load1;
  wire        op1;

`ifndef DEBUG
  reg [ 3:0] cnt0;
  wire       op0;
`endif

  // Continuous assignments
  assign op0   = wb0_stb_i & wb0_cyc_i;
  assign op1   = wb1_stb_i & wb1_cyc_i;

  assign busy0 = |cnt0;
  assign busy1 = |cnt1;

  assign load0 = !busy0 & op0;
  assign load1 = !busy1 & (!op0 & op1 | op1 & busy0);

  assign sram_clk_      = wb_clk_i;
  assign sram_adv_ld_n_ = 1'b0;
  assign wb0_ack_o      = cnt0[3];
  assign wb1_ack_o      = cnt1[3];

  assign sram_data_ =  (op0 & cnt0[1] & wb0_we_i) ? wr0
                    : ((op1 & cnt1[1] & wb1_we_i) ? wr1 : 32'hzzzzzzzz);

  // Behaviour
  // cnt0
  always @(posedge wb_clk_i)
    cnt0 <= wb_rst_i ? 4'b0 : { cnt0[2:0], load0 };

  // cnt1
  always @(posedge wb_clk_i)
    cnt1 <= wb_rst_i ? 4'b0 : { cnt1[2:0], load1 };

  // wb0_dat_o
  always @(posedge wb_clk_i)
    wb0_dat_o <= cnt0[2] ? (wb0_adr_i[1] ? sram_data_[31:16]
                             : sram_data_[15:0]) : wb0_dat_o;
  // wb1_dat_o
  always @(posedge wb_clk_i)
    wb1_dat_o <= cnt1[2] ? (wb1_adr_i[1] ? sram_data_[31:16]
                             : sram_data_[15:0]) : wb1_dat_o;
  // sram_addr_
  always @(posedge wb_clk_i)
    sram_addr_ <= load0 ? { 3'b0, wb0_adr_i[19:2] }
                        : (load1 ? { 3'b0, wb1_adr_i[19:2] }
                        : sram_addr_);
  // sram_we_n_
  always @(posedge wb_clk_i)
    sram_we_n_ <= (load0 & wb0_we_i) ? 1'b0 :
                  ((load1 & wb1_we_i) ? 1'b0 : 1'b1);

  // sram_bw_
  always @(posedge wb_clk_i)
    sram_bw_ <= load0 ? (wb0_adr_i[1] ? { ~wb0_sel_i, 2'b11 }
                                      : { 2'b11, ~wb0_sel_i })
                      : (wb1_adr_i[1] ? { ~wb1_sel_i, 2'b11 }
                                      : { 2'b11, ~wb1_sel_i });
  // sram_cen_
  always @(posedge wb_clk_i)
    sram_cen_ <= wb_rst_i ? 1'b1 : !(op0 | op1);

  // wr0
  always @(posedge wb_clk_i)
    wr0 <= op0 ? (wb0_adr_i[1] ? { wb0_dat_i, 16'h0 }
                               : { 16'h0, wb0_dat_i }) : wr0;
  // wr1
  always @(posedge wb_clk_i)
    wr1 <= op1 ? (wb1_adr_i[1] ? { wb1_dat_i, 16'h0 }
                               : { 16'h0, wb1_dat_i }) : wr1;
endmodule
