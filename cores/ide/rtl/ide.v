/*
 *  Wishbone IDE Controller
 *  Copyright (C) 2011  Geert Jan Laanstra <g.j.laanstraATutwente.nl>
 *
 *  Used to access IDE/ATAPI Devices like Harddisk, CdRom, etc...
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
 *
 *  2011-06-27 Geert Jan Laanstra
 */

module ide (
  input         wb_clk_i,
  input         wb_rst_i,

  input         wb_stb_i,
  input         wb_cyc_i,
  input  [19:1] wb_adr_i,
  input         wb_we_i,
  input  [ 1:0] wb_sel_i,
  input  [15:0] wb_dat_i,
  output [15:0] wb_dat_o,
  output        wb_ack_o,
  output        wb_tgc_o,
  
  output        ide_nreset,
  output        ide_ndiow,
  output        ide_ndior,
  output        ide_ncs1fx,
  output        ide_ncs3fx,
  output [ 2:0] ide_da,
  inout  [15:0] ide_dd,
  input         ide_iordy,

  input         ide_intrq,
  input         ide_dmarq,
  output        ide_ndmack,
  input         ide_npdiag
  );

  //------------------------------------------------------------------------------------------------------------------
  // IDE WB slave
  //------------------------------------------------------------------------------------------------------------------

  // delay stb
  reg [3:1] wb_stb_i_d;
  always @ (posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        wb_stb_i_d <= 3'b000;
      else 
        begin
          wb_stb_i_d[1] <= wb_stb_i;
          wb_stb_i_d[2] <= wb_stb_i_d[1];
          wb_stb_i_d[3] <= wb_stb_i_d[2];
        end
    end
	 
  // detect start of access
  wire adr_ena;
  wire cs_ena;
  wire act_ena;
  assign adr_ena = wb_stb_i      & ~wb_stb_i_d[1];
  assign cs_ena  = wb_stb_i_d[1] & ~wb_stb_i_d[2];
  assign act_ena = wb_stb_i_d[2] & ~wb_stb_i_d[3];

  reg [2:0] adr;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        adr <= 3'b000;
      else if (adr_ena)
        adr <= {wb_adr_i[2:1], (wb_sel_i[1:0] == 2'b10)};
      else
        adr <= adr;
    end
      
  reg ncs1fx;
  reg ncs3fx;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        begin
          ncs1fx <= 1'b1;
          ncs3fx <= 1'b1;
        end
      else if (cs_ena)
        begin
          ncs1fx <=  (wb_adr_i[9]);
          ncs3fx <= ~(wb_adr_i[9] & (wb_adr_i[2:1] == 2'b11));
        end
      else
        begin
          ncs1fx <= ncs1fx;
          ncs3fx <= ncs3fx;
        end
    end
  
  reg niow;
  reg nior;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | ide_ack)
        begin
          niow <= 1'b1;
          nior <= 1'b1;
        end
      else if (act_ena)
        begin
          niow <= (ncs1fx & ncs3fx) | ~wb_we_i;
          nior <= (ncs1fx & ncs3fx) |  wb_we_i;
        end
      else
        begin
          niow <= niow;
          nior <= nior;
        end
    end
    

  // generate address to ide interface
  reg ide_oe;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        ide_oe <= 1'b0;
      else if (adr_ena)
        ide_oe <= wb_we_i;
      else
        ide_oe <= ide_oe;
    end
    
  // generate data to ide interface
  reg [15:0] ide_wd;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        ide_wd <= 16'h0000;
      else if (adr_ena)
        begin
          if      (wb_we_i & (wb_sel_i == 2'b11))
            ide_wd <= wb_dat_i;
          else if (wb_we_i & (wb_sel_i == 2'b01))
            ide_wd <= {8'h00, wb_dat_i[7:0]};
          else if (wb_we_i & (wb_sel_i == 2'b10))
            ide_wd <= {8'h00, wb_dat_i[15:8]};
          else
            ide_wd <= 16'h0000;
        end         
      else
        ide_wd <= ide_wd;
    end
  assign ide_dd = (ide_oe ? ide_wd : 16'hZZZZ);

  // reading data back...
  reg [15:0] ide_rd;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wb_ack_o)
        ide_rd <= 16'h0000;
      else if (ide_ack)
        begin
          if      (~wb_we_i & (wb_sel_i == 2'b11))
            ide_rd <= ide_dd;
          else if (~wb_we_i & (wb_sel_i == 2'b01))
            ide_rd <= {8'h00, ide_dd[7:0]};
          else if (~wb_we_i & (wb_sel_i == 2'b10))
            ide_rd <= {ide_dd[7:0], 8'h00};
          else
            ide_rd <= 16'h0000;
        end
      else
        ide_rd <= ide_rd;
    end
  assign wb_dat_o = ide_rd;

  // acknowledge back to wb
  //reg ide_ack_pre;
  reg ide_ack;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | ide_ack)
        begin
          //ide_ack_pre <= 1'b0;
          ide_ack <= 1'b0;
        end
      else
        begin
          //ide_ack_pre <= ~(nior & niow);
          ide_ack <= (~(nior & niow) & ide_iordy);
        end  
    end

  reg wb_ack;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        wb_ack <= 1'b0;
      else
        wb_ack <= ide_ack;
    end
  assign wb_ack_o = wb_ack;

  // connect to ide interface
  assign ide_nreset = ~wb_rst_i;

  assign ide_da     = adr;

  assign ide_ncs1fx = ncs1fx;
  assign ide_ncs3fx = ncs3fx;
  
  assign ide_ndiow  = niow;
  assign ide_ndior  = nior;
  
  reg intrq;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        intrq <= 1'b0;
      else
        intrq <= ide_intrq;
    end
  assign wb_tgc_o = intrq;
  
  assign ide_ndmack = 1'b1;
endmodule
