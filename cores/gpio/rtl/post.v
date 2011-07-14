/*
 *  Wishbone Intel 8259 Prgrammable Interrupt Controller
 *  Copyright (C) 2011  Geert Jan Laanstra <g.j.laanstraATutwente.nl>
 *
 *  Fixed (not rotating) priority for now..
 *  Pipelined Wihbone Support 
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

module post (
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
  
  
  output [ 7:0] postcode
  );

  //------------------------------------------------------------------------------------------------------------------
  // PostCode WB slave
  //------------------------------------------------------------------------------------------------------------------

  // delay stb
  reg wb_stb_i_d1;
  always @ (posedge wb_clk_i)
    wb_stb_i_d1 <= wb_rst_i ? 1'b0 : wb_stb_i;
	 
  // detect start of access
  wire wb_stb;
  assign wb_stb = wb_stb_i & ~wb_stb_i_d1;

  // generate common write or read
  wire wr;
  wire rd;
  assign wr = wb_stb   & wb_cyc_i & wb_we_i  & ~wb_sel_i[1] &  wb_sel_i[0] & ~wb_ack;	 // Allow only byte access
  assign rd = wb_stb_i & wb_cyc_i & ~wb_we_i & ~wb_sel_i[1] &  wb_sel_i[0] & ~wb_ack;
  
  // generate write enables
  reg wr_post;
  always @(posedge wb_clk_i)
    begin
      wr_post <= wb_rst_i ? 1'b0 : wr;
    end

  // store data for pipeline block write support
  reg [15:0] wb_dat_ir;
  always @(posedge wb_clk_i)
  begin
    if (wb_rst_i)
      wb_dat_ir <= 16'h0000;
    else
      wb_dat_ir <= wb_dat_i;
  end
    
  reg [7:0] post;

  always @(posedge wb_clk_i)
    begin
	    if (wb_rst_i)
		    begin
			  post <= 8'b0;
			end
	    else
		    begin
			  post = wr_post ? wb_dat_ir[ 7:0] : post;
		    end
    end
	
  // reading status
  reg [15:0] dat_o;
  always @(posedge wb_clk_i)
    begin
      // reading imr
	  if (wb_rst_i)
      dat_o[15:8] <= 8'h00;
    else
      dat_o[15:8] <= 8'h00;
		
      // reading of register
	  if (wb_rst_i)
	    dat_o[ 7:0] <= 8'h00;
    else if (rd)
      dat_o[ 7:0] <= post;
    else
      dat_o[7:0] <= 8'h00;	  
    end
  assign wb_dat_o = dat_o;
  
  // acknowledge back to wb
  reg wb_ack;
  always @(posedge wb_clk_i)
    wb_ack <= wb_rst_i ? 1'b0 : ((wr | rd) & ~wb_ack);
  assign wb_ack_o = wb_ack;

  assign postcode = post;
endmodule
