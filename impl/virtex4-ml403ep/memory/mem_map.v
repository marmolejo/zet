`timescale 1ns/10ps

//`include "defines.v"

module mem_map (
`ifdef DEBUG
    output     [ 2:0] curr_st,
`endif
/*
    output req_write,
    output req_read,
    output one_more_cycle,
    output vga2_we,
    output vga2_rw,
    output vga4_rw,
*/
    // VGA pad signals
    output        vga_red_o,
    output        vga_green_o,
    output        vga_blue_o,
    output        horiz_sync,
    output        vert_sync,

    // Wishbone signals
    input         clk_i,  // 25 Mhz VDU clock
    input         rst_i,
    input  [19:0] adr_i,
    input  [15:0] dat_i,
    output [15:0] dat_o,
    input         we_i,
    output        ack_o,
    input         stb_i,
    input         cyc_i,
    input         byte_i,

    // Pad signals - Flash / SRAM
    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        sram_adv_ld_n_,
    output        flash_ce2_
  );

  // Net declarations
  wire [15:0] dat_mem_o, dat_vdu_o;
  wire        ack_mem_o, ack_vdu_o;
  wire        stb_mem_i, stb_vdu_i;

  // Module instantiations
  mem_ctrl mem_ctrl0 (
`ifdef DEBUG
    .curr_st (curr_st),
`endif
    .clk_i  (clk_i),
    .rst_i  (rst_i),
    .adr_i  (adr_i),
    .dat_i  (dat_i),
    .dat_o  (dat_mem_o),
    .we_i   (we_i),
    .ack_o  (ack_mem_o),
    .stb_i  (stb_mem_i),
    .byte_i (byte_i),

    // Pad signals - Flash / SRAM
    .sram_clk_        (sram_clk_),
    .sram_flash_addr_ (sram_flash_addr_),
    .sram_flash_data_ (sram_flash_data_),
    .sram_flash_oe_n_ (sram_flash_oe_n_),
    .sram_flash_we_n_ (sram_flash_we_n_),
    .sram_bw_         (sram_bw_),
    .sram_cen_        (sram_cen_),
    .sram_adv_ld_n_   (sram_adv_ld_n_),
    .flash_ce2_       (flash_ce2_)
  );

  vdu vdu0 (
/*
    .req_write      (req_write),
    .req_read       (req_read),
    .one_more_cycle (one_more_cycle),
    .vga2_we        (vga2_we),
    .vga2_rw        (vga2_rw),
    .vga4_rw        (vga4_rw),
*/
    // Wishbone signals
    .clk_i  (clk_i),
    .rst_i  (rst_i),
    .stb_i  (stb_vdu_i),
    .cyc_i  (stb_vdu_i),
    .we_i   (we_i),
    .adr_i  (adr_i[11:0]),
    .dat_i  (dat_i),
    .dat_o  (dat_vdu_o),
    .ack_o  (ack_vdu_o),
    .byte_i (byte_i),

    // VGA pad signals
    .vga_red_o   (vga_red_o),
    .vga_green_o (vga_green_o),
    .vga_blue_o  (vga_blue_o),
    .horiz_sync  (horiz_sync),
    .vert_sync   (vert_sync)
  );

  // Continuous assignments
  assign stb_vdu_i = (adr_i[19:13]==7'b1011_100) & stb_i;
  assign stb_mem_i = (adr_i[19:13]!=7'b1011_100) & stb_i;
  assign ack_o     = stb_vdu_i ? ack_vdu_o : ack_mem_o;
  assign dat_o     = stb_vdu_i ? dat_vdu_o : dat_mem_o;
endmodule
