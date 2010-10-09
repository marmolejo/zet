/*
 *  Sound module
 *  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

// --------------------------------------------------------------------
// Description: Sound module.  This is NOT a sound blaster emulator.
// This module produces simple sounds by implementing a simple interface,
// The user simply writes a byte of data to the left and/or right channels.
// Then poll the status register which will raise a flag when ready for the
// next byte of data. Alternatively, it can generate an interupt to request
// the next byte.
//
// Sound uses 16 I/O addresses 0x0nn0 to 0x0nnF, nn can be anything
//
// I/O Address  Description
// -----------  ------------------
//      0x0210  Left  Channel
//      0x0211  Right Channel
//      0x0212  High byte of timing increment
//      0x0213  Low byte of timing increment
//      0x0215  Control, 0x01 to enable interupt, 0x00 for polled mode
//      0x0217  Status, 0x80 when ready for next data, else 0x00
//
// --------------------------------------------------------------------

module sound (
    input         wb_clk_i,
    input         wb_rst_i,
    input  [ 2:0] wb_adr_i,
    input  [ 1:0] wb_sel_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    output reg    wb_ack_o,

    input  dac_clk,
    output audio_l,
    output audio_r
  );

  // --------------------------------------------------------------------
  // Wishbone Handling
  // --------------------------------------------------------------------
  reg   [7:0]  sb_dat_o;
  wire  [3:0]  sb_adr_i   = {wb_adr_i, wb_sel_i[1]};
  wire  [7:0]  sb_dat_i   = wb_sel_i[0] ? wb_dat_i[7:0] : wb_dat_i[15:8]; // 16 to 8 bit
  assign       wb_dat_o   = {sb_dat_o, sb_dat_o};
  wire        wb_ack_i   = wb_stb_i &  wb_cyc_i;    // Immediate ack
  wire      wr_command = wb_ack_i &  wb_we_i;     // Wishbone write access, Singal to send
  wire      rd_command = wb_ack_i & ~wb_we_i;     // Wishbone write access, Singal to send

  always @(posedge wb_clk_i or posedge wb_rst_i) begin  // Synchrounous
      if(wb_rst_i) wb_ack_o <= 1'b0;
      else         wb_ack_o <= wb_ack_i & ~wb_ack_o; // one clock delay on acknowledge output
  end

  // --------------------------------------------------------------------
  // The following table lists the functions of the I/O ports:
  // I/O Address   Description Access
  // -----------   -------------------
  //    Base + 0   Left  channel data, write only
  //    Base + 1   Right channel data, write only
  //    Base + 2   High byte for timer, write only
  //    Base + 3   Low byte for timer, write only
  //    Base + 5   Control, write only
  //    Base + 7   Status, read only
  // --------------------------------------------------------------------
  `define REG_CHAN01      4'h0    // W  - Channel 1
  `define REG_CHAN02      4'h1    // W  - Channel 1
  `define REG_TIMERH      4'h2    // W  - Timer increment high byte
  `define REG_TIMERL      4'h3    // W  - Timer increment low byte
  `define REG_CONTRL      4'h5    // W  - Control
  `define REG_STATUS      4'h7    // R  - Status
  // --------------------------------------------------------------------

  // --------------------------------------------------------------------
  // DefaultTime Constant
  // --------------------------------------------------------------------
  `define DSP_DEFAULT_RATE  16'd671    // Default sampling rate is 8Khz

  // --------------------------------------------------------------------
  // Sound Blaster Register behavior
  // --------------------------------------------------------------------
  reg         start;      // Start the timer
  reg       timeout;    // Timer has timed out
  reg [19:0]  timer;      // DAC output timer register
  reg [15:0]  time_inc;    // DAC output time increment
  wire [7:0]  TMR_STATUS = {timeout, 7'h00};

  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous Logic
    if(wb_rst_i) begin
      sb_dat_o  <=  8'h00;                 // Default value
    end
    else begin
    if(rd_command) begin
          case(sb_adr_i)                                 // Determine which register was read
              `REG_STATUS: sb_dat_o <= TMR_STATUS;    // DSP Read status
        `REG_TIMERH: sb_dat_o <= time_inc[15:8];   // Read back the timing register
        `REG_TIMERL: sb_dat_o <= time_inc[ 7:0];  // Read back the timing register
              default:     sb_dat_o <= 8'h00;        // Default
          endcase                                     // End of case
    end
    end                          // End of Reset if
  end                            // End Synchrounous always

  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous Logic

    if(wb_rst_i) begin
      dsp_audio_l <=  8'h80;               // default is equivalent to 1/2
      dsp_audio_r <=  8'h80;               // default is equivalent to 1/2
      start       <=  1'b0;                // Timer not on
      timeout     <=  1'b0;                // Not timed out
      time_inc    <=  `DSP_DEFAULT_RATE;        // Default value
    end
    else begin

      if(wr_command) begin                           // If a write was requested
          case(sb_adr_i)                               // Determine which register was writen to
        `REG_CHAN01: begin
          dsp_audio_l <= sb_dat_i;        // Get the user data or data
          start    <= 1'b1;
          timeout      <= 1'b0;
        end
        `REG_CHAN02: begin
          dsp_audio_r <= sb_dat_i;        // Get the user data or data
          start    <= 1'b1;
          timeout      <= 1'b0;
        end
        `REG_TIMERH: time_inc[15:8] <= sb_dat_i;  // Get the user data or data
        `REG_TIMERL: time_inc[ 7:0] <= sb_dat_i;  // Get the user data or data
              default: ;                    // Default value
          endcase                                 // End of case
      end                          // End of Write Command if

    if(timed_out) begin
      start   <= 1'b0;
      timeout  <= 1'b1;
    end

    end                          // End of Reset if
  end                            // End Synchrounous always

  // --------------------------------------------------------------------
  // Audio Timer interrupt Generation Section
  // DAC Clock set to system clock which is 12,500,000Hz
  // Interval = DAC_ClK / Incr = 12,500,000 / (1048576 / X ) = 8000Hz
  // X = 1048576 / (12,500,000 / 8000) = 1048576 / 1562.5
  // X = 671
  // --------------------------------------------------------------------
  wire timed_out = timer[19];
  always @(posedge dac_clk) begin
    if(wb_rst_i) begin
      timer <= 20'd0;
    end
    else begin
    if(start) timer <= timer + time_inc;
    else      timer <= 20'd0;
    end
  end

  // --------------------------------------------------------------------
  // PWM CLock Generation Section:
  // We need to divide down the clock for PWM, dac_clk = 12.5Mhz
  // then 12,500,000 / 512 = 24,414Hz which is a good sampling rate for audio
  // 0 =   2
  // 1 =   4
  // 2 =   8  1,562,500Hz
  // 3 =  16
  // 4 =  32
  // 5 =  64
  // 6 = 128
  // 7 = 256
  // 8 = 512  24,414Hz
  // --------------------------------------------------------------------
    wire       pwm_clk = clkdiv[2];
    reg  [8:0] clkdiv;
    always @(posedge dac_clk) clkdiv <= clkdiv + 9'd1;

  // --------------------------------------------------------------------
  // Audio Generation Section
  // --------------------------------------------------------------------
    reg [7:0] dsp_audio_l;
    reg [7:0] dsp_audio_r;
    sound_dac8 left (pwm_clk, dsp_audio_l, audio_l);  // 8 bit pwm DAC
    sound_dac8 right(pwm_clk, dsp_audio_r, audio_r);  // 8 bit pwm DAC

endmodule
