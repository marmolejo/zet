`timescale 1ns/100ps

module flash_prom_zet_cntrlr (
    output            NF_WE,
    output            NF_CE,
    output            NF_OE,
    output            NF_BYTE,
    output     [21:1] NF_A,
    input      [15:0] NF_D,

    input         cpu_clk,
    input         sys_clk,
    input         reset,
    input  [16:0] addr,
    input         byte_m,
    output [15:0] rd_data,
    input         enable,
    output        ready
  );

  // Net and register declarations
  wire [15:0] addr0, addr1;
  reg  [15:0] word0;
  reg  [7:0]  word1;
  wire [7:0]  byte_l0, byte_l1, byte_h0;
  wire        a0;
  wire        sec_wrd;
  reg         old_clk, start_cmd;
  reg  [3:0]  state, next_state;
  reg         eff_ready;
  reg  [15:0] nf_addr;
  reg  [16:0] addr_l;
  reg         byte_m_l;

  wire        rdy_to_start;

  parameter   word0_st = 4'd0;
  parameter   wait1    = 4'd1;
  parameter   wait2    = 4'd2;
  parameter   wait3    = 4'd3;
  parameter   word1_st = 4'd4;
  parameter   wait4    = 4'd5;
  parameter   wait5    = 4'd6;
  parameter   wait6    = 4'd7;
  parameter   rd_word1 = 4'd8;
  parameter   rd_done  = 4'd9;

  // Assignments
  assign addr0   = addr_l[16:1];
  assign addr1   = addr0 + 16'd1;
  assign a0      = addr_l[0];

  assign byte_l0 = word0[7:0];
  assign byte_h0 = word0[15:8];
  assign byte_l1 = word1;

  assign rd_data = byte_m ? ( a0 ? { {8{byte_h0[7]}}, byte_h0 }
                                 : { {8{byte_l0[7]}}, byte_l0 } )
                          : ( a0 ? { byte_l1, byte_h0 }
                                 : word0 );

  assign ready   = (next_state==rd_done) || !enable;
  assign sec_wrd = (!byte_m_l && a0);

  assign rdy_to_start = cpu_clk && !old_clk && eff_ready && enable;

  assign NF_BYTE = 1'b1;
  assign NF_WE   = 1'b1;
  assign NF_CE   = 1'b0;
  assign NF_OE   = 1'b0;
  assign NF_A    = { 5'b0, nf_addr };

  // word0 load logic
  always @(posedge sys_clk)
    if (reset) word0 <= 16'h0;
    else if (state == wait3) word0 <= NF_D;
    else word0 <= word0;

  // word1 load logic
  always @(posedge sys_clk)
    if (reset) word1 <= 8'h0;
    else if (state == wait6) word1 <= NF_D[7:0];
    else word1 <= word1;

  // nf_addr load logic
  always @(posedge sys_clk)
    if (reset) nf_addr <= 16'h0;
    else if (start_cmd || state == rd_done) nf_addr <= addr0;
    else if (state == wait3) nf_addr <= addr1;
    else nf_addr <= nf_addr;

  // addr_l load logic
  always @(negedge sys_clk)
    if (reset) addr_l <= 17'h0;
    else if (rdy_to_start) addr_l <= addr;
    else addr_l <= addr_l;

  // byte_m_l load logic
  always @(negedge sys_clk)
    if (reset) byte_m_l <= 1'b0;
    else if (rdy_to_start) byte_m_l <= byte_m;
    else byte_m_l <= byte_m_l;

  // Read sequence fsm
  always @(state or reset or sec_wrd)
    if (reset) next_state <= rd_done;
    else
      case (state)
        word0_st: next_state <= wait1;
        wait1:    next_state <= wait2;
        wait2:    next_state <= wait3;
        wait3:    next_state <= word1_st;
        word1_st: next_state <= sec_wrd ? wait4 : rd_done;
        wait4:    next_state <= wait5;
        wait5:    next_state <= wait6;
        wait6:    next_state <= rd_word1;
        rd_word1: next_state <= rd_done;
        default:  next_state <= word0_st;
      endcase

  always @(posedge sys_clk)
    if (reset) state <= rd_word1;
    else begin
      if (start_cmd) state <= word0_st;
      else state <= (next_state==rd_done) ? state : next_state;
    end

  // start_cmd signal
  always @(negedge sys_clk)
    if (reset)
      begin
        old_clk <= 1'b0;
        start_cmd <= 1'b0;
      end
    else
      begin
        if (rdy_to_start) start_cmd <= 1'b1;
        else start_cmd <= 1'b0;
        old_clk <= cpu_clk;
      end

  always @(posedge cpu_clk) eff_ready <= ready;
endmodule
