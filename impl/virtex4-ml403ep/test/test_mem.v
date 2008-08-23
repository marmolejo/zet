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
        estat            <= 8'd00;
        dada             <= 16'd0;
        sram_flash_addr_ <= 21'h00002;
        sram_flash_oe_n_ <= 1'd0;
        sram_flash_we_n_ <= 1'd1;
        sram_bw_         <= 4'hf; 
        sram_cen_        <= 1'd1;
        flash_ce2_       <= 1'd1;
      end
    else
      case (estat)
        8'd00:
          begin
            estat            <= 8'd05;
            dada             <= sram_flash_data_;
            sram_flash_addr_ <= 21'h00006;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd0;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd05:
          begin
            estat            <= 8'd06;
            dada             <= dada;
            sram_flash_addr_ <= 21'h00006;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd06:
          begin
            estat            <= 8'd10;
            dada             <= dada;
            sram_flash_addr_ <= 21'h00006;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd10:
          begin
            estat            <= 8'd15;
            dada             <= dada;
            sram_flash_addr_ <= 21'h00003;
            sram_flash_oe_n_ <= 1'd0;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hf; 
            sram_cen_        <= 1'd1;
            flash_ce2_       <= 1'd1;
          end      
        8'd15:
          begin
            estat            <= 8'd20;
            dada             <= sram_flash_data_;
            sram_flash_addr_ <= 21'h00008;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd0;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
        8'd20:
          begin
            estat            <= 8'd25;
            dada             <= dada;
            sram_flash_addr_ <= 21'h00008;
            sram_flash_oe_n_ <= 1'd1;
            sram_flash_we_n_ <= 1'd1;
            sram_bw_         <= 4'hc; 
            sram_cen_        <= 1'd0;
            flash_ce2_       <= 1'd0;
          end
      endcase
endmodule
