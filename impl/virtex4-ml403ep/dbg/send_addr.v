module send_addr (
    // Serial pad signal
    output       trx_,

    // Wishbone slave interface
    input        wb_clk_i,
    input        wb_rst_i,
    input [19:0] wb_dat_i,
    input        wb_we_i,
    input        wb_stb_i,
    input        wb_cyc_i,
    output       wb_ack_o
  );

  // Registers and nets
  reg  [1:0] pack;
  reg        st;
  wire       op;
  wire       start;
  wire       sack;
  wire [7:0] dat;
  wire [7:0] b0, b1, b2;

  // Module instantiation
  send_serial ss0 (
    .trx_ (trx_),

    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_dat_i (dat),
    .wb_we_i  (wb_we_i),
    .wb_stb_i (wb_stb_i),
    .wb_cyc_i (wb_cyc_i),
    .wb_ack_o (sack)
  );

  // Continuous assignments
  assign op       = wb_we_i & wb_stb_i & wb_cyc_i;
  assign start    = !st & op;
  assign wb_ack_o = st & sack & pack[1];
  assign dat      = st & pack[0] ? (pack[1] ? b2 : b1) : b0;

  assign b0 = { 1'b0, wb_dat_i[6:0] };
  assign b1 = { 1'b0, wb_dat_i[13:7] };
  assign b2 = { 2'b11, wb_dat_i[19:14] };

  // Behaviour
  // pack
  always @(posedge wb_clk_i)
    pack <= wb_rst_i ? 2'b0 : (start ? 2'b0
      : (st ? (sack ? { pack[0], 1'b1 } : pack) : 2'b0));

  // st
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 1'b0 : (st ? !wb_ack_o : op);
endmodule
