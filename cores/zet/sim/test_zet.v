`timescale 10ns/100ps

module test_zet;

  // Net declarations
  wire [15:0] dat_o;
  wire [15:0] mem_dat_i, io_dat_i, dat_i;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire [ 1:0] sel;
  wire        stb;
  wire        cyc;
  wire        ack, mem_ack, io_ack;
  wire        inta;
  wire        nmia;
  wire [19:0] pc;

  reg         clk;
  reg         rst;

  reg  [15:0] io_reg;

  reg         intr;

  // Module instantiations
  memory mem0 (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_o),
    .wb_dat_o (mem_dat_i),
    .wb_adr_i (adr),
    .wb_we_i  (we),
    .wb_sel_i (sel),
    .wb_stb_i (stb & !tga),
    .wb_cyc_i (cyc & !tga),
    .wb_ack_o (mem_ack)
  );

  zet zet (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_adr_o (adr),
    .wb_we_o  (we),
    .wb_tga_o (tga),
    .wb_sel_o (sel),
    .wb_stb_o (stb),
    .wb_cyc_o (cyc),
    .wb_ack_i (ack),
    .wb_tgc_i (1'b0),
    .wb_tgc_o (inta),
    .nmi      (1'b0),
    .nmia     (nmia),
    .pc       (pc)
  );

  // Assignments
  assign io_dat_i = (adr[15:1]==15'h5b) ? { io_reg[7:0], 8'h0 }
    : ((adr[15:1]==15'h5c) ? { 8'h0, io_reg[15:8] } : 16'h0);
  assign dat_i = inta ? 16'd3 : (tga ? io_dat_i : mem_dat_i);

  assign ack    = tga ? io_ack : mem_ack;
  assign io_ack = stb;

  // Behaviour
  // IO Stub
  always @(posedge clk)
    if (adr[15:1]==15'h5b && sel[1] && cyc && stb)
      io_reg[7:0] <= dat_o[15:8];
    else if (adr[15:1]==15'h5c & sel[0] && cyc && stb)
      io_reg[15:8] <= dat_o[7:0];

  always #4 clk = ~clk;  // 12.5 Mhz

  initial
    begin
         intr <= 1'b0;
         clk <= 1'b1;
         rst <= 1'b0;
      #5 rst <= 1'b1;
      #5 rst <= 1'b0;

      #1000 intr <= 1'b1;
      //@(posedge inta)
      @(posedge clk) intr <= 1'b0;
    end

  initial
    begin
      $readmemh("data.rtlrom", mem0.ram, 19'h78000);
      $readmemb("../rtl/micro_rom.dat",
        zet.core.micro_data.micro_rom.rom);
    end
endmodule
