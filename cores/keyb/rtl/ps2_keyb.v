/*
 *  PS2 Wishbone 8042 compatible keyboard controller
 *
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
 *  adapted from the opencores keyboard controller from John Clayton
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

//`include "defines.v"

`timescale 1ns/100ps

`define TOTAL_BITS   11
`define RELEASE_CODE 16'hF0
`define LEFT_SHIFT   16'h12
`define RIGHT_SHIFT  16'h59

module ps2_keyb (
`ifdef DEBUG
    output           rx_output_strobe,
    output           released,
    output           rx_shifting_done,
`endif
    // Wishbone slave interface
    input            wb_clk_i,
    input            wb_rst_i,
    output reg [7:0] wb_dat_o,   // scancode
    output reg       wb_tgc_o,   // intr

    // PS2 PAD signals
    inout            ps2_clk_,
    inout            ps2_data_
  );

  // Parameter declarations
  // The timer value can be up to (2^bits) inclusive.
  parameter TIMER_60USEC_VALUE_PP = 1920; // Number of sys_clks for 60usec.
  parameter TIMER_60USEC_BITS_PP  = 11;   // Number of bits needed for timer
  parameter TIMER_5USEC_VALUE_PP  = 186;  // Number of sys_clks for debounce
  parameter TIMER_5USEC_BITS_PP   = 8;    // Number of bits needed for timer
  parameter TRAP_SHIFT_KEYS_PP    = 0;    // Default: No shift key trap.

  // State encodings, provided as parameters
  // for flexibility to the one instantiating the module.
  // In general, the default values need not be changed.

  // State "m1_rx_clk_l" has been chosen on purpose.  Since the input
  // synchronizing flip-flops initially contain zero, it takes one clk
  // for them to update to reflect the actual (idle = high) status of
  // the I/O lines from the keyboard.  Therefore, choosing 0 for m1_rx_clk_l
  // allows the state machine to transition to m1_rx_clk_h when the true
  // values of the input signals become present at the outputs of the
  // synchronizing flip-flops.  This initial transition is harmless, and it
  // eliminates the need for a "reset" pulse before the interface can operate.
  parameter m1_rx_clk_h = 1;
  parameter m1_rx_clk_l = 0;
  parameter m1_rx_falling_edge_marker = 13;
  parameter m1_rx_rising_edge_marker = 14;
  parameter m1_tx_force_clk_l = 3;
  parameter m1_tx_first_wait_clk_h = 10;
  parameter m1_tx_first_wait_clk_l = 11;
  parameter m1_tx_reset_timer = 12;
  parameter m1_tx_wait_clk_h = 2;
  parameter m1_tx_clk_h = 4;
  parameter m1_tx_clk_l = 5;
  parameter m1_tx_wait_keyboard_ack = 6;
  parameter m1_tx_done_recovery = 7;
  parameter m1_tx_error_no_keyboard_ack = 8;
  parameter m1_tx_rising_edge_marker = 9;

  // Nets and registers
  wire rx_output_event;
  wire tx_shifting_done;
  wire timer_60usec_done;
  wire timer_5usec_done;
`ifndef DEBUG
  wire rx_output_strobe;
  wire rx_shifting_done;
  wire released;
`endif
  wire [6:0] xt_code;

  reg [3:0] bit_count;
  reg [3:0] m1_state;
  reg [3:0] m1_next_state;

  reg ps2_clk_hi_z;     // Without keyboard, high Z equals 1 due to pullups.
  reg ps2_data_hi_z;    // Without keyboard, high Z equals 1 due to pullups.
  reg ps2_clk_s;        // Synchronous version of this input
  reg ps2_data_s;       // Synchronous version of this input

  reg enable_timer_60usec;
  reg enable_timer_5usec;
  reg [TIMER_60USEC_BITS_PP-1:0] timer_60usec_count;
  reg [TIMER_5USEC_BITS_PP-1:0] timer_5usec_count;

  reg [`TOTAL_BITS-1:0] q;

  reg hold_released;    // Holds prior value, cleared at rx_output_strobe

  // Module instantiation
  translate_8042 tr0 (
//    .clk     (wb_clk_i),
    .at_code (q[7:1]),
    .xt_code (xt_code)
  );

  // Continuous assignments
  // This signal is high for one clock at the end of the timer count.
  assign rx_shifting_done = (bit_count == `TOTAL_BITS);
  assign tx_shifting_done = (bit_count == `TOTAL_BITS-1);

  assign rx_output_event  = (rx_shifting_done
                          && ~released
                          );
  assign rx_output_strobe = (rx_shifting_done
                          && ~released
                          && ( (TRAP_SHIFT_KEYS_PP == 0)
                               || ( (q[8:1] != `RIGHT_SHIFT)
                                    &&(q[8:1] != `LEFT_SHIFT)
                                  )
                             )
                          );

  assign ps2_clk_  = ps2_clk_hi_z  ? 1'bZ : 1'b0;
  assign ps2_data_ = ps2_data_hi_z ? 1'bZ : 1'b0;

  assign timer_60usec_done =
    (timer_60usec_count == (TIMER_60USEC_VALUE_PP - 1));
  assign timer_5usec_done = (timer_5usec_count == TIMER_5USEC_VALUE_PP - 1);

  // Create the signals which indicate special scan codes received.
  // These are the "unlatched versions."
  //assign extended = (q[8:1] == `EXTEND_CODE) && rx_shifting_done;
  assign released = (q[8:1] == `RELEASE_CODE) && rx_shifting_done;

  // Behaviour
  // wb_tgc_o
  always @(posedge wb_clk_i)
    wb_tgc_o <= wb_rst_i ? 1'b0 : rx_output_strobe;

  // This is the shift register
  always @(posedge wb_clk_i)
    if (wb_rst_i) q <= 0;
    //  else if (((m1_state == m1_rx_clk_h) && ~ps2_clk_s)
    else if ( (m1_state == m1_rx_falling_edge_marker)
             ||(m1_state == m1_tx_rising_edge_marker) )
        q <= {ps2_data_s,q[`TOTAL_BITS-1:1]};

  // This is the 60usec timer counter
  always @(posedge wb_clk_i)
    if (~enable_timer_60usec) timer_60usec_count <= 0;
    else if (~timer_60usec_done) timer_60usec_count <= timer_60usec_count + 10'd1;

  // This is the 5usec timer counter
  always @(posedge wb_clk_i)
    if (~enable_timer_5usec) timer_5usec_count <= 0;
    else if (~timer_5usec_done) timer_5usec_count <= timer_5usec_count + 6'd1;

  // Input "synchronizing" logic -- synchronizes the inputs to the state
  // machine clock, thus avoiding errors related to
  // spurious state machine transitions.
  //
  // Since the initial state of registers is zero, and the idle state
  // of the ps2_clk and ps2_data lines is "1" (due to pullups), the
  // "sense" of the ps2_clk_s signal is inverted from the true signal.
  // This allows the state machine to "come up" in the correct
  always @(posedge wb_clk_i)
  begin
    ps2_clk_s <= ps2_clk_;
    ps2_data_s <= ps2_data_;
  end

  // State transition logic
  always @(m1_state
           or q
           or tx_shifting_done
           or ps2_clk_s
           or ps2_data_s
           or timer_60usec_done
           or timer_5usec_done
          )
    begin : m1_state_logic

    // Output signals default to this value,
    //  unless changed in a state condition.
    ps2_clk_hi_z  <= 1;
    ps2_data_hi_z <= 1;
    enable_timer_60usec <= 0;
    enable_timer_5usec  <= 0;

    case (m1_state)

      m1_rx_clk_h :
      begin
        enable_timer_60usec <= 1;
        if (~ps2_clk_s)
          m1_next_state <= m1_rx_falling_edge_marker;
        else m1_next_state <= m1_rx_clk_h;
      end

      m1_rx_falling_edge_marker :
      begin
        enable_timer_60usec <= 0;
        m1_next_state <= m1_rx_clk_l;
      end

      m1_rx_rising_edge_marker :
      begin
        enable_timer_60usec <= 0;
        m1_next_state <= m1_rx_clk_h;
      end

      m1_rx_clk_l :
      begin
        enable_timer_60usec <= 1;
        if (ps2_clk_s)
          m1_next_state <= m1_rx_rising_edge_marker;
        else m1_next_state <= m1_rx_clk_l;
      end

      m1_tx_reset_timer :
      begin
        enable_timer_60usec <= 0;
        m1_next_state <= m1_tx_force_clk_l;
      end

      m1_tx_force_clk_l :
      begin
        enable_timer_60usec <= 1;
        ps2_clk_hi_z <= 0;  // Force the ps2_clk line low.
        if (timer_60usec_done)
          m1_next_state <= m1_tx_first_wait_clk_h;
        else m1_next_state <= m1_tx_force_clk_l;
      end

      m1_tx_first_wait_clk_h :
      begin
        enable_timer_5usec <= 1;
        ps2_data_hi_z <= 0;        // Start bit.
        if (~ps2_clk_s && timer_5usec_done)
          m1_next_state <= m1_tx_clk_l;
        else
          m1_next_state <= m1_tx_first_wait_clk_h;
      end

      // This state must be included because the device might possibly
      // delay for up to 10 milliseconds before beginning its clock pulses.
      // During that waiting time, we cannot drive the data (q[0]) because it
      // is possibly 1, which would cause the keyboard to abort its receive
      // and the expected clocks would then never be generated.
      m1_tx_first_wait_clk_l :
      begin
        ps2_data_hi_z <= 0;
        if (~ps2_clk_s) m1_next_state <= m1_tx_clk_l;
        else m1_next_state <= m1_tx_first_wait_clk_l;
      end

      m1_tx_wait_clk_h :
      begin
        enable_timer_5usec <= 1;
        ps2_data_hi_z <= q[0];
        if (ps2_clk_s && timer_5usec_done)
          m1_next_state <= m1_tx_rising_edge_marker;
        else
          m1_next_state <= m1_tx_wait_clk_h;
      end

      m1_tx_rising_edge_marker :
      begin
        ps2_data_hi_z <= q[0];
        m1_next_state <= m1_tx_clk_h;
      end

      m1_tx_clk_h :
      begin
        ps2_data_hi_z <= q[0];
        if (tx_shifting_done) m1_next_state <= m1_tx_wait_keyboard_ack;
        else if (~ps2_clk_s) m1_next_state <= m1_tx_clk_l;
        else m1_next_state <= m1_tx_clk_h;
      end

      m1_tx_clk_l :
      begin
        ps2_data_hi_z <= q[0];
        if (ps2_clk_s) m1_next_state <= m1_tx_wait_clk_h;
        else m1_next_state <= m1_tx_clk_l;
      end

      m1_tx_wait_keyboard_ack :
      begin
        if (~ps2_clk_s && ps2_data_s)
          m1_next_state <= m1_tx_error_no_keyboard_ack;
        else if (~ps2_clk_s && ~ps2_data_s)
          m1_next_state <= m1_tx_done_recovery;
        else m1_next_state <= m1_tx_wait_keyboard_ack;
      end

      m1_tx_done_recovery :
      begin
        if (ps2_clk_s && ps2_data_s) m1_next_state <= m1_rx_clk_h;
        else m1_next_state <= m1_tx_done_recovery;
      end

      m1_tx_error_no_keyboard_ack :
      begin
        if (ps2_clk_s && ps2_data_s) m1_next_state <= m1_rx_clk_h;
        else m1_next_state <= m1_tx_error_no_keyboard_ack;
      end

      default : m1_next_state <= m1_rx_clk_h;
    endcase
  end

  // State register
  always @(posedge wb_clk_i)
  begin : m1_state_register
    if (wb_rst_i) m1_state <= m1_rx_clk_h;
    else m1_state <= m1_next_state;
  end

  // wb_dat_o - scancode
  always @(posedge wb_clk_i)
    if (wb_rst_i) wb_dat_o <= 8'b0;
    else wb_dat_o <=
      (rx_output_strobe && q[8:1]) ? (q[8] ? q[8:1]
        : {hold_released,xt_code})
     : wb_dat_o;

  // This is the bit counter
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i
         || rx_shifting_done
         || (m1_state == m1_tx_wait_keyboard_ack) // After tx is done.
         ) bit_count <= 0;  // normal reset
      else if (timer_60usec_done
               && (m1_state == m1_rx_clk_h)
               && (ps2_clk_s)
              ) bit_count <= 0;  // rx watchdog timer reset
      else if ( (m1_state == m1_rx_falling_edge_marker) // increment for rx
              ||(m1_state == m1_tx_rising_edge_marker)  // increment for tx
              )
        bit_count <= bit_count + 4'd1;
  end

  // Store the special scan code status bits
  // Not the final output, but an intermediate storage place,
  // until the entire set of output data can be assembled.
  always @(posedge wb_clk_i)
    if (wb_rst_i || rx_output_event) hold_released <= 0;
    else if (rx_shifting_done && released) hold_released <= 1;

endmodule

module translate_8042 (
  //  input            clk,
    input      [6:0] at_code,
    output     [6:0] xt_code
  );

  // Registers, nets and parameters
  reg [7:0] rom[0:2**7-1];

  assign xt_code = rom[at_code][6:0];

  // Behaviour
/*
  always @(posedge clk)
    xt_code <= rom[at_code][6:0];
*/
  initial $readmemh("xt_codes.dat", rom);
endmodule
