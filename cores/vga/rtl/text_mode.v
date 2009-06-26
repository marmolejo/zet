/*
 * Pipeline description
 *  h_count[2:0]
 *   000
 *   001  col_addr, row_addr
 *   010  ver_addr, hor_addr
 *   011  csr_addr_o
 *   100  sram_addr_
 *   101  csr_dat_o
 *   110  char_data_out, attr_data_out
 *   111  vga_shift
 *   000  vga_blue_o <= vga_shift[7]
 */

module text_mode (
    input clk,
    input rst,

    // CSR slave interface for reading
    output reg [16:1] csr_adr_o,
    input      [15:0] csr_dat_i,

    input [9:0] h_count,
    input [9:0] v_count,
    input       horiz_sync_i,
    input       video_on_h_i,
    output      video_on_h_o,

    output reg [1:0] vga_red_o,
    output reg [1:0] vga_green_o,
    output reg [1:0] vga_blue_o,
    output           horiz_sync_o
  );

  // Registers and nets
  reg  [ 6:0] col_addr;
  reg  [ 4:0] row_addr;
  reg  [ 6:0] hor_addr;
  reg  [ 6:0] ver_addr;
  wire [10:0] vga_addr;

  wire [11:0] char_addr;
  wire [ 7:0] char_data_out;
  reg  [ 7:0] attr_data_out;

  reg  [5:0] pipe;
  wire       load_shift;

  reg  [6:0] video_on_h;
  reg  [6:0] horiz_sync;

  wire fg_or_bg;
  wire brown_bg;
  wire brown_fg;

  reg [7:0] vga_shift;
  reg [2:0] vga_fg_colour;
  reg [2:0] vga_bg_colour;
  reg       intense;

  // Module instances
  char_rom vdu_char_rom (
    .clk  (clk),
    .addr (char_addr),
    .q    (char_data_out)
  );

  // Continuous assignments
  assign vga_addr     = { 4'b0, hor_addr } + { ver_addr, 4'b0 };
  assign char_addr    = { csr_dat_i[7:0], v_count[3:0] };
  assign load_shift   = pipe[5];
  assign video_on_h_o = video_on_h[6];
  assign horiz_sync_o = horiz_sync[6];

  assign fg_or_bg = vga_shift[7];
  assign brown_fg = (vga_fg_colour==3'd6) && !intense;
  assign brown_bg = (vga_bg_colour==3'd6);

  // Behaviour
  // Address generation
  always @(posedge clk)
    if (rst)
      begin
        col_addr  <= 7'h0;
        row_addr  <= 5'h0;
        ver_addr  <= 7'h0;
        hor_addr  <= 7'h0;
        csr_adr_o <= 16'h0;
      end
    else
      begin
        // h_count[2:0] == 001
        col_addr  <= h_count[9:3];
        row_addr  <= v_count[8:4];

        // h_count[2:0] == 010
        ver_addr  <= { 2'b00, row_addr } + { row_addr, 2'b00 };
        // ver_addr = row_addr x 5
        hor_addr  <= col_addr;

        // h_count[2:0] == 011
        // vga_addr = row_addr * 80 + hor_addr
        csr_adr_o <= { 5'h0, vga_addr };
      end

  // Pipeline count
  always @(posedge clk)
    pipe <= rst ? 6'b0 : { pipe[4:0], (h_count[2:0]==3'b0) };

  // attr_data_out
  always @(posedge clk) attr_data_out <= csr_dat_i[15:8];

  // video_on_h
  always @(posedge clk)
    video_on_h <= rst ? 7'b0 : { video_on_h[5:0], video_on_h_i };

  // horiz_sync
  always @(posedge clk)
    horiz_sync <= rst ? 7'b0 : { horiz_sync[5:0], horiz_sync_i };

  // Video shift register
  always @(posedge clk)
    if (rst)
      begin
        vga_fg_colour <= 3'b0;
        vga_bg_colour <= 3'b0;
        intense       <= 1'b0;
        vga_shift     <= 8'h0;
      end
    else
      if (load_shift)
        begin
          vga_fg_colour <= attr_data_out[2:0];
          vga_bg_colour <= attr_data_out[6:4];
          intense       <= attr_data_out[3];
          vga_shift     <= char_data_out;
        end
      else vga_shift <= { vga_shift[6:0], 1'b0 };

  // VGA pad outputs
  always @(posedge clk)
    if (rst)
      begin
        vga_blue_o  <= 2'h0;
        vga_green_o <= 2'h0;
        vga_red_o   <= 2'h0;
      end
    else
      begin
        vga_blue_o  <= fg_or_bg ? { vga_fg_colour[0], intense }
                                : { vga_bg_colour[0], 1'b0 };
        // Green color exception with color brown
        // http://en.wikipedia.org/wiki/Color_Graphics_Adapter#With_an_RGBI_monitor
        vga_green_o <= fg_or_bg ? (brown_fg ? 2'b01 : { vga_fg_colour[1], intense })
                     : (brown_bg ? 2'b01 : { vga_bg_colour[1], 1'b0 });
        vga_red_o   <= fg_or_bg ? { vga_fg_colour[2], intense }
                                : { vga_bg_colour[2], 1'b0 };
      end

endmodule
