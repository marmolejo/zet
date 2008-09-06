`timescale 1ns/10ps

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

    // Pad signals
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
  wire        rom_area;
  wire [ 5:0] high_flash;
  wire [ 5:0] high_addr;
  wire [ 1:0] be;  // byte enable
  wire        a0;  // address 0 bit
  wire [15:0] wr;  // word from memory read
  wire [15:0] ww;  // word to memory write
  wire [15:0] bhr; // byte high read, sign extended
  wire [15:0] blr; // byte low read, sign extended
  wire [19:0] adr_1; // next address
  wire        odd_word; // Word odd operation
  wire [19:0] adr; // address
  wire        next_cnd; // Next byte condition

  // Register declarations
  reg [1:0] cnt;
  reg       next;
  reg [7:0] bhr_l;

  // Continous assignments
  assign sram_clk_        = clk_i;
  assign sram_flash_addr_ = { high_addr, adr[15:1] };
  assign sram_flash_we_n_ = cnt != 2'b00 | !stb_i | !we_i | rom_area;
  assign sram_flash_oe_n_ = !rom_area & we_i;
  assign sram_bw_         = { 2'b11, be };
  assign sram_cen_        = rom_area | !stb_i;
  assign flash_ce2_       = rom_area &  stb_i;

  assign sram_flash_data_ = we_i ? ww : 16'hzzzz;

  assign rom_area   = (adr[19:16]==4'hc || adr[19:16]==4'hf);
  assign high_flash = { 5'b0, adr[17] };
  assign high_addr  = rom_area ? high_flash : { 2'b0, adr[19:16] };
  assign be         = byte_i ? (a0 ? 2'b01 : 2'b10) 
                             : (a0 ? (next ? 2'b10 : 2'b01) : 2'b00);
  assign a0         = adr_i[0];
  assign wr         = sram_flash_data_;
  assign bhr        = { {8{wr[15]}}, wr[15:8] };
  assign blr        = { {8{wr[7]}},  wr[7:0] };
  assign ww         = a0 ? { dat_i[7:0], dat_i[15:8] } : dat_i;

  assign adr_1   = adr_i + 20'd1;
  assign odd_word = a0 & !byte_i;
  assign adr      = (next && stb_i && odd_word) ? adr_1 : adr_i;
  assign ack_o    = stb_i & (rom_area ? (!odd_word | next)
                             : (cnt==2'b10 & (!odd_word | next)));
  assign dat_o    = byte_i ? (a0 ? bhr : blr)
                           : (a0 ? { wr[7:0], bhr_l } : wr);
  assign next_cnd = stb_i & odd_word & 
    (next ? (rom_area ? 1'b0 : (cnt==2'b10 ? 1'b0 : 1'b1 ))
          : (rom_area ? 1'b1 : (cnt==2'b10 ? 1'b1 : 1'b0)));

  // Behavioral description
  // cnt
  always @(posedge clk_i)
    if (rst_i) cnt <= 2'd0;
    else cnt <= (stb_i && !rom_area) ?
      ((cnt==2'b10) ? 2'd0 : cnt + 2'b1) : 2'd0;

  // next
  always @(posedge clk_i)
    if (rst_i) next <= 1'b0;
    else next <= next_cnd;

  // bhr_l
  always @(posedge clk_i) bhr_l <= next_cnd ? wr[15:8] : bhr_l;
endmodule