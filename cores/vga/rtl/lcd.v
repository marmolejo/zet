module lcd (
    input clk,              // 25 Mhz clock
    input rst,

    input shift_reg_1,      // if set: 320x200
    input graphics_alpha,   // if not set: 640x400 text mode

    // CSR slave interface for reading
    output [16:1] csr_adr_o,
    input  [15:0] csr_dat_i,

    // VGA pad signals
    output reg [1:0] vga_red_o,
    output reg [1:0] vga_green_o,
    output reg [1:0] vga_blue_o,
    output           horiz_sync,
    output reg       vert_sync
  );

  // Synchronization constants, these values are taken from:
  //  http://tinyvga.com/vga-timing/640x400@70Hz
  localparam HOR_DISP_END = 10'd640; // Last horizontal pixel displayed
  localparam HOR_SYNC_BEG = 10'd657; // Start of horizontal synch pulse
  localparam HOR_SYNC_END = 10'd753; // End of Horizontal Synch pulse
  localparam HOR_SCAN_END = 10'd799; // Last pixel in scan line

  localparam VER_DISP_END_0 = 10'd400;  // last row displayed
  localparam VER_SYNC_BEG_0 = 10'd412;  // start of vertical synch pulse
  localparam VER_SYNC_END_0 = 10'd415;  // end of vertical synch pulse
  localparam VER_SCAN_END_0 = 10'd448;  // Last scan row in the frame
  localparam VER_DISP_END_1 = 10'd480;  // last row displayed
  localparam VER_SYNC_BEG_1 = 10'd490;  // start of vertical synch pulse
  localparam VER_SYNC_END_1 = 10'd492;  // end of vertical synch pulse
  localparam VER_SCAN_END_1 = 10'd524;  // Last scan row in the frame

  // Registers and nets
  reg        video_on_v;
  reg        video_on_h_i;
  reg [9:0]  h_count;   // Horizontal pipeline delay is 2 cycles
  reg [9:0]  v_count;   // 0 to VER_SCAN_END

  wire       mode640x480;
  wire [9:0] ver_disp_end;
  wire [9:0] ver_sync_beg;
  wire [9:0] ver_sync_end;
  wire [9:0] ver_scan_end;
  wire       video_on;
  wire       pix_on1;
  wire       pix_on2;
  wire       pix_on3;
  wire       pix_on4;

  wire [3:0] blue_gm;
  wire [3:0] green_gm;
  wire [3:0] red_gm;
  wire [1:0] blue_tm;
  wire [1:0] green_tm;
  wire [1:0] red_tm;

  wire video_on_h_tm;
  wire video_on_h_gm;
  wire video_on_h;

  reg  horiz_sync_i;
  wire horiz_sync_tm;
  wire horiz_sync_gm;

  // Module instances
  text_mode tm (
    .clk (clk),
    .rst (rst),

    // CSR slave interface for reading
    .csr_adr_o (csr_adr_o),
    .csr_dat_i (csr_dat_i),

    .h_count      (h_count),
    .v_count      (v_count),
    .horiz_sync_i (horiz_sync_i),
    .video_on_h_i (video_on_h_i),
    .video_on_h_o (video_on_h_tm),

    .vga_red_o    (red_tm),
    .vga_green_o  (green_tm),
    .vga_blue_o   (blue_tm),
    .horiz_sync_o (horiz_sync_tm)
  );

  // Continuous assignments
  assign mode640x480  = graphics_alpha & !shift_reg_1;
  assign ver_disp_end = mode640x480 ? VER_DISP_END_1 : VER_DISP_END_0;
  assign ver_sync_beg = mode640x480 ? VER_SYNC_BEG_1 : VER_SYNC_BEG_0;
  assign ver_sync_end = mode640x480 ? VER_SYNC_END_1 : VER_SYNC_END_0;
  assign ver_scan_end = mode640x480 ? VER_SCAN_END_1 : VER_SCAN_END_0;
  assign video_on     = video_on_h && video_on_v;

  assign pix_on1 = (h_count==10'd1);
  assign pix_on2 = (h_count==HOR_DISP_END);
  assign pix_on3 = (v_count==10'd0);
  assign pix_on4 = (mode640x480 ? (v_count==10'd479) : (v_count==10'd399));

  assign blue_gm  = (pix_on1 || pix_on4) ? 4'hf : 4'h7;
  assign green_gm = (pix_on2 || pix_on4) ? 4'hf : 4'h7;
  assign red_gm   = (pix_on3 || pix_on4) ? 4'hf : 4'h7;

  assign video_on_h_gm = video_on_h_i;
  assign video_on_h    = graphics_alpha ? video_on_h_gm : video_on_h_tm;

  assign horiz_sync_gm = horiz_sync_i;
  assign horiz_sync    = graphics_alpha ? horiz_sync_gm : horiz_sync_tm;

  // Sync generation & timing process
  // Generate horizontal and vertical timing signals for video signal
  always @(posedge clk)
    if (rst)
      begin
        h_count      <= 10'b0;
        horiz_sync_i <= 1'b1;
        v_count      <= 10'b0;
        vert_sync    <= 1'b1;
        video_on_h_i <= 1'b1;
        video_on_v   <= 1'b1;
      end
    else
      begin
        h_count      <= (h_count==HOR_SCAN_END) ? 10'b0 : h_count + 10'b1;
        horiz_sync_i <= (h_count==HOR_SYNC_BEG) ? 1'b0
                      : ((h_count==HOR_SYNC_END) ? 1'b1 : horiz_sync_i);
        v_count      <= (v_count==ver_scan_end && h_count==HOR_SCAN_END) ? 10'b0
                      : ((h_count==HOR_SCAN_END) ? v_count + 10'b1 : v_count);
        vert_sync    <= (v_count==ver_sync_beg) ? 1'b0
                      : ((v_count==ver_sync_end) ? 1'b1 : vert_sync);

        video_on_h_i <= (h_count==10'h0) ? 1'b1
                      : ((h_count==HOR_DISP_END) ? 1'b0 : video_on_h_i);
        video_on_v   <= (v_count==10'h0) ? 1'b1
                      : ((v_count==ver_disp_end) ? 1'b0 : video_on_v);
      end

  // Colour signals
  always @(posedge clk)
    if (rst)
      begin
        vga_red_o     <= 2'b0;
        vga_green_o   <= 2'b0;
        vga_blue_o    <= 2'b0;
      end
    else
      begin
        vga_blue_o  <=  video_on ?  (graphics_alpha ? blue_gm[3:2] : blue_tm) : 2'b0 ;
        vga_green_o <=  video_on ?  (graphics_alpha ? green_gm[3:2] : green_tm)  : 2'b0 ;
        vga_red_o   <=  video_on ?  (graphics_alpha ? red_gm[3:2] : red_tm)  : 2'b0 ;
      end

endmodule
