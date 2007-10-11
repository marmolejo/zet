///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2005 Xilinx, Inc.
// This	design is confidential and proprietary of Xilinx, All Rights Reserved.
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /	/\/   /
// /___/  \  /   Vendor			: Xilinx
// \   \   \/    Version		: $Name: mig_v1_7_b7 $
//  \	\        Application		: MIG
//  /	/        Filename		: vlog_xst_bl4_parameters_0.v
// /___/   /\    Date Last Modified	: $Date: 2007/02/09 14:18:51 $
// \   \  /  \   Date Created		: Mon May 2 2005
//  \___\/\___\
// Device	: Spartan-3/3A
// Design Name	: DDR2 SDRAM
// Purpose	: This module has the parameters used in the design
///////////////////////////////////////////////////////////////////////////////

`define   data_width                               16
`define   data_strobe_width                        2
`define   data_mask_width                          2
`define   clk_width                                1
`define   ReadEnable                               1
`define   cke_width                                1
`define   deep_memory                              1
`define   memory_width                             8
`define   registered                               0
`define   col_ap_width                             11
`define   DatabitsPerStrobe                        8
`define   DatabitsPerMask                          8
`define   no_of_CS                                 1
`define   RESET                                    0
`define   data_mask                                1
`define   write_pipe_itr                           1
`define   ecc_enable                               0
`define   ecc_width                                0
`define   dq_width                                 16
`define   dm_width                                 2
`define   dqs_width                                2
`define   write_pipeline                           4
`define   top_bottom                                0
`define   left_right                                1
`define   row_address                              13
`define   column_address                           10
`define   bank_address                             2
`define   spartan3a                                1
`define   burst_length                             3'b010
`define   burst_type                               1'b0
`define   cas_latency_value                        3'b011
`define   mode                                     1'b0
`define   dll_rst                                  1'b1
`define   write_recovery                           3'b010
`define   pd_mode                                  1'b0
`define   load_mode_register                       13'b0010100110010
`define   outputs                                  1'b0
`define   rdqs_ena                                 1'b0
`define   dqs_n_ena                                1'b0
`define   ocd_operation                            3'b000
`define   odt_enable                               2'b00
`define   additive_latency_value                   3'b000
`define   op_drive_strength                        1'b0
`define   dll_ena                                  1'b0
`define   ext_load_mode_register                   13'b0000000000000
`define   chip_address                             1
`define   reset_active_low                         1'b0
`define   rcd_count_value                          3'b001
`define   ras_count_value                          4'b0101
`define   mrd_count_value                          1'b1
`define   rp_count_value                           3'b001
`define   rfc_count_value                          6'b001101
`define   trtp_count_value                         3'b000
`define   twr_count_value                          3'b010
`define   twtr_count_value                         3'b001
`define   max_ref_width                            11
`define   max_ref_cnt                        11'b10000000001


`timescale 1ns/100ps
