//
// Memory map test. It testes all kind of memory accesses in
//   different RAM / ROM / video areas. RAM contents at the end:
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
//   Mem[1f:1e] = 0365
//
// In the screen: Aet erotessor ... (first & second 'e' yellow
//   and fist 'o' yellow)
//

module mem_map_test (
    input         sys_clk_in_,

    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        flash_ce2_,

    output        tft_lcd_clk_,
    output        tft_lcd_r_,
    output        tft_lcd_g_,
    output        tft_lcd_b_,
    output        tft_lcd_hsync_,
    output        tft_lcd_vsync_,

    output        rs_,
    output        rw_,
    output        e_,
    output  [7:4] db_
  );

  // Net declarations
  wire        rst;
  wire        clk;
  wire [15:0] dada_ent;
  wire        ack;
  wire        clk_100M;
  wire [63:0] f1, f2;
  wire [15:0] m1, m2;

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
    .clk_100M    (clk_100M),
    .vdu_clk     (tft_lcd_clk_),
    .rst         (rst)
  );

  mem_map mem_map0 (
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
    .flash_ce2_       (flash_ce2_),

    // VGA pad signals
    .vdu_clk     (tft_lcd_clk_),
    .vga_red_o   (tft_lcd_r_),
    .vga_green_o (tft_lcd_g_),
    .vga_blue_o  (tft_lcd_b_),
    .horiz_sync  (tft_lcd_hsync_),
    .vert_sync   (tft_lcd_vsync_)
  );

  lcd_display lcd0 (
    .f1 (f1),  // 1st row
    .f2 (f2),  // 2nd row
    .m1 (m1),  // 1st row mask
    .m2 (m2),  // 2nd row mask

    .clk (clk_100M),  // 100 Mhz clock

    // Pad signals
    .lcd_rs_  (rs_),
    .lcd_rw_  (rw_),
    .lcd_e_   (e_),
    .lcd_dat_ (db_)
  );

  // Continuous assignments
  assign f1 = { estat, 4'h0, dada_sor, 4'h0, dada1, dada2 };
  assign f2 = { adr, 7'h0, we, 7'h0, stb, 7'h0, byte_o, 4'h0, dada_ent };
  assign m1 = 16'b1101111011111111;
  assign m2 = 16'b1111101010101111;


  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (dada1 = 1234)
        estat    <= 8'h00;
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
        8'h00:
          begin  // ROM word read (dada2 = 0a0b)
            estat    <= 8'h05;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0004;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h05:
          if (ack) begin  // RAM word read (@4)
            estat    <= 8'h10;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada_ent;
            adr      <= 20'h8;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h10:
          if (ack) begin // RAM write (@2 = @4)
            estat    <= 8'h15;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h4;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h15:
          if (ack) begin // RAM write (@3 = 0a0b)
            estat    <= 8'h20;
            dada_sor <= dada2;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h6;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h20:
          if (ack) begin // RAM write (@1 = 1234)
            estat    <= 8'h25;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h25:
          if (ack) begin // ROM read byte (83)
            estat    <= 8'h30;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0040;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h30:
          if (ack) begin // RAM word write (@8 = ff83)
            estat    <= 8'h35;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h10;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h35:
          if (ack) begin // RAM byte read (07)
            estat    <= 8'h40;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h2;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h40:
          if (ack) begin // RAM word write (@9 = 0034)
            estat    <= 8'h45;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h12;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h45:
          if (ack) begin // RAM byte write (@0 = 34)
            estat    <= 8'h50;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h0;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h50:
          if (ack) begin // ROM read byte odd (62)
            estat    <= 8'h55;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0031;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h55:
          if (ack) begin // RAM word write (@10 = 0062)
            estat    <= 8'h60;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h14;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h60:
          if (ack) begin // RAM byte read odd (8c)
            estat    <= 8'h65;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h9;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h65:
          if (ack) begin // RAM word write (@11 = ff8c)
            estat    <= 8'h70;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h16;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h70:
          if (ack) begin // RAM byte write odd (@12 = 8cxx)
            estat    <= 8'h75;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h19;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h75:
          if (ack) begin // ROM word read odd (0b06)
            estat    <= 8'h80;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hc0003;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h80:
          if (ack) begin // RAM word write (@13 = 0b06)
            estat    <= 8'h85;
            dada_sor <= dada_ent;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h1a;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h85:
          if (ack) begin // RAM word read (odd)
            estat    <= 8'h90;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'h3;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h90:
          if (ack) begin // RAM word write (even)
            estat    <= 8'h95;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'h1c;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h95:
          if (ack) begin // RAM word write (odd)
            estat    <= 8'ha0;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'd13;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end

        // Video test
        8'ha0:
          if (ack) begin // byte write even / A
            estat    <= 8'ha5;
            dada_sor <= 16'h41;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8000;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'ha5:
          if (ack) begin // byte write odd (attr) yellow (e)
            estat    <= 8'hb0;
            dada_sor <= 16'h03;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8003;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'hb0:
          if (ack) begin // word read (even) - yellow e
            estat    <= 8'hb5;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8002;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hb5:
          if (ack) begin // word write (even) RAM @7 = 0365
            estat    <= 8'hc0;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada_ent;
            adr      <= 20'h1e;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hc0: // word write (even) yellow e in
               //   place of the p of processor
          if (ack) begin 
            estat    <= 8'hc5;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8008;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hc5:
          if (ack) begin // word read (odd) 7403 't' yellow
            estat    <= 8'hd0;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8003; // b8009
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hd0:
          if (ack) begin // word write (odd)
            // This changes the color attribute of the
            //  'o' in "processor" and writes a 't' in place
            // of the 'o'
            estat    <= 8'hd5;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'hb800d;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'hd5:
          if (ack) begin
            estat <= 8'he0;
            we    <= 1'b0;
            stb   <= 1'b0;
          end
      endcase
endmodule
