
module pc_trace (
    // PAD signals
    output trx_,

    input         clk_100M,
    input         clk,
    input         rst,
    input  [19:0] pc,
    input  [ 2:0] zet_st,
    output reg    block
  );

  // Registers and nets
  reg [19:0] old_pc;
  reg [ 1:0] ser_stb_sync;
  reg [ 1:0] ser_ack_sync;
  reg        new_pc;
  reg        st;
  wire       clk_921600;
  wire       rst2;
  wire       stb;
  wire       ack;
  wire       ser_ack;

  // Module instantiations
  clk_uart clk0 (
    .clk_100M   (clk_100M),
    .rst        (rst),
    .clk_921600 (clk_921600),
    .rst2       (rst2)
  );

  send_addr ser0 (
    .trx_     (trx_),
    .wb_clk_i (clk_921600),
    .wb_rst_i (rst2),
    .wb_dat_i (pc),
    .wb_we_i  (stb),
    .wb_stb_i (stb),
    .wb_cyc_i (stb),
    .wb_ack_o (ser_ack)
  );

  // Continous assignments
  assign stb = st | new_pc;
  assign ack = ser_ack_sync[1];

  // Behaviour
  // old_pc
  always @(posedge clk) old_pc <= pc;

  // new_pc
  always @(posedge clk)
    new_pc <= rst ? 1'b0
      : ((old_pc != pc && zet_st == 3'b0) ? 1'b1 : 1'b0);

  // block
  always @(posedge clk)
    block <= rst ? 1'b0 : (new_pc ? st : block);

  // st
  always @(posedge clk)
    st <= rst ? 1'b0
      : (st ? (ack ? (new_pc | block) : 1'b1) : new_pc);

  // ser_stb_sync[0]
  always @(posedge clk_921600)
    ser_stb_sync <= { ser_stb_sync[0], stb };

  // ser_ack_sync[0]
  always @(posedge clk)
    ser_ack_sync <= { ser_ack_sync[0], ser_ack };
endmodule
