module test_mem_ctrl (
    input         sys_clk_in_,
    
    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output reg    sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output reg       sram_cen_,
    output reg       flash_ce2_,
	 
    output [ 8:0] leds_
  );

  // Net declarations
  wire rst;
  wire clk;
  wire ack_o;
  wire [15:0] dat_o;

  // Register declarations
  reg [7:0] estat;

  reg [19:0] adr_i;
  reg [15:0] dat_i;
  reg        we_i;
  reg        byte_i;

  // Module instantiations
  clock c0 (
    .sys_clk_in_ (sys_clk_in_),
    .clk         (clk),
    .rst         (rst)
  );

  mem_ctrl mem0 (
    .clk_i (clk),
	 .rst_i (rst),
    .adr_i (adr_i),
    .dat_i (dat_i),
    .dat_o (dat_o),
    .we_i  (we_i),
    .ack_o (ack_o),
    .stb_i (1'b1),
    .byte_i (byte_i),

    .sram_clk_        (sram_clk_),
    .sram_flash_addr_ (sram_flash_addr_),
    .sram_flash_data_ (sram_flash_data_),
    .sram_flash_oe_n_ (sram_flash_oe_n_),
//    .sram_flash_we_n_ (sram_flash_we_n_),
    .sram_bw_         (sram_bw_)
//    .sram_cen_        (sram_cen_),
//    .flash_ce2_       (flash_ce2_)
  );

  // Continuous assignments
  assign leds_ = dat_i[8:0];

  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (even address)
        adr_i <= 20'hc0002;
        dat_i <= 16'd0;
        we_i  <= 1'd0;
        byte_i <= 1'd0;
        estat <= 8'd00;
        sram_flash_we_n_ <= 1'd1;
        sram_cen_  <= 1'd1;
        flash_ce2_ <= 1'd1;
      end
    else
      case (estat)
        8'd00:
          begin // RAM word write (even address)
            adr_i <= 20'h00004;
            dat_i <= dat_o;
            we_i  <= 1'd1;
            byte_i <= 1'd0;
            estat <= 8'd01;
            sram_flash_we_n_ <= 1'd0;
            sram_cen_  <= 1'd0;
            flash_ce2_ <= 1'd0;
          end
        8'd01:
          begin // RAM word write (even address)
            adr_i <= 20'h00006;
            dat_i <= dat_i;
            we_i  <= 1'd1;
            byte_i <= 1'd0;
            estat <= 8'd05;
            sram_flash_we_n_ <= 1'd0;
            sram_cen_  <= 1'd0;
            flash_ce2_ <= 1'd0;
          end        
       8'd02:
          begin // RAM word read (even address)
            adr_i <= 20'h00006;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd03;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd0;
            flash_ce2_ <= 1'd0;
          end                
       8'd03:
          begin // RAM word write (even address)
            adr_i <= 20'h00008;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd05;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd0;
            flash_ce2_ <= 1'd0;
          end              
     /*   8'd04:
          begin  // WE to 0
            adr_i <= 20'h00004;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd05;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd0;  // (0,0) y (1,0) funcionan
            flash_ce2_ <= 1'd0;  // (0,1) y (1,1) : se escribe lo de la ROM
          end*/
        8'd05:
          begin  // SRAM Chip enable to 0
            adr_i <= 20'h00008;
            dat_i <= dat_o;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd06;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd1;  // (0,0) y (1,0) funcionan
            flash_ce2_ <= 1'd0;  // (0,1) y (1,1) : se escribe lo de la ROM
          end        
        default:
          begin // ROM word read
            adr_i <= 20'hc0006;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd06;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd1;
            flash_ce2_ <= 1'd1;
          end
/*        default:
          begin
            adr_i <= 20'hc0006;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd06;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd1;
            flash_ce2_ <= 1'd1;
		      end
        8'd07:
          begin
            adr_i <= 20'h00006;
            dat_i <= dat_i;
            we_i  <= 1'd0;
            byte_i <= 1'd0;
            estat <= 8'd07;
            sram_flash_we_n_ <= 1'd1;
            sram_cen_  <= 1'd1;
            flash_ce2_ <= 1'd1;
		      end
	
		  8'd06:
		    begin
			   byte_i <= 1'b1;
			   estat <= 8'd10;
			 end
		  8'd10:
          begin // RAM word write (even address)
            dat_i <= dat_o;

				adr_i <= 20'h00008;
				we_i  <= 1'd1;
            estat <= 8'd15;
   		 end
		  8'd15:
          begin
				we_i  <= 1'd0;
            estat <= 8'd20;
   		 end */
	 endcase
endmodule
