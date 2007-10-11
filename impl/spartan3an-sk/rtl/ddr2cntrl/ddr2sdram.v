///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2005 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor			: Xilinx
// \   \   \/    Version		: $Name: mig_v1_7_b7 $
//  \   \        Application		: MIG
//  /   /        Filename		: vlog_xst_bl4_main_0.v
// /___/   /\    Date Last Modified	: $Date: 2007/02/06 08:08:58 $
// \   \  /  \   Date Created		: Mon May 2 2005
//  \___\/\___\
// Device	: Spartan-3/3A
// Design Name	: DDR2 SDRAM
// Purpose	: This modules has the instantiation for top and test_bench 
//		  modules.
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`include "parameters.v"

module ddr2_sdram_zet_cntrlr
  (
    inout [15:0] cntrl0_DDR2_DQ,
    output [12:0] cntrl0_DDR2_A,
    output [1:0] cntrl0_DDR2_BA,
    output  cntrl0_DDR2_CK,
    output  cntrl0_DDR2_CK_N,
    output  cntrl0_DDR2_CKE,
    output  cntrl0_DDR2_CS_N,
    output  cntrl0_DDR2_RAS_N,
    output  cntrl0_DDR2_CAS_N,
    output  cntrl0_DDR2_WE_N,
    output  cntrl0_DDR2_ODT,
    output [1:0] cntrl0_DDR2_DM,
    inout [1:0] cntrl0_DDR2_DQS,
    inout [1:0] cntrl0_DDR2_DQS_N,
    input  sys_clk,                   // 133Mhz
    input  cntrl0_rst_dqs_div_in,     // loopback
    output  cntrl0_rst_dqs_div_out,   // loopback
    input  board_reset,                // board reset
   
    input             cpu_clk,
    input      [19:0] addr,
    input      [15:0] wr_data,
    input             we,
    input             byte_m,
    output reg [15:0] rd_data,
    output reg        mem_rst,
    input             enable,
    output            ready
  );

   // Net declarations
   wire                                          auto_ref_req;
   wire                                          clk_int;
   wire                                          sys_rst90;
   wire                                          sys_rst180;
   wire                                          clk90_int;
   wire                                          burst_done_val1;
   wire                                          init_val1;
   wire                                          ar_done_val1;
   wire                                          user_ack1;
   wire                                          user_data_val1;
   wire [((`data_width*2)-1):0]                  user_output_data;
   wire [((`row_address +
           `col_ap_width  + `bank_address)-1):0] usr_addr1, usr_addr2;   
   wire [3:0]                                    user_cmd1;
   wire [((`data_width*2)-1):0]                  usr_data1, usr_data2;
   wire [((`data_mask_width*2)-1):0]             usr_mask1;
   wire [19:0]                                   addr1;

   wire sys_rst;
   wire [7:0] byte_h, byte_l;
   wire col_grp_ch;
   wire row_change;

   reg  old_clk, start_cmd;
   reg [3:0] rd_state, next_rd_state, wr_state, next_wr_state;
   reg [1:0] data_state, next_data_state;
   reg [1:0] init_state, next_init_state;
   reg burst_rd, burst_wr;
   reg [3:0] u_cmd_rd, u_cmd_wr, u_cmd_init;
   reg [((`row_address +
           `col_ap_width  + `bank_address)-1):0] u1_address;
   reg [((`data_width*2)-1):0]                  u1_data_i;
   reg [((`data_mask_width*2)-1):0]             u1_data_m;
   reg row_rd_pass, row_wr_pass;
   reg eff_ready;

   parameter nop_cmd   = 4'h0;
   parameter init_cmd  = 4'h2;
   parameter write_cmd = 4'h4;
   parameter read_cmd  = 4'h6;

   parameter write_st   = 4'd0;
   parameter read_st    = 4'd0;
   parameter wait_ack   = 4'd1;
   parameter wait_addr1 = 4'd2;
   parameter wait_addr2 = 4'd3;
   parameter snd_addr1  = 4'd4;
   parameter snd_addr2  = 4'd5;
   parameter snd_burst1 = 4'd6;
   parameter snd_burst2 = 4'd7;
   parameter end_burst  = 4'd8;
   parameter nop_op     = 4'd9;
   parameter wait_nack  = 4'd10;
   parameter wr_done    = 4'd11;
   parameter wait_data  = 4'd10;
   parameter read_data1 = 4'd11;
   parameter wait_data2 = 4'd12;
   parameter read_data2 = 4'd13;
   parameter wait_rd_nack = 4'd14;
   parameter rd_done    = 4'd15;

   parameter init_st    = 2'd0;
   parameter nop_init   = 2'd1;
   parameter init_done  = 2'd2;

   parameter snd_word1  = 2'd0;
   parameter snd_word2  = 2'd1;
   parameter snd_word3  = 2'd2;
   parameter snd_word4  = 2'd3;  

   // Module instantiations
   vlog_xst_bl4 cntrl0
     (
       .cntrl0_DDR2_DQ         (cntrl0_DDR2_DQ),
       .cntrl0_DDR2_A          (cntrl0_DDR2_A),
       .cntrl0_DDR2_BA         (cntrl0_DDR2_BA),
       .cntrl0_DDR2_CK         (cntrl0_DDR2_CK),
       .cntrl0_DDR2_CK_N       (cntrl0_DDR2_CK_N),
       .cntrl0_DDR2_CKE        (cntrl0_DDR2_CKE),
       .cntrl0_DDR2_CS_N       (cntrl0_DDR2_CS_N),
       .cntrl0_DDR2_RAS_N      (cntrl0_DDR2_RAS_N),
       .cntrl0_DDR2_CAS_N      (cntrl0_DDR2_CAS_N),
       .cntrl0_DDR2_WE_N       (cntrl0_DDR2_WE_N),
       .cntrl0_DDR2_ODT        (cntrl0_DDR2_ODT),
       .cntrl0_DDR2_DM         (cntrl0_DDR2_DM),
       .cntrl0_DDR2_DQS        (cntrl0_DDR2_DQS),
       .cntrl0_DDR2_DQS_N      (cntrl0_DDR2_DQS_N),
       .SYS_CLK                (sys_clk),
       .cntrl0_rst_dqs_div_in  (cntrl0_rst_dqs_div_in),
       .cntrl0_rst_dqs_div_out (cntrl0_rst_dqs_div_out),
       .reset_in_n             (board_reset),

       .auto_ref_req           (auto_ref_req),    // output from controller
       .clk_0                  (clk_int),         // from DCM
       .sys_rst90              (sys_rst90),       // from DCM
       .sys_rst180             (sys_rst180),      // from DCM
       .clk90_0                (clk90_int),       // from DCM
       .burst_done_val1        (burst_done_val1), // input to controller
       .init_val1              (init_val1),       // output from controller
       .ar_done_val1           (ar_done_val1),    // output from controller
       .user_ack1              (user_ack1),       // output from controller
       .user_data_val1         (user_data_val1),  // output from controller
       .user_output_data       (user_output_data),// output from controller
       .u1_address             (u1_address),      // input to controller
       .user_cmd1              (user_cmd1),       // input to controller
       .u1_data_i              (u1_data_i),       // input to controller
       .u1_data_m              (u1_data_m)        // input to controller
     );

  // Assignments
  assign sys_rst    = sys_rst90 | sys_rst180;
  assign usr_addr1  = { 3'b0, addr[19:10], 1'b0, addr[9:0], 2'b00 }; 
  assign addr1      = addr + 20'd1;
  assign usr_addr2  = { 3'b0, addr1[19:10], 1'b0, addr1[9:0], 2'b00 };

  assign usr_mask1  = (byte_m || col_grp_ch) ? 4'b1011 : 4'b1010;
  assign usr_data1  = { 8'b0, wr_data[7:0], 8'b0, wr_data[15:8] };
  assign usr_data2  = { 8'b0, wr_data[15:8], 16'b0 };

  assign burst_done_val1 = we ? burst_rd : burst_wr;
  assign user_cmd1  = mem_rst ? u_cmd_init : (we ? u_cmd_rd : u_cmd_wr);
  assign byte_h     = user_output_data[7:0];
  assign byte_l     = user_output_data[23:16];
  assign col_grp_ch = (addr[1:0]==2'b11 && !byte_m && !row_change);
  assign row_change = (addr1[10] ^ addr[10]) && !byte_m;
  assign ready      = (we ? (next_rd_state==rd_done) 
                           : (next_wr_state==wr_done))
                       || !enable;

  // Behaviour
  // Write command
  always @(wr_state or user_ack1 or mem_rst or usr_addr1 or usr_addr2)
    if (mem_rst) 
      begin 
        u_cmd_wr <= nop_cmd; 
        burst_wr <= 1'b0; 
        next_wr_state <= wr_done;
        row_wr_pass   <= 1'b0;
      end
    else
      case (wr_state)
        write_st:    if (!user_ack1)
          begin 
            u_cmd_wr <= write_cmd;
            u1_address <= row_wr_pass ? usr_addr2 : usr_addr1;
            next_wr_state <= wait_ack;
          end
        wait_ack:    if (user_ack1) 
          begin
            next_data_state <= snd_word1;
            next_wr_state <= wait_addr1;
          end
        wait_addr1:  next_wr_state <= wait_addr2;
        wait_addr2:  next_wr_state <= col_grp_ch ? snd_addr1 : snd_burst1;
        snd_addr1:   begin u1_address <= usr_addr2; next_wr_state <= snd_addr2; end
        snd_addr2:   next_wr_state <= snd_burst1;
        snd_burst1:  begin burst_wr <= 1'b1; next_wr_state <= snd_burst2; end
        snd_burst2:  next_wr_state <= end_burst;
        end_burst:   begin burst_wr <= 1'b0; next_wr_state <= nop_op; end
        nop_op:      begin u_cmd_wr <= nop_cmd; next_wr_state <= wait_nack; end
        wait_nack:   if (!user_ack1 && next_wr_state==wait_nack) 
          begin
            if (row_change && !row_wr_pass)
              begin
                next_wr_state <= write_st;
                row_wr_pass   <= 1'b1;
              end
            else
              begin
                next_wr_state <= wr_done;
                row_wr_pass   <= 1'b0;
              end
          end
        default:    next_wr_state <= write_st;
      endcase

  // Send data
  always @(data_state or user_ack1 or usr_mask1 or usr_data1 or 
           col_grp_ch or usr_data2 or mem_rst)
    if (mem_rst) next_data_state <= snd_word4;
    else
      case (data_state)
        snd_word1: if (user_ack1) 
          begin
            u1_data_m <= row_change ? 4'b1011 : usr_mask1;
            u1_data_i <= row_wr_pass ? usr_data2 : usr_data1;
            next_data_state <= snd_word2;
          end
        snd_word2: begin u1_data_m <= 4'b1111; next_data_state <= snd_word3; end
        snd_word3: 
          begin 
            u1_data_m <= col_grp_ch ? 4'b1011 : 4'b1111;
            u1_data_i <= usr_data2;
            next_data_state <= snd_word4;
          end
        default: u1_data_m <= 4'b1111;
      endcase

  // Read command
  always @(rd_state or user_ack1 or user_data_val1 or mem_rst)
    if (mem_rst) 
      begin 
        u_cmd_rd <= nop_cmd; 
        burst_rd <= 1'b0; 
        next_rd_state <= rd_done; 
        row_rd_pass <= 1'b0;
      end
    else
      case (rd_state)
        read_st:     if (!user_ack1)
          begin 
            u_cmd_rd <= read_cmd; 
            u1_address <= row_rd_pass ? usr_addr2 : usr_addr1;
            next_rd_state <= wait_ack; 
          end
        wait_ack:    if (user_ack1) next_rd_state <= wait_addr1;
        wait_addr1:  next_rd_state <= wait_addr2;
        wait_addr2:  next_rd_state <= col_grp_ch ? snd_addr1 : snd_burst1;
        snd_addr1:   begin u1_address <= usr_addr2; next_rd_state <= snd_addr2; end
        snd_addr2:   next_rd_state <= snd_burst1;
        snd_burst1:  begin burst_rd <= 1'b1; next_rd_state <= snd_burst2; end
        snd_burst2:  next_rd_state <= end_burst;
        end_burst:   begin burst_rd <= 1'b0; next_rd_state <= nop_op; end
        nop_op:      begin u_cmd_rd <= nop_cmd; next_rd_state <= wait_data; end
        wait_data:   if (user_data_val1) next_rd_state <= read_data1;
        read_data1:   
          begin
            rd_data <= byte_m ? { {8{byte_l[7]}}, byte_l } 
              : row_rd_pass ? { byte_l, rd_data[7:0] } : { byte_h, byte_l };
            next_rd_state <= col_grp_ch ? wait_data2 : wait_rd_nack;
          end
        wait_data2: next_rd_state <= read_data2;
        read_data2: 
          begin
            rd_data[15:8] <= byte_l;
            next_rd_state <= wait_rd_nack;
          end
        wait_rd_nack: if (!user_ack1 && next_rd_state==wait_rd_nack)
          begin
            if (row_change && !row_rd_pass)
              begin
                next_rd_state <= read_st;
                row_rd_pass   <= 1'b1;
              end
            else
              begin
                next_rd_state <= rd_done;
                row_rd_pass   <= 1'b0;
              end
          end
        default:    next_rd_state <= read_st;
      endcase

  // Init command
  always @(init_state or init_val1 or sys_rst)
    if (sys_rst) 
      begin 
        u_cmd_init <= nop_cmd; 
        next_init_state <= init_st;
      end
    else
      case (init_state)
        init_st:  begin u_cmd_init <= init_cmd; next_init_state <= nop_init; end
        nop_init: 
          begin 
            u_cmd_init <= nop_cmd;  
            if (init_val1) next_init_state <= init_done; 
          end
        default: next_init_state <= init_st;
      endcase

  always @(negedge clk_int)
    if (sys_rst)
      begin
        init_state <= init_done;
        wr_state <= wait_nack;
        rd_state <= wait_rd_nack;
        mem_rst  <= 1'b1;
      end
    else 
      if (mem_rst)
        begin
          if (next_init_state==init_done) mem_rst <= 1'b0;
          else init_state <= next_init_state;
        end
      else
        if (start_cmd) 
          begin 
            if (we) rd_state <= read_st;
            else    wr_state <= write_st;
          end
        else
          begin
            if (we) rd_state <= (next_rd_state==rd_done) ? rd_state : next_rd_state;
            else    wr_state <= (next_wr_state==wr_done) ? wr_state : next_wr_state;
          end

  always @(posedge clk90_int)
    if (sys_rst) data_state <= snd_word4;
    else data_state <= next_data_state;

  // start_cmd signal
  always @(posedge clk_int)
    if (mem_rst || !enable)
      begin
        old_clk <= cpu_clk;
        start_cmd <= 1'b0;
      end
    else
      begin
        if (cpu_clk && !old_clk && eff_ready) start_cmd <= 1'b1;
        else start_cmd <= 1'b0;
        old_clk = cpu_clk;
      end
  
  always @(posedge cpu_clk) eff_ready = ready;
endmodule
