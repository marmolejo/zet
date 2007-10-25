`timescale 1ns/100ps
`include "parameters.v"
module board; 

  // Net and register declaration
/*
  wire [`clk_width-1 : 0]         ddr2_clk;
  wire [`clk_width-1 : 0]         ddr2_clkb;
  wire [`cke_width-1 : 0]         ddr2_cke;
  wire [0 : 0]                    ddr2_csb;
  wire                            ddr2_web;
  wire                            ddr2_rasb;
  wire                            ddr2_casb;
  wire [`data_mask_width-1:0]     ddr2_dm;
  wire [`bank_address - 1:0]      ddr2_ba;
  wire [`row_address-1:0]         ddr2_address;
  wire                            ddr2_ODT;
  wire [`data_strobe_width-1 : 0] ddr_dqs_sdram;
  wire [`data_width-1:0]          ddr_dq_sdram;
  wire [`data_strobe_width-1 : 0] ddr_dqs_sdram_n;
  wire [`data_width-1:0]          ddr_dq_fpga;
  wire [`data_strobe_width-1 : 0] ddr_dqs_fpga;
  wire                            rst_dqs_div_out;
  wire [`data_strobe_width-1 : 0] ddr_dqs_fpga_n;
  wire                            ddr_clkb;
*/
  wire        NF_WE;
  wire        NF_CE;
  wire        NF_OE;
  wire        NF_BYTE;
  wire        NF_RP;
  wire [21:1] NF_A;
  wire [15:0] NF_D;

  wire        vga_r, vga_g, vga_b, vga_hsync, vga_vsync;
  wire [1:0]  led;

  reg         sys_clk /*, ddr_clk */;
  reg         rst;
  reg         enable, enable_o;
// wire  [2:0] CMD;

  // Module instantiations
/*
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
*/
  test_stub flash_rom0 (
    .W_N      (NF_WE),
    .E_N      (NF_CE),
    .G_N      (NF_OE),
    .Byte_N   (NF_BYTE),
    .RP       (NF_RP),
    .A        (NF_A),
    .DQ       (NF_D[14:0]),
    .DQ15A_1  (NF_D[15])
  );

  zet_soc fpga0 (
//    .DDR_CLK     (ddr_clk),
    .SYS_CLK     (sys_clk),
/*
    .SD_DQ       (ddr_dq_fpga),
    .SD_A        (ddr2_address),
    .SD_BA       (ddr2_ba),
    .SD_CK_P     (ddr2_clk),
    .SD_CK_N     (ddr2_clkb),
    .SD_CKE      (ddr2_cke),
    .SD_CS       (ddr2_csb),
    .SD_RAS      (ddr2_rasb),
    .SD_CAS      (ddr2_casb),
    .SD_WE       (ddr2_web),
    .SD_ODT      (ddr2_ODT),
    .SD_UDM      (ddr2_dm[1]),
    .SD_LDM      (ddr2_dm[0]),
    .SD_UDQS_P   (ddr_dqs_fpga[1]),
    .SD_LDQS_P   (ddr_dqs_fpga[0]),
    .SD_UDQS_N   (ddr_dqs_fpga_n[1]),
    .SD_LDQS_N   (ddr_dqs_fpga_n[0]),
    .SD_LOOP_IN  (rst_dqs_div_out),
    .SD_LOOP_OUT (rst_dqs_div_out),
*/
    .NF_D        (NF_D),
    .NF_A        (NF_A),
    .NF_WE       (NF_WE),
    .NF_CE       (NF_CE),
    .NF_OE       (NF_OE),
    .NF_BYTE     (NF_BYTE),
    .NF_RP       (NF_RP),

    .BTN_SOUTH   (rst),

    .VGA_R       (vga_r),
    .VGA_G       (vga_g),
    .VGA_B       (vga_b),
    .VGA_HSYNC   (vga_hsync),
    .VGA_VSYNC   (vga_vsync),

    .LED         (led)
  );

  // Assignments
/*
  assign ddr_dqs_fpga = (enable == 1'b1) ?  ddr_dqs_sdram : `data_strobe_width'hZ;
  assign ddr_dq_fpga  = ( enable == 1'b1) ? ddr_dq_sdram : `data_width'hZ;

  assign ddr_dqs_sdram = (enable == 1'b0) ? ddr_dqs_fpga : `data_strobe_width'hZ;
  assign ddr_dq_sdram = (enable == 1'b0) ? ddr_dq_fpga : `data_width'hZ;

  assign ddr_dqs_fpga_n = (enable == 1'b1) ?  ddr_dqs_sdram_n : `data_strobe_width'hZ;
  assign ddr_dqs_sdram_n = (enable == 1'b0) ? ddr_dqs_fpga_n : `data_strobe_width'hZ;

  assign CMD = {ddr2_rasb,ddr2_casb,ddr2_web};
  assign ddr_clkb = ~ddr_clk;
*/
  // Behaviour
  initial enable = 1'b0;

  // Clock Generation
  initial 
    begin
      // ddr_clk <= 1'b1;
      sys_clk <= 1'b1;
    end

  // RESET Generation
  initial
    begin
      rst = 1'b0;
      # 800 rst = 1'b1;
      # 100 rst = 1'b0;
    end
/*
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
*/
// always # 3.7593984962406 ddr_clk <= ~ddr_clk; // 133 MHZ
  always # 10              sys_clk <= ~sys_clk; // 50Mhz
endmodule
