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

module test_kotku;

  // Registers and nets
  reg        clk_50;
  reg        clk_27;
  wire [9:0] ledr;
  wire [7:0] ledg;
  reg  [9:0] sw;

  wire [21:0] flash_addr;
  wire [ 7:0] flash_data;
  wire        flash_we_n;
  wire        flash_oe_n;
  wire        flash_rst_n;
  wire        flash_ry;

  wire [11:0] sdram_addr;
  wire [15:0] sdram_data;
  wire [ 1:0] sdram_ba;
  wire [ 1:0] sdram_dqm;
  wire        sdram_ras_n;
  wire        sdram_cas_n;
  wire        sdram_ce;
  wire        sdram_clk;
  wire        sdram_we_n;
  wire        sdram_cs_n;

  wire [17:0] sram_addr_;
  wire [15:0] sram_data_;
  wire        sram_we_n_;
  wire        sram_oe_n_;
  wire        sram_ce_n_;
  wire [ 1:0] sram_bw_n_;

  // Module instantiations
  kotku kotku (
    .clk_50_ (clk_50),
//    .clk_27_ (clk_27),
    .ledr_   (ledr),
    .ledg_   (ledg),
    .sw_     (sw),

    // flash signals
    .flash_addr_  (flash_addr),
    .flash_data_  (flash_data),
    .flash_we_n_  (flash_we_n),
    .flash_oe_n_  (flash_oe_n),
    .flash_rst_n_ (flash_rst_n),

    // sdram signals
    .sdram_addr_  (sdram_addr),
    .sdram_data_  (sdram_data),
    .sdram_ba_    (sdram_ba),
    .sdram_dqm_   (sdram_dqm),
    .sdram_ras_n_ (sdram_ras_n),
    .sdram_cas_n_ (sdram_cas_n),
    .sdram_ce_    (sdram_ce),
    .sdram_clk_   (sdram_clk),
    .sdram_we_n_  (sdram_we_n),
    .sdram_cs_n_  (sdram_cs_n),

    // sram signals
    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  s29al032d_00 flash (
    .A21 (flash_addr[21]),
    .A20 (flash_addr[20]),
    .A19 (flash_addr[19]),
    .A18 (flash_addr[18]),
    .A17 (flash_addr[17]),
    .A16 (flash_addr[16]),
    .A15 (flash_addr[15]),
    .A14 (flash_addr[14]),
    .A13 (flash_addr[13]),
    .A12 (flash_addr[12]),
    .A11 (flash_addr[11]),
    .A10 (flash_addr[10]),
    .A9  (flash_addr[ 9]),
    .A8  (flash_addr[ 8]),
    .A7  (flash_addr[ 7]),
    .A6  (flash_addr[ 6]),
    .A5  (flash_addr[ 5]),
    .A4  (flash_addr[ 4]),
    .A3  (flash_addr[ 3]),
    .A2  (flash_addr[ 2]),
    .A1  (flash_addr[ 1]),
    .A0  (flash_addr[ 0]),

    .DQ7 (flash_data[7]),
    .DQ6 (flash_data[6]),
    .DQ5 (flash_data[5]),
    .DQ4 (flash_data[4]),
    .DQ3 (flash_data[3]),
    .DQ2 (flash_data[2]),
    .DQ1 (flash_data[1]),
    .DQ0 (flash_data[0]),

    .CENeg    (1'b0),
    .OENeg    (flash_oe_n),
    .WENeg    (flash_we_n),
    .RESETNeg (flash_rst_n),
    .ACC      (1'b1),
    .RY       (flash_ry)
  );

  mt48lc16m16a2 sdram (
    .Dq    (sdram_data),
    .Addr  (sdram_addr),
    .Ba    (sdram_ba),
    .Clk   (sdram_clk),
    .Cke   (sdram_ce),
    .Cs_n  (sdram_cs_n),
    .Ras_n (sdram_ras_n),
    .Cas_n (sdram_cas_n),
    .We_n  (sdram_we_n),
    .Dqm   (sdram_dqm)
  );

  IS61LV25616 sram (
    .A   (sram_addr_),
    .IO  (sram_data_),
    .CE_ (sram_ce_n_),
    .OE_ (sram_oe_n_),
    .WE_ (sram_we_n_),
    .LB_ (sram_bw_n_[0]),
    .UB_ (sram_bw_n_[1])
  );

  // Behaviour
  // Clock generation
  always #10 clk_50 <= !clk_50;
  always #18.518518 clk_27 <= !clk_27;

  initial
    begin
      $readmemh("bios.dat",flash.Mem);

      clk_50 <= 1'b0;
      clk_27 <= 1'b0;
      sw <= 10'h0;
    end

endmodule
