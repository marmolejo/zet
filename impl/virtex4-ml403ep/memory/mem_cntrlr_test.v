//
// Memory controller test. It testes all kind of memory accesses in
//   different RAM / ROM areas. RAM contents at the end:
//
//   Mem[01:00] = xx34
//   Mem[03:02] = 1234
//   Mem[05:04] = Mem[09:08]
//   Mem[07:06] = 0a0b
//   Mem[0d:0c] = 12xx
//   Mem[0f:0e] = xxMem[08]
//   Mem[11:10] = ff83
//   Mem[13:12] = 0034
//   Mem[15:14] = 0062
//   Mem[17:16] = ext(Mem[09])
//   Mem[19:18] = Mem[09]xx
//   Mem[1b:1a] = 0b06
//   Mem[1d:1c] = Mem[08]12
//

module mem_cntrlr_test (
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

  assign leds_[7:0] = estat;

  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (dada1 = 1234)
        estat    <= 8'h10;
        dada_sor <= 16'd0;
        dada1    <= 16'h1234;
        dada2    <= 16'h6789;
        adr      <= 21'hc0002;
        we       <= 1'd0;
        stb      <= 1'd0;
        byte_o   <= 1'd0;
      end
    else
      case (estat)
        8'h10:
          begin  // ROM word read (dada2 = 0a0b)
            estat    <= 8'h20;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0004;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h20:
          if (ack) begin  // RAM word read (@4)
            estat    <= 8'h30;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada_ent;
            adr      <= 20'h8;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h30:
          if (ack) begin // RAM write (@2 = @4)
            estat    <= 8'h40;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h4;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h40:
          if (ack) begin // RAM write (@3 = 0a0b)
            estat    <= 8'h50;
            dada_sor <= dada2;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h6;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h50:
          if (ack) begin // RAM write (@1 = 1234)
            estat    <= 8'h60;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h60:
          if (ack) begin // ROM read byte (83)
            estat    <= 8'h62;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0040;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h62:
          if (ack) begin // RAM word write (@8 = ff83)
            estat    <= 8'h65;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h10;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h65:
          if (ack) begin // RAM byte read (07)
            estat    <= 8'h70;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h70:
          if (ack) begin // RAM word write (@9 = 0034)
            estat    <= 8'h75;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h12;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h75:
          if (ack) begin // RAM byte write (@0 = 34)
            estat    <= 8'h80;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h0;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h80:
          if (ack) begin // ROM read byte odd (62)
            estat    <= 8'h90;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0031;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h90:
          if (ack) begin // RAM word write (@10 = 0062)
            estat    <= 8'h95;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h14;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h95:
          if (ack) begin // RAM byte read odd (8c)
            estat    <= 8'ha0;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h9;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'ha0:
          if (ack) begin // RAM word write (@11 = ff8c)
            estat    <= 8'hb0;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h16;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hb0:
          if (ack) begin // RAM byte write odd (@12 = 8cxx)
            estat    <= 8'hc0;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h19;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'hc0:
          if (ack) begin // ROM word read odd (0b06)
            estat    <= 8'hd0;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0003;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hd0:
          if (ack) begin // RAM word write (@13 = 0b06)
            estat    <= 8'he0;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h1a;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'he0:
          if (ack) begin // RAM word read (odd)
            estat    <= 8'he7;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h3;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'he7:
          if (ack) begin // RAM word write (even)
            estat    <= 8'he9;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'h1c;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'he9:
          if (ack) begin // RAM word write (odd)
            estat    <= 8'hf0;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'd13;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hf0:
          if (ack) begin
            estat <= 8'hf5;
            we    <= 1'b0;
            stb   <= 1'b0;
          end
      endcase
endmodule
