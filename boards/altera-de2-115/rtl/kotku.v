/*
 *  Zet SoC top level file for Altera DE2-115 board
 *  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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

module kotku (
    // Clock input
    input        clk_50_,

    // General purpose IO
    input  [7:0] sw_,
    input        key_,
    output [6:0] hex0_,
    output [6:0] hex1_,
    output [6:0] hex2_,
    output [6:0] hex3_,
    output [6:0] hex4_,
	  output [6:0] hex5_,
    
	  output [6:0] hex6_,   // bios post code ?
    output [6:0] hex7_,
    
    output [17:0] ledr_,  // red leds
    output [7:0] ledg_,   // green leds

    // flash signals
    output [22:0] flash_addr_,
    input  [ 7:0] flash_data_,
    output        flash_oe_n_,
    output        flash_ce_n_,

    // sdram signals
    output [11:0] sdram_addr_,
    inout  [15:0] sdram_data_,
    output [ 1:0] sdram_ba_,
    output        sdram_ras_n_,
    output        sdram_cas_n_,
    output        sdram_ce_,
    output        sdram_clk_,
    output        sdram_we_n_,
    output        sdram_cs_n_,

    // sram signals
    output [16:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output [ 1:0] sram_bw_n_,

    // VGA signals
    output [ 3:0] tft_lcd_r_,
    output [ 3:0] tft_lcd_g_,
    output [ 3:0] tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,
    output        tft_lcd_clk_,

    // UART signals
    output        uart_txd_,

    // PS2 signals
    input         ps2_kclk_, // PS2 keyboard Clock
    inout         ps2_kdat_, // PS2 Keyboard Data
    inout         ps2_mclk_, // PS2 Mouse Clock
    inout         ps2_mdat_, // PS2 Mouse Data

    // SD card signals
    output        sd_sclk_,
    input         sd_miso_,
    output        sd_mosi_,
    output        sd_ss_,

    // I2C for audio codec
    inout         i2c_sdat_,
    output        i2c_sclk_,

    // Audio codec signals
    input         aud_daclrck_,
    output        aud_dacdat_,
    input         aud_bclk_,
    output        aud_xck_
  );

  // Registers and nets
  wire        cpu_clk;
  wire        sdram_clk;
  wire        vga_clk;
  wire        pll_lock;
  
  // wires to CPU  
  wire [19:0] cpu_pc;

  wire        cpu_stb_o;
  wire        cpu_cyc_o;
  wire        cpu_tga_o;
  wire [19:1] cpu_adr_o;
  wire        cpu_we_o;
  wire [ 1:0] cpu_sel_o;
  wire [15:0] cpu_dat_o;
  wire [15:0] cpu_dat_i;
  wire        cpu_ack_i;
  wire [ 1:0] cpu_tgc_i;
  wire [ 1:0] cpu_tgc_o;
  
  // wires to BIOS ROM
  wire [15:0] rom_dat_o;
  wire [15:0] rom_dat_i;
  wire        rom_tga_i;
  wire [19:1] rom_adr_i;
  wire [ 1:0] rom_sel_i;
  wire        rom_we_i;
  wire        rom_cyc_i;
  wire        rom_stb_i;
  wire        rom_ack_o;

  // wires to flash controller
  wire [15:0] fl_dat_o;
  wire [15:0] fl_dat_i;
  wire        fl_tga_i;
  wire [19:1] fl_adr_i;
  wire [ 1:0] fl_sel_i;
  wire        fl_we_i;
  wire        fl_cyc_i;
  wire        fl_stb_i;
  wire        fl_ack_o;

  // Unused outputs
  wire       flash_we_n_;
  wire       flash_rst_n_;
  wire       sram_ce_n_;
  wire [1:0] sdram_dqm_;
  wire       a12;
  wire [2:0] s19_17;

  // Unused inputs
  wire uart_rxd_;
  wire aud_adcdat_;

  // wires to vga controller
  wire [15:0] vga_dat_o;
  wire [15:0] vga_dat_i;
  wire        vga_tga_i;
  wire [19:1] vga_adr_i;
  wire [ 1:0] vga_sel_i;
  wire        vga_we_i;
  wire        vga_cyc_i;
  wire        vga_stb_i;
  wire        vga_ack_o;

  // cross clock domain synchronized signals
  wire [15:0] vga_dat_o_s;
  wire [15:0] vga_dat_i_s;
  wire        vga_tga_i_s;
  wire [19:1] vga_adr_i_s;
  wire [ 1:0] vga_sel_i_s;
  wire        vga_we_i_s;
  wire        vga_cyc_i_s;
  wire        vga_stb_i_s;
  wire        vga_ack_o_s;

  // wires to uart controller
  wire [15:0] uart_dat_o;
  wire [15:0] uart_dat_i;
  wire        uart_tga_i;
  wire [19:1] uart_adr_i;
  wire [ 1:0] uart_sel_i;
  wire        uart_we_i;
  wire        uart_cyc_i;
  wire        uart_stb_i;
  wire        uart_ack_o;

  wire        int_uart;
  
  // wires to keyboard controller
  wire [15:0] keyb_dat_o;
  wire [15:0] keyb_dat_i;
  wire        keyb_tga_i;
  wire [19:1] keyb_adr_i;
  wire [ 1:0] keyb_sel_i;
  wire        keyb_we_i;
  wire        keyb_cyc_i;
  wire        keyb_stb_i;
  wire        keyb_ack_o;
  
  wire        int_keyboard;
  wire        int_mouse;
  
    // wires to speaker controller
  wire [15:0] spk_dat_o;
  wire [15:0] spk_dat_i;
  wire        spk_tga_i;
  wire [19:1] spk_adr_i;
  wire [ 1:0] spk_sel_i;
  wire        spk_we_i;
  wire        spk_cyc_i;
  wire        spk_stb_i;
  wire        spk_ack_o;

  // wires to timer controller
  wire [15:0] timer_dat_o;
  wire [15:0] timer_dat_i;
  wire        timer_tga_i;
  wire [19:1] timer_adr_i;
  wire [ 1:0] timer_sel_i;
  wire        timer_we_i;
  wire        timer_cyc_i;
  wire        timer_stb_i;
  wire        timer_ack_o;
  
  wire        int_timer;

  // wires to sd controller
  wire [19:1] sd_adr_i;
  wire [15:0] sd_dat_o;
  wire [15:0] sd_dat_i;
  wire        sd_tga_i;
  wire [ 1:0] sd_sel_i;
  wire        sd_we_i;
  wire        sd_cyc_i;
  wire        sd_stb_i;
  wire        sd_ack_o;

  // wires to sd bridge
  wire [19:1] sd_adr_i_s;
  wire [15:0] sd_dat_o_s;
  wire [15:0] sd_dat_i_s;
  wire        sd_tga_i_s;
  wire [ 1:0] sd_sel_i_s;
  wire        sd_we_i_s;
  wire        sd_cyc_i_s;
  wire        sd_stb_i_s;
  wire        sd_ack_o_s;

  // wires to gpio controller
  wire [15:0] gpio_dat_o;
  wire [15:0] gpio_dat_i;
  wire        gpio_tga_i;
  wire [19:1] gpio_adr_i;
  wire [ 1:0] gpio_sel_i;
  wire        gpio_we_i;
  wire        gpio_cyc_i;
  wire        gpio_stb_i;
  wire        gpio_ack_o;

  // wires to postcode port
  wire        post_stb_i;
  wire        post_cyc_i;
  wire        post_tga_i;
  wire [19:0] post_adr_i;
  wire        post_we_i;
  wire [ 1:0] post_sel_i;
  wire [15:0] post_dat_i;
  wire [15:0] post_dat_o;
  wire        post_ack_o;
  
  wire [ 7:0] postcode;

	
  // wires to SDRAM controller
  wire [19:1] fmlbrg_adr_s;
  wire [15:0] fmlbrg_dat_w_s;
  wire [15:0] fmlbrg_dat_r_s;
  wire [ 1:0] fmlbrg_sel_s;
  wire        fmlbrg_cyc_s;
  wire        fmlbrg_stb_s;
  wire        fmlbrg_tga_s;
  wire        fmlbrg_we_s;
  wire        fmlbrg_ack_s;

  wire [19:1] fmlbrg_adr;
  wire [15:0] fmlbrg_dat_w;
  wire [15:0] fmlbrg_dat_r;
  wire [ 1:0] fmlbrg_sel;
  wire        fmlbrg_cyc;
  wire        fmlbrg_stb;
  wire        fmlbrg_tga;
  wire        fmlbrg_we;
  wire        fmlbrg_ack;

  wire [19:1] csrbrg_adr_s;
  wire [15:0] csrbrg_dat_w_s;
  wire [15:0] csrbrg_dat_r_s;
  wire [ 1:0] csrbrg_sel_s;
  wire        csrbrg_cyc_s;
  wire        csrbrg_stb_s;
  wire        csrbrg_tga_s;
  wire        csrbrg_we_s;
  wire        csrbrg_ack_s;

  wire [19:1] csrbrg_adr;
  wire [15:0] csrbrg_dat_w;
  wire [15:0] csrbrg_dat_r;
  wire [ 1:0] csrbrg_sel;
  wire        csrbrg_tga;
  wire        csrbrg_cyc;
  wire        csrbrg_stb;
  wire        csrbrg_we;
  wire        csrbrg_ack;

  wire        sb_cyc_i;
  wire        sb_stb_i;

  wire [ 2:0] csr_a;
  wire        csr_we;
  wire [15:0] csr_dw;
  wire [15:0] csr_dr_hpdmc;

  wire [25:0] fml_adr;
  wire        fml_stb;
  wire        fml_we;
  wire        fml_ack;
  wire [ 1:0] fml_sel;
  wire [15:0] fml_di;
  wire [15:0] fml_do;


  // wires to Pic 
  wire        picm_stb_i;
  wire        picm_cyc_i;
  wire        picm_tga_i;
  wire [19:1] picm_adr_i;
  wire [ 1:0] picm_sel_i;
  wire        picm_we_i;
  wire [15:0] picm_dat_i;
  wire [15:0] picm_dat_o;
  wire        picm_ack_o;
  
  wire [ 7:0] pic_cas;
  
  wire        pics_stb_i;
  wire        pics_cyc_i;
  wire        pics_tga_i;
  wire [19:1] pics_adr_i;
  wire [ 1:0] pics_sel_i;
  wire        pics_we_i;
  wire [15:0] pics_dat_i;
  wire [15:0] pics_dat_o;
  wire        pics_ack_o;
  
  wire        pics_nmi;		// not used
  
  wire [ 1:0] picm_tgc_o;	// int, nmi
  wire [ 1:0] picm_tgc_i;
  wire [ 1:0] pics_tgc_o;	// intv[2], dummy
  wire [ 1:0] pics_tgc_i;

  wire [15:0] pic_intv;
  wire        pic_nmi;
  
  // others
  wire        timer_clk;
  wire        timer2_o;

  // Audio only signals
  //wire [ 7:0] aud_dat_o;
  //wire        aud_cyc_i;
  //wire        aud_ack_o;
  //wire        aud_sel_cond;

  // Keyboard-audio shared signals
  //wire [ 7:0] kaud_dat_o;
  //wire        kaud_cyc_i;
  //wire        kaud_ack_o;

  wire sys_rst;
  
  reset reset (
    .clk  (cpu_clk),		// clk - input frequency
    .lock (pll_lock),   // pll lock
    .sw   (sw_),			// user switches
    .rst  (sys_rst)     // reset out
  );

//`ifndef SIMULATION
  /*
   * Debounce it (counter holds reset for 10.49ms),
   * and generate power-on reset.
   */
//  wire rst_lck;
//  assign rst_lck    = !sw_[0] & pll_lock;
//  reg  [16:0] rst_debounce;
//  initial rst_debounce <= 17'h1FFFF;
//  reg sys_rst;
//  initial sys_rst <= 1'b1;
//  always @(posedge cpu_clk) begin
//    if(~rst_lck) /* reset is active low */
//      rst_debounce <= 17'h1FFFF;
//    else if(rst_debounce != 17'd0)
//      rst_debounce <= rst_debounce - 17'd1;
//    sys_rst <= rst_debounce != 17'd0;
//  end
//`else
//  wire rst_lck;
//  assign rst_lck    = !sw_[0] & pll_lock;
//  wire sys_rst;
//  assign sys_rst = !rst_lck;
//`endif

  // Continuous assignments

 
  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c0     (sdram_clk),    // 100 Mhz
    .c1     (sdram_clk_),   // to SDRAM chip
    .c2     (vga_clk),      // 25 Mhz
    .c3     (tft_lcd_clk_), // 25 Mhz to VGA chip
    .c4     (cpu_clk),      // 12.5 Mhz
    .locked (pll_lock)
  );

  clk_gen #(
    .res   (21),
    .phase (21'd100091)
    ) timerclk (
    .clk_i (vga_clk),       // 25 MHz
    .rst_i (sys_rst),
    .clk_o (timer_clk)      // 1.193178 MHz (required 1.193182 MHz)
  );

  clk_gen #(
    .res   (18),
    .phase (18'd29595)
    ) audioclk (
    .clk_i (sdram_clk),     // 100 MHz (use highest freq to minimize jitter)
    .rst_i (sys_rst),
    .clk_o (aud_xck_)       // 11.28960 MHz (required 11.28960 MHz)
  );

  bootrom bootrom (
    .clk (cpu_clk),         // Wishbone slave interface
    .rst (sys_rst),
    .wb_dat_i (rom_dat_i),
    .wb_dat_o (rom_dat_o),
    .wb_adr_i (rom_adr_i),
    .wb_we_i  (rom_we_i ),
    .wb_tga_i (rom_tga_i),
    .wb_stb_i (rom_stb_i),
    .wb_cyc_i (rom_cyc_i),
    .wb_sel_i (rom_sel_i),
    .wb_ack_o (rom_ack_o)
  );

  flash8_r2 flash8_r2 (
    // Wishbone slave interface
    .wb_clk_i (cpu_clk),        // Main Clock
    .wb_rst_i (sys_rst),        // Reset Line
    .wb_adr_i (fl_adr_i),       // Address lines
    .wb_sel_i (fl_sel_i),       // Select lines
    .wb_dat_i (fl_dat_i),       // Command to send
    .wb_dat_o (fl_dat_o),       // Received data
    .wb_cyc_i (fl_cyc_i),       // Cycle
    .wb_stb_i (fl_stb_i),       // Strobe
    .wb_we_i  (fl_we_i),        // Write enable
    .wb_ack_o (fl_ack_o),       // Normal bus termination

    // Pad signals
    .flash_addr_  (flash_addr_),
    .flash_data_  (flash_data_),
    .flash_we_n_  (flash_we_n_),
    .flash_oe_n_  (flash_oe_n_),
    .flash_ce_n_  (flash_ce_n_),
    .flash_rst_n_ (flash_rst_n_)
  );

  wb_abrgr wb_fmlbrg (
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wbs_clk_i (cpu_clk),
    .wbs_adr_i (fmlbrg_adr_s),
    .wbs_dat_i (fmlbrg_dat_w_s),
    .wbs_dat_o (fmlbrg_dat_r_s),
    .wbs_sel_i (fmlbrg_sel_s),
    .wbs_tga_i (fmlbrg_tga_s),
    .wbs_stb_i (fmlbrg_stb_s),
    .wbs_cyc_i (fmlbrg_cyc_s),
    .wbs_we_i  (fmlbrg_we_s),
    .wbs_ack_o (fmlbrg_ack_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (fmlbrg_adr),
    .wbm_dat_o (fmlbrg_dat_w),
    .wbm_dat_i (fmlbrg_dat_r),
    .wbm_sel_o (fmlbrg_sel),
    .wbm_tga_o (fmlbrg_tga),
    .wbm_stb_o (fmlbrg_stb),
    .wbm_cyc_o (fmlbrg_cyc),
    .wbm_we_o  (fmlbrg_we),
    .wbm_ack_i (fmlbrg_ack)
  );

  fmlbrg #(
    .fml_depth   (26),
    .cache_depth (10)   // 1 Kbyte cache
    ) fmlbrg (
    .sys_clk  (sdram_clk),
    .sys_rst  (sys_rst),

    // Wishbone slave interface
    .wb_adr_i ({6'h0,fmlbrg_adr}),
    .wb_dat_i (fmlbrg_dat_w),
    .wb_dat_o (fmlbrg_dat_r),
    .wb_sel_i (fmlbrg_sel),
    .wb_cyc_i (fmlbrg_cyc),
    .wb_stb_i (fmlbrg_stb),
    .wb_tga_i (fmlbrg_tga),
    .wb_we_i  (fmlbrg_we),
    .wb_ack_o (fmlbrg_ack),

    // FML master interface
    .fml_adr (fml_adr),
    .fml_stb (fml_stb),
    .fml_we  (fml_we),
    .fml_ack (fml_ack),
    .fml_sel (fml_sel),
    .fml_do  (fml_do),
    .fml_di  (fml_di)
  );

  wb_abrgr wb_csrbrg (
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wbs_clk_i (cpu_clk),
    .wbs_adr_i (csrbrg_adr_s),
    .wbs_dat_i (csrbrg_dat_w_s),
    .wbs_dat_o (csrbrg_dat_r_s),
    .wbs_sel_i (csrbrg_sel_s),
    .wbs_tga_i (csrbrg_tga_s),
    .wbs_stb_i (csrbrg_stb_s),
    .wbs_cyc_i (csrbrg_cyc_s),
    .wbs_we_i  (csrbrg_we_s),
    .wbs_ack_o (csrbrg_ack_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (csrbrg_adr),
    .wbm_dat_o (csrbrg_dat_w),
    .wbm_dat_i (csrbrg_dat_r),
    .wbm_sel_o (csrbrg_sel),
    .wbm_tga_o (csrbrg_tga),
    .wbm_stb_o (csrbrg_stb),
    .wbm_cyc_o (csrbrg_cyc),
    .wbm_we_o  (csrbrg_we),
    .wbm_ack_i (csrbrg_ack)
  );

  csrbrg csrbrg (
    .sys_clk (sdram_clk),
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wb_adr_i (csrbrg_adr),
    .wb_dat_i (csrbrg_dat_w),
    .wb_dat_o (csrbrg_dat_r),
    .wb_cyc_i (csrbrg_cyc),
    .wb_stb_i (csrbrg_stb),
    .wb_we_i  (csrbrg_we),
    .wb_ack_o (csrbrg_ack),

    // CSR master interface
    .csr_a  (csr_a),
    .csr_we (csr_we),
    .csr_do (csr_dw),
    .csr_di (csr_dr_hpdmc)
  );

  hpdmc #(
    .csr_addr          (1'b0),
    .sdram_depth       (26),
    .sdram_columndepth (10)
    ) hpdmc (
    .sys_clk (sdram_clk),
    .sys_rst (sys_rst),

    // CSR slave interface
    .csr_a  (csr_a),
    .csr_we (csr_we),
    .csr_di (csr_dw),
    .csr_do (csr_dr_hpdmc),

    // FML slave interface
    .fml_adr (fml_adr),
    .fml_stb (fml_stb),
    .fml_we  (fml_we),
    .fml_ack (fml_ack),
    .fml_sel (fml_sel),
    .fml_di  (fml_do),
    .fml_do  (fml_di),

    // SDRAM pad signals
    .sdram_cke   (sdram_ce_),
    .sdram_cs_n  (sdram_cs_n_),
    .sdram_we_n  (sdram_we_n_),
    .sdram_cas_n (sdram_cas_n_),
    .sdram_ras_n (sdram_ras_n_),
    .sdram_dqm   (sdram_dqm_),
    .sdram_adr   ({a12,sdram_addr_}),
    .sdram_ba    (sdram_ba_),
    .sdram_dq    (sdram_data_)
  );

  wb_abrg vga_brg (
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wbs_clk_i (cpu_clk),
    .wbs_adr_i (vga_adr_i_s),
    .wbs_dat_i (vga_dat_i_s),
    .wbs_dat_o (vga_dat_o_s),
    .wbs_sel_i (vga_sel_i_s),
    .wbs_tga_i (vga_tga_i_s),
    .wbs_stb_i (vga_stb_i_s),
    .wbs_cyc_i (vga_cyc_i_s),
    .wbs_we_i  (vga_we_i_s),
    .wbs_ack_o (vga_ack_o_s),

    // Wishbone master interface
    .wbm_clk_i (vga_clk),
    .wbm_adr_o (vga_adr_i),
    .wbm_dat_o (vga_dat_i),
    .wbm_dat_i (vga_dat_o),
    .wbm_sel_o (vga_sel_i),
    .wbm_tga_o (vga_tga_i),
    .wbm_stb_o (vga_stb_i),
    .wbm_cyc_o (vga_cyc_i),
    .wbm_we_o  (vga_we_i),
    .wbm_ack_i (vga_ack_o)
  );

  wire [17:1] csrm_adr_o;
  wire [ 1:0] csrm_sel_o;
  wire        csrm_we_o;
  wire [15:0] csrm_dat_o;
  wire [15:0] csrm_dat_i;

  vga vga (
    .wb_rst_i (sys_rst),

    // Wishbone slave interface
    .wb_clk_i (vga_clk),   // 25MHz VGA clock
    .wb_dat_i (vga_dat_i),
    .wb_dat_o (vga_dat_o),
    .wb_adr_i (vga_adr_i),  // 128K
    .wb_we_i  (vga_we_i),
    .wb_tga_i (vga_tga_i),
    .wb_sel_i (vga_sel_i),
    .wb_stb_i (vga_stb_i),
    .wb_cyc_i (vga_cyc_i),
    .wb_ack_o (vga_ack_o),

    // VGA pad signals
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_),

    // CSR SRAM master interface
    .csrm_adr_o (csrm_adr_o),
    .csrm_sel_o (csrm_sel_o),
    .csrm_we_o  (csrm_we_o),
    .csrm_dat_o (csrm_dat_o),
    .csrm_dat_i (csrm_dat_i)
  );

  csr_sram csr_sram (
    .sys_clk (vga_clk),

    // CSR slave interface
    .csr_adr_i (csrm_adr_o),
    .csr_sel_i (csrm_sel_o),
    .csr_we_i  (csrm_we_o),
    .csr_dat_i (csrm_dat_o),
    .csr_dat_o (csrm_dat_i),

    // Pad signals
    .sram_addr_ ({s19_17,sram_addr_}),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  // RS232 COM1 Port
  serial com1 (
    .wb_clk_i (cpu_clk),          // Main Clock
    .wb_rst_i (sys_rst),          // Reset Line
    .wb_adr_i (uart_adr_i),       // Address lines
    .wb_sel_i (uart_sel_i),       // Select lines
    .wb_dat_i (uart_dat_i),       // Command to send
    .wb_dat_o (uart_dat_o),
    .wb_we_i  (uart_we_i),        // Write enable
    .wb_stb_i (uart_stb_i),
    .wb_cyc_i (uart_cyc_i),
    .wb_ack_o (uart_ack_o),
    .wb_tgc_o (int_uart),         // Interrupt request

    .rs232_tx (uart_txd_),        // UART signals
    .rs232_rx (uart_rxd_)         // serial input/output
  );

  ps2 ps2 (
    .wb_clk_i (cpu_clk),         // Main Clock
    .wb_rst_i (sys_rst),         // Reset Line
    .wb_adr_i (keyb_adr_i),      // Address lines
    .wb_sel_i (keyb_sel_i),      // Select lines
    .wb_dat_i (keyb_dat_i),      // Command to send to Ethernet
    .wb_dat_o (keyb_dat_o),
    .wb_we_i  (keyb_we_i),       // Write enable
    .wb_stb_i (keyb_stb_i),
    .wb_cyc_i (keyb_cyc_i),
    .wb_ack_o (keyb_ack_o),
    .wb_tgk_o (int_keyboard),    // Keyboard Interrupt request
    .wb_tgm_o (int_mouse),       // Mouse Interrupt request

    .ps2_kbd_clk_ (ps2_kclk_),
    .ps2_kbd_dat_ (ps2_kdat_),
    .ps2_mse_clk_ (ps2_mclk_),
    .ps2_mse_dat_ (ps2_mdat_)
  );

`ifndef SIMULATION
  /*
   * Seems that we have a serious bug in Modelsim that prevents
   * from simulating when this core is present
   */
  speaker speaker (
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),
	  .wb_adr_i (spk_adr_i),      // Address lines
    .wb_sel_i (spk_sel_i),      // Select lines
    .wb_dat_i (spk_dat_i),
    .wb_dat_o (spk_dat_o),
    .wb_we_i  (spk_we_i),
    .wb_stb_i (spk_stb_i),
    .wb_cyc_i (spk_cyc_i),
    .wb_ack_o (spk_ack_o),

    .clk_100M (sdram_clk),
    .clk_25M  (vga_clk),
    .timer2   (timer2_o),

    .i2c_sclk_ (i2c_sclk_),
    .i2c_sdat_ (i2c_sdat_),

    .aud_adcdat_  (aud_adcdat_),
    .aud_daclrck_ (aud_daclrck_),
    .aud_dacdat_  (aud_dacdat_),
    .aud_bclk_    (aud_bclk_)
  );
`else
  assign spk_dat_o = 16'h0;
  assign spk_ack_o = spk_stb_i & spk_cyc_i;
`endif

  // Selection logic between keyboard and audio ports (port 65h: audio)
  //assign aud_sel_cond = keyb_adr_i[2:1]==2'b00 && keyb_sel_i[1];
  //assign aud_cyc_i    = kaud_cyc_i && aud_sel_cond;
  //assign keyb_cyc_i   = kaud_cyc_i && !aud_sel_cond;
  //assign kaud_ack_o   = aud_cyc_i & aud_ack_o | keyb_cyc_i & keyb_ack_o;
  //assign kaud_dat_o   = {8{aud_cyc_i}} & aud_dat_o
  //                      | {8{keyb_cyc_i}} & keyb_dat_o[15:8];

  timer timer (
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),
    .wb_adr_i (timer_adr_i),
    .wb_sel_i (timer_sel_i),
    .wb_dat_i (timer_dat_i),
    .wb_dat_o (timer_dat_o),
    .wb_stb_i (timer_stb_i),
    .wb_cyc_i (timer_cyc_i),
    .wb_we_i  (timer_we_i),
    .wb_ack_o (timer_ack_o),
    .wb_tgc_o (int_timer),
    .tclk_i   (timer_clk),     // 1.193182 MHz = (14.31818/12) MHz
    .gate2_i  (spk_dat_o[8]),
    .out2_o   (timer2_o)
  );

//  simple_pic pic0 (
//    .clk  (clk),
//    .rst  (rst),
//    .intv (intv),
//    .inta (inta),
//    .intr (intr),
//    .iid  (iid)
//    );

  // primary interupt controller
  pic #(
    .int_vector (8'h08),
    .int_mask   (8'b11101000)
  ) picm (
    .wb_clk_i   (cpu_clk),
    .wb_rst_i   (sys_rst),

    .nsp        (1'b1),	   			  // master (1) or slave (0)
    .cas_i      (1'b0),				    // cascade input (slave)
    .cas_o      (pic_cas),  		  // cascade output (master)

    .pic_intv   (pic_intv[7:0]),	// input interupt vectors
    .pic_nmi    (pic_nmi),			  // input nmi

    .wb_stb_i   (picm_stb_i),
    .wb_cyc_i   (picm_cyc_i),
    .wb_adr_i   (picm_adr_i),
    .wb_sel_i   (picm_sel_i),
    .wb_we_i    (picm_we_i),
    .wb_dat_i   (picm_dat_i),
    .wb_dat_o   (picm_dat_o),		  // interrupt vector output (to cpu)
    .wb_ack_o   (picm_ack_o),

    .wb_tgc_o   (picm_tgc_o),		  // intr, nmi  (to cpu)
    .wb_tgc_i   (picm_tgc_i),		  // inta, nmia (from cpu)
	 
	  .test_int_irr  (ledr_[7:0]),
	  .test_int_isr  (ledg_[7:0])
  );
    
  wire [15:0] test_dummy;
  
  // secondary interrupt controller
  pic #(
    .int_vector (8'h70),
    .int_mask   (8'b11101111)
  ) pics(
    .wb_clk_i   (cpu_clk),
    .wb_rst_i   (sys_rst),

    .nsp        (1'b0),			      // master (1) or slave (0)
    .cas_i      (pic_cas[2]),		  // cascade input (slave)
    .cas_o      (),               // cascade output (master)

    .pic_intv   (pic_intv[15:8]),	// input interupt vectors
    .pic_nmi    (1'b0),						// input nmi

    .wb_stb_i   (pics_stb_i),
    .wb_cyc_i   (pics_cyc_i),
    .wb_adr_i   (pics_adr_i),
    .wb_sel_i   (pics_sel_i),
    .wb_we_i    (pics_we_i),
    .wb_dat_i   (pics_dat_i),
    .wb_dat_o   (pics_dat_o),			// interrupt vector output (to cpu)
    .wb_ack_o   (pics_ack_o),

    .wb_tgc_o   (pics_tgc_o),     // intv[2], dummy
    .wb_tgc_i   (pics_tgc_i),			// inta, nmia (from cpu)
	 
	  .test_int_irr  (),
	  .test_int_isr  ()
  );
  assign ledr_[17] = picm_tgc_i[0];
  assign ledr_[16] = picm_tgc_o[0];
  assign ledr_[15] = picm_tgc_i[1];
  assign ledr_[14] = picm_tgc_o[1];
  assign ledr_[13] = pic_intv[12];
  assign ledr_[12] = pic_intv[5];
  assign ledr_[11] = pic_intv[4];
  assign ledr_[10] = pic_intv[3];
  assign ledr_[ 9] = pic_intv[2];
  assign ledr_[ 8] = pic_intv[1];
    
  assign pic_intv[ 0] = int_timer;			// (Int08/IRQ00) timer
  assign pic_intv[ 1] = int_keyboard;		// (Int09/IRQ01) ps/2 keyboard
//  assign pic_intv[ 2] = 1'b0;  // (Int0A/IRQ02) cascaded slave
  assign pic_intv[ 2] = pics_tgc_o[1];  // (Int0A/IRQ02) cascaded slave
//  assign pic_intv[ 3] = int_mouse;      // (Int0B/IRQ03) ps/2 mouse
  assign pic_intv[ 3] = 1'b0;
  assign pic_intv[ 4] = int_uart;			  // (Int0C/IRQ04) serial port
  assign pic_intv[ 5] = 1'b0;
  assign pic_intv[ 6] = 1'b0;
  assign pic_intv[ 7] = 1'b0;
  assign pic_intv[ 8] = 1'b0;
  assign pic_intv[ 9] = 1'b0;
  assign pic_intv[10] = 1'b0;
  assign pic_intv[11] = 1'b0;
  assign pic_intv[12] = int_mouse;			// (Int74/IRQ12) ps/2 mouse
//  assign pic_intv[12] = 1'b0;
  assign pic_intv[13] = 1'b0;
  assign pic_intv[14] = 1'b0;
  assign pic_intv[15] = 1'b0;
  
  wb_abrgr sd_brg (
    .sys_rst (sys_rst),

    // Wishbone slave interface
    .wbs_clk_i (cpu_clk),
    .wbs_adr_i (sd_adr_i_s),
    .wbs_dat_i (sd_dat_i_s),
    .wbs_dat_o (sd_dat_o_s),
    .wbs_sel_i (sd_sel_i_s),
    .wbs_tga_i (sd_tga_i_s),
    .wbs_stb_i (sd_stb_i_s),
    .wbs_cyc_i (sd_cyc_i_s),
    .wbs_we_i  (sd_we_i_s),
    .wbs_ack_o (sd_ack_o_s),
 
    // Wishbone master interface
    .wbm_clk_i (cpu_clk),
    .wbm_adr_o (sd_adr_i),
    .wbm_dat_o (sd_dat_i),
    .wbm_dat_i (sd_dat_o),
    .wbm_tga_o (sd_tga_i),
    .wbm_sel_o (sd_sel_i),
    .wbm_stb_o (sd_stb_i),
    .wbm_cyc_o (sd_cyc_i),
    .wbm_we_o  (sd_we_i),
    .wbm_ack_i (sd_ack_o)
  );

  sdspi sdspi (
    // Serial pad signal
    .sclk (sd_sclk_),
    .miso (sd_miso_),
    .mosi (sd_mosi_),
    .ss   (sd_ss_),

    // Wishbone slave interface
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),
    .wb_dat_i (sd_dat_i),
    .wb_dat_o (sd_dat_o),
    .wb_we_i  (sd_we_i),
    .wb_sel_i (sd_sel_i),
    .wb_stb_i (sd_stb_i),
    .wb_cyc_i (sd_cyc_i),
    .wb_ack_o (sd_ack_o)
  );

  
post post (
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),

	.wb_stb_i (post_stb_i),
    .wb_cyc_i (post_cyc_i),
    .wb_adr_i (post_adr_i),
    .wb_we_i  (post_we_i),
    .wb_sel_i (post_sel_i),
    .wb_dat_i (post_dat_i),
    .wb_dat_o (post_dat_o),
    .wb_ack_o (post_ack_o),
  
    .postcode (postcode)
  );  

  
  // Switches and leds
  sw_leds sw_leds (
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),

    // Wishbone slave interface
    .wb_adr_i (gpio_adr_i),
    .wb_dat_o (gpio_dat_o),
    .wb_dat_i (gpio_dat_i),
    .wb_sel_i (gpio_sel_i),
    .wb_we_i  (gpio_we_i),
    .wb_stb_i (gpio_stb_i),
    .wb_cyc_i (gpio_cyc_i),
    .wb_ack_o (gpio_ack_o),

    // GPIO inputs/outputs
//    .leds_  ({ledr_,ledg_[7:4]}),
    .leds_  (),
    .sw_    (sw_),
    .pb_    (key_),
    .tick   (pic_intv[0]),
    .nmi_pb (pic_nmi) // NMI from pushbutton
  );

  //assign ledg_[3:0] = cpu_pc[3:0];
  
  
  hex_display hex16 (
    .num ({postcode, 4'b0, cpu_pc[19:0]}),
    .en  (1'b1),

    .hex0 (hex0_),
    .hex1 (hex1_),
    .hex2 (hex2_),
    .hex3 (hex3_),
	  .hex4 (hex4_),
	  .hex5 (hex5_),
	  .hex6 (hex6_),
	  .hex7 (hex7_)
  );

  zet zet (
    .pc (cpu_pc),

    // Wishbone master interface
    .wb_clk_i (cpu_clk),
    .wb_rst_i (sys_rst),
    .wb_dat_i (cpu_dat_i),
    .wb_dat_o (cpu_dat_o),
    .wb_adr_o (cpu_adr_o),
    .wb_we_o  (cpu_we_o),
    .wb_tga_o (cpu_tga_o),
    .wb_sel_o (cpu_sel_o),
    .wb_stb_o (cpu_stb_o),
    .wb_cyc_o (cpu_cyc_o),
    .wb_ack_i (cpu_ack_i),
    .wb_tgc_i (cpu_tgc_i),
    .wb_tgc_o (cpu_tgc_o)
  );

  wb_switch #(
    .s0_addr_1 (21'h0FFF00), // bios boot mem 0xfff00 - 0xfffff
    .s0_mask_1 (21'h1FFF00), // bios boot ROM Memory

    .s1_addr_1 (21'h0_A0000), // mem 0xa0000 - 0xbffff
    .s1_mask_1 (21'h1_E0000), // VGA
    .s1_addr_2 (21'h1_003C0), // io 0x3c0 - 0x3df
    .s1_mask_2 (21'h1_0FFE0), // VGA IO

    .s2_addr_1 (21'h1_003F8), // io 0x3f8 - 0x3ff
    .s2_mask_1 (21'h1_0FFF8), // RS232 IO

    .s3_addr_1 (21'h1_00060), // io 0x60, 0x64 (8 bit lsb)
    .s3_mask_1 (21'h1_0FFFB), // Keyboard / Mouse IO

    .s4_addr_1 (21'h1_00100), // io 0x100 - 0x101
    .s4_mask_1 (21'h1_0FFFE), // SD Card IO

    .s5_addr_1 (21'h1_0F100), // io 0xf100 - 0xf103
    .s5_mask_1 (21'h1_0FFFC), // GPIO

    .s6_addr_1 (21'h1_0F200), // io 0xf200 - 0xf20f
    .s6_mask_1 (21'h1_0FFF0), // CSR Bridge SDRAM Control
	 
    .s7_addr_1 (21'h1_00040), // io 0x40 - 0x43
    .s7_mask_1 (21'h1_0FFFC), // Timer control port

    .s8_addr_1 (21'h1_00238), // io 0x0238 - 0x023b
    .s8_mask_1 (21'h1_0FFFC), // Flash IO port

    //.s9_addr_1 (20'b1_0000_0000_0010_0001_000), // io 0x0210 - 0x021F
    //.s9_mask_1 (20'b1_0000_1111_1111_1111_000), // Sound Blaster
    .s9_addr_1 (21'h1_00061), // io 0x0061 (8 bit msb)
    .s9_mask_1 (21'h1_0FFFF), // pc speaker

    .sA_addr_1 (21'h1_0F300), // io 0xf300 - 0xf3ff
    .sA_mask_1 (21'h1_0FF00), // SDRAM Control
    .sA_addr_2 (21'h0_00000), // mem 0x00000 - 0xfffff
    .sA_mask_2 (21'h1_00000), // Base RAM

    .sB_addr_1 (21'h1_00000), // 
    .sB_mask_1 (21'h1_FFFFF), // not used

    .sC_addr_1 (21'h1_00000), // 
    .sC_mask_1 (21'h1_FFFFF), // not used

    .sD_addr_1 (21'h1_00080), // io 0x0080
    .sD_mask_1 (21'h1_FFFFF), // postcode register

    .sE_addr_1 (21'h1_000A0), // io 0x00A0 - 0x00A1
    .sE_mask_1 (21'h1_0FFFE), // 8259A Slave Interrupt Controller

    .sF_addr_1 (21'h1_00020), // io 0x0020 - 0x0021
    .sF_mask_1 (21'h1_0FFFE)  // 8259A Master Interrupt Controller
    ) wbs (

    // Master interface
    .m_dat_i (cpu_dat_o),
    .m_dat_o (cpu_dat_i),
    .m_adr_i ({cpu_tga_o, cpu_adr_o}),
    .m_sel_i (cpu_sel_o),
    .m_we_i  (cpu_we_o),
    .m_cyc_i (cpu_cyc_o),
    .m_stb_i (cpu_stb_o),
    .m_ack_o (cpu_ack_i),
	 .m_tgc_o (cpu_tgc_i),
	 .m_tgc_i (cpu_tgc_o),

    // Slave 0 interface - bios rom
    .s0_dat_i (rom_dat_o),
    .s0_dat_o (rom_dat_i),
    .s0_adr_o ({rom_tga_i, rom_adr_i}),
    .s0_sel_o (rom_sel_i),
    .s0_we_o  (rom_we_i),
    .s0_cyc_o (rom_cyc_i),
    .s0_stb_o (rom_stb_i),
    .s0_ack_i (rom_ack_o),

     // Slave 1 interface - vga
    .s1_dat_i (vga_dat_o_s),
    .s1_dat_o (vga_dat_i_s),
    .s1_adr_o ({vga_tga_i_s, vga_adr_i_s}),
    .s1_sel_o (vga_sel_i_s),
    .s1_we_o  (vga_we_i_s),
    .s1_cyc_o (vga_cyc_i_s),
    .s1_stb_o (vga_stb_i_s),
    .s1_ack_i (vga_ack_o_s),

    // Slave 2 interface - uart
    .s2_dat_i (uart_dat_o),
    .s2_dat_o (uart_dat_i),
    .s2_adr_o ({uart_tga_i, uart_adr_i}),
    .s2_sel_o (uart_sel_i),
    .s2_we_o  (uart_we_i),
    .s2_cyc_o (uart_cyc_i),
    .s2_stb_o (uart_stb_i),
    .s2_ack_i (uart_ack_o),

    // Slave 3 interface - keyb
    //.s3_dat_i ({kaud_dat_o,keyb_dat_o[7:0]}),
    .s3_dat_i (keyb_dat_o),
    .s3_dat_o (keyb_dat_i),
    .s3_adr_o ({keyb_tga_i, keyb_adr_i}),
    .s3_sel_o (keyb_sel_i),
    .s3_we_o  (keyb_we_i),
    .s3_cyc_o (keyb_cyc_i),
    .s3_stb_o (keyb_stb_i),
    .s3_ack_i (keyb_ack_o),

    // Slave 4 interface - sd
    .s4_dat_i (sd_dat_o_s),
    .s4_dat_o (sd_dat_i_s),
    .s4_adr_o ({sd_tga_i_s, sd_adr_i_s}),
    .s4_sel_o (sd_sel_i_s),
    .s4_we_o  (sd_we_i_s),
    .s4_cyc_o (sd_cyc_i_s),
    .s4_stb_o (sd_stb_i_s),
    .s4_ack_i (sd_ack_o_s),

    // Slave 5 interface - gpio
    .s5_dat_i (gpio_dat_o),
    .s5_dat_o (gpio_dat_i),
    .s5_adr_o ({gpio_tga_i, gpio_adr_i}),
    .s5_sel_o (gpio_sel_i),
    .s5_we_o  (gpio_we_i),
    .s5_cyc_o (gpio_cyc_i),
    .s5_stb_o (gpio_stb_i),
    .s5_ack_i (gpio_ack_o),

    // Slave 6 interface - csr bridge
    .s6_dat_i (csrbrg_dat_r_s),
    .s6_dat_o (csrbrg_dat_w_s),
    .s6_adr_o ({csrbrg_tga_s,csrbrg_adr_s}),
    .s6_sel_o (csrbrg_sel_s),
    .s6_we_o  (csrbrg_we_s),
    .s6_cyc_o (csrbrg_cyc_s),
    .s6_stb_o (csrbrg_stb_s),
    .s6_ack_i (csrbrg_ack_s),

    // Slave 7 interface - timer
    .s7_dat_i (timer_dat_o),
    .s7_dat_o (timer_dat_i),
    .s7_adr_o ({timer_tga_i, timer_adr_i}),
    .s7_sel_o (timer_sel_i),
    .s7_we_o  (timer_we_i),
    .s7_cyc_o (timer_cyc_i),
    .s7_stb_o (timer_stb_i),
    .s7_ack_i (timer_ack_o),

    // Slave 8 interface - flash
    .s8_dat_i (fl_dat_o),
    .s8_dat_o (fl_dat_i),
    .s8_adr_o ({fl_tga_i, fl_adr_i}),
    .s8_sel_o (fl_sel_i),
    .s8_we_o  (fl_we_i),
    .s8_cyc_o (fl_cyc_i),
    .s8_stb_o (fl_stb_i),
    .s8_ack_i (fl_ack_o),

    // Slave 9 interface - not connected
    .s9_dat_i (spk_dat_o),
    .s9_dat_o (spk_dat_i),
    .s9_adr_o ({spk_tga_i, spk_adr_i}),
    .s9_sel_o (spk_sel_i),
    .s9_we_o  (spk_we_i),
    .s9_cyc_o (spk_cyc_i),
    .s9_stb_o (spk_stb_i),
    .s9_ack_i (spk_ack_o),

    // Slave A interface - sdram
    .sA_dat_i (fmlbrg_dat_r_s),
    .sA_dat_o (fmlbrg_dat_w_s),
    .sA_adr_o ({fmlbrg_tga_s, fmlbrg_adr_s}),
    .sA_sel_o (fmlbrg_sel_s),
    .sA_we_o  (fmlbrg_we_s),
    .sA_cyc_o (fmlbrg_cyc_s),
    .sA_stb_o (fmlbrg_stb_s),
    .sA_ack_i (fmlbrg_ack_s),

    .sB_dat_i (16'h0000),
    .sB_dat_o (),
    .sB_adr_o (),		// tga_s, adr_s
    .sB_sel_o (),
    .sB_we_o  (),
    .sB_cyc_o (),
    .sB_stb_o (),
    .sB_ack_i (1'b0),

    .sC_dat_i (16'h0000),
    .sC_dat_o (),
    .sC_adr_o (),		// tga_s, adr_s
    .sC_sel_o (),
    .sC_we_o  (),
    .sC_cyc_o (),
    .sC_stb_o (),
    .sC_ack_i (1'b0),

    .sD_dat_i (post_dat_o),
    .sD_dat_o (post_dat_i),
    .sD_adr_o ({post_tga_i, post_adr_i}),		// tga_s, adr_s
    .sD_sel_o (post_sel_i),
    .sD_we_o  (post_we_i),
    .sD_cyc_o (post_cyc_i),
    .sD_stb_o (post_stb_i),
    .sD_ack_i (post_ack_o),

	// slave E interface - PIC slave
    .sE_dat_i (pics_dat_o),
    .sE_dat_o (pics_dat_i),
    .sE_adr_o ({pics_tga_i, pics_adr_i}),
    .sE_sel_o (pics_sel_i),
    .sE_we_o  (pics_we_i),
    .sE_cyc_o (pics_cyc_i),
    .sE_stb_o (pics_stb_i),
    .sE_ack_i (pics_ack_o),
	
    .sE_tgc_o (pics_tgc_i),		// inta, nmia (from cpu)
    .sE_tgc_i (pics_tgc_o),		// intv[2], dummy

    // slave F interface - PIC master
    .sF_dat_i (picm_dat_o),
    .sF_dat_o (picm_dat_i),
    .sF_adr_o ({picm_tga_i, picm_adr_i}),
    .sF_sel_o (picm_sel_i),
    .sF_we_o  (picm_we_i),
    .sF_cyc_o (picm_cyc_i),
    .sF_stb_o (picm_stb_i),
    .sF_ack_i (picm_ack_o),

    .sF_tgc_o (picm_tgc_i),		// inta, nmia (from cpu)
    .sF_tgc_i (picm_tgc_o)		// intr, nmi  (to cpu)
    );	 
endmodule
