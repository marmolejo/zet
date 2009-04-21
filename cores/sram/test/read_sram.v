module read_sram (
    output [9:0] ledr_,
    output [7:0] ledg_,
    input  [9:0] sw_,

    // Pad signals
    output  [17:0] sram_addr_,
    input   [15:0] sram_data_,
    output         sram_we_n_,
    output         sram_oe_n_,
    output         sram_ce_n_,
    output  [ 1:0] sram_bw_n_
  );

  // Continuous assignments
  assign sram_addr_      = { 8'b0011_0000, sw_ };
  assign { ledr_,ledg_ } = { 2'b00, sram_data_ };

  assign sram_we_n_ = 1'b1;
  assign sram_oe_n_ = 1'b0;
  assign sram_ce_n_ = 1'b0;
  assign sram_bw_n_ = 2'b00;
endmodule
