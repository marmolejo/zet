// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      flash.v
// Description: Wishbone Compatible flash core.
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module flash (
    input             wb_clk_i,          // Wishbone slave interface
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output     [15:0] wb_dat_o,
    input      [16:1] wb_adr_i,
    input             wb_we_i,
    input             wb_tga_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    input      [ 1:0] wb_sel_i,
    output reg        wb_ack_o,
    output     [21:0] flash_addr_,		// Pad signals
    input      [15:0] flash_data_,
    output            flash_we_n_,
    output            flash_oe_n_,
    output            flash_ce_n_,
    output            flash_rst_n_
  );

  // Continuous assignments
  assign flash_rst_n_ = 1'b1;
  assign flash_we_n_  = 1'b1;
  assign flash_oe_n_  = !op;
  assign flash_ce_n_  = !op;
  assign flash_addr_  = wb_tga_i ? { 1'b1, base, wb_adr_i[9:1] } : { 5'h0, wb_adr_i };

  assign wb_dat_o = flash_data_;
  
  // wb_ack_o
  wire   op           = wb_stb_i & wb_cyc_i;
  always @(posedge wb_clk_i) wb_ack_o <= wb_rst_i ? 1'b0 : (wb_ack_o ? 1'b0 : op);


  // base
  reg  [11:0] base;
  wire opbase  = op & wb_tga_i & wb_we_i;
  always @(posedge wb_clk_i) base <= wb_rst_i ? 12'h0: ((opbase) ? wb_dat_i[11:0] : base);

endmodule
