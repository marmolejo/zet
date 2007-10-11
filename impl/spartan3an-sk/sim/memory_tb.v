
`timescale 1ns/100ps
`include "parameters.v"
module memory_tb; 

  // Net and register declaration
  reg  ddr_clk, cpu_clk;
  wire ddr_clkb;
  reg  rst;

  reg  [19:0] addr;
  reg  [15:0] wr_data;
  reg         we;
  reg         byte_m;
  wire [15:0] rd_data;
  wire        mem_rst;
  wire        ready;

  wire [`clk_width-1 : 0] ddr2_clk;
  wire [`clk_width-1 : 0] ddr2_clkb;

  wire [`data_strobe_width-1 : 0]  ddr_dqs_fpga;
  wire [`data_strobe_width-1 : 0]  ddr_dqs_fpga_n;
  wire [`data_strobe_width-1 : 0]  ddr_dqs_sdram_n;
  wire [`data_strobe_width-1 : 0]  ddr_dqs_sdram;
  wire [`data_width-1:0]  ddr_dq_fpga;
  wire [`data_width-1:0]  ddr_dq_sdram;
  wire  [`row_address-1:0] ddr2_address;
  wire  [`cke_width-1 : 0]ddr2_cke;
  wire  [0 : 0]ddr2_csb;
  wire  ddr2_web;
  wire  ddr2_rasb;
  wire  ddr2_casb;
  wire  [`bank_address - 1:0]  ddr2_ba;
  wire  ddr2_ODT;

  wire [`data_mask_width-1:0] ddr2_dm;
  wire [2:0] CMD;
  reg  enable_o;
  reg  enable;

  wire rst_dqs_div_in;
  wire rst_dqs_div_out;

  wire        NF_WE;
  wire        NF_CE;
  wire        NF_OE;
  wire        NF_BYTE;
  wire [21:1] NF_A;
  wire [15:0] NF_D;

  reg sys_clk;

  // Module instantiation
  memory mem_ctrlr_0 (
    .cntrl0_DDR2_DQ    (ddr_dq_fpga),
    .cntrl0_DDR2_A     (ddr2_address),
    .cntrl0_DDR2_BA    (ddr2_ba),
    .cntrl0_DDR2_CK    (ddr2_clk),
    .cntrl0_DDR2_CK_N  (ddr2_clkb),
    .cntrl0_DDR2_CKE   (ddr2_cke),
    .cntrl0_DDR2_CS_N  (ddr2_csb),
    .cntrl0_DDR2_RAS_N (ddr2_rasb),
    .cntrl0_DDR2_CAS_N (ddr2_casb),
    .cntrl0_DDR2_WE_N  (ddr2_web),
    .cntrl0_DDR2_ODT   (ddr2_ODT),
    .cntrl0_DDR2_DM    (ddr2_dm),
    .cntrl0_DDR2_DQS   (ddr_dqs_fpga),
    .cntrl0_DDR2_DQS_N (ddr_dqs_fpga_n),
    .cntrl0_rst_dqs_div_in (rst_dqs_div_out),    // loopback
    .cntrl0_rst_dqs_div_out (rst_dqs_div_out),   // loopback
 
    .NF_WE       (NF_WE),
    .NF_CE       (NF_CE),
    .NF_OE       (NF_OE),
    .NF_BYTE     (NF_BYTE),
    .NF_A        (NF_A),
    .NF_D        (NF_D),

    .ddr_clk     (ddr_clk),
    .sys_clk     (sys_clk),
    .cpu_clk     (cpu_clk),
    .mem_rst     (mem_rst),
    .board_reset (rst),

    .addr        (addr),
    .wr_data     (wr_data),
    .we          (we),
    .byte_m      (byte_m),
    .rd_data     (rd_data),
    .ready       (ready)
	);

  ddr2 X16_0 (
		.ck     (ddr2_clk[0]),
		.ck_n   (ddr2_clkb[0]),
		.cke    (ddr2_cke),
		.cs_n   (ddr2_csb),
		.ras_n  (ddr2_rasb),
		.cas_n  (ddr2_casb),
		.we_n   (ddr2_web),
		.dm_rdqs(ddr2_dm[1:0]),
		.ba     (ddr2_ba),
		.addr   (ddr2_address),
		.dq     (ddr_dq_sdram[15:0]),
		.dqs    (ddr_dqs_sdram[1:0]),
		.dqs_n  ( ddr_dqs_sdram_n[1:0]),
		.rdqs_n (),
		.odt    (ddr2_ODT)
	);

  test_stub flash_rom0 (
    .W_N      (NF_WE),
    .E_N      (NF_CE),
    .G_N      (NF_OE),
    .Byte_N   (NF_BYTE),
    .A        (NF_A),
    .DQ       (NF_D[14:0]),
    .DQ15A_1  (NF_D[15])
  );


  // Assignments
  assign ddr_dqs_fpga = (enable == 1'b1) ?  ddr_dqs_sdram : `data_strobe_width'hZ;
  assign ddr_dq_fpga  = ( enable == 1'b1) ? ddr_dq_sdram : `data_width'hZ;

  assign ddr_dqs_sdram = (enable == 1'b0) ? ddr_dqs_fpga : `data_strobe_width'hZ;
  assign ddr_dq_sdram = (enable == 1'b0) ? ddr_dq_fpga : `data_width'hZ;

  assign ddr_dqs_fpga_n = (enable == 1'b1) ?  ddr_dqs_sdram_n : `data_strobe_width'hZ;
  assign ddr_dqs_sdram_n = (enable == 1'b0) ? ddr_dqs_fpga_n : `data_strobe_width'hZ;

  assign CMD = {ddr2_rasb,ddr2_casb,ddr2_web};
  assign ddr_clkb = ~ ddr_clk;

  // Behaviour
  initial enable = 1'b0;

  // Clock Generation
  initial 
    begin
      ddr_clk <= 1'b1;
      cpu_clk <= 1'b1;
      sys_clk <= 1'b1;
    end

  // RESET Generation
  initial
    begin
      rst = 1'b1;
      we <= 1'b1;
      # 37.593984962406 rst = 1'b0;
      @(negedge mem_rst)

      @(posedge cpu_clk)
        addr    <= 20'h18b2e;
        byte_m  <= 1'b0;
        we      <= 1'b0;
        wr_data <= 16'h0cd3;

      @(posedge cpu_clk)
        addr    <= 20'h18b2e;
        byte_m  <= 1'b0;
        we      <= 1'b0;
        wr_data <= 16'h8cf1;

      // Flash test
      @(posedge cpu_clk) 
        addr    <= 20'hf0011;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'hf0011;
        byte_m  <= 1'b1;
      @(posedge cpu_clk) 
        addr    <= 20'hf0010;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'hf0010;
        byte_m  <= 1'b1;
      @(posedge cpu_clk)
        addr    <= 20'hf0013;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'hf0013;
        byte_m  <= 1'b1;

      // RAM - write test
      // Write - word in even address
      @(posedge cpu_clk) 
        addr    <= 20'h00004;
        wr_data <= 16'h4321;
        we      <= 1'b0;
        byte_m  <= 1'b0;
      // Write - byte in even address
      @(posedge cpu_clk)
        addr    <= 20'h00006;
        wr_data <= 16'h8765;
        we      <= 1'b0;
        byte_m  <= 1'b1;
      // Write - word in odd address - without group/col change
      @(posedge cpu_clk)
        addr    <= 20'h00009;
        wr_data <= 16'h4321;
        we      <= 1'b0;
        byte_m  <= 1'b0;
      // Write - byte in odd address - without group/col change
      @(posedge cpu_clk)
        addr    <= 20'h0000b;
        wr_data <= 16'h4321;
        we      <= 1'b0;
        byte_m  <= 1'b1;

      // RAM - read test
      // Read - word in even address
      @(posedge cpu_clk)
        addr    <= 20'h00004;
        we      <= 1'b1;
        byte_m  <= 1'b0;
      // Read - byte in odd address - without group/col change
      @(posedge cpu_clk)
        addr    <= 20'h00005;
        byte_m  <= 1'b1;
      // Read - word in odd address - without group/col change
      @(posedge cpu_clk)
        addr    <= 20'h00005;
        byte_m  <= 1'b0;
      // Read - word in even address
      @(posedge cpu_clk)
        addr    <= 20'h00006;
        byte_m  <= 1'b0;
      // Read - byte in even address
      @(posedge cpu_clk)
        addr    <= 20'h00006;
        byte_m  <= 1'b1;
      @(posedge cpu_clk)
        addr    <= 20'h00008;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h0000a;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h0000c;
        byte_m  <= 1'b0;

      // Write - byte in odd address with group change
      @(posedge cpu_clk)
        addr    <= 20'h00013;
        byte_m  <= 1'b1;
        we      <= 1'b0;
        wr_data <= 16'h4321;
      // Read - byte in odd address with group change
      @(posedge cpu_clk)
        addr    <= 20'h00013;
        we      <= 1'b1;
        byte_m  <= 1'b1;
      @(posedge cpu_clk)
        addr    <= 20'h00012;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h00014;
        byte_m  <= 1'b0;

      // Write - word in odd address with group change
      @(posedge cpu_clk)
        addr    <= 20'h00017;
        byte_m  <= 1'b0;
        we      <= 1'b0;
        wr_data <= 16'h4321;
      // Read - word in odd address with group change
      @(posedge cpu_clk)
        addr    <= 20'h00017;
        byte_m  <= 1'b0;
        we      <= 1'b1;
      @(posedge cpu_clk)
        addr    <= 20'h00016;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h00018;
        byte_m  <= 1'b0;

      // Write - byte in odd address with col change
      @(posedge cpu_clk)
        addr    <= 20'h003ff;
        byte_m  <= 1'b1;
        we      <= 1'b0;
        wr_data <= 16'h4321;
      // Read - byte in odd address with col change
      @(posedge cpu_clk)
        addr    <= 20'h003ff;
        byte_m  <= 1'b1;
        we      <= 1'b1;
      @(posedge cpu_clk)
        addr    <= 20'h003fe;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h00400;
        byte_m  <= 1'b0;

      // Write - word in odd address with col change
      @(posedge cpu_clk) 
        addr    <= 20'h007ff;
        byte_m  <= 1'b0;
        we      <= 1'b0;
        wr_data <= 16'h4321;
      // Read - word in odd address with col change
      @(posedge cpu_clk)
      @(posedge cpu_clk)
        addr    <= 20'h007ff;
        byte_m  <= 1'b0;
        we      <= 1'b1;
      @(posedge cpu_clk)
      @(posedge cpu_clk)
        addr    <= 20'h007fe;
        byte_m  <= 1'b0;
      @(posedge cpu_clk)
        addr    <= 20'h00800;
        byte_m  <= 1'b0;
        
    end

  always @(posedge ddr_clk)
    begin
      if (CMD == 3'b100)     // -- Write
        enable_o <= 1'b0;
      else if(CMD == 3'b101) // -- Read
        enable_o <= 1'b1;
      else
        enable_o <= enable_o;
    end

  always @(posedge ddr_clk) enable <= enable_o;

  always # 3.7593984962406 ddr_clk <= ~ ddr_clk; // 133 MHZ
  always # 150  cpu_clk <= ~cpu_clk; // 3.33Mhz
  always # 10.1 sys_clk <= ~sys_clk; // 50Mhz
endmodule
