module lcd_test (
    // Pad signals
    input        sys_clk_in_,
    output       rs_,
    output       rw_,
    output       e_,
    inout  [7:4] db_
  );

  // Module instantiations
  lcd_display lcd0 (
    .clk (sys_clk_in_),
    .f1  (64'h123456f890abcde7),
    .f2  (64'h7645321dcbaef987),
    .m1  (16'b0101011101011111),
    .m2  (16'b1110101110101111),

    .lcd_rs_ (rs_),
    .lcd_rw_ (rw_),
    .lcd_e_  (e_),
    .lcd_dat_(db_)
  );

endmodule
