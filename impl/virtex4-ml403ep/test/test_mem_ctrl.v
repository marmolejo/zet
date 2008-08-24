module test_mem_ctrl (
    input         sys_clk_in_,
    
    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        flash_ce2_,
    
    output [ 8:0] leds_
  );

  // Net declarations
  wire        rst;
  wire        clk;
  wire [15:0] dada_ent;
  wire        ack;

  // Register declarations
  reg [ 7:0] estat;
  reg [15:0] dada_sor;
  reg [15:0] dada1;
  reg [15:0] dada2;
  reg [19:0] adr;
  reg        we;
  reg        stb;
  reg        byte_o;

  // Module instantiations
  clock c0 (
    .sys_clk_in_ (sys_clk_in_),
    .clk         (clk),
    .rst         (rst)
  );

  mem_ctrl mem_ctrl0 (
    // Wishbone signals
    .clk_i  (clk),
	  .rst_i  (rst),
    .adr_i  (adr),
    .dat_i  (dada_sor),
    .dat_o  (dada_ent),
    .we_i   (we),
    .ack_o  (ack),
    .stb_i  (stb),
    .byte_i (byte_o),

    // Pad signals
    .sram_clk_        (sram_clk_),
    .sram_flash_addr_ (sram_flash_addr_),
    .sram_flash_data_ (sram_flash_data_),
    .sram_flash_oe_n_ (sram_flash_oe_n_),
    .sram_flash_we_n_ (sram_flash_we_n_),
    .sram_bw_         (sram_bw_),
    .sram_cen_        (sram_cen_),
    .flash_ce2_       (flash_ce2_)
  );

  // Continuous assignments
  assign leds_     = dada_sor[8:0];

  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (dada1 = 0607)
        estat    <= 8'd00;
        dada_sor <= 16'd0;
        dada1    <= 16'h1234;
        dada2    <= 16'h6789;
        adr      <= 21'hc0002;
        we       <= 1'd0;
        stb      <= 1'd1;
        byte_o   <= 1'd0;
      end
    else
      case (estat)
        8'd00:
          if (ack) begin  // ROM word read (dada2 = 0a0b)
            estat    <= 8'd20;
            dada_sor <= dada_sor;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'hc0004;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd20:
          if (ack) begin  // RAM word read (@4)
            estat    <= 8'd30;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada_ent;
            adr      <= 20'h8;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd30:
          if (ack) begin // RAM write (@2 = @4)
            estat    <= 8'd40;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h4;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd40:
          if (ack) begin // RAM write (@3 = 0a0b)
            estat    <= 8'd50;
            dada_sor <= dada2;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h6;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd50:
          if (ack) begin // RAM write (@1 = 0607)
            estat    <= 8'd55;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd55:
          if (ack) begin // ROM read byte (83)
            estat    <= 8'd60;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0040;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd60:
          if (ack) begin // RAM word write (@8 = ff83)
            estat    <= 8'd65;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h10;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd65:
          if (ack) begin // RAM byte read (07)
            estat    <= 8'd70;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd70:
          if (ack) begin // RAM word write (@9 = 0007)
            estat    <= 8'd75;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h12;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd75:
          if (ack) begin // RAM byte write (@0 = 07)
            estat    <= 8'd85;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h0;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd85:
          if (ack) begin // ROM read byte odd (62)
            estat    <= 8'd90;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0031;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd90:
          if (ack) begin // RAM word write (@10 = 0062)
            estat    <= 8'd95;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h14;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd95:
          if (ack) begin // RAM byte read odd (8c)
            estat    <= 8'd100;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h9;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd100:
          if (ack) begin // RAM word write (@11 = ff8c)
            estat    <= 8'd105;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h16;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'd105:
          if (ack) begin // RAM byte write odd (@12 = 8cxx)
            estat    <= 8'd110;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h19;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'd110:
          if (ack) begin
            estat    <= 8'd115;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h19;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
      endcase
endmodule
