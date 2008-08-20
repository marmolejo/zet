`timescale 1ns/10ps

// For the moment, we only accept READ/WRITE BYTE/WORD 
//   on even addresses

module mem_ctrl (
    // Wishbone signals
    input         clk_i,
	 input         rst_i,
    input  [19:0] adr_i,
    input  [15:0] dat_i,
    output [15:0] dat_o,
    input         we_i,
    output        ack_o,
    input         stb_i,
    input         byte_i,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        flash_ce2_
  );

  // Net declarations
  wire ram_or_rom;
  wire [5:0] high_flash;
  wire [5:0] high_addr;
  wire [15:0] wr;  // word from memory read
  wire [15:0] ww;  // word to memory write
  wire [15:0] bhr; // byte high read, sign extended
  wire [15:0] blr; // byte low read, sign extended
  wire        a0;  // address 0 bit
  wire [ 1:0] be;  // byte enable
  wire [19:0] adr_1; // next address
  wire [19:0] adr; // adress

  // Register declarations
  reg       estat;
  reg [7:0] bhr_l;

  // Continuous assignments
  assign ram_or_rom = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign high_flash = { 5'b0, adr[17] };
  assign high_addr  = ram_or_rom ? high_flash : { 2'b0, adr[19:16] };
  
  assign wr  = sram_flash_data_;
  assign a0  = adr_i[0];
  assign bhr = { {8{wr[15]}}, wr[15:8] };
  assign blr = { {8{wr[7]}},  wr[7:0] };
  assign be  = byte_i ? (a0 ? 2'b01 : 2'b10) : 2'b00;
  assign ww  = a0 ? { dat_i[7:0], dat_i[15:8] } : dat_i;

  assign adr_1 = adr_i + 20'd1;
  assign adr = (estat && a0 && !byte_i) ? adr_1 : adr_i;

  // Wishbone outputs
  assign ack_o = stb_i && estat;
  assign dat_o = byte_i ? (a0 ? bhr : blr) : (a0 ? { wr[7:0], bhr_l } : wr);

  // PAD outputs
  assign sram_clk_   = clk_i;
  assign sram_flash_addr_ = { high_addr, adr[15:1] };
  assign sram_flash_data_ = sram_flash_we_n_ ? 16'hzzzz : ww;
  assign sram_flash_oe_n_ = /* !ram_or_rom && */ we_i;
  assign sram_flash_we_n_ = ram_or_rom || !we_i;
  assign sram_bw_ = { 2'b11, be };

  assign sram_cen_   = /* ram_or_rom || */ !stb_i;
  assign flash_ce2_  = /* ram_or_rom && */  stb_i;

  // Behavioral description
  // estat
  always @(posedge clk_i)
    if (rst_i) estat <= 1'b1;
    else estat <= estat ? (!stb_i || !a0 || byte_i) : 1'b1;

  // bhr_l
  always @(posedge clk_i) bhr_l <= wr[15:8];
endmodule
