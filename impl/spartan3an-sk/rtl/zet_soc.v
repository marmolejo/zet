`timescale 1ns/100ps

module zet_soc (
//    input         DDR_CLK,
    input         SYS_CLK,
/*
    inout  [15:0] SD_DQ,
    output [12:0] SD_A,
    output  [1:0] SD_BA,
    output        SD_CK_P,
    output        SD_CK_N,
    output        SD_CKE,
    output        SD_CS,
    output        SD_RAS,
    output        SD_CAS,
    output        SD_WE,
    output        SD_ODT,
    output        SD_UDM,
    output        SD_LDM,
    inout         SD_UDQS_P,
    inout         SD_LDQS_P,
    inout         SD_UDQS_N,
    inout         SD_LDQS_N,
    input         SD_LOOP_IN,
    output        SD_LOOP_OUT,
*/
    input  [15:0] NF_D,
    output [21:1] NF_A,
    output        NF_WE,
    output        NF_CE,
    output        NF_OE,
    output        NF_BYTE,
    output        NF_RP,

    input         BTN_SOUTH,

    output        VGA_R,
    output        VGA_G,
    output        VGA_B,
    output        VGA_HSYNC,
    output        VGA_VSYNC,

    output  [1:0] LED
  );

  // Net declarations
  wire        cpu_clk;
  wire        mem_rst;
  wire [19:0] addr;
  wire [15:0] wr_data;
  wire        we, m_io;
  wire        byte_m;
  wire [15:0] rd_data, vdu_data, mem_data /*, io_data */;
  wire        vdu_cs;
  wire        mem_op;
  wire        ready, mem_rdy, vdu_rdy;
  wire        wr_cnd;  // Stub
//  reg  [15:0] io_reg;

  // Module instantiation
  memory mem_ctrlr_0 (
/*
    .cntrl0_DDR2_DQ         (SD_DQ),
    .cntrl0_DDR2_A          (SD_A),
    .cntrl0_DDR2_BA         (SD_BA),
    .cntrl0_DDR2_CK         (SD_CK_P),
    .cntrl0_DDR2_CK_N       (SD_CK_N),
    .cntrl0_DDR2_CKE        (SD_CKE),
    .cntrl0_DDR2_CS_N       (SD_CS),
    .cntrl0_DDR2_RAS_N      (SD_RAS),
    .cntrl0_DDR2_CAS_N      (SD_CAS),
    .cntrl0_DDR2_WE_N       (SD_WE),
    .cntrl0_DDR2_ODT        (SD_ODT),
    .cntrl0_DDR2_DM         ({SD_UDM, SD_LDM}),
    .cntrl0_DDR2_DQS        ({SD_UDQS_P, SD_LDQS_P}),
    .cntrl0_DDR2_DQS_N      ({SD_UDQS_N, SD_LDQS_N}),
    .cntrl0_rst_dqs_div_in  (SD_LOOP_IN),   // loopback
    .cntrl0_rst_dqs_div_out (SD_LOOP_OUT),   // loopback
*/
    .NF_WE       (NF_WE),
    .NF_CE       (NF_CE),
    .NF_OE       (NF_OE),
    .NF_BYTE     (NF_BYTE),
    .NF_A        (NF_A),
    .NF_D        (NF_D),

//    .ddr_clk     (DDR_CLK),
    .sys_clk     (SYS_CLK),
    .cpu_clk     (cpu_clk),
    .mem_rst     (mem_rst),
    .board_reset (BTN_SOUTH),

    .addr        (addr),
//    .wr_data     (wr_data),
//    .we          (we & ~m_io),
    .byte_m      (byte_m),
    .rd_data     (mem_data),
    .mem_op      (mem_op),
    .ready       (mem_rdy)
  );

  cpu cpu0 (
    .clk     (cpu_clk),
    .rst     (mem_rst),
    .rd_data (rd_data), 
    .wr_data (wr_data),
    .addr    (addr),
    .we      (we),
    .byte_m  (byte_m),
    .m_io    (m_io),
    .wr_cnd  (wr_cnd), // Stub
    .mem_op  (mem_op),
    .mem_rdy (ready)
  );

  vdu vdu0 (
    .vga_red_o   (VGA_R),
    .vga_green_o (VGA_G),
    .vga_blue_o  (VGA_B),
    .horiz_sync  (VGA_HSYNC),
    .vert_sync   (VGA_VSYNC),

    .vdu_clk_in  (SYS_CLK),  // 50MHz System clock
    .cpu_clk_out (cpu_clk),  // 12.5 MHz CPU Clock
    .vdu_rst     (BTN_SOUTH),
    .vdu_cs      (vdu_cs),
    .vdu_we      (we),
    .byte_m      (byte_m),
    .vdu_addr    (addr[11:0]),
    .wr_data     (wr_data),
    .rd_data     (vdu_data),
    .ready       (vdu_rdy)
  );

//  assign io_data = (addr[15:0]==16'hb7) ? io_reg : 16'd0;
  assign vdu_cs  = (addr[19:12]==16'hb8) && mem_op;
  assign rd_data = /* m_io ? io_data : */ (vdu_cs ? vdu_data : mem_data);
  assign ready   = vdu_cs ? vdu_rdy : mem_rdy;
  assign NF_RP   = 1'b1;
  assign LED     = { wr_cnd, m_io };

  // Behaviour
  // IO Stub
/*
  always @(posedge cpu_clk)
    if (addr==20'hb7 & ~we & m_io) 
      io_reg <= byte_m ? { io_reg[15:8], wr_data[7:0] } : wr_data;
*/
endmodule