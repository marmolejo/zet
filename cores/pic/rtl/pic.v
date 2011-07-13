/*
 *  Wishbone Intel 8259 Prgrammable Interrupt Controller
 *  Copyright (C) 2011  Geert Jan Laanstra <g.j.laanstraATutwente.nl>
 *
 *  Fixed (not rotating) priority for now..
 *  Pipelined Wihbone Support 
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
 *
 *  2011-06-27 Geert Jan Laanstra
 */

module pic #(
    parameter int_vector = 8'h08,
    parameter int_mask = 8'b11100100
    )(
  input         wb_clk_i,
  input         wb_rst_i,

  input         nsp,   			// master (1) or slave (0)
  input	        cas_i,			// cascade input (slave) connect to one of the cascade outputs of a master (not like the 8259)
  output  [7:0] cas_o,			// cascade output (master) connect on of the outputs to the input of a slave (not like the 8259)
  
  input   [7:0] pic_intv,
  input         pic_nmi,

  input         wb_stb_i,
  input         wb_cyc_i,
  input  [19:1] wb_adr_i,
  input         wb_we_i,
  input  [ 1:0] wb_sel_i,
  input  [15:0] wb_dat_i,
  output [15:0] wb_dat_o,		// device or interrupt vector output
  output        wb_ack_o,
  
  output  [1:0] wb_tgc_o,		// intr, nmi
  input   [1:0] wb_tgc_i,		// inta, nmia
  
  output [ 7:0] test_int_irr,  // tested interrupts
  output [ 7:0] test_int_isr
  );

  //------------------------------------------------------------------------------------------------------------------
  // Interrupt Controller WB slave
  //------------------------------------------------------------------------------------------------------------------

  // delay stb
  reg wb_stb_i_d1;
  always @ (posedge wb_clk_i)
    wb_stb_i_d1 <= wb_rst_i ? 1'b0 : wb_stb_i;
	 
  // detect start of access
  wire wb_stb;
  assign wb_stb = wb_stb_i & ~wb_stb_i_d1;

  // generate common write or read
  wire [1:0] wr;
  wire [1:0] rd;
  assign wr[0] = wb_stb   & wb_cyc_i & wb_we_i  & ~wb_sel_i[1] &  wb_sel_i[0] & ~wb_ack;	 // Allow only byte access
  assign wr[1] = wb_stb   & wb_cyc_i & wb_we_i  &  wb_sel_i[1] & ~wb_sel_i[0] & ~wb_ack;  
  assign rd[0] = wb_stb_i & wb_cyc_i & ~wb_we_i & ~wb_sel_i[1] &  wb_sel_i[0] & ~wb_ack;
  assign rd[1] = wb_stb_i & wb_cyc_i & ~wb_we_i &  wb_sel_i[1] & ~wb_sel_i[0] & ~wb_ack;
  
  // generate icw write enables
  reg [4:1] wr_icw;
  always @(posedge wb_clk_i)
    begin
      wr_icw[1] <= wb_rst_i ? 1'b0 : (wr[0] & wb_dat_i[4]);
      wr_icw[2] <= wb_rst_i ? 1'b0 : (wr[1] & (icw_sel == load_icw2));
      wr_icw[3] <= wb_rst_i ? 1'b0 : (wr[1] & (icw_sel == load_icw3));
      wr_icw[4] <= wb_rst_i ? 1'b0 : (wr[1] & (icw_sel == load_icw4));
    end

  // generate ocw write enables    
  reg [3:1] wr_ocw;
  always @(posedge wb_clk_i)
    begin
      wr_ocw[1] <= wb_rst_i ? 1'b0 : (wr[1] & (icw_sel == 2'b00));			// allow writes only when initialization is done
      wr_ocw[2] <= wb_rst_i ? 1'b0 : (wr[0] & (wb_dat_i[4:3] == 2'b00));
      wr_ocw[3] <= wb_rst_i ? 1'b0 : (wr[0] & (wb_dat_i[4:3] == 2'b01));
    end

  // store data for pipeline block write support
  reg [15:0] wb_dat_ir;
  always @(posedge wb_clk_i)
  begin
    if (wb_rst_i)
      wb_dat_ir <= 16'h0000;
    else
      wb_dat_ir <= wb_dat_i;
  end
    
  // icw selection state machine
  reg [1:0] icw_sel;
  parameter load_icw1 = 2'h0, load_icw2 = 2'h1, load_icw3 = 2'h2, load_icw4 = 2'h3;
  always @ (posedge wb_clk_i)
    begin
      if (wb_rst_i)
	      icw_sel <= load_icw1;
      else if (wr_icw[1])
        icw_sel <= load_icw2;
	    else
	      begin
          case (icw_sel)
	          load_icw1:
              icw_sel <= load_icw1;
						
 	          load_icw2:
              // check if we need icw3, icw4 or we're done
              if (~icw1_sngl)
                icw_sel <= wr_icw[2] ? load_icw3 : load_icw2;
              else if (icw1_ic4)
                icw_sel <= wr_icw[2] ? load_icw4 : load_icw2;
              else
                icw_sel <= wr_icw[2] ? load_icw1 : load_icw2;
						
	          load_icw3:
              // check if we need icw4 or we're done
              if (icw1_ic4)
                icw_sel <= wr_icw[3] ? load_icw4 : load_icw3;
              else
                icw_sel <= wr_icw[3] ? load_icw1 : load_icw3;

            load_icw4:
              // check if we're done
              icw_sel <= wr_icw[4] ? load_icw1 : load_icw4;
	        endcase
		    end
    end
	
  // Initialization Control Word registers
  reg [7:0] icw1;
  reg [7:0] icw2;
  reg [7:0] icw3;
  reg [7:0] icw4;

  always @(posedge wb_clk_i)
    begin
	    if (wb_rst_i)
		    begin
	        icw1 <= (nsp) ? 8'b00000000 : 8'b00000000;    // ZET default : master edge/slave level, cascaded
			    icw2 <= int_vector;                           // vector start
		      icw3 <= (nsp) ? 8'b00000100 : 8'h02; 			    // master + slave at 2, 
		      icw4 <= (nsp) ? 8'b00000011 : 8'b00000011;    // ZET default : auto end of interrupt (master)
		    end
	    else
		    begin
          icw1 <= wr_icw[1] ? wb_dat_ir[ 7:0] : icw1;
          icw2 <= wr_icw[2] ? wb_dat_ir[15:8] : icw2;
          icw3 <= wr_icw[3] ? wb_dat_ir[15:8] : icw3;
          icw4 <= wr_icw[4] ? wb_dat_ir[15:8] : icw4;
		    end
    end
	
  // icw1 content
  wire icw1_ltim;				// level (1) or edge (0)
  wire icw1_sngl;				// single (1) or cascaded (0)
  wire icw1_ic4;				// icw4 needed
  assign icw1_ltim = icw1[3];
  assign icw1_sngl = icw1[1];
  assign icw1_ic4 = icw1[0];
  
  // icw2 content
  wire [7:3] icw2_t;		// vector address
  assign icw2_t[7:3] = icw2[7:3];
  
  // icw3 content
  wire [7:0] icw3_s;		// where is a slave
  wire [2:0] icw3_id;		// what's my slave id
  assign icw3_s[7:0] = icw3[7:0];
  assign icw3_id[2:0] = icw3[2:0];
  
  // icw4 content
  wire icw4_sfnm;				// special fully nested (1) or not (0)
  wire icw4_bm;         // buffered mode
  wire icw4_ms;         // buffered master (1) or slave (0) 
  wire icw4_aeoi;				// atomatic end of interrupt
  assign icw4_sfnm = icw4[4];
  assign icw4_bm   = icw4[3];
  assign icw4_ms   = icw4[2];
  assign icw4_aeoi = icw4[1];

  // check if we're in master or slave mode
  reg master;
  always @(posedge wb_clk_i)
    master <= wb_rst_i ? 1'b0 : (nsp | (icw4_bm & icw4_ms));

  // OperationControlWord Registers
  reg [7:0] ocw1;
  reg [7:0] ocw2;
  reg [7:0] ocw3;
  always @(posedge wb_clk_i)
    begin
	    if (wb_rst_i | wr_icw[1])
	      begin 
	        ocw1 <= int_mask;             	      // ZET default : int0, int1, int3 and int4
		      ocw2 <= {3'b000, 2'b00, 3'b000};	    // ZET default : 
		      ocw3 <= {3'b000, 5'b00011};		        // ZET default : read isr
          ocw3_smm <= 1'b0;
		    end
      else
		    begin
	        ocw1 <= (wr_ocw[1] ? wb_dat_ir[15:8] : ocw1);
	        ocw2 <= (wr_ocw[2] ? wb_dat_ir[ 7:0] : ocw2);
          ocw3 <= (wr_ocw[3] ? wb_dat_ir[ 7:0] : ocw3);
          ocw3_p <= (wr_ocw[3] ? wb_dat_ir[2] : (rd[0] ? 1'b0 : ocw3_p));
          ocw3_smm <= (wr_ocw[3] & wb_dat_ir[6]) ? wb_dat_ir[5] : ocw3_smm;
		    end
	  end

  // ocw1 content
  wire [7:0] ocw1_im;             // interrupt mask
  assign ocw1_im = ocw1;
  
  // ocw2 content
  wire   sw_eoi;			// non specific end of interrupt (with or without rotation)
  assign sw_eoi     = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b01);
  wire   sw_pri_eoi;  // rotate priority on non specific end of interrupt
  assign sw_pri_eoi = (wr_ocw[2] & (wb_dat_ir[7:5] == 3'b101));
//  assign sw_pri_eoi = (wr_ocw[2] & (wb_dat_ir[7:5] == 3'b001));
 
  wire [7:0] sw_seoi; // specific end of interrupt (with or without rotation)
  assign sw_seoi[0] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd0);
  assign sw_seoi[1] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd1);
  assign sw_seoi[2] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd2);
  assign sw_seoi[3] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd3);
  assign sw_seoi[4] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd4);
  assign sw_seoi[5] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd5);
  assign sw_seoi[6] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd6);
  assign sw_seoi[7] = wr_ocw[2] & (wb_dat_ir[6:5] == 2'b11) & (wb_dat_ir[2:0] == 3'd7);
  wire   sw_pri_seoi; // rotate priority on "Specific End Of Interrupt"
  assign sw_pri_seoi = wr_ocw[2] & (wb_dat_ir[7:5] == 3'b111);
  
  reg    ocw2_raeoi;  // rotate on automatic end of interrupt (when enabled)
  always @(posedge wb_clk_i)
    ocw2_raeoi     <= wb_rst_i ? 1'b0 : ((wr_ocw[2] & (wb_dat_ir[6:5] == 2'b00)) ? wb_dat_ir[7] : ocw2_raeoi);

  wire   sw_pri_set;  // set priority on "Set Priority"
  assign sw_pri_set = wr_ocw[2] & (wb_dat_ir[7:5] == 3'b110);
  
  //ocw3 content
  reg    ocw3_smm;                // special mask mode
  reg    ocw3_p;                  // poll
  wire   ocw3_rr;                 // read register command
  wire   ocw3_ris;                // isr (1) or irr (0)
  assign ocw3_rr = ocw3[1];
  assign ocw3_ris = ocw3[0];
  
  // reading status
  reg [15:0] dat_o;
  always @(posedge wb_clk_i)
    begin
      // reading imr
	    if (wb_rst_i)
        dat_o[15:8] <= 8'h00;
      else if (rd[1])					      // Interrupt Mask Register
        dat_o[15:8] <= ocw1_im[7:0];
      else
        dat_o[15:8] <= 8'h00;
		
      // reading of others
	    if (wb_rst_i)
	      dat_o[ 7:0] <= 8'h00;
      else if (rd[0] & ocw3_p)			// Interrupt Poll Register
        dat_o[ 7:0] <= ipr[7:0];
      else if (rd[0] & ocw3_rr)
	      if (ocw3_ris)					      // Interrupt Service Register
		      dat_o[7:0] <= isr[7:0];
        else							          // Interrupt Request Register
          dat_o[7:0] <= irr[7:0];
      else
        dat_o[7:0] <= 8'h00;	  
    end
  
  // acknowledge back to wb
  reg wb_ack;
  always @(posedge wb_clk_i)
    wb_ack <= wb_rst_i ? 1'b0 : ((wr[0] | wr[1] | rd[0] | rd[1]) & ~wb_ack);
  assign wb_ack_o = wb_ack;

  //------------------------------------------------------------------------------------------------------------------
  // The Interrupt Controller itself...  
  //------------------------------------------------------------------------------------------------------------------
  
  wire [7:0] intv;
  wire inta;
  wire nmi;
  wire nmia;
  
  assign nmi  = pic_nmi;
  
  assign inta = wb_tgc_i[1];
  assign nmia = wb_tgc_i[0];
  assign wb_tgc_o[1] = intr;
  assign wb_tgc_o[0] = nmi;

  // delay vector one clock to detect rising edge
  reg [7:0] intv_r;
  reg [7:0] intv_rr;
  wire [7:0] set_irr;
  always @(posedge wb_clk_i)
  begin
    if (wb_rst_i)
      begin
        intv_r  <= 8'b0;
        intv_rr <= 8'b0;
      end
    else
      begin
        intv_r <= pic_intv;                // sync int inputs to clock domain
        if (icw1_ltim)
          intv_rr <= 8'b0;                  // level detection
        else
          intv_rr <= intv_r;                // just delay for edge detection
      end
  end
  assign set_irr = intv_r & ~intv_rr;       // edge detection
	 
  // interrupt register, this detects edge or level interrupt
  reg [7:0] irr;
  always @(posedge wb_clk_i)
    begin	   //  reset/clear				             detect     		 hold
	    irr[0] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[0]) | (irr[0] & ~isr_set[0]));
	    irr[1] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[1]) | (irr[1] & ~isr_set[1]));
	    irr[2] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[2]) | (irr[2] & ~isr_set[2]));
	    irr[3] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[3]) | (irr[3] & ~isr_set[3]));
	    irr[4] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[4]) | (irr[4] & ~isr_set[4]));
	    irr[5] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[5]) | (irr[5] & ~isr_set[5]));
	    irr[6] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[6]) | (irr[6] & ~isr_set[6]));
	    irr[7] <= (wb_rst_i | wr_icw[1]) ? 1'b0 : ((set_irr[7]) | (irr[7] & ~isr_set[7]));
	 end

  // mask detected interrupts
  wire [7:0] irr_masked;
  assign irr_masked[0] = irr[0] & ~ocw1_im[0] & ~(isr[0] & ocw3_smm);
  assign irr_masked[1] = irr[1] & ~ocw1_im[1] & ~(isr[1] & ocw3_smm);
  assign irr_masked[2] = irr[2] & ~ocw1_im[2] & ~(isr[2] & ocw3_smm);
  assign irr_masked[3] = irr[3] & ~ocw1_im[3] & ~(isr[3] & ocw3_smm);
  assign irr_masked[4] = irr[4] & ~ocw1_im[4] & ~(isr[4] & ocw3_smm);
  assign irr_masked[5] = irr[5] & ~ocw1_im[5] & ~(isr[5] & ocw3_smm);
  assign irr_masked[6] = irr[6] & ~ocw1_im[6] & ~(isr[6] & ocw3_smm);
  assign irr_masked[7] = irr[7] & ~ocw1_im[7] & ~(isr[7] & ocw3_smm);

  reg [2:0] int_pri;                 // keep track of current priority
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)                   // default 7 is the lowest priority
        int_pri <= 3'd7;
      else if (sw_pri_set)            // set priority command
        int_pri <= wb_dat_ir[2:0];   // software provides lowest level
      else if (sw_pri_seoi)           // rotate on specific end of interrupt command
        int_pri <= wb_dat_ir[2:0];   // software provides lowest level 
      else if (sw_pri_eoi)            // rotate on non specific end of interrupt
        int_pri <= ipr[2:0];         // current level will be lowest level
      else if (hw_pri_aeoi)           // rotate on automatic end of interrupt
        int_pri <= iid_r[2:0];       // current level will be lowest level
      else
        int_pri <= int_pri;  
    end
    
  reg [7:0] rot_irr;              // masked and rotated interrupt register
  reg [7:0] rot_isr;
  reg [7:0] rot_slv;
  reg [2:0] iid_0pri;
  reg [2:0] iid_1pri;
  reg [2:0] iid_2pri;
  reg [2:0] iid_3pri;
  reg [2:0] iid_4pri;
  reg [2:0] iid_5pri;
  reg [2:0] iid_6pri;
  reg [2:0] iid_7pri;
  reg [7:0] casb_0pri;
  reg [7:0] casb_1pri;
  reg [7:0] casb_2pri;
  reg [7:0] casb_3pri;
  reg [7:0] casb_4pri;
  reg [7:0] casb_5pri;
  reg [7:0] casb_6pri;
  reg [7:0] casb_7pri;
//  reg [7:0] pri_b;
  always @(posedge wb_clk_i)
    begin
      // pre generate iid of it's level
      iid_0pri <= ((int_pri + 3'd1) & 3'b111);
      iid_1pri <= ((int_pri + 3'd2) & 3'b111);
      iid_2pri <= ((int_pri + 3'd3) & 3'b111);
      iid_3pri <= ((int_pri + 3'd4) & 3'b111);
      iid_4pri <= ((int_pri + 3'd5) & 3'b111);
      iid_5pri <= ((int_pri + 3'd6) & 3'b111);
      iid_6pri <= ((int_pri + 3'd7) & 3'b111);
      iid_7pri <= ((int_pri + 3'd0) & 3'b111);
      // pre generate slave activation mask (uses to much resources, but results in fast code)
      casb_0pri <= master ? ((8'b00000001 << ((int_pri + 3'd1) & 3'b111)) & icw3_s) : 8'b0;
      casb_1pri <= master ? ((8'b00000001 << ((int_pri + 3'd2) & 3'b111)) & icw3_s) : 8'b0;
      casb_2pri <= master ? ((8'b00000001 << ((int_pri + 3'd3) & 3'b111)) & icw3_s) : 8'b0;
      casb_3pri <= master ? ((8'b00000001 << ((int_pri + 3'd4) & 3'b111)) & icw3_s) : 8'b0;
      casb_4pri <= master ? ((8'b00000001 << ((int_pri + 3'd5) & 3'b111)) & icw3_s) : 8'b0;
      casb_5pri <= master ? ((8'b00000001 << ((int_pri + 3'd6) & 3'b111)) & icw3_s) : 8'b0;
      casb_6pri <= master ? ((8'b00000001 << ((int_pri + 3'd7) & 3'b111)) & icw3_s) : 8'b0;
      casb_7pri <= master ? ((8'b00000001 << ((int_pri + 3'd0) & 3'b111)) & icw3_s) : 8'b0;
      // prerotate masked irr
      case (int_pri)
        7:  rot_irr[7:0]    <= {irr_masked[7:0]};
        6:  rot_irr[7:0]    <= {irr_masked[6:0], irr_masked[7  ]};
        5:  rot_irr[7:0]    <= {irr_masked[5:0], irr_masked[7:6]};
        4:  rot_irr[7:0]    <= {irr_masked[4:0], irr_masked[7:5]};
        3:  rot_irr[7:0]    <= {irr_masked[3:0], irr_masked[7:4]};
        2:  rot_irr[7:0]    <= {irr_masked[2:0], irr_masked[7:3]};
        1:  rot_irr[7:0]    <= {irr_masked[1:0], irr_masked[7:2]};
        0:  rot_irr[7:0]    <= {irr_masked[  0], irr_masked[7:1]};
      endcase
      // prerotate isr
      case (int_pri)
        7:  rot_isr[7:0]    <= {isr[7:0]};
        6:  rot_isr[7:0]    <= {isr[6:0], isr[7  ]};
        5:  rot_isr[7:0]    <= {isr[5:0], isr[7:6]};
        4:  rot_isr[7:0]    <= {isr[4:0], isr[7:5]};
        3:  rot_isr[7:0]    <= {isr[3:0], isr[7:4]};
        2:  rot_isr[7:0]    <= {isr[2:0], isr[7:3]};
        1:  rot_isr[7:0]    <= {isr[1:0], isr[7:2]};
        0:  rot_isr[7:0]    <= {isr[  0], isr[7:1]};
      endcase
      // prerotate icw3_s
      case (int_pri)
        7:  rot_slv[7:0]    <= {icw3_s[7:0]};
        6:  rot_slv[7:0]    <= {icw3_s[6:0], icw3_s[7  ]};
        5:  rot_slv[7:0]    <= {icw3_s[5:0], icw3_s[7:6]};
        4:  rot_slv[7:0]    <= {icw3_s[4:0], icw3_s[7:5]};
        3:  rot_slv[7:0]    <= {icw3_s[3:0], icw3_s[7:4]};
        2:  rot_slv[7:0]    <= {icw3_s[2:0], icw3_s[7:3]};
        1:  rot_slv[7:0]    <= {icw3_s[1:0], icw3_s[7:2]};
        0:  rot_slv[7:0]    <= {icw3_s[  0], icw3_s[7:1]};
      endcase
     end
  
  // track and hold interrupt priority
  reg       intr;             // interrupt signal
  reg [2:0] iid_r;            // interrupt id number
  reg       master_ena;       // master active
  reg [7:0] casb;             // cascade slave select to seperate slaves
  always @(posedge wb_clk_i)
  begin
    if (wb_rst_i) 
      begin
        intr <= 1'b0;
	      iid_r <= 3'd0;
        master_ena <= 1'b0;
        casb <= 8'b00000000;
      end
    else if (int_reset)          // clean up after
      begin
        intr <= 1'b0;
	      iid_r <= 3'd0;
        master_ena <= 1'b0;
		    casb <= 8'b00000000;
      end
  	else if (freeze)             // remove int signal to cpu
      begin
	      intr <= 1'b0;
	      iid_r <= iid_r; 
        master_ena <= master_ena;
		    casb <= casb;
      end
	  else if (rot_irr[0])         // 0 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[0]);
	      iid_r <= iid_0pri;
        master_ena <= master & (~rot_slv[0]);
		    casb <= casb_0pri;
      end
	  else if (rot_irr[1])         // 1 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[1]);
	      iid_r <= iid_1pri;
        master_ena <= master & (~rot_slv[1]);
		    casb <= casb_1pri;
      end
	  else if (rot_irr[2])         // 2 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[2]);
	      iid_r <= iid_2pri;
        master_ena <= master & (~rot_slv[2]);
		    casb <= casb_2pri;
      end
	  else if (rot_irr[3])         // 3 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[3]);
	      iid_r <= iid_3pri;
        master_ena <= master & (~rot_slv[3]);
		    casb <= casb_3pri;
      end
	  else if (rot_irr[4])         // 4 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[4]);
	      iid_r <= iid_4pri;
        master_ena <= master & (~rot_slv[4]);
		    casb <= casb_4pri;
      end
	  else if (rot_irr[5])         // 5 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[5]);
	      iid_r <= iid_5pri;
        master_ena <= master & (~rot_slv[5]);
		    casb <= casb_5pri;
      end
	  else if (rot_irr[6])         // 6 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[6]);
	      iid_r <= iid_6pri;
        master_ena <= master & (~rot_slv[6]);
		    casb <= casb_6pri;
      end
	  else if (rot_irr[7])         // 7 -> highest priority
      begin
	      intr <= (master & icw4_sfnm) | (~rot_isr[7]);
	      iid_r <= iid_7pri;
        master_ena <= master & (~rot_slv[7]);
		    casb <= casb_7pri;
      end
	  else
      begin
        intr <= 1'b0;
	      iid_r <= 3'd0;
        master_ena <= 1'b0;
		    casb <= 8'b0;
      end
  end
  
  // takeover moment
  wire [7:0] isr_set;
  assign isr_set[0] = (master | slave_ena) & ((iid_r == 3'd0) & inta_r & ~inta_rr);
  assign isr_set[1] = (master | slave_ena) & ((iid_r == 3'd1) & inta_r & ~inta_rr);
  assign isr_set[2] = (master | slave_ena) & ((iid_r == 3'd2) & inta_r & ~inta_rr);
  assign isr_set[3] = (master | slave_ena) & ((iid_r == 3'd3) & inta_r & ~inta_rr);
  assign isr_set[4] = (master | slave_ena) & ((iid_r == 3'd4) & inta_r & ~inta_rr);
  assign isr_set[5] = (master | slave_ena) & ((iid_r == 3'd5) & inta_r & ~inta_rr);
  assign isr_set[6] = (master | slave_ena) & ((iid_r == 3'd6) & inta_r & ~inta_rr);
  assign isr_set[7] = (master | slave_ena) & ((iid_r == 3'd7) & inta_r & ~inta_rr);

  // interrupt service register
  reg [7:0] isr;
  always @(posedge wb_clk_i)
    begin
      // store info for isr
 	    isr[0]  <= (wb_rst_i | wr_icw[1] | pic_eoi[0]) ? 1'b0 : (isr_set[0] | isr[0]);
	    isr[1]  <= (wb_rst_i | wr_icw[1] | pic_eoi[1]) ? 1'b0 : (isr_set[1] | isr[1]);
	    isr[2]  <= (wb_rst_i | wr_icw[1] | pic_eoi[2]) ? 1'b0 : (isr_set[2] | isr[2]);
	    isr[3]  <= (wb_rst_i | wr_icw[1] | pic_eoi[3]) ? 1'b0 : (isr_set[3] | isr[3]);
	    isr[4]  <= (wb_rst_i | wr_icw[1] | pic_eoi[4]) ? 1'b0 : (isr_set[4] | isr[4]);
	    isr[5]  <= (wb_rst_i | wr_icw[1] | pic_eoi[5]) ? 1'b0 : (isr_set[5] | isr[5]);
	    isr[6]  <= (wb_rst_i | wr_icw[1] | pic_eoi[6]) ? 1'b0 : (isr_set[6] | isr[6]);
	    isr[7]  <= (wb_rst_i | wr_icw[1] | pic_eoi[7]) ? 1'b0 : (isr_set[7] | isr[7]);
    end

  // interrupt poll register (only usefull in normal eoi mode)
  reg [7:0] ipr;
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i | wr_icw[1])
        ipr <= 8'b00000000;
      else if (int_reset)  // store info for polling
        begin
          ipr[7] <= intr;
          ipr[6:3] <= 4'b0000;
          ipr[2:0] <= iid_r[2:0]; 
        end
      else
        ipr <= ipr;
    end

  wire [15:0] vector;
  assign vector = { 8'h00, icw2_t[7:3], iid_r[2:0] };

  // delay int ack some clock cycles
  reg inta_r;
  reg inta_rr;
  reg inta_rrr;
  always @(posedge wb_clk_i)
    begin
      inta_r <= wb_rst_i ? 1'b0 : inta;
      inta_rr <= wb_rst_i ? 1'b0 : inta_r; 
      inta_rrr <= wb_rst_i ? 1'b0 : inta_rr; 
    end

  reg int_reset;
  always @(posedge wb_clk_i)
    int_reset <= wb_rst_i ? 1'b0 : (inta_r & ~inta_rr);
  
  // check when to stop searching for highest priority
  wire freeze;
  assign freeze = (inta | inta_r | inta_rr);

  // Generate Hardware end of interrupt
  wire hw_eoi;
  assign hw_eoi = ((master | slave_ena) & (inta_r & ~inta_rr));

  // Generate Hardware Rotate Priority
  reg hw_pri_aeoi; 
  always @(posedge wb_clk_i)
    hw_pri_aeoi <= wb_rst_i ? 1'b0 : (icw4_aeoi & hw_eoi & ocw2_raeoi);
  
  // detect end of interrupt
  reg [7:0] pic_eoi;
  always @(posedge wb_clk_i)
  begin
    if (wb_rst_i)
      begin
        pic_eoi <= 8'b00000000;
      end
    else
      begin // Automatic End Of Interrupt (Hardware) or "Non Specific" / "Specific" End Of Interrupt (Software)
        pic_eoi[0] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[0]);
        pic_eoi[1] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[1]);
        pic_eoi[2] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[2]);
        pic_eoi[3] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[3]);
        pic_eoi[4] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[4]);
        pic_eoi[5] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[5]);
        pic_eoi[6] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[6]);
        pic_eoi[7] <= (icw4_aeoi) ? hw_eoi : (sw_eoi | sw_seoi[7]);
      end
  end

  // send cascade select signal to slave that has to respond... 
  assign cas_o = casb;
  
  // detect if we shoould generate aeoi and/or the interrupt vector
  wire slave_ena;
  assign slave_ena  = cas_i;

  // drive vector or data
  // only generate nmi vector when master...
  assign wb_dat_o = (nmia & master) ? 16'h0002 : (((inta | inta_r) & (master_ena | slave_ena)) ? vector : dat_o);
  
  // just some test signals....
  reg [7:0] test_irr;
  reg [7:0] test_isr;
  always @(posedge wb_clk_i)
  begin
    test_irr <= (wb_rst_i) ? 1'b0 : icw4;
    test_isr <= (wb_rst_i) ? 1'b0 : ipr;
  end
  assign test_int_irr = test_irr;
  assign test_int_isr = test_isr;
endmodule
