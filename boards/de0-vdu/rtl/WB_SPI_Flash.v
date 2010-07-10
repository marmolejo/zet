// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      WB_SPI_Flash.v
// Description: Wishbone SPI Flash RAM core.
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module WB_SPI_Flash(
    input            	wb_clk_i,	// Wishbone slave interface
    input            	wb_rst_i,
    input      [8:0] 	wb_dat_i,
    output reg [7:0] 	wb_dat_o,
    input            	wb_we_i,
    input      [1:0] 	wb_sel_i,
    input            	wb_stb_i,
    input            	wb_cyc_i,
    output reg       	wb_ack_o,

    output reg 			sclk,		// Serial pad signal
    input      			miso,
    output reg 			mosi,
    output reg 			sels
  );

  // Registers and nets
  wire       op;
  wire       start;
  wire       send;
  reg  [7:0] tr;
  reg        st;
  reg  [7:0] sft;
  reg  [1:0] clk_div;

  // Continuous assignments
  assign op     = wb_stb_i & wb_cyc_i;
  assign start  = !st & op;
  assign send   = start & wb_we_i & wb_sel_i[0];

  // Behaviour
  always @(posedge wb_clk_i) mosi <= wb_rst_i ? 1'b1 : (clk_div == 2'b10 ? (send ? wb_dat_i[7] : tr[7]) : mosi);

  always @(posedge wb_clk_i) tr  <= wb_rst_i ? 8'hff : (clk_div == 2'b10 ? { (send ? wb_dat_i[6:0] : tr[6:0]), 1'b1 } : tr);

  always @(posedge wb_clk_i) wb_ack_o <= wb_rst_i ? 1'b0 : (wb_ack_o ? 1'b0 : (sft[0] && clk_div == 2'b00));

  always @(posedge wb_clk_i) sft <= wb_rst_i ? 8'h0 : (clk_div == 2'b10 ? { start, sft[7:1] } : sft);

  always @(posedge wb_clk_i) st <= wb_rst_i ? 1'b0 : (st ? !sft[0] : op && clk_div == 2'b10);

  always @(posedge wb_clk_i) wb_dat_o <= wb_rst_i ? 8'h0 : ((op && clk_div == 2'b0) ? { wb_dat_o[6:0], miso } : wb_dat_o);

  always @(posedge wb_clk_i) sclk <= wb_rst_i ? 1'b1 : (clk_div[0] ? sclk : !(op & clk_div[1]));

  always @(negedge wb_clk_i) sels <= wb_rst_i ? 1'b1 : ((op & wb_we_i & wb_sel_i[1]) ? wb_dat_i[8] : sels);

  always @(posedge wb_clk_i) clk_div <= clk_div - 2'd1;

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------
// End of WB Ethernet Module
// --------------------------------------------------------------------

