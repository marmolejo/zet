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
 *
 *  USALion MS           - porting zet to DE2_70 board
 *  30th October 2009
 */
 
 
module kotku (

	input         iCLK_50,
	output [15:0] oLEDR,
	output [7:0] oLEDG,
	input  [7:0] iSW,

	// flash signals
    output [21:0] oFLASH_A,                      
    input  [31:0] FLASH_DQ,                      
    output        oFLASH_BYTE_N,                 
    output        oFLASH_WE_N,                   
    output        oFLASH_OE_N,                   
    output        oFLASH_CE_N,                   
    output        oFLASH_RST_N,                  
    //input		  iFLASH_RY_N
    output        oFLASH_WP_N,

    // sdram signals
    output [12:0] oDRAM1_A,
    inout  [31:16] DRAM_DQ,
    output [ 1:0] oDRAM1_BA,
    output [ 1:0] oDRAM1_DQM,
    output        oDRAM1_RAS_N,
    output        oDRAM1_CAS_N,
    output        oDRAM1_CKE,
    output        oDRAM1_CLK,
    output        oDRAM1_WE_N,
    output        oDRAM1_CS_N,

    // sram signals
    output [18:0] oSRAM_A,                       //sram_addr_,
    inout  [31:0] SRAM_DQ,                       //[15:0] sram_data_,
    output        oSRAM_WE_N,                    //sram_we_n_,
    output        oSRAM_OE_N,                    //sram_oe_n_,          
    output        oSRAM_CE1_N,					 //sram_ce_n_,
    output [ 3:0] oSRAM_BE_N,                    //[1:0]sram_bw_n_,   

	output        oSRAM_CLK,
	
    inout  [3:0]  SRAM_DPA,
	
    output        oSRAM_CE2,
    output        oSRAM_CE3_N,   
    output        oSRAM_GW_N,
    output        oSRAM_ADSP_N,   
    output        oSRAM_ADSC_N,
	output        oSRAM_ADV_N, 
      
    // VGA signals
    output [ 9:0] oVGA_R,                       
    output [ 9:0] oVGA_G,                       
    output [ 9:0] oVGA_B,                       
    output        oVGA_HS,                      
    output        oVGA_VS,
        
    output        oVGA_SYNC_N,                  
    output        oVGA_BLANK_N,
    output        oVGA_CLOCK,
    
    // UART signals
    input         iUART_RXD,
    output        oUART_TXD,

    // PS2 signals
    inout         PS2_KBCLK,
    inout         PS2_KBDAT,
    
    // SD card signals
    output        oSD_CLK,
    input         SD_DAT,
    output        SD_CMD,
    output        SD_DAT3
   
 );

 // Registers and nets
 wire        clk;
 wire        lock;
 wire        rst;
 wire [15:0] dat_o;
 wire [15:0] dat_i;
 wire [19:1] adr;
 wire        we;
 wire        tga;
 wire [ 1:0] sel;
 wire        stb;
 
 // FLASH
 wire        flash_stb;
 wire        cyc;
 wire        ack;
 wire        flash_ack;
 wire        flash_arena;
 wire        flash_mem_arena; 
 wire        flash_io_arena;
 wire [15:0] flash_dat_o;

  // SDRAM
  wire [31:0] sdram_dat_o;
  wire        sdram_stb;
  wire        sdram_ack;
  wire        sdram_mem_arena;
  wire        sdram_arena;  
  wire        sdram_clk;

  // VGA
  wire        vdu_clk;
  wire [15:0] vdum_dat_i;
  wire [ 6:0] h_vdu_adr;
  wire [11:1] vdum_adr_o;
  wire        vdum_we_o;
  wire [ 1:0] vdum_sel_o;
  wire        vdum_stb_o;
  wire        vdum_cyc_o;
  wire        vdum_ack_i;
  wire [15:0] vdu_dat_o;
  wire [15:0] vga_dat_o;
  wire        vdu_ack;
  wire        vdu_ack_o;
  wire        vdu_stb;
  wire        vga_stb;
  wire        vdu_mem_arena;
  wire        vdu_io_arena;
  wire        vdu_arena;
  reg  [ 1:0] vdu_stb_sync;

  // COM1
  wire        com1_stb;
  wire [ 7:0] com1_dat_i;
  wire [ 7:0] com1_dat_o;
  wire        com1_ack_o;
  wire        com1_io_arena;
  wire        com1_arena;

  // EMS
  wire        ems_stb;
  wire [15:0] ems_dat_o;
  wire        ems_ack_o;
  wire        ems_io_arena;
  wire        ems_arena;
  wire [31:0] ems_sdram_adr;

  // KEYBOARD
  wire [ 7:0] keyb_dat_o;
  wire        keyb_io_arena;
  wire        keyb_io_status;

  // INT
  wire [ 7:0] intv;
  wire [ 2:0] iid;
  wire        intr;
  wire        inta;
  
  // SD
  wire [ 7:0] sd_dat_o;
  wire        sd_io_arena;
  wire        sd_arena;
  wire        sd_ack;
  wire        sd_stb;

  wire        sw_arena;

  
  reg  [15:0] io_reg;
 

  // Spare Pins
  // SSRAM
  assign oSRAM_CE2       = 1'b1;
  assign oSRAM_CE3_N     = 1'b0;
  assign oSRAM_CLK       = 1'b1;
  assign oSRAM_GW_N      = 1'b1;
  assign oSRAM_ADSC_N    = 1'b1;
  assign oSRAM_ADSP_N    = 1'b1;
  assign oSRAM_ADV_N     = 1'b1;
  assign SRAM_DQ[31:16]  = 16'bz;
  assign oSRAM_A[18]     = 1'b0;
  
 // VGA
  assign oVGA_BLANK_N    = 1'b1;
  assign oVGA_SYNC_N     = 1'b1;

 // Module instances
 pll pll (
   .inclk0 (iCLK_50),
   .c0     (sdram_clk),
   .c1     (vdu_clk),
   .c2     (clk),
   .locked (lock)
 );
 

 flash flash (
	// Wishbone slave interface
	.wb_clk_i (clk),
	.wb_rst_i (rst),
	.wb_dat_o (flash_dat_o),
	.wb_adr_i (adr[16:1]), //(adr[16:1]),
	.wb_stb_i (flash_stb),
	.wb_cyc_i (flash_stb),
	.wb_ack_o (flash_ack),

	// Pad signals
	.flash_addr_   (oFLASH_A),       		 
	.flash_data_   (FLASH_DQ), 				 
	.flash_byte_n_ (oFLASH_BYTE_N),			 
	.flash_we_n_   (oFLASH_WE_N),  			 
	.flash_oe_n_   (oFLASH_OE_N),        	 
	.flash_ce_n_   (oFLASH_CE_N),			 
	.flash_rst_n_  (oFLASH_RST_N),			 
    .flash_wp_n_   (oFLASH_WP_N)
 );

  yadmc #(
    .sdram_depth       (23),
    .sdram_columndepth (9),  //8
    .sdram_adrwires    (13), //12
    .cache_depth       (4)
    ) yadmc (

    // Wishbone slave interface
    .sys_clk  (clk),
    .sys_rst  (rst),
    .wb_adr_i (ems_sdram_adr),
    .wb_dat_i ({16'h0,dat_o}),
    .wb_dat_o (sdram_dat_o),
    .wb_sel_i ({2'b00,sel}),
    .wb_cyc_i (sdram_stb),
    .wb_stb_i (sdram_stb),
    .wb_we_i  (we),
    .wb_ack_o (sdram_ack),

    // SDRAM interface
    .sdram_clk   (sdram_clk),
    .sdram_cke   (oDRAM1_CKE),
    .sdram_cs_n  (oDRAM1_CS_N),
    .sdram_we_n  (oDRAM1_WE_N),
    .sdram_cas_n (oDRAM1_CAS_N),
    .sdram_ras_n (oDRAM1_RAS_N),
    .sdram_dqm   (oDRAM1_DQM),
    .sdram_adr   (oDRAM1_A),
    .sdram_ba    (oDRAM1_BA),
    .sdram_dq    (DRAM_DQ[31:16])
  );

  vga vga (
    // Wishbone slave interface
    .wb_rst_i (rst),
    .wb_clk_i (vdu_clk), // 25MHz VDU clock
    .wb_dat_i (dat_o),
    .wb_dat_o (vga_dat_o),
    .wb_adr_i (adr[16:1]),    // 128K
    .wb_we_i  (we),
    .wb_tga_i (tga),
    .wb_sel_i (sel),
    .wb_stb_i (vga_stb),
    .wb_cyc_i (vga_stb),
    .wb_ack_o (vdu_ack_o),

    // VGA pad signals
    .vga_red_o   (oVGA_R),
    .vga_green_o (oVGA_G),
    .vga_blue_o  (oVGA_B),
    .horiz_sync  (oVGA_HS),
    .vert_sync   (oVGA_VS),

    // SRAM pad signals
    .sram_addr_ (oSRAM_A[17:0]),
    .sram_data_ (SRAM_DQ[15:0]),
    .sram_we_n_ (oSRAM_WE_N),
    .sram_oe_n_ (oSRAM_OE_N),
    .sram_ce_n_ (oSRAM_CE1_N),
    .sram_bw_n_ (oSRAM_BE_N[3:0])
  );

  delay_ack d_ack_vga (
    .clk_vga  (vdu_clk),
    .clk_cpu  (clk),
    .wb_rst_i (rst),
    .wb_ack_i (vdu_ack_o),
    .wb_stb_i (vdu_stb_sync[1]),
    .wb_ack_o (vdu_ack),
    .wb_stb_o (vga_stb),

    .wb_dat_cpu (vga_dat_o),
    .wb_dat_o   (vdu_dat_o)
  );

  uart_top com1 (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_adr_i ({adr[2:1],~sel[0]}),
    .wb_dat_i (com1_dat_i),
    .wb_dat_o (com1_dat_o),
    .wb_we_i  (we),
    .wb_stb_i (com1_stb),
    .wb_cyc_i (cyc),
    .wb_ack_o (com1_ack_o),
    .wb_sel_i (4'b0),
    .int_o    (intv[4]), // interrupt request

    // UART signals
    // serial input/output
    .stx_pad_o  (oUART_TXD),
    .srx_pad_i  (iUART_RXD),

    // modem signals
    //.rts_pad_o,
    .cts_pad_i  (1'b1),
    //.dtr_pad_o,
    .dsr_pad_i  (1'b1),
    .ri_pad_i   (1'b0),
    .dcd_pad_i  (1'b0)
    //, baud_o
  );

 ems #(
    .IO_BASE_ADDR (16'h0208)
    ) ems_card (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_adr_i (adr[15:1]),
    .wb_dat_i (dat_o),
    .wb_dat_o (ems_dat_o),
    .wb_sel_i (sel),
    .wb_cyc_i (cyc),
    .wb_stb_i (ems_stb),
    .wb_we_i (we),
    .wb_ack_o (ems_ack_o),
    .ems_io_arena (ems_io_arena),

    // sdram address interface
    .sdram_adr_i (adr),
    .sdram_adr_o (ems_sdram_adr)
  );



  ps2_keyb #(
    .TIMER_60USEC_VALUE_PP (750),
    .TIMER_60USEC_BITS_PP  (10),
    .TIMER_5USEC_VALUE_PP  (60),
    .TIMER_5USEC_BITS_PP   (6)
    ) keyboard (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_o (keyb_dat_o),
    .wb_tgc_o (intv[1]),

    .ps2_clk_  (PS2_KBCLK),
    .ps2_data_ (PS2_KBDAT)
  );
  
  
    timer #(
    .res   (33),
    .phase (12507)
    ) timer0 (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_tgc_o (intv[0])
  );

  simple_pic pic0 (
    .clk  (clk),
    .rst  (rst),
    .intv (intv),
    .inta (inta),
    .intr (intr),
    .iid  (iid)
  );

  
    sdspi sdspi (
    // Serial pad signal
    .sclk  (oSD_CLK),
    .miso  (SD_DAT),
    .mosi  (SD_CMD),
    .ss    (SD_DAT3),

    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (sd_dat_o),
    .wb_we_i  (we),
    .wb_sel_i (sel),
    .wb_stb_i (sd_stb),
    .wb_cyc_i (sd_stb),
    .wb_ack_o (sd_ack)
  );


  
 cpu zet_proc (
      
   // Wishbone master interface
   .wb_clk_i (clk),
   .wb_rst_i (rst),
   .wb_dat_i (dat_i),
   .wb_dat_o (dat_o),
   .wb_adr_o (adr),
   .wb_we_o  (we),
   .wb_tga_o (tga),
   .wb_sel_o (sel),
   .wb_stb_o (stb),
   .wb_cyc_o (cyc),
   .wb_ack_i (ack),
   .wb_tgc_i (1'b0)
 );

 //Green LEDs
 assign oLEDG[0] = flash_arena;
 assign oLEDG[1] = sdram_arena;
 assign oLEDG[2] = vdu_arena;

 


 //Memory Map

  // Continous assignments
  assign rst = !lock;

  // FLASH
  assign flash_mem_arena = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign flash_io_arena  = (adr[15:9]==7'b1110_000);
  assign flash_arena     = (!tga & flash_mem_arena)
                         | (tga & flash_io_arena);
  assign flash_stb       = flash_arena & stb & cyc;

  // SDRAM
  assign oDRAM1_CLK      = sdram_clk;
  assign sdram_mem_arena = !flash_mem_arena & !vdu_mem_arena;
  assign sdram_arena     = !tga & sdram_mem_arena;
  assign sdram_stb       = sdram_arena & stb & cyc;

// VDU
  assign oVGA_CLOCK      = vdu_clk;
  assign vdu_mem_arena   = (adr[19:17]==5'b101);  // A0000h-BFFFFh -- 128K
  assign vdu_io_arena    = (adr[15:5]==11'b0000_0011_110);
  assign vdu_arena       = (!tga & vdu_mem_arena)
                         | (tga & vdu_io_arena);
  assign vdu_stb         = vdu_arena & stb & cyc;

  // COM1
  assign com1_io_arena   = (adr[15:4]==12'h03f && adr[3]==1'b1);
  assign com1_arena      = (tga & com1_io_arena);
  assign com1_stb        = com1_arena & stb & cyc;
  assign com1_dat_i      = (sel[0] ? dat_o[7:0] : dat_o[15:8]);

  // EMS gets its I/O address from "dipswitches" (parameter) on the EMS module
  //assign ems_io_arena   = {adr[15:4]==12'h020 && adr[3]==1'b1};
  assign ems_arena      = (tga & ems_io_arena);
  assign ems_stb        = ems_arena & stb & cyc;

  // MS-DOS is reading IO address 0x64 to check the inhibit bit
  assign keyb_io_status  = (adr[15:1]==15'h0032 && !we);
  assign keyb_io_arena   = (adr[15:1]==15'h0030 && !we);

  // SD
  assign sd_io_arena     = (adr[15:1]==15'h0080);
  assign sd_arena        = sd_io_arena & tga;
  assign sd_stb          = sd_arena & stb & cyc;

  assign sw_arena        = (adr[15:1]==15'h0081);

  assign ack             = tga ? (flash_io_arena ? flash_ack
                               : (vdu_io_arena ? vdu_ack
                               : (sd_io_arena ? sd_ack
                               : (com1_io_arena ? com1_ack_o
                               : (ems_io_arena ? ems_ack_o
                             //  : (sb16_io_arena ? sb16_ack_o 
                               : (stb & cyc))))))  
							   : (vdu_mem_arena ? vdu_ack
                               : (flash_mem_arena ? flash_ack 
                               : sdram_ack)); 

  assign io_dat_i  = flash_io_arena ? flash_dat_o
                   : (vdu_io_arena ? vdu_dat_o
                   : (com1_io_arena ? {com1_dat_o, com1_dat_o}
                   : (ems_io_arena ? ems_dat_o
            //       : (sb16_io_arena ? sb16_dat_o
                   : (keyb_io_arena ? keyb_dat_o
                   : (keyb_io_status ? 16'h10
                   : (sd_io_arena ? {8'h0,sd_dat_o}
                   : (sw_arena ? iSW[7:0] 
                   : 16'hffff)))))));

  assign dat_i     = inta ? { 13'b0000_0000_0000_1, iid }
                   : (tga ? io_dat_i
                   : (vdu_mem_arena ? vdu_dat_o
                   : (flash_mem_arena ? flash_dat_o
                   : sdram_dat_o[15:0]))); 

 // LEDS
 assign oLEDR = io_reg;
 always @(posedge clk)
   io_reg <= rst ? 16'h0 //: 16'h5555;
       : ((tga && stb && cyc && we && adr[15:8]==8'hF1) //0x00F1XX
       ?   dat_o : io_reg );

  // vdu_stb_sync
  always @(posedge vdu_clk)
    vdu_stb_sync <= { vdu_stb_sync[0], vdu_stb };




endmodule
