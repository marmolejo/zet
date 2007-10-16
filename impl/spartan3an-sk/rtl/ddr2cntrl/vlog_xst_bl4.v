///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2005 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor			: Xilinx
// \   \   \/    Version		: $Name: mig_v1_7_b7 $
//  \   \        Application		: MIG
//  /   /        Filename		: vlog_xst_bl4.v
// /___/   /\    Date Last Modified	: $Date: 2007/02/06 08:08:58 $
// \   \  /  \   Date Created		: Mon May 2 2005
//  \___\/\___\
// Device	: Spartan-3/3A
// Design Name	: DDR2 SDRAM
// Purpose	: This module has the instantiations main and infrastructure_top
//		  modules
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
module vlog_xst_bl4
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
   input  SYS_CLK,                   // 133Mhz
   input  cntrl0_rst_dqs_div_in,     // loopback
   output  cntrl0_rst_dqs_div_out,   // loopback
   input  reset_in_n,                // South Button
  
   output auto_ref_req,
   output clk_0, 
   output sys_rst90, 
   output sys_rst180,
   output clk90_0,
   input burst_done_val1,
   output init_val1,
   output ar_done_val1,
   output user_ack1,
   output user_data_val1,
   output [31:0] user_output_data,
   input [25:0] u1_address,
   input [3:0] user_cmd1,
   input [31:0] u1_data_i,
   input [3:0] u1_data_m
   );

   wire       wait_200us;
   wire       sys_rst;
   wire [4:0] delay_sel_val;

   vlog_xst_bl4_top_0        top0
      (
       .auto_ref_req           (auto_ref_req),
       .wait_200us             (wait_200us),
       .rst_dqs_div_in           (cntrl0_rst_dqs_div_in),
       .rst_dqs_div_out        (cntrl0_rst_dqs_div_out),
       .user_input_data       (u1_data_i),
      .user_data_mask(u1_data_m),
       .user_output_data       (user_output_data),
       .user_data_valid       (user_data_val1),
       .user_input_address    (u1_address[25:0]),
       .user_command_register (user_cmd1),
       .user_cmd_ack             (user_ack1),
       .burst_done               (burst_done_val1),
       .init_val         (init_val1),
       .ar_done          (ar_done_val1),
       .DDR2_DQS         (cntrl0_DDR2_DQS),
      .DDR2_DQS_N (cntrl0_DDR2_DQS_N),
       .DDR2_DQ          (cntrl0_DDR2_DQ),
       .DDR2_CKE         (cntrl0_DDR2_CKE),
       .DDR2_CS_N        (cntrl0_DDR2_CS_N),
       .DDR2_RAS_N               (cntrl0_DDR2_RAS_N),
       .DDR2_CAS_N               (cntrl0_DDR2_CAS_N),
       .DDR2_WE_N        (cntrl0_DDR2_WE_N),
      .DDR2_DM          (cntrl0_DDR2_DM),

       .DDR2_ODT         (cntrl0_DDR2_ODT),
       .DDR2_BA          (cntrl0_DDR2_BA),
       .DDR2_A                   (cntrl0_DDR2_A),
       .DDR2_CK                (cntrl0_DDR2_CK),
       .DDR2_CK_N      (cntrl0_DDR2_CK_N),
       .clk_int                (clk_0),
       .clk90_int      (clk90_0),
       .delay_sel_val          (delay_sel_val),
       .sys_rst                (sys_rst),
       .sys_rst90      (sys_rst90),
       .sys_rst180             (sys_rst180)
       );


vlog_xst_bl4_infrastructure_top infrastructure_top0
   (
    .SYS_CLK	(SYS_CLK),
    .reset_in_n	(reset_in_n),
    .wait_200us_rout   (wait_200us),
    .delay_sel_val1_val(delay_sel_val),
    .sys_rst_val       (sys_rst),
    .sys_rst90_val     (sys_rst90),
    .clk_int_val     (clk_0),
    .clk90_int_val     (clk90_0),
    .sys_rst180_val    (sys_rst180)
    );

endmodule
