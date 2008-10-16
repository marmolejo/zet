`timescale 1ns/10ps

//`include "defines.v"

module mem_ctrl (
`ifdef DEBUG
    output     [ 2:0] curr_st,
`endif
    // Wishbone signals
    input             clk_i,
    input             rst_i,
    input      [19:0] adr_i,
    input      [15:0] dat_i,
    output reg [15:0] dat_o,
    input             we_i,
    output reg        ack_o,
    input             stb_i,
    input             byte_i,

    // Pad signals
    output        sram_clk_,
    output [20:0] sram_flash_addr_,
    inout  [15:0] sram_flash_data_,
    output        sram_flash_oe_n_,
    output        sram_flash_we_n_,
    output [ 3:0] sram_bw_,
    output        sram_cen_,
    output        sram_adv_ld_n_,
    output        flash_ce2_
  );

  // Register and net declarations
  reg [15:0] ww;  // word to memory write
  reg [14:0] adr;
  reg [ 3:0] highad;
  reg [ 1:0] be;
  reg        wen;
  reg        sr_cen;
  reg        fl_ce;
  reg        adv_ld;
  reg [ 2:0] cs, ns;

  wire rom_area;
  wire a0;       // address 0 bit
  wire odd_word; // Word odd operation
  wire fl_sel;    // flash chip select
  wire sr_sel;    // sram chip select

  wire [15:0] bhr; // byte high read, sign extended
  wire [15:0] blr; // byte low read, sign extended
  wire [15:0] wr;  // word from memory read
  wire [14:0] adr1;
  wire [ 3:0] high;
  wire [15:0] wwc;

  // Declare the symbolic names for states
  parameter [2:0]
    adr_setup = 3'd0,
    cen_setup = 3'd1,
    brs_setup = 3'd2,
    dat_1     = 3'd3,
    dat_2     = 3'd4,
    wait_1    = 3'd5,
    datf_2    = 3'd6,
    ce_off    = 3'd7;

  // Continuous assignments
  assign sram_clk_        = !clk_i;
  assign sram_flash_oe_n_ = 1'b0;
  assign sram_flash_we_n_ = wen;
  assign sram_flash_data_ = ((cs==brs_setup || cs==dat_1 &&
                           odd_word) && we_i) ? ww : 16'hzzzz;
  assign sram_flash_addr_ = { 2'b0, highad, adr };
  assign sram_bw_         = { 2'b11, be };
  assign sram_cen_        = sr_cen;
  assign flash_ce2_       = fl_ce;
  assign sram_adv_ld_n_   = adv_ld;

  assign rom_area   = (adr_i[19:16]==4'hc || adr_i[19:16]==4'hf);
  assign a0         = adr_i[0];
  assign bhr        = { {8{wr[15]}}, wr[15:8] };
  assign blr        = { {8{wr[7]}},  wr[7:0] };
  assign wr         = sram_flash_data_;

  assign odd_word = a0 & !byte_i;
  assign fl_sel   = rom_area &  stb_i;
  assign sr_sel   = rom_area | !stb_i;
  assign adr1     = adr_i[15:1] + 15'd1;
  assign high     = rom_area ? { 3'b0, adr_i[17] }
                             : { adr_i[19:16] };
  assign wwc      = a0 ? { dat_i[7:0], dat_i[15:8] } : dat_i;

`ifdef DEBUG
  assign curr_st  = cs;
`endif

  // Behaviour
  // cs
  always @(posedge clk_i) cs <= rst_i ? ce_off : ns;

  // dat_o
  always @(posedge clk_i)
    dat_o <= (ns == dat_1 ? (byte_i ? (a0 ? bhr : blr)
                                    : (a0 ? { 8'd0, wr[15:8] } : wr))
           : (ns == dat_2 ? { wr[7:0], dat_o[7:0] }
           : (ns == datf_2 ? { wr[7:0], dat_o[7:0] } : dat_o)));

  always @(posedge clk_i)
    case (ns)
      default:
        begin
          adr    <= adr_i[15:1];
          highad <= high;
          be     <= byte_i ? (a0 ? 2'b01 : 2'b10)
                           : (a0 ? 2'b01 : 2'b00);
          ww     <= wwc;
          wen    <= !we_i | rom_area;
          sr_cen <= 1'b1;
          fl_ce  <= 1'b0;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      cen_setup:
        begin
          adr    <= adr_i[15:1];
          highad <= high;
          be     <= byte_i ? (a0 ? 2'b01 : 2'b10)
                           : (a0 ? 2'b01 : 2'b00);
          ww     <= wwc;
          wen    <= !we_i | rom_area;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      brs_setup:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= odd_word ? 2'b10 : 2'b00;
          ww     <= wwc;
          wen    <= odd_word ? !we_i : 1'b1;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      dat_1:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= 2'b00;
          ww     <= wwc;
          wen    <= 1'b1;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      dat_2:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= 2'b00;
          ww     <= wwc;
          wen    <= 1'b1;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      wait_1:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= 2'b00;
          ww     <= wwc;
          wen    <= 1'b1;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      datf_2:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= 2'b00;
          ww     <= wwc;
          wen    <= 1'b1;
          sr_cen <= sr_sel;
          fl_ce  <= fl_sel;
          adv_ld <= 1'b0;
          ack_o  <= 1'b0;
        end
      ce_off:
        begin
          adr    <= adr1;
          highad <= high;
          be     <= 2'b00;
          ww     <= wwc;
          wen    <= 1'b1;
          sr_cen <= 1'b1;
          fl_ce  <= 1'b0;
          adv_ld <= 1'b0;
          ack_o  <= 1'b1;
        end
    endcase

  // state machine
  always @(*)
    case (cs)
      default:   ns <= stb_i ? cen_setup : adr_setup;
      cen_setup: ns <= stb_i ? (rom_area ? dat_1 : brs_setup)
                             : adr_setup;
      brs_setup: ns <= stb_i ? dat_1 : adr_setup;
      dat_1:     ns <= stb_i ? (odd_word ? dat_2 : ce_off )
                             : adr_setup;
      dat_2:     ns <= stb_i ? (rom_area ? wait_1 : ce_off)
                             : adr_setup;
      wait_1:    ns <= stb_i ? datf_2 : adr_setup;
      datf_2:    ns <= stb_i ? ce_off : adr_setup;
      ce_off:    ns <= adr_setup;
    endcase

endmodule


