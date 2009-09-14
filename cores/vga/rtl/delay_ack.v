// Delays wb_ack_o until wb_stb_i is not low

module delay_ack (
    input  clk_vga,
    input  clk_cpu,
    input  wb_rst_i,
    input  wb_ack_i,
    input  wb_stb_i,
    output wb_ack_o,
    output wb_stb_o,

    input      [15:0] wb_dat_cpu,
    output reg [15:0] wb_dat_o
  );

  // Registers and nets
  reg  [1:0] cs, ns;
  reg        ft;
  reg  [2:0] sync;
  reg  [2:0] count;
  wire       rdy;

  localparam [1:0]
    IDLE = 2'b00,
    WORK = 2'b01,
    ACKW = 2'b10,
    SYNW = 2'b11;


  // Continuous assignments
  assign wb_stb_o = cs==WORK;
  assign rdy      = count[2];

  // and recreate the flag from the level change
  assign wb_ack_o = (sync[2] ^ sync[1]);

  // Behaviour
  // wb_dat_o
  always @(posedge clk_vga)
    wb_dat_o <= wb_rst_i ? 16'h0 : (wb_ack_i ? wb_dat_cpu : wb_dat_o);

  // state machine
  // cs - current state
  always @(posedge clk_vga)
    cs <= wb_rst_i ? IDLE : ns;

  // ns - next state
  always @(*)
    case (cs)
      default: ns <= wb_stb_i ? WORK : IDLE;
      WORK:    ns <= wb_ack_i ? ACKW : WORK;
      ACKW:    ns <= wb_ack_o ? SYNW : ACKW;
      SYNW:    ns <= rdy ? IDLE : SYNW;
    endcase

  // this changes level when a flag is seen
  always @(posedge clk_vga)
    ft <= wb_rst_i ? 1'b0 : (wb_ack_i ? ~ft : ft);

  // which can then be synched to clk_cpu
  always @(posedge clk_cpu)
    sync <= wb_rst_i ? 3'h0 : {sync[1:0], ft};

  // wait till next round
  always @(posedge clk_vga)
    count <= wb_rst_i ? 3'h0
      : (wb_ack_o ? 3'h1 : { count[1:0], 1'b0 });

endmodule
