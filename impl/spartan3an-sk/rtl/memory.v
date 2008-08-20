`timescale 1ns/10ps

module memory (
/*
    inout      [15:0] cntrl0_DDR2_DQ,
    output     [12:0] cntrl0_DDR2_A,
    output      [1:0] cntrl0_DDR2_BA,
    output            cntrl0_DDR2_CK,
    output            cntrl0_DDR2_CK_N,
    output            cntrl0_DDR2_CKE,
    output            cntrl0_DDR2_CS_N,
    output            cntrl0_DDR2_RAS_N,
    output            cntrl0_DDR2_CAS_N,
    output            cntrl0_DDR2_WE_N,
    output            cntrl0_DDR2_ODT,
    output      [1:0] cntrl0_DDR2_DM,
    inout       [1:0] cntrl0_DDR2_DQS,
    inout       [1:0] cntrl0_DDR2_DQS_N,
    input             cntrl0_rst_dqs_div_in,    // loopback
    output            cntrl0_rst_dqs_div_out,   // loopback
*/
    output            NF_WE,
    output            NF_CE,
    output            NF_OE,
    output            NF_BYTE,
    output     [21:1] NF_A,
    input      [15:0] NF_D,

//    input             ddr_clk,
    input             sys_clk,
    input             cpu_clk,
//    output            mem_rst,
    input             reset,

    input      [19:0] addr,
//    input      [15:0] wr_data,
//    input             we,
    input             byte_m,
    output     [15:0] rd_data,
    input             mem_op,
    output            ready
  );

  // Net declarations
  wire        rom_area;
  wire [15:0] rd_rom_data /*, rd_ram_data */;
  wire [16:0] rom_addr;
  wire        rom_ready /*, ram_ready */;
  wire        rom_op /*, ram_op */;

  // Module instantiations
  flash_prom_zet_cntrlr flash0 (
    .NF_WE   (NF_WE),
    .NF_CE   (NF_CE),
    .NF_OE   (NF_OE),
    .NF_BYTE (NF_BYTE),
    .NF_A    (NF_A),
    .NF_D    (NF_D),

    .cpu_clk (cpu_clk),
    .sys_clk (sys_clk),
    .reset   (reset),
    .addr    (rom_addr),
    .byte_m  (byte_m),
    .rd_data (rd_rom_data),
    .enable  (rom_op),
    .ready   (rom_ready)
  );
/*
  ddr2_sdram_zet_cntrlr sdram0 (
    .cntrl0_DDR2_DQ         (cntrl0_DDR2_DQ),
    .cntrl0_DDR2_A          (cntrl0_DDR2_A),
    .cntrl0_DDR2_BA         (cntrl0_DDR2_BA),
    .cntrl0_DDR2_CK         (cntrl0_DDR2_CK),
    .cntrl0_DDR2_CK_N       (cntrl0_DDR2_CK_N),
    .cntrl0_DDR2_CKE        (cntrl0_DDR2_CKE),
    .cntrl0_DDR2_CS_N       (cntrl0_DDR2_CS_N),
    .cntrl0_DDR2_RAS_N      (cntrl0_DDR2_RAS_N),
    .cntrl0_DDR2_CAS_N      (cntrl0_DDR2_CAS_N),
    .cntrl0_DDR2_WE_N       (cntrl0_DDR2_WE_N),
    .cntrl0_DDR2_ODT        (cntrl0_DDR2_ODT),
    .cntrl0_DDR2_DM         (cntrl0_DDR2_DM),
    .cntrl0_DDR2_DQS        (cntrl0_DDR2_DQS),
    .cntrl0_DDR2_DQS_N      (cntrl0_DDR2_DQS_N),
    .cntrl0_rst_dqs_div_in  (cntrl0_rst_dqs_div_in),  // loopback
    .cntrl0_rst_dqs_div_out (cntrl0_rst_dqs_div_out), // loopback

    .board_reset            (board_reset),            // board reset
    .sys_clk                (ddr_clk),
    .cpu_clk                (cpu_clk),
    .addr                   (addr),
    .wr_data                (wr_data),
    .we                     (we),
    .byte_m                 (byte_m),
    .rd_data                (rd_ram_data),
    .mem_rst                (mem_rst),
    .enable                 (ram_op),
    .ready                  (ram_ready)
  );
*/

  // Assignments
  assign rom_area       = (addr[19:16]==4'hf || addr[19:16]==4'hc);
  assign rd_data        = rom_area ? rd_rom_data : 16'h0 /* rd_ram_data */;
  assign rom_addr[16]   = (addr[19:16]==4'hf);
  assign rom_addr[15:0] = addr;
  assign ready          = rom_area ? rom_ready : 1'b1 /* ram_ready */;
  assign rom_op         = rom_area && mem_op;
//  assign ram_op         = !rom_area && mem_op;
endmodule