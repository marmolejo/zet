module wb_mpu_lcd (
    // Wishbone slave interface
    input        wb_clk_i, // 6.25 Mhz
    input        wb_rst_i,
    input  [9:0] wb_dat_i, // 4/8 bit, rs, db[7:0]
    output       wb_ack_o,
    input        wb_we_i,
    input        wb_stb_i,
    input        wb_cyc_i,

    // PAD signals
    output reg   rs_,
    output reg   rw_,
    output reg   e_,
    inout  [3:0] db_,
  );

  // State parameters
  parameter rdy_st = 2'h0;

  // Registers and nets
  reg [1:0] st, ns;
  reg [1:0] cnt;
  wire      op;
  wire      b4;

  // Assignments
  assign op = wb_we_i & wb_stb_i & wb_cyc_i;
  assign b4 = wb_dat_i[9];

  // Behaviour
  // cnt
  always @(posedge wb_clk_i)
    cnt <= (wb_rst_i | !op) ? 2'b0 : (cnt + 2'b1);

  // e
  always @(posedge wb_clk_i)
    e_ <= wb_rst_i ? 1'b0
      : ((st==rdy_st & op) ? 1'b1 : );

  always @(posedge wb_clk_i)
    if (wb_rst_i)
    else
      case (st)
        rdy_st: ns <= op ? e1_st : rd_st;
        e1u_st: ns <= e1h_st;
        e1h_st: ns <= e1d_st;
        e1d_st: ns <= b4 ? d2s_st : rd_st;
        d2s_st: ns <= e2u_st;
        e2u_st: ns <= e1d_st;

      endcase
endmodule
