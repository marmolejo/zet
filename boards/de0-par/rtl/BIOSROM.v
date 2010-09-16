// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      BIOSROM.v
// Description: Wishbone Compatible BIOS ROM core using megafunction ROM
// The following is to get rid of the warning about not initializing the ROM
// altera message_off 10030
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module BIOSROM(
    input             wb_clk_i,          // Wishbone slave interface
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output     [15:0] wb_dat_o,
    input      [19:1] wb_adr_i,
    input             wb_we_i,
    input             wb_tga_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    input      [ 1:0] wb_sel_i,
    output reg        wb_ack_o
);

wire ack_o = wb_stb_i & wb_cyc_i;
always @(posedge wb_clk_i) wb_ack_o <= ack_o;

reg  [15:0] rom[0:127]; 	// Instantiate the ROM
initial $readmemh("biosrom.dat", rom);

wire   [ 6:0] rom_addr = wb_adr_i[7:1];
wire   [15:0] rom_dat  = rom[rom_addr];
assign        wb_dat_o = rom_dat;

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------
  
