/*
 *  Wishbone switch and address decoder
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  Copyright (C) 2008, 2009 Sebastien Bourdeauducq - http://lekernel.net
 *  Copyright (C) 2000 Johny Chi - chisuhua@yahoo.com.cn
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module wb_switch #(
    parameter s0_addr_1 = 21'h00000,  // Default Values
    parameter s0_mask_1 = 21'h00000,
    parameter s1_addr_1 = 21'h00000,
    parameter s1_mask_1 = 21'h00000,
    parameter s1_addr_2 = 21'h00000,
    parameter s1_mask_2 = 21'h00000,
    parameter s2_addr_1 = 21'h00000,
    parameter s2_mask_1 = 21'h00000,
    parameter s3_addr_1 = 21'h00000,
    parameter s3_mask_1 = 21'h00000,
    parameter s4_addr_1 = 21'h00000,
    parameter s4_mask_1 = 21'h00000,
    parameter s5_addr_1 = 21'h00000,
    parameter s5_mask_1 = 21'h00000,
    parameter s6_addr_1 = 21'h00000,
    parameter s6_mask_1 = 21'h00000,
    parameter s7_addr_1 = 21'h00000,
    parameter s7_mask_1 = 21'h00000,
    parameter s8_addr_1 = 21'h00000,
    parameter s8_mask_1 = 21'h00000,
    parameter s9_addr_1 = 21'h00000,
    parameter s9_mask_1 = 21'h00000,
    parameter sA_addr_1 = 21'h00000,
    parameter sA_mask_1 = 21'h00000,
    parameter sA_addr_2 = 21'h00000,
    parameter sA_mask_2 = 21'h00000,
    parameter sB_addr_1 = 21'h00000,
    parameter sB_mask_1 = 21'h00000,
    parameter sC_addr_1 = 21'h00000,
    parameter sC_mask_1 = 21'h00000,
    parameter sD_addr_1 = 21'h00000,
    parameter sD_mask_1 = 21'h00000,
    parameter sE_addr_1 = 21'h00000,
    parameter sE_mask_1 = 21'h00000,
    parameter sF_addr_1 = 21'h00000,
    parameter sF_mask_1 = 21'h00000
	 )(
    // Master interface
    input  [15:0] m_dat_i,
    output [15:0] m_dat_o,
    input  [20:1] m_adr_i,
    input  [ 1:0] m_sel_i,
    input         m_we_i,
    input         m_cyc_i,
    input         m_stb_i,
    output        m_ack_o,

    output [ 1:0] m_tgc_o,
    input  [ 1:0] m_tgc_i,

    // Slave 0 interface
    input  [15:0] s0_dat_i,
    output [15:0] s0_dat_o,
    output [20:1] s0_adr_o,
    output [ 1:0] s0_sel_o,
    output        s0_we_o,
    output        s0_cyc_o,
    output        s0_stb_o,
    input         s0_ack_i,

    // Slave 1 interface
    input  [15:0] s1_dat_i,
    output [15:0] s1_dat_o,
    output [20:1] s1_adr_o,
    output [ 1:0] s1_sel_o,
    output        s1_we_o,
    output        s1_cyc_o,
    output        s1_stb_o,
    input         s1_ack_i,

    // Slave 2 interface
    input  [15:0] s2_dat_i,
    output [15:0] s2_dat_o,
    output [20:1] s2_adr_o,
    output [ 1:0] s2_sel_o,
    output        s2_we_o,
    output        s2_cyc_o,
    output        s2_stb_o,
    input         s2_ack_i,

    // Slave 3 interface
    input  [15:0] s3_dat_i,
    output [15:0] s3_dat_o,
    output [20:1] s3_adr_o,
    output [ 1:0] s3_sel_o,
    output        s3_we_o,
    output        s3_cyc_o,
    output        s3_stb_o,
    input         s3_ack_i,

    // Slave 4 interface
    input  [15:0] s4_dat_i,
    output [15:0] s4_dat_o,
    output [20:1] s4_adr_o,
    output [ 1:0] s4_sel_o,
    output        s4_we_o,
    output        s4_cyc_o,
    output        s4_stb_o,
    input         s4_ack_i,

    // Slave 5 interface
    input  [15:0] s5_dat_i,
    output [15:0] s5_dat_o,
    output [20:1] s5_adr_o,
    output [ 1:0] s5_sel_o,
    output        s5_we_o,
    output        s5_cyc_o,
    output        s5_stb_o,
    input         s5_ack_i,

    // Slave 6 interface
    input  [15:0] s6_dat_i,
    output [15:0] s6_dat_o,
    output [20:1] s6_adr_o,
    output [ 1:0] s6_sel_o,
    output        s6_we_o,
    output        s6_cyc_o,
    output        s6_stb_o,
    input         s6_ack_i,

    // Slave 7 interface
    input  [15:0] s7_dat_i,
    output [15:0] s7_dat_o,
    output [20:1] s7_adr_o,
    output [ 1:0] s7_sel_o,
    output        s7_we_o,
    output        s7_cyc_o,
    output        s7_stb_o,
    input         s7_ack_i,

    // Slave 8 interface
    input  [15:0] s8_dat_i,
    output [15:0] s8_dat_o,
    output [20:1] s8_adr_o,
    output [ 1:0] s8_sel_o,
    output        s8_we_o,
    output        s8_cyc_o,
    output        s8_stb_o,
    input         s8_ack_i,

    // Slave 9 interface
    input  [15:0] s9_dat_i,
    output [15:0] s9_dat_o,
    output [20:1] s9_adr_o,
    output [ 1:0] s9_sel_o,
    output        s9_we_o,
    output        s9_cyc_o,
    output        s9_stb_o,
    input         s9_ack_i,

    // Slave A interface
    input  [15:0] sA_dat_i,
    output [15:0] sA_dat_o,
    output [20:1] sA_adr_o,
    output [ 1:0] sA_sel_o,
    output        sA_we_o,
    output        sA_cyc_o,
    output        sA_stb_o,
    input         sA_ack_i,

    // Slave B interface
    input  [15:0] sB_dat_i,
    output [15:0] sB_dat_o,
    output [20:1] sB_adr_o,
    output [ 1:0] sB_sel_o,
    output        sB_we_o,
    output        sB_cyc_o,
    output        sB_stb_o,
    input         sB_ack_i,

    // Slave C interface
    input  [15:0] sC_dat_i,
    output [15:0] sC_dat_o,
    output [20:1] sC_adr_o,
    output [ 1:0] sC_sel_o,
    output        sC_we_o,
    output        sC_cyc_o,
    output        sC_stb_o,
    input         sC_ack_i,

    // Slave D interface
    input  [15:0] sD_dat_i,
    output [15:0] sD_dat_o,
    output [20:1] sD_adr_o,
    output [ 1:0] sD_sel_o,
    output        sD_we_o,
    output        sD_cyc_o,
    output        sD_stb_o,
    input         sD_ack_i,

    // Slave E interface - Pic Slave
    input  [15:0] sE_dat_i,
    output [15:0] sE_dat_o,
    output [20:1] sE_adr_o,
    output [ 1:0] sE_sel_o,
    output        sE_we_o,
    output        sE_cyc_o,
    output        sE_stb_o,
    input         sE_ack_i,

    output [ 1:0] sE_tgc_o,		// inta, nmia
    input  [ 1:0] sE_tgc_i,

	// Slave F interface - Pic Master
    input  [15:0] sF_dat_i,
    output [15:0] sF_dat_o,
    output [20:1] sF_adr_o,
    output [ 1:0] sF_sel_o,
    output        sF_we_o,
    output        sF_cyc_o,
    output        sF_stb_o,
    input         sF_ack_i,

    output [ 1:0] sF_tgc_o,		// inta, nmia
    input  [ 1:0] sF_tgc_i		// intr, nmi
	 );

`define mbusw_ls  20 + 2 + 16 + 1 + 1 + 1  // address + byte select + data + cyc + we + stb

wire [15:0] slave_sel;
wire [20:0] m_adr;
wire [15:0] i_dat_s;   // internal shared bus, slave data to master
wire        def_ack_i; // default ack (we don't want to stall the bus)
wire        i_bus_ack; // internal shared bus, ack signal

wire [`mbusw_ls -1:0] i_bus_m;    // internal shared bus, master data and control to slave

assign m_tgc_o = sF_tgc_i;        // intr, nmi
assign sE_tgc_o = m_tgc_i;        // inta, nmia
assign sF_tgc_o = m_tgc_i;        // inta, nmia

assign m_dat_o = (m_tgc_i[0] | m_tgc_i[1]) ? (sF_dat_i | sE_dat_i) : i_dat_s; // int vector or slave data
//assign m_dat_o = i_dat_s;
assign m_ack_o = i_bus_ack;

// Bus Acknowlegement
assign i_bus_ack =   s0_ack_i | s1_ack_i | s2_ack_i | s3_ack_i | s4_ack_i | s5_ack_i | s6_ack_i | s7_ack_i |
                     s8_ack_i | s9_ack_i | sA_ack_i | sB_ack_i | sC_ack_i | sD_ack_i | sE_ack_i | sF_ack_i | 
							def_ack_i;
							
assign i_dat_s =
//assign m_dat_o = // or'ed bus should be enough.... slaves should never drive bus when not selected.... only active interrupt controllers though
           ({16{slave_sel[ 0]}} & s0_dat_i) // slave read data
          |({16{slave_sel[ 1]}} & s1_dat_i)
          |({16{slave_sel[ 2]}} & s2_dat_i)
          |({16{slave_sel[ 3]}} & s3_dat_i)
          |({16{slave_sel[ 4]}} & s4_dat_i)
          |({16{slave_sel[ 5]}} & s5_dat_i)
          |({16{slave_sel[ 6]}} & s6_dat_i)
          |({16{slave_sel[ 7]}} & s7_dat_i)
          |({16{slave_sel[ 8]}} & s8_dat_i)
          |({16{slave_sel[ 9]}} & s9_dat_i)
          |({16{slave_sel[10]}} & sA_dat_i)
          |({16{slave_sel[11]}} & sB_dat_i)
          |({16{slave_sel[12]}} & sC_dat_i)
          |({16{slave_sel[13]}} & sD_dat_i)
          |({16{slave_sel[14]}} & sE_dat_i)
          |({16{slave_sel[15]}} & sF_dat_i);

// add odd/even selection		  
assign m_adr = {m_adr_i, m_sel_i[1]};

// Bus Selection logic
assign slave_sel[ 0] =  ((m_adr & s0_mask_1) == s0_addr_1);
assign slave_sel[ 1] =  ((m_adr & s1_mask_1) == s1_addr_1) | ((m_adr & s1_mask_2) == s1_addr_2);
assign slave_sel[ 2] =  ((m_adr & s2_mask_1) == s2_addr_1);
assign slave_sel[ 3] =  ((m_adr & s3_mask_1) == s3_addr_1);
assign slave_sel[ 4] =  ((m_adr & s4_mask_1) == s4_addr_1);
assign slave_sel[ 5] =  ((m_adr & s5_mask_1) == s5_addr_1);
assign slave_sel[ 6] =  ((m_adr & s6_mask_1) == s6_addr_1);
assign slave_sel[ 7] =  ((m_adr & s7_mask_1) == s7_addr_1);
assign slave_sel[ 8] =  ((m_adr & s8_mask_1) == s8_addr_1);
assign slave_sel[ 9] =  ((m_adr & s9_mask_1) == s9_addr_1);
assign slave_sel[10] = (((m_adr & sA_mask_1) == sA_addr_1) | (( m_adr & sA_mask_2)== sA_addr_2)) & ~(|slave_sel[9:0]);
assign slave_sel[11] =  ((m_adr & sB_mask_1) == sB_addr_1);
assign slave_sel[12] =  ((m_adr & sC_mask_1) == sC_addr_1);
assign slave_sel[13] =  ((m_adr & sD_mask_1) == sD_addr_1);
assign slave_sel[14] =  ((m_adr & sE_mask_1) == sE_addr_1);
assign slave_sel[15] =  ((m_adr & sF_mask_1) == sF_addr_1);

// not implemented devices..
assign def_ack_i = m_stb_i & m_cyc_i & ~(|slave_sel[15:0]);

assign i_bus_m = {m_adr_i, m_sel_i, m_dat_i, m_we_i, m_cyc_i, m_stb_i};

assign {s0_adr_o, s0_sel_o, s0_dat_o, s0_we_o, s0_cyc_o}  = i_bus_m[`mbusw_ls -1:1];  // slave 0
assign  s0_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[0];     // stb_o = cyc_i & stb_i & slave_sel

assign {s1_adr_o, s1_sel_o, s1_dat_o, s1_we_o, s1_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 1
assign  s1_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[1];

assign {s2_adr_o, s2_sel_o, s2_dat_o, s2_we_o, s2_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 2
assign  s2_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[2];

assign {s3_adr_o, s3_sel_o, s3_dat_o, s3_we_o, s3_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 3
assign  s3_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[3];

assign {s4_adr_o, s4_sel_o, s4_dat_o, s4_we_o, s4_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 4
assign  s4_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[4];

assign {s5_adr_o, s5_sel_o, s5_dat_o, s5_we_o, s5_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 5
assign  s5_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[5];

assign {s6_adr_o, s6_sel_o, s6_dat_o, s6_we_o, s6_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 6
assign  s6_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[6];

assign {s7_adr_o, s7_sel_o, s7_dat_o, s7_we_o, s7_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 7
assign  s7_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[7];

assign {s8_adr_o, s8_sel_o, s8_dat_o, s8_we_o, s8_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 8
assign  s8_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[8];

assign {s9_adr_o, s9_sel_o, s9_dat_o, s9_we_o, s9_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 9
assign  s9_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[9];

assign {sA_adr_o, sA_sel_o, sA_dat_o, sA_we_o, sA_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave A
assign  sA_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[10];

assign {sB_adr_o, sB_sel_o, sB_dat_o, sB_we_o, sB_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave B
assign  sB_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[11];

assign {sC_adr_o, sC_sel_o, sC_dat_o, sC_we_o, sC_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave C
assign  sC_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[12];

assign {sD_adr_o, sD_sel_o, sD_dat_o, sD_we_o, sD_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave D
assign  sD_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[13];

assign {sE_adr_o, sE_sel_o, sE_dat_o, sE_we_o, sE_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave E
assign  sE_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[14];

assign {sF_adr_o, sF_sel_o, sF_dat_o, sF_we_o, sF_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave F
assign  sF_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[15];

endmodule
