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
    output        tft_lcd_vsync_
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

  // Behavioral description
  always @(posedge clk)
    if (rst)
      begin  // ROM word read (dada1 = 0607)
        estat    <= 8'h02;
        dada_sor <= 16'd0;
        dada1    <= 16'h1234;
        dada2    <= 16'h6789;
        adr      <= 20'hffff0;
        we       <= 1'd0;
        stb      <= 1'd1;
        byte_o   <= 1'd1;
      end
    else
      case (estat)
        8'h02:
          if (ack) begin
            estat    <= 8'h04;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'h0;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        // Video test
        8'h04:
          if (ack) begin // byte write even / A
            estat    <= 8'h06;
            dada_sor <= 16'h41;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8000;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h06:
          if (ack) begin // byte write odd (attr) yellow (e)
            estat    <= 8'h10;
            dada_sor <= 16'h03;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8003;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd1;
          end
        8'h10:
          if (ack) begin // word read (even) - yellow e
            estat    <= 8'h15;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8002;
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h15:
          if (ack) begin // word write (even) RAM @7 = 0365
            estat    <= 8'h20;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada_ent;
            adr      <= 20'he;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h20: // word write (even) yellow e in
               //   place of the p of processor
          if (ack) begin 
            estat    <= 8'h25;
            dada_sor <= dada1;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8008;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h25:
          if (ack) begin // word read (odd) 7403 't' yellow
            estat    <= 8'h30;
            dada_sor <= dada_sor;
            dada1    <= dada1;
            dada2    <= dada2;
            adr      <= 20'hb8003; // b8009
            we       <= 1'd0;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h30:
          if (ack) begin // word write (odd)
            // This changes the color attribute of the
            //  'o' in "processor" and writes a 't' in place
            // of the 'o'
            estat    <= 8'h35;
            dada_sor <= dada_ent;
            dada1    <= dada_ent;
            dada2    <= dada2;
            adr      <= 20'hb800d;
            we       <= 1'd1;
            stb      <= 1'd1;
            byte_o   <= 1'd0;
          end
        8'h35:
          if (ack) begin
            estat <= 8'h40;
            we    <= 1'b0;
            stb   <= 1'b0;
          end
      endcase
endmodule
