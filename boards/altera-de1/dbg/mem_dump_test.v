`timescale 1ns/10ps

module mem_dump_test;

  // Registers and nets
  reg        clk_50;
  reg  [9:0] sw;

  wire [17:0] sram_addr_;
  wire [15:0] sram_data_;
  wire        sram_we_n_;
  wire        sram_oe_n_;
  wire        sram_ce_n_;
  wire [ 1:0] sram_bw_n_;

  // Module instances
  mem_dump_top mem_dump_top0 (
    .clk_50_ (clk_50),
    .sw_     (sw),

    .sram_addr_ (sram_addr_),
    .sram_data_ (sram_data_),
    .sram_we_n_ (sram_we_n_),
    .sram_oe_n_ (sram_oe_n_),
    .sram_ce_n_ (sram_ce_n_),
    .sram_bw_n_ (sram_bw_n_)
  );

  IS61LV25616 sram (
    .A   (sram_addr_),
    .IO  (sram_data_),
    .CE_ (sram_ce_n_),
    .OE_ (sram_oe_n_),
    .WE_ (sram_we_n_),
    .LB_ (sram_bw_n_[0]),
    .UB_ (sram_bw_n_[1])
  );

  // Behaviour
  // Clock generation
  always #10 clk_50 <= !clk_50;

  initial
    begin
      $readmemh("../../../cores/vga/rtl/char_rom.dat",
        mem_dump_top0.vdu0.vdu_char_rom.rom);
      $readmemh("../../../cores/sram/sim/rnd_data.dat",
        sram.bank0);
      $readmemh("../../../cores/sram/sim/rnd_data.dat",
        sram.bank1);

      clk_50 <= 1'b0;
      sw <= 10'h0;
    end

endmodule
