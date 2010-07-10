//  Zet SoC - Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>  
module kotku (
    input        clk_50_,
    output [9:0] ledr_,
    output [7:0] ledg_,
    input  [9:0] sw_,
    input  [3:0] key_,
    output [6:0] hex0_,
    output [6:0] hex1_,
    output [6:0] hex2_,
    output [6:0] hex3_,

    // flash signals
    output [21:0] flash_addr_,
    input  [ 7:0] flash_data_,
    output        flash_we_n_,
    output        flash_oe_n_,
    output        flash_ce_n_,
    output        flash_rst_n_,

    // sdram signals
    output [11:0] sdram_addr_,
    inout  [15:0] sdram_data_,
    output [ 1:0] sdram_ba_,
    output [ 1:0] sdram_dqm_,
    output        sdram_ras_n_,
    output        sdram_cas_n_,
    output        sdram_ce_,
    output        sdram_clk_,
    output        sdram_we_n_,
    output        sdram_cs_n_,

    // sram signals
    output [17:0] sram_addr_,
    inout  [15:0] sram_data_,
    output        sram_we_n_,
    output        sram_oe_n_,
    output        sram_ce_n_,
    output [ 1:0] sram_bw_n_,

    // VGA signals
    output [ 3:0] tft_lcd_r_,
    output [ 3:0] tft_lcd_g_,
    output [ 3:0] tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,

    // UART signals
    input         uart_rxd_,
    output        uart_txd_,

    // PS2 signals
    inout         ps2_kclk_,	// PS2 keyboard Clock
    inout         ps2_kdat_,	// PS2 Keyboard Data
    inout         ps2_mclk_,	// PS2 Mouse Clock
    inout         ps2_mdat_,	// PS2 Mouse Data
    
    // SD card signals
    output        sd_sclk_,
    input         sd_miso_,
    output        sd_mosi_,
    output        sd_ss_
  );

  // Registers and nets
  wire        clk;
  wire        rst_lck;
  wire [15:0] dat_o;
  wire [15:0] dat_i;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire [ 1:0] sel;
  wire        stb;
  wire        cyc;
  wire        ack;

  wire        lock;

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

  // wires for Ethernet Network controller
  wire [15:0] wb_net_dat_o;          // Wishbone bus slave interface
  wire [15:0] wb_net_dat_i;          // Wishbone bus slave interface
  wire        wb_net_tga_i;
  wire [ 2:1] wb_net_adr_i;
  wire [ 1:0] wb_net_sel_i;
  wire        wb_net_we_i;
  wire        wb_net_cyc_i;
  wire        wb_net_stb_i;
  wire        wb_net_ack_o;
  
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

  // wires to sd controller
  wire [15:0] sd_dat_o;
  wire [15:0] sd_dat_i;
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
  wire        csrbrg_cyc;
  wire        csrbrg_stb;
  wire        csrbrg_we;
  wire        csrbrg_ack;

  wire [ 2:0] csr_a;
  wire        csr_we;
  wire [15:0] csr_dw;
  wire [15:0] csr_dr_hpdmc;

  wire [22:0] fml_adr;
  wire        fml_stb;
  wire        fml_we;
  wire        fml_ack;
  wire [ 1:0] fml_sel;
  wire [15:0] fml_di;
  wire [15:0] fml_do;

  // wires to default stb/ack
  wire def_cyc_i;
  wire def_stb_i;

  wire [15:0] sw_dat_o;

  wire        sdram_clk;

  wire        vga_clk;

  wire [ 7:0] intv;
  wire [ 2:0] iid;
  wire        intr;
  wire        inta;

  wire [15:0] ip;
  wire [19:0] pc;
  wire [15:0] cs;
  wire [ 2:0] state;

  reg [16:0] rst_debounce;

  // Module instantiations
  pll pll (
    .inclk0 (clk_50_),
    .c0     (sdram_clk),  // 100 Mhz
    .c1     (vga_clk),    // 25 Mhz
    .c2     (clk),        // 12.5 Mhz
    .locked (lock)
  );

