/*
 *  DUT VGA LCD FML
 *
 *  VGA FML support
 *  Copyright (C) 2013 Charley Picker <charleypicker@yahoo.com>
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

//`timescale 1ns/10ps
`timescale 1ns/1ps

module tb_vga_lcd_fml;

  // Registers and nets
  reg       clk_100;
  reg       rst;
  
  reg shift_reg1;       // if set: 320x200
  reg graphics_alpha;   // if not set: 640x400 text mode

  // VGA LCD FML master interface
  wire [20-1:0] fml_adr;
  wire                 fml_stb;
  reg                  fml_we;
  reg                  fml_ack;
  wire           [1:0] fml_sel;
  wire          [15:0] fml_do;
  reg           [15:0] fml_di;
    
  // VGA LCD Direct Cache Bus
  wire                 dcb_stb;
  wire        [20-1:0] dcb_adr;
  reg           [15:0] dcb_dat;
  reg                  dcb_hit;
	
  // attribute_ctrl
  reg   [3:0] pal_addr;
  reg         pal_we;
  wire  [7:0] pal_read;
  reg   [7:0] pal_write;

  // dac_regs
  reg        dac_we;
  reg  [1:0] dac_read_data_cycle;
  reg  [7:0] dac_read_data_register;
  wire [3:0] dac_read_data;
  reg  [1:0] dac_write_data_cycle;
  reg  [7:0] dac_write_data_register;
  reg  [3:0] dac_write_data;

  // VGA pad signals
  wire [3:0] vga_red_o;
  wire [3:0] vga_green_o;
  wire [3:0] vga_blue_o;
  wire       horiz_sync;
  wire       vert_sync;
    
  // Base address of video memory
  reg [15:0] start_addr;

  // CRTC
  reg [5:0] cur_start;
  reg [5:0] cur_end;
  reg [4:0] vcursor;
  reg [6:0] hcursor;

  reg [6:0] horiz_total;
  reg [6:0] end_horiz;
  reg [6:0] st_hor_retr;
  reg [4:0] end_hor_retr;
  reg [9:0] vert_total;
  reg [9:0] end_vert;
  reg [9:0] st_ver_retr;
  reg [3:0] end_ver_retr;

  reg x_dotclockdiv2;

  // retrace signals
  wire v_retrace;
  wire vh_retrace;
  
  wire vga_clk;
  
  /* Process FML requests */
  reg [2:0] fml_wcount;
  reg [2:0] fml_rcount;
  reg [3:0] fml_pipe;
  initial begin
	  fml_ack = 1'b0;
	  fml_wcount = 0;
	  fml_rcount = 0;
  end
  
  always @(posedge clk_100)
    fml_pipe <= rst ? 4'b0 : { fml_pipe[2:0], fml_stb };

  always @(posedge clk_100) begin
	  if(fml_stb & (fml_wcount == 0) & (fml_rcount == 0)) begin
		  fml_ack <= 1'b1;
		  if(fml_we) begin
			  //$display("%t FML W addr %x data %x", $time, fml_adr, fml_dw);
			  fml_wcount <= 7;
		  end else begin
			  fml_di = 16'hbeef;
			  //$display("%t FML R addr %x data %x", $time, fml_adr, fml_di);
			  fml_rcount <= 7;
		  end
	  end else
		  fml_ack <= 1'b0;
	  if(fml_wcount != 0) begin
		  //#1 $display("%t FML W continuing %x / %d", $time, fml_dw, fml_wcount);
		  fml_wcount <= fml_wcount - 1;
	  end
	  if(fml_rcount != 0) begin
		  //fml_di = #1 {13'h1eba, fml_rcount};
		  fml_di = {13'h1eba, fml_rcount};
		  //$display("%t FML R continuing %x / %d", $time, fml_di, fml_rcount);
		  fml_rcount <= fml_rcount - 1;
	  end
  end
  
  /* Process DCB requests */
  //reg [15:0] dcb_dat;
  reg [2:0] dcb_rcount;
  reg [3:0] dcb_pipe;
  initial begin
	  dcb_hit = 1'b0;	  
	  dcb_rcount = 0;
  end
  
  always @(posedge clk_100)
    dcb_pipe <= rst ? 4'b0 : { dcb_pipe[2:0], dcb_stb };

  always @(posedge clk_100) begin
    //if (dcb_stb)
      //$display("%t DCB R addr %x", $time, dcb_adr);
    if (dcb_stb & (dcb_rcount == 0))
         begin
           dcb_hit <= 1'b1;
           //dcb_hit <= 1'b0;
		       dcb_dat = 16'hbeef;
			     //$display("%t DCB R addr %x data %x", $time, dcb_adr, dcb_dat);
			     dcb_rcount <= 7;
		     end else
		         dcb_hit <= 1'b0;		
	  if(dcb_stb & (dcb_rcount != 0)) begin
		         //dcb_dat = #1 {13'h1eba, dcb_rcount};
		         dcb_dat = {13'h1eba, dcb_rcount};
		         //$display("%t DCB R continuing %x / %d", $time, dcb_dat, dcb_rcount);
		         dcb_rcount <= dcb_rcount - 1;
	  end	  
  end
  
  // Module instantiations
  vga_lcd_fml #(
    .fml_depth   (20)  // 8086 can only address 1 MB  
    ) dut (
      .clk(clk_100),              // 100 Mhz clock
      .rst(rst),

      .shift_reg1(shift_reg1),       // if set: 320x200
      .graphics_alpha(graphics_alpha),   // if not set: 640x400 text mode

      // VGA LCD FML master interface
      .fml_adr(fml_adr),
      .fml_stb(fml_stb),
      .fml_we(fml_we),
      .fml_ack(fml_ack),
      .fml_sel(fml_sel),
      .fml_do(fml_do),
      .fml_di(fml_di),
    
      // VGA LCD Direct Cache Bus
      .dcb_stb(dcb_stb),
      .dcb_adr(dcb_adr),
      .dcb_dat(dcb_dat),
      .dcb_hit(dcb_hit),

      // attribute_ctrl
      .pal_addr(pal_addr),
      .pal_we(pal_we),
      .pal_read(pal_read),
      .pal_write(pal_write),

      // dac_regs
      .dac_we(dac_we),
      .dac_read_data_cycle(dac_read_data_cycle),
      .dac_read_data_register(dac_read_data_register),
      .dac_read_data(dac_read_data),
      .dac_write_data_cycle(dac_write_data_cycle),
      .dac_write_data_register(dac_write_data_register),
      .dac_write_data(dac_write_data),

      // VGA pad signals
      .vga_red_o(vga_red_o),
      .vga_green_o(vga_green_o),
      .vga_blue_o(vga_blue_o),
      .horiz_sync(horiz_sync),
      .vert_sync(vert_sync),
    
      // Base address of video memory
      .start_addr(start_addr),

      // CRTC
      .cur_start(cur_start),
      .cur_end(cur_end),
      .vcursor(vcursor),
      .hcursor(hcursor),

      .horiz_total(horiz_total),
      .end_horiz(end_horiz),
      .st_hor_retr(st_hor_retr),
      .end_hor_retr(end_hor_retr),
      .vert_total(vert_total),
      .end_vert(end_vert),
      .st_ver_retr(st_ver_retr),
      .end_ver_retr(end_ver_retr),

      .x_dotclockdiv2(x_dotclockdiv2),

      // retrace signals
      .v_retrace(v_retrace),
      .vh_retrace(vh_retrace),
      
      .vga_clk(vga_clk)
  );
    
  // Continuous assignments
  
    
  // Behaviour
  // Clock generation
  //always #10 clk_100 <= !clk_100;
  initial clk_100 = 1'b0;
  always #5 clk_100 = ~clk_100;
  
task waitclock;
begin
	@(posedge clk_100);
	#1;
end
endtask

always begin
  // Initialize to a known state
  rst = 1'b1;  // reset is active  
        
  waitclock;  
    
  rst = 1'b0;
  
  waitclock;
  
 /* 
  // Set Text Mode
  shift_reg1   = 1'b0;       // if set: 320x200
  graphics_alpha = 1'b0;   // if not set: 640x400 text mode
 */
  
  
  
  // Set Linear Mode
  shift_reg1   = 1'b1;       // if set: 320x200
  graphics_alpha = 1'b1;   // if not set: 640x400 text mode
  
  
  // Base address of video memory
  start_addr = 16'h1000;  
      
  // CRTC configuration signals
    
  cur_start    = 5'd0;   // reg [5:0]   cur_start,
  cur_end      = 5'd0;   // reg [5:0]   cur_end,
  vcursor      = 4'd0;   // reg [4:0]   vcursor,
  hcursor      = 6'd0;   // reg [6:0]   hcursor,
  
  
  horiz_total  = 7'd79; // reg [6:0]   horiz_total,
  //horiz_total  = 7'd639; // reg [6:0]   horiz_total,
  end_horiz    = 7'd750; // reg [6:0]   end_horiz,
  st_hor_retr  = 7'd760; // reg [6:0]   st_hor_retr,
  st_hor_retr  = 7'd656; // reg [6:0]   st_hor_retr,
  //end_hor_retr = 5'd10;  // reg [4:0]   end_hor_retr,
  end_hor_retr = 5'd750;  // reg [4:0]   end_hor_retr,
  end_hor_retr = 5'd752;  // reg [4:0]   end_hor_retr,
  vert_total   = 10'd399; // reg [9:0]   vert_total,
  end_vert     = 10'd550; // reg [9:0]   end_vert,
  st_ver_retr  = 10'd560; // reg [9:0]   st_ver_retr,
  //end_ver_retr = 4'd10;  // reg [3:0]   end_ver_retr,
  end_ver_retr = 4'd750;  // reg [3:0]   end_ver_retr,
      
  x_dotclockdiv2 = 1'b0;  // reg x_dotclockdiv2
  
  repeat (20000) begin
      waitclock;
  end
  
  $stop;
      
end  

endmodule