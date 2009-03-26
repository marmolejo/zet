module test_sram (
    input        clk_27_,

    output reg [9:0] ledr_,
    output reg [7:0] ledg_,
    input      [9:0] sw_,

    // Pad signals
    output reg [17:0] sram_addr_,
    inout      [15:0] sram_data_,
    output reg        sram_we_n_,
    output reg        sram_oe_n_,
    output            sram_ce_n_,
    output reg [ 1:0] sram_bw_n_
  );

  // Nets
  wire clk;
  wire lock;
  wire rst;

  reg [ 7:0] st;
  reg [15:0] ww;

  // Module instantiations
  pll pll (
    .inclk0 (clk_27_),
    .c0     (clk),
    .locked (lock)
  );

  // Continuous assignments
  assign sram_ce_n_ = 1'b0;
  assign sram_data_ = sram_we_n_ ? 16'hzzzz : ww;

  assign rst = !lock;

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        sram_addr_ <= 18'h00;
        ww         <= 16'h0;
        sram_we_n_ <= 1'b1;
        sram_oe_n_ <= 1'b0;
        sram_bw_n_ <= 2'b11;
        st         <= 8'h0;
        {ledr_,ledg_} <= 18'h0;
      end
    else
      case (st)
        8'h0:
          begin
            sram_addr_ <= { 8'h0, sw_ };
            ww         <= 16'h7654;
            sram_we_n_ <= 1'b0;
            sram_oe_n_ <= 1'b1;
            sram_bw_n_ <= 2'b00;
            st         <= 8'h1;
          end
        8'h1:
          begin
            sram_addr_ <= 18'h00;
            ww         <= 16'h0000;
            sram_we_n_ <= 1'b1;
            sram_oe_n_ <= 1'b0;
            sram_bw_n_ <= 2'b11;
            st         <= 8'h2;
          end
        8'h2:
          begin
            sram_addr_ <= { 8'h0, sw_ };
            sram_we_n_ <= 1'b1;
            sram_oe_n_ <= 1'b0;
            sram_bw_n_ <= 2'b00;
            st         <= 8'h3;
          end
        8'h3:
          begin
            {ledr_,ledg_} <= {2'b00, sram_data_};
            st            <= 8'h4;
          end
        default:
          begin
            sram_addr_ <= 18'h00;
            ww         <= 16'h0000;
            sram_we_n_ <= 1'b1;
            sram_oe_n_ <= 1'b0;
            sram_bw_n_ <= 2'b11;
            st         <= 8'h2;
          end
      endcase

endmodule