`ifndef SIMULATION
  /*
   * Debounce it (counter holds reset for 10.49ms),
   * and generate power-on reset.
   */
  initial rst_debounce <= 17'h1FFFF;
  reg rst;
  initial rst <= 1'b1;
  always @(posedge clk) begin
    if(~rst_lck) rst_debounce <= 17'h1FFFF;   /* reset is active low */
    else if(rst_debounce != 17'd0) rst_debounce <= rst_debounce - 17'd1;
    rst <= rst_debounce != 17'd0;
  end
`else
  wire rst;
  assign rst = !rst_lck;
`endif

  flash flash (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (fl_dat_i),
    .wb_dat_o (fl_dat_o),
    .wb_adr_i (fl_adr_i[16:1]),
    .wb_we_i  (fl_we_i),
    .wb_tga_i (fl_tga_i),
    .wb_stb_i (fl_stb_i),
    .wb_cyc_i (fl_cyc_i),
    .wb_sel_i (fl_sel_i),
    .wb_ack_o (fl_ack_o),

    // Pad signals
    .flash_addr_  (flash_addr_),
    .flash_data_  (flash_data_),
    .flash_we_n_  (flash_we_n_),
    .flash_oe_n_  (flash_oe_n_),
    .flash_ce_n_  (flash_ce_n_),
    .flash_rst_n_ (flash_rst_n_)
  );

  wb_abrgr wb_fmlbrg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
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
    .fml_depth   (23),
    .cache_depth (10)   // 1 Kbyte cache
    ) fmlbrg (
    .sys_clk  (sdram_clk),
    .sys_rst  (rst),

    // Wishbone slave interface
    .wb_adr_i ({3'b000,fmlbrg_adr}),
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
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_adr_i (csrbrg_adr_s),
    .wbs_dat_i (csrbrg_dat_w_s),
    .wbs_dat_o (csrbrg_dat_r_s),
    .wbs_stb_i (csrbrg_stb_s),
    .wbs_cyc_i (csrbrg_cyc_s),
    .wbs_we_i  (csrbrg_we_s),
    .wbs_ack_o (csrbrg_ack_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (csrbrg_adr),
    .wbm_dat_o (csrbrg_dat_w),
    .wbm_dat_i (csrbrg_dat_r),
    .wbm_stb_o (csrbrg_stb),
    .wbm_cyc_o (csrbrg_cyc),
    .wbm_we_o  (csrbrg_we),
    .wbm_ack_i (csrbrg_ack)
  );

  csrbrg csrbrg (
    .sys_clk (sdram_clk),
    .sys_rst (rst),
    
    // Wishbone slave interface
    .wb_adr_i (csrbrg_adr[3:1]),
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
    .sdram_depth       (23),
    .sdram_columndepth (8)
    ) hpdmc (
    .sys_clk (sdram_clk),
    .sys_rst (rst),

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
    .sdram_adr   (sdram_addr_),
    .sdram_ba    (sdram_ba_),
    .sdram_dq    (sdram_data_)
  );

  wb_abrg vga_brg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
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

  vga vga (
    // Wishbone slave interface
    .wb_rst_i (rst),
    .wb_clk_i (vga_clk),   // 25MHz VGA clock
    .wb_dat_i (vga_dat_i),
    .wb_dat_o (vga_dat_o),
    .wb_adr_i (vga_adr_i[16:1]),    // 128K
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

    // SRAM pad signals
    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  uart_top com1 (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_adr_i ({uart_adr_i[2:1],~uart_sel_i[0]}),
    .wb_dat_i (uart_dat_i),
    .wb_dat_o (uart_dat_o),
    .wb_we_i  (uart_we_i),
    .wb_stb_i (uart_stb_i),
    .wb_cyc_i (uart_cyc_i),
    .wb_ack_o (uart_ack_o),
    .wb_sel_i (4'b0),
    .int_o    (intv[4]), // interrupt request

    // UART signals
    // serial input/output
    .stx_pad_o  (uart_txd_),
    .srx_pad_i  (uart_rxd_),

    // modem signals
    .cts_pad_i  (1'b1),
    .dsr_pad_i  (1'b1),
    .ri_pad_i   (1'b0),
    .dcd_pad_i  (1'b0)
  );

  WB_Ethernet Ethernet(
    .wb_clk_i(clk),					// Main Clock 
    .wb_rst_i(rst),  				// Reset Line
    .wb_dat_i(wb_net_dat_i),        // Command to send to Ethernet
    .wb_dat_o(wb_net_dat_o),        // Received data
    .wb_cyc_i(wb_net_cyc_i),        // Cycle
    .wb_stb_i(wb_net_stb_i),        // Strobe
    .wb_adr_i(wb_net_adr_i),        // Address lines
    .wb_sel_i(wb_net_sel_i),        // Select lines
    .wb_we_i(wb_net_we_i),          // Write enable
    .wb_ack_o(wb_net_ack_o),        // Normal bus termination
    .wb_tgc_o(intv[7])              // Ethernet Interrupt request
  );

  WB_PS2 PS2(
    .wb_clk_i(clk),					// Main Clock 
    .wb_rst_i(rst),  				// Reset Line
    .wb_adr_i(keyb_adr_i[2:1]),		// Address lines
    .wb_sel_i(keyb_sel_i),			// Select lines
    .wb_dat_i(keyb_dat_i),			// Command to send to Ethernet
    .wb_dat_o(keyb_dat_o),
    .wb_we_i(keyb_we_i),            // Write enable
    .wb_stb_i(keyb_stb_i),
    .wb_cyc_i(keyb_cyc_i),
    .wb_ack_o(keyb_ack_o),
    .wb_tgk_o(intv[1]),             // Keyboard Interrupt request
    .wb_tgm_o(intv[3]),             // Mouse Interrupt request

    .PS2_KBD_CLK(ps2_kclk_),.PS2_KBD_DAT(ps2_kdat_),
	.PS2_MSE_CLK(ps2_mclk_),.PS2_MSE_DAT(ps2_mdat_),
	
	.testlines(ledr_[9:8]), .tstclr(~key_[1])
	    
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

  wb_abrgr sd_brg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_dat_i (sd_dat_i_s),
    .wbs_dat_o (sd_dat_o_s),
    .wbs_sel_i (sd_sel_i_s),
    .wbs_stb_i (sd_stb_i_s),
    .wbs_cyc_i (sd_cyc_i_s),
    .wbs_we_i  (sd_we_i_s),
    .wbs_ack_o (sd_ack_o_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_dat_o (sd_dat_i),
    .wbm_dat_i (sd_dat_o),
    .wbm_sel_o (sd_sel_i),
    .wbm_stb_o (sd_stb_i),
    .wbm_cyc_o (sd_cyc_i),
    .wbm_we_o  (sd_we_i),
    .wbm_ack_i (sd_ack_o)
  );

  sdspi sdspi (
    // Serial pad signal
    .sclk  (sd_sclk_),
    .miso  (sd_miso_),
    .mosi  (sd_mosi_),
    .ss    (sd_ss_),

    // Wishbone slave interface
    .wb_clk_i (sdram_clk),
    .wb_rst_i (rst),
    .wb_dat_i (sd_dat_i),
    .wb_dat_o (sd_dat_o),
    .wb_we_i  (sd_we_i),
    .wb_sel_i (sd_sel_i),
    .wb_stb_i (sd_stb_i),
    .wb_cyc_i (sd_cyc_i),
    .wb_ack_o (sd_ack_o)
  );

  // Switches and leds
  sw_leds sw_leds (
    // Wishbone slave interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_adr_i (gpio_adr_i),
    .wb_dat_o (gpio_dat_o),
    .wb_dat_i (gpio_dat_i),
    .wb_sel_i (gpio_sel_i),
    .wb_we_i  (gpio_we_i),
    .wb_stb_i (gpio_stb_i),
    .wb_cyc_i (gpio_cyc_i),
    .wb_ack_o (gpio_ack_o),

    // GPIO inputs/outputs
    .leds_ ({ledr_[7:0],ledg_[7:4]}),
    .sw_   (sw_)
  );

  cpu zet_proc (
    .ip         (ip),
    .cs         (cs),
    .state      (state),
    .dbg_block  (1'b0),

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
    .wb_tgc_i (intr),
    .wb_tgc_o (inta)
  );

  wb_switch #(
    .s0_addr_1 (20'b0_1111_0000_0000_0000_000), // mem 0xf0000 - 0xfffff  Flash Memory interface
    .s0_mask_1 (20'b1_1111_0000_0000_0000_000),
    .s0_addr_2 (20'b0_1100_0000_0000_0000_000), // mem 0xc0000 - 0xcffff
    .s0_mask_2 (20'b1_1111_0000_0000_0000_000),
    .s0_addr_3 (20'b1_0000_1110_0000_0000_000), // io 0xe000 - 0xfeff
    .s0_mask_3 (20'b1_0000_1111_1110_0000_000),
    
    .s1_addr_1 (20'b0_1010_0000_0000_0000_000), // mem 0xa0000 - 0xbffff  VGA Interface
    .s1_mask_1 (20'b1_1110_0000_0000_0000_000),
    .s1_addr_2 (20'b1_0000_0000_0011_1100_000), // io 0x3c0 - 0x3df
    .s1_mask_2 (20'b1_0000_1111_1111_1110_000),
    
    .s2_addr_1 (20'b1_0000_0000_0011_1111_100), // io 0x3f8 - 0x3ff  COM1 RS232 Port
    .s2_mask_1 (20'b1_0000_1111_1111_1111_100),
    
    .s3_addr_1 (20'b1_0000_0000_0000_0110_000), // io 0x60, 0x64  Keyboard Mouse Interface
    .s3_mask_1 (20'b1_0000_1111_1111_1111_101),
    
    .s4_addr_1 (20'b1_0000_0000_0001_0000_000), // io 0x100 - 0x101  SD Card IO
    .s4_mask_1 (20'b1_0000_1111_1111_1111_111),
    
    .s5_addr_1 (20'b1_0000_1111_0001_0000_000), // io 0xf100 - 0xf103 GPIO 
    .s5_mask_1 (20'b1_0000_1111_1111_1111_110),
    
    .s6_addr_1 (20'b1_0000_1111_0010_0000_000), // io 0xf200 - 0xf20f  CSR Bridge
    .s6_mask_1 (20'b1_0000_1111_1111_1111_000),

    .s7_addr_1 (20'b1_0000_0000_0011_0110_000), // io 0x0360 - 0x036F Ethernet Network adapter
    .s7_mask_1 (20'b1_0000_1111_1111_1111_000),

    .s8_addr_1 (20'b1_0000_1111_0011_0000_000), // io 0xf300 - 0xf3ff  SDRAM Control interface
    .s8_mask_1 (20'b1_0000_1111_1111_0000_000),
    
    .s8_addr_2 (20'b0_0000_0000_0000_0000_000), // mem 0x00000 - 0xfffff
    .s8_mask_2 (20'b1_0000_0000_0000_0000_000)
    ) wbs (

    // Master interface
    .m_dat_i (dat_o),
    .m_dat_o (sw_dat_o),
    .m_adr_i ({tga,adr}),
    .m_sel_i (sel),
    .m_we_i  (we),
    .m_cyc_i (cyc),
    .m_stb_i (stb),
    .m_ack_o (ack),

    // Slave 0 interface - flash
    .s0_dat_i (fl_dat_o),
    .s0_dat_o (fl_dat_i),
    .s0_adr_o ({fl_tga_i,fl_adr_i}),
    .s0_sel_o (fl_sel_i),
    .s0_we_o  (fl_we_i),
    .s0_cyc_o (fl_cyc_i),
    .s0_stb_o (fl_stb_i),
    .s0_ack_i (fl_ack_o),

    // Slave 1 interface - vga
    .s1_dat_i (vga_dat_o_s),
    .s1_dat_o (vga_dat_i_s),
    .s1_adr_o ({vga_tga_i_s,vga_adr_i_s}),
    .s1_sel_o (vga_sel_i_s),
    .s1_we_o  (vga_we_i_s),
    .s1_cyc_o (vga_cyc_i_s),
    .s1_stb_o (vga_stb_i_s),
    .s1_ack_i (vga_ack_o_s),

    // Slave 2 interface - uart
    .s2_dat_i (uart_dat_o),
    .s2_dat_o (uart_dat_i),
    .s2_adr_o ({uart_tga_i,uart_adr_i}),
    .s2_sel_o (uart_sel_i),
    .s2_we_o  (uart_we_i),
    .s2_cyc_o (uart_cyc_i),
    .s2_stb_o (uart_stb_i),
    .s2_ack_i (uart_ack_o),

    // Slave 3 interface - keyb
    .s3_dat_i (keyb_dat_o),
    .s3_dat_o (keyb_dat_i),
    .s3_adr_o ({keyb_tga_i,keyb_adr_i}),
    .s3_sel_o (keyb_sel_i),
    .s3_we_o  (keyb_we_i),
    .s3_cyc_o (keyb_cyc_i),
    .s3_stb_o (keyb_stb_i),
    .s3_ack_i (keyb_ack_o),

    // Slave 4 interface - sd
    .s4_dat_i (sd_dat_o_s),
    .s4_dat_o (sd_dat_i_s),
    .s4_adr_o ({sd_tga_i_s,sd_adr_i_s}),
    .s4_sel_o (sd_sel_i_s),
    .s4_we_o  (sd_we_i_s),
    .s4_cyc_o (sd_cyc_i_s),
    .s4_stb_o (sd_stb_i_s),
    .s4_ack_i (sd_ack_o_s),

    // Slave 5 interface - gpio
    .s5_dat_i (gpio_dat_o),
    .s5_dat_o (gpio_dat_i),
    .s5_adr_o ({gpio_tga_i,gpio_adr_i}),
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

    // Slave 7 interface - Ethernet Interface
    .s7_dat_i (wb_net_dat_o),
    .s7_dat_o (wb_net_dat_i),
    .s7_adr_o ({wb_net_tga_i,wb_net_adr_i}),
    .s7_sel_o (wb_net_sel_i),
    .s7_we_o  (wb_net_we_i),
    .s7_cyc_o (wb_net_cyc_i),
    .s7_stb_o (wb_net_stb_i),
    .s7_ack_i (wb_net_ack_o),

    // Slave 8 interface - sdram
    .s8_dat_i (fmlbrg_dat_r_s),
    .s8_dat_o (fmlbrg_dat_w_s),
    .s8_adr_o ({fmlbrg_tga_s,fmlbrg_adr_s}),
    .s8_sel_o (fmlbrg_sel_s),
    .s8_we_o  (fmlbrg_we_s),
    .s8_cyc_o (fmlbrg_cyc_s),
    .s8_stb_o (fmlbrg_stb_s),
    .s8_ack_i (fmlbrg_ack_s),

    // Slave 9 interface - default
    .s9_dat_i (16'hffff),
    .s9_dat_o (),
    .s9_adr_o (),
    .s9_sel_o (),
    .s9_we_o  (),
    .s9_cyc_o (def_cyc_i),
    .s9_stb_o (def_stb_i),
    .s9_ack_i (def_cyc_i & def_stb_i)
  );

  hex_display hex16 (
    .num (pc[19:4]),
    .en  (1'b1),
    .hex0 (hex0_),
    .hex1 (hex1_),
    .hex2 (hex2_),
    .hex3 (hex3_)
  );

  // Continuous assignments
  assign rst_lck         = key_[0] & lock;
  assign sdram_clk_      = sdram_clk;
  assign dat_i = inta ? { 13'b0000_0000_0000_1, iid } : sw_dat_o;
  assign pc  = (cs << 4) + ip;
  assign ledg_[3:0] = pc[3:0];

endmodule
