`timescale 1ns/100ps

module wb_flash_prom_zet_cntrlr (
    // Pad signals
    output            NF_WE,
    output            NF_CE,
    output            NF_OE,
    output            NF_BYTE,
    output     [21:1] NF_A,
    input      [15:0] NF_D,

    // Wishbone signals
    input             wb_clk_i,  // 13.33Mhz maximum
    input             wb_rst_i,
    input             wb_stb_i,
    input      [16:0] wb_adr_i,
    input             wb_byte_i, // Address tag: byte(1) or word(0) size
    output     [15:0] wb_dat_o,
    output            wb_ack_o
  );

  // Nets and registers declaration
  wire [15:0] nf_addr;

  reg  [16:0] addr;
  reg         byte_op;
  reg         wb_ack_o;
  reg         old_stb;

  // Continuous assignments
  assign NF_BYTE = 1'b1;
  assign NF_WE   = 1'b1;
  assign NF_CE   = 1'b0;
  assign NF_OE   = 1'b0;
  assign NF_A    = { 5'b0, nf_addr };

  // Behaviour

  // Latching of wb_adr_i and wb_byte_i
  always @(posedge wb_clk_i)
    if (wb_rst_i) addr <= 17'h0;
    else if (wb_stb_i) addr <= wb_adr_i;
    else addr <= addr;

  always @(posedge wb_clk_i)
    if (wb_rst_i) byte_op <= 1'b0;
    else if (wb_stb_i) addr <= wb_byte_i;
    else byte_op <= byte_op;

  // nf_addr
  always @(posedge wb_clk_i)
    if (wb_rst_i) nf_addr <= 16'h0;
    else if (

  // wb_ack_o
  always @(posedge wb_clk_i)
    if (wb_rst_i) wb_ack_o <= 1'b0;
    else if (next_state == rd_done) wb_ack_o <= 1'b1;
    else wb_ack_o <= wb_ack_o;

  // old_stb
  always @(posedge wb_clk_i)
    if (wb_rst_i) old_stb <= 1'b0;
    else old_stb <= wb_stb_i;

  // state
  always @(posedge wb_clk_i)
    if (wb_rst_i) state <= rd_word1;
    else begin
      if (start_cmd) state <= word0_st;
      else state <= (next_state==rd_done) ? state : next_state;
    end

  // Simple read sequence FSM
  always @(state or wb_rst_i or sec_wrd)
    if (wb_rst_i) next_state <= rd_done;
    else
      case (state)
        word0_st: next_state <= sec_wrd ? word1_st : rd_done;
        word1_st: next_state <= rd_done;
        default: next_state <= word0_st;
      endcase



endmodule
