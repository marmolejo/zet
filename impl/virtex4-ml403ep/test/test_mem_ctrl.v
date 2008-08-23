module test_mem_ctrl (
    input             sys_clk_in_,
    
    output            sram_clk_,
    output reg [20:0] sram_flash_addr_,
    inout      [15:0] sram_flash_data_,
    output reg        sram_flash_oe_n_,
    output reg        sram_flash_we_n_,
    output reg [ 3:0] sram_bw_,
    output reg        sram_cen_,
    output reg        flash_ce2_,
    
    output     [ 8:0] leds_
  );

  // Net declarations
  wire rst;
  wire clk;

  // Register declarations
  reg [ 7:0] estat;
  reg [15:0] dada;
  reg [15:0] dada1;
  reg [15:0] dada2;

  // Module instantiations
  clock c0 (
    .sys_clk_in_ (sys_clk_in_),
    .clk         (clk),
    .rst         (rst)
  );

  // Continuous assignments
  assign sram_clk_ = clk;
  assign leds_      = dada[8:0];
  assign sram_flash_data_ = sram_flash_we_n_ ? 16'hzzzz : dada;

  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (even address)
        estat            <= 8'd20;
        dada             <= 16'd0;
        dada1            <= 16'h1234;
        dada2            <= 16'h6789;
        sram_flash_addr_ <= 21'h00008;
        sram_flash_oe_n_ <= 1'd0;
        sram_flash_we_n_ <= 1'd1;
        sram_bw_         <= 4'hc; 
        sram_cen_        <= 1'd1;
        flash_ce2_       <= 1'd1;
      end
    else
      case (estat)
        8'd20:
          begin  // RAM word read (even address)
            estat            <= 8'd21;
            dada             <= 16'd0;
            dada1            <= 16'h1234;
            dada2            <= 16'h6789;
            sram_flash_addr_ <= 21'h00004;
            sram_flash_oe_n_ <= 1'd0;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd21:
          begin  // RAM word read (even address)
            estat            <= 8'd22;
            dada             <= 16'd0;
            dada1            <= 16'h1234;
            dada2            <= 16'h6789;
            sram_flash_addr_ <= 21'h00004;
            sram_flash_oe_n_ <= 1'd0;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd22:
          begin  // RAM word read (even address)
            estat            <= 8'd30;
            dada             <= 16'd0;
            dada1            <= 16'h1234;
            dada2            <= 16'h6789;
            sram_flash_addr_ <= 21'h00004;
            sram_flash_oe_n_ <= 1'd0;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd30:
          begin // RAM write
            estat            <= 8'd32;
            dada             <= sram_flash_data_;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00002;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd0;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd32:
          begin // RAM write (1st wait cycle)
            estat            <= 8'd35;
            dada             <= dada;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00002;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd35:
          begin // RAM write (2nd wait cycle)
            estat            <= 8'd40;
            dada             <= dada;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00002;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd40:
          begin // RAM write
            estat            <= 8'd42;
            dada             <= dada2;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00003;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd0;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd42:
          begin // RAM write (1st wait cycle)
            estat            <= 8'd45;
            dada             <= dada;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00003;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd45:
          begin // RAM write (2nd wait cycle)
            estat            <= 8'd50;
            dada             <= dada;
            dada1            <= dada1; 
            dada2            <= dada2;
            sram_flash_addr_ <= 21'h00003;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
      endcase
endmodule
