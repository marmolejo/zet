// Video Display terminal
// John Kent
// 3th September 2004 
// Assumes a pixel clock input of 50 MHz
// Generates a 12.5MHz CPU Clock output
//
// Display Format is: 
// 80 characters across	by 25 characters down.
// 8 horizonal pixels / character
// 16 vertical scan lines / character (2 scan lines/row)
`timescale 1ns/10ps

module vdu
  (
    input             vdu_clk,     // 25MHz	VDU clock
    input             cpu_clk,     // CPU Clock
    input             vdu_rst,
    input             vdu_cs,
    input             vdu_we,
    input             byte_m,
    input      [11:0] vdu_addr,
    input      [15:0] wr_data,
    output reg [15:0] rd_data,
    output            ready,

    output reg        vga_red_o,
    output reg        vga_green_o,
    output reg        vga_blue_o,
    output reg        horiz_sync,
    output reg        vert_sync
  );

  // Net, registers and parameters

  // Synchronization constants
  parameter HOR_DISP_END = 10'd639; // Last horizontal pixel displayed
  parameter HOR_SYNC_BEG = 10'd679; // Start of horizontal synch pulse
  parameter HOR_SYNC_END = 10'd775; // End of Horizontal Synch pulse
  parameter HOR_SCAN_END = 10'd799; // Last pixel in scan line
  parameter HOR_DISP_CHR = 80;      // Number of characters displayed per row

  parameter VER_DISP_END = 9'd399;  // last row displayed
  parameter VER_SYNC_BEG = 9'd413;  // start of vertical synch pulse
  parameter VER_SYNC_END = 9'd414;  // end of vertical synch pulse
  parameter VER_SCAN_END = 9'd450;  // Last scan row in the frame
  parameter VER_DISP_CHR = 6'd25;   // Number of character rows displayed

  reg        cursor_on_v;
  reg        cursor_on_h;
  reg        video_on_v;
  reg        video_on_h;
  reg [9:0]  h_count;
  reg [8:0]  v_count;       // 0 to VER_SCAN_END
  reg [22:0] blink_count;

  // Character generator ROM
  wire        char_cs;
  wire        char_we;
  wire [11:0] char_addr;
  wire [7:0]  char_data_in;
  wire [7:0]  char_data_out;

  // Control registers
  wire [6:0] reg_hcursor; // 80 columns
  wire [4:0] reg_vcursor; // 25 rows
  wire [4:0] reg_voffset; // 25 rows

  // Video shift register
  reg [7:0] vga_shift;
  reg [2:0] vga_fg_colour;
  reg [2:0] vga_bg_colour;
  reg       cursor_on;
  wire      cursor_on1;
  reg       video_on;
  wire      video_on1;

  // vga character ram access bus
  reg   [6:0] col_addr;  // 0 to 79
  reg   [4:0] row_addr;  // 0 to 49 (25 * 2 -1)
  reg   [6:0] col1_addr; // 0 to 79
  reg   [4:0] row1_addr; // 0 to 49 (25 * 2 - 1)
  reg   [6:0] hor_addr;  // 0 to 79
  reg   [6:0] ver_addr;  // 0 to 124
  reg         vga0_we;
  reg         vga0_rw, vga1_rw, vga2_rw, vga3_rw, vga4_rw;
  reg         vga1_we;
  reg         vga2_we;
  reg         buff_we;
  reg   [7:0] buff_data_in;
  reg         attr_we;
  reg   [7:0] attr_data_in;
  reg  [10:0] buff_addr;
  reg  [10:0] attr0_addr;
  reg         attr0_we;
  reg  [10:0] buff0_addr;
  reg         buff0_we;
  reg  [10:0] attr_addr;
  wire        vga_cs;
  wire  [7:0] vga_data_out;
  wire  [7:0] attr_data_out;
  wire [10:0] vga_addr;  // 2K byte character buffer
  wire        a0;
  wire [10:0] vdu_addr1;
  wire        byte1;
  wire [15:0] out_data;
  wire [15:0] ext_attr, ext_buff;
  wire        fg_or_bg;

  // Character write handshake signals
  reg req_write; // request character write
  reg req_read;
  reg one_more_cycle;

  // Module instantiation
  char_rom vdu_char_rom (
    .clk   (vdu_clk),
    .rst   (vdu_rst),
    .cs    (char_cs),
    .we    (char_we),
    .addr  (char_addr),
    .wdata (char_data_in),
    .rdata (char_data_out)
  );

  ram_2k char_buff_ram (
    .clk   (vdu_clk),
    .rst   (vdu_rst),
    .cs    (vga_cs),
    .we    (buff_we),
    .addr  (buff_addr),
    .wdata (buff_data_in),
    .rdata (vga_data_out)
  );

  ram_2k_attr attr_buff_ram (
    .clk   (vdu_clk),
    .rst   (vdu_rst),
    .cs    (vga_cs),
    .we    (attr_we),
    .addr  (attr_addr),
    .wdata (attr_data_in),
    .rdata (attr_data_out)
  );

  // Assignments
  assign video_on1  = video_on_h && video_on_v;
  assign cursor_on1 = cursor_on_h && cursor_on_v;
  assign char_cs    = 1'b1;
  assign char_we    = 1'b1;
  assign char_data_in = 8'b0;
  assign char_addr  = { vga_data_out, v_count[3:0] };
  assign vga_addr   = { 4'b0, hor_addr} + { ver_addr, 4'b0 };
  assign a0         = vdu_addr[0];
  assign vdu_addr1  = vdu_addr[11:1] + 11'd1;
  assign byte1      = byte_m || (vdu_addr == 12'hfff);
  assign ready      = !req_write && !req_read;
  assign out_data   = a0 ? (byte_m ? ext_attr : {vga_data_out, attr_data_out} ) 
                     : (byte_m ? ext_buff : {attr_data_out, vga_data_out} );
  assign ext_buff   = { {8{vga_data_out[7]}}, vga_data_out };
  assign ext_attr   = { {8{attr_data_out[7]}}, attr_data_out };

  assign vga_cs     = 1'b1;

  // Old control registers
  assign reg_hcursor = 7'b0;
  assign reg_vcursor = 5'd0;
  assign reg_voffset = 5'd0;

  assign fg_or_bg    = vga_shift[7] ^ cursor_on;

  // Behaviour

  // CPU write interface
  always @(negedge vdu_clk)
    if (vdu_rst)
      begin
        attr0_addr    <= 11'b0;
        attr0_we      <= 1'b1;
        attr_data_in  <= 8'h0;
        buff0_addr    <= 11'b0;
        buff0_we      <= 1'b1;
        buff_data_in  <= 8'h0;
      end
    else
      begin
        if (vdu_cs && ready)
          begin
            attr0_addr   <= vdu_addr[11:1];
            attr0_we     <= vdu_we | (byte1 & ~a0);
            attr_data_in <= a0 ? wr_data[7:0] : wr_data[15:8];
            buff0_addr   <= (a0 && !byte1) ? vdu_addr1 : vdu_addr[11:1];
            buff0_we     <= vdu_we | (byte1 & a0);
            buff_data_in <= a0 ? wr_data[15:8] : wr_data[7:0];
          end
      end

  always @(negedge cpu_clk)
    if (vdu_rst)
      begin
        req_write <= 1'b0;
        req_read  <= 1'b0;
        one_more_cycle <= 1'b0;
      end
    else
      begin
        if (vdu_cs && !vdu_we && ready) req_write <= 1'b1;
        else if (req_write && !vga2_we) req_write <= 1'b0;
        if (vdu_cs && vdu_we)
          begin
            if (ready) 
              begin
                req_read <= 1'b1;
                if (vga2_rw) one_more_cycle <= 1'b1;
                else one_more_cycle <= 1'b0;
              end
            else 
              if (req_read && vga4_rw) 
                begin
                  if (one_more_cycle) one_more_cycle <= 1'b0;
                  else req_read <= 1'b0;
                end
          end
      end

  // Sync generation & timing process
  // Generate horizontal and vertical timing signals for video signal
  always @(negedge vdu_clk) 
    if (vdu_rst)
      begin
        h_count     <= 10'b0;
        horiz_sync  <= 1'b1;
        v_count     <= 9'b0;
        vert_sync   <= 1'b1;
        video_on_h  <= 1'b1;
        video_on_v  <= 1'b1;
        cursor_on_h <= 1'b0;
        cursor_on_v <= 1'b0;
        blink_count <= 22'b0;
      end
    else
      begin
        h_count    <= (h_count==HOR_SCAN_END) ? 10'b0 : h_count + 10'b1;
        horiz_sync <= (h_count==HOR_SYNC_BEG) ? 1'b0 
                    : ((h_count==HOR_SYNC_END) ? 1'b1 : horiz_sync);
        v_count    <= (v_count==VER_SCAN_END && h_count==HOR_SCAN_END) ? 9'b0 
                    : ((h_count==HOR_SYNC_END) ? v_count + 9'b1 : v_count);
        vert_sync  <= (v_count==VER_SYNC_BEG) ? 1'b0 
                    : ((v_count==VER_SYNC_END) ? 1'b1 : vert_sync);
        video_on_h <= (h_count==HOR_SCAN_END) ? 1'b1 
                    : ((h_count==HOR_DISP_END) ? 1'b0 : video_on_h);
        video_on_v <= (v_count==VER_SYNC_BEG) ? 1'b1 
                    : ((v_count==VER_DISP_END) ? 1'b0 : video_on_v);
        cursor_on_h <= (h_count[9:3] == reg_hcursor[6:0]);
        cursor_on_v <= (v_count[8:4] == reg_vcursor[4:0]);
        blink_count <= blink_count + 22'd1;
      end

  // Video memory access
  always @(negedge vdu_clk)
    if (vdu_rst)
      begin
        vga0_we <= 1'b0;
        vga0_rw <= 1'b1;
        row_addr <= 5'b0;
        col_addr <= 7'b0;

        vga1_we  <= 1'b0;
        vga1_rw  <= 1'b1;
        row1_addr <= 5'b0;
        col1_addr <= 7'b0;

        vga2_we  <= 1'b0;
        vga2_rw  <= 1'b0;
        vga3_rw  <= 1'b0;
        vga4_rw  <= 1'b0;
        ver_addr <= 7'b0;
        hor_addr <= 7'b0;

        buff_addr <= 10'b0;
        attr_addr <= 10'b0;
        buff_we   <= 1'b1;
        attr_we   <= 1'b1;

        rd_data   <= 16'd0;
      end
    else
      begin
        // on h_count = 0 initiate character write
        // all other cycles are reads
        case (h_count[2:0])
          3'b000:   // pipeline character write
            begin 
              vga0_we <= !req_write;
              vga0_rw <= 1'b1;
            end
          default:  // other 6 cycles free
            begin
              vga0_we <= 1'b1;
              vga0_rw <= 1'b0;
              col_addr <= h_count[9:3];
              row_addr <= v_count[8:4] + reg_voffset[4:0];
            end
        endcase

        // on vdu_clk + 1 round off row address
        // row1_addr = (row_addr % 80)
        vga1_we <= vga0_we;
        vga1_rw <= vga0_rw;
        row1_addr <= (row_addr < VER_DISP_CHR) ? row_addr
                    : row_addr - VER_DISP_CHR;
        col1_addr <= col_addr;

        // on vdu_clk + 2 calculate vertical address
        // ver_addr = (row_addr % 80) x 5
        vga2_we <= vga1_we;
        vga2_rw <= vga1_rw;
        ver_addr <= { 2'b00, row1_addr } + { row1_addr, 2'b00 }; // x5
        hor_addr <= col1_addr;

        // on vdu_clk + 3 calculate memory address
        // vga_addr = (row_addr % 80) * 80 + hor_addr
        buff_addr <= vga2_rw ? buff0_addr : vga_addr;
        attr_addr <= vga2_rw ? attr0_addr : vga_addr;
        buff_we   <= vga2_rw ? (buff0_we | vga2_we) : 1'b1;
        attr_we   <= vga2_rw ? (attr0_we | vga2_we) : 1'b1;
        vga3_rw   <= vga2_rw;

        rd_data   <= vga3_rw ? out_data : rd_data;
        vga4_rw   <= vga3_rw;
      end

  // Video shift register
  always @(negedge vdu_clk)
    if (vdu_rst)
      begin
        video_on      = 1'b0;
        cursor_on     = 1'b0;
        vga_bg_colour = 3'b000;
        vga_fg_colour = 3'b111;
        vga_shift     = 8'b00000000;
        vga_red_o     = 1'b0;
        vga_green_o   = 1'b0;
        vga_blue_o    = 1'b0;
      end
    else
      begin
        if (h_count[2:0] == 3'b000)
          begin
            video_on  = video_on1;
            cursor_on = (cursor_on1 | attr_data_out[3]) & blink_count[22];
            vga_fg_colour = attr_data_out[2:0];
            vga_bg_colour = attr_data_out[6:4];
            if (!attr_data_out[7]) vga_shift = char_data_out;
            else
              case (v_count[3:2])
                2'b00: vga_shift = { {4{vga_data_out[0]}}, {4{vga_data_out[1]}} };
                2'b01: vga_shift = { {4{vga_data_out[2]}}, {4{vga_data_out[3]}} };
                2'b10: vga_shift = { {4{vga_data_out[4]}}, {4{vga_data_out[5]}} };
                default: vga_shift = { {4{vga_data_out[6]}}, {4{vga_data_out[7]}} };
              endcase
          end
        else vga_shift = { vga_shift[6:0], 1'b0 };

        //
        // Colour mask is
        //  7  6  5  4  3  2  1  0
        //  X BG BB BR  X FG FB FR
        //
        vga_red_o    = fg_or_bg ? video_on & vga_fg_colour[0] 
                                : video_on & vga_bg_colour[0];
        vga_green_o  = fg_or_bg ? video_on & vga_fg_colour[1]
                                : video_on & vga_bg_colour[1];
        vga_blue_o   = fg_or_bg ? video_on & vga_fg_colour[2]
                                : video_on & vga_bg_colour[2];
      end
endmodule
