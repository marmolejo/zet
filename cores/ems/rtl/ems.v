/*
 *  Copyright (c) 2009  Mark McDougall (tcdev) <msmcdoug@iinet.net.au>
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

module ems #(
    parameter EMS_VERSION = 3_2,
    parameter IO_BASE_ADDR = 16'h0208
  ) (
    // WISHBONE interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:1] wb_adr_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [ 1:0] wb_sel_i,
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    output reg    wb_ack_o,
    output        ems_io_arena,

    // sdram address interface
    input [19:1] sdram_adr_i,
    output [31:0] sdram_adr_o
  );

  initial
    begin
      // synthesis translate_off
      $display("=== EMS parameters ===");
      $display("ems_version\t\t\t%1d.%1d", EMS_VERSION/10, EMS_VERSION%10);
      $display("io_base_addr\t\t\t$%h", IO_BASE_ADDR);
      // synthesis translate_on
    end

  //
  // register interface
  //
  // register bank select
  assign ems_io_arena = { wb_adr_i[15:3] == IO_BASE_ADDR[15:3] };

  reg ems_enable;
  // base address of 64KB block in UMB [19:16]
  reg [19:16] umb_base_adr;
  // x4 page address registers for 16KB memory blocks [22:14]
  // - assumes 8MB is the largest we can address atm
  // - *** only 4MB possible ATM
  reg [21:14] page_adr [0:3];

  // supports 8-bit I/O only atm...
  wire [7:0] dat_i = (wb_sel_i[0] ? wb_dat_i[7:0] : wb_dat_i[15:8]);
  wire [1:0] page_reg = { wb_adr_i[1], ~wb_sel_i[0] };

  // register read logic
  wire [7:0] dat_o = ~wb_adr_i[2] ? page_adr[page_reg] 
                              		: { ems_enable, 3'b0, umb_base_adr };
  assign wb_dat_o = { dat_o, dat_o };

  // register write logic
  always @(posedge wb_clk_i)
    if (wb_rst_i)
    begin
      ems_enable <= 1'b0;
      umb_base_adr <= 4'h0;
      page_adr[0] <= 8'h00;
      page_adr[1] <= 8'h00;
      page_adr[2] <= 8'h00;
      page_adr[3] <= 8'h00;
    end
    else if (wb_cyc_i && wb_stb_i && wb_we_i)
      if (~wb_adr_i[2])
        // page registers
        page_adr[page_reg] <= dat_i;
      else
        // enable/base address register
        { ems_enable, umb_base_adr } <= { dat_i[7], dat_i[3:0] };

  always @(posedge wb_clk_i)
    wb_ack_o <= wb_rst_i ? 1'b0 : (wb_cyc_i && wb_stb_i);

  //
  // sdram interface
  //
  wire page_frame_arena = (sdram_adr_i[19:16] == umb_base_adr);
  wire [1:0] page = sdram_adr_i[15:14];

  assign sdram_adr_o = ems_enable && page_frame_arena
                        ? { 9'b0, page_adr[page], sdram_adr_i[13:1], 2'b00 }
                        : { 11'b0, sdram_adr_i, 2'b00 };
endmodule
