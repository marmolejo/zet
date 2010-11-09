/*
 *  PS2 Mouse without FIFO buffer
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

module ps2_mouse_nofifo (
    input clk,
    input reset,

    input  [7:0] writedata,   // data to send
    input        write,       // signal to send it

    output [7:0] readdata,    // data read
    output       irq,         // signal data has arrived

    output command_was_sent,
    output error_sending_command,
    output buffer_overrun_error,

    inout ps2_clk,
    inout ps2_dat
  );

  // Unused outputs
  wire start_receiving_data;
  wire wait_for_incoming_data;

  // --------------------------------------------------------------------
  // Internal Modules
  // --------------------------------------------------------------------
  ps2_mouse mouse (
    .clk   (clk),
    .reset (reset),

    .the_command  (writedata),
    .send_command (write),

    .received_data    (readdata),
    .received_data_en (irq),

    .command_was_sent              (command_was_sent),
    .error_communication_timed_out (error_sending_command),
    .start_receiving_data          (start_receiving_data),
    .wait_for_incoming_data        (wait_for_incoming_data),

    .ps2_clk (ps2_clk),
    .ps2_dat (ps2_dat)
  );

  // Continous assignments
  assign buffer_overrun_error = error_sending_command;

endmodule
