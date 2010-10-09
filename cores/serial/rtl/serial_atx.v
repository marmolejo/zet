/*
 *  RS-232 asynchronous TX module
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

module serial_atx (
    input        clk,
    input        txd_start,
    input        baud1tick,  // Desired baud rate
    input  [7:0] txd_data,
    output reg   txd,  // Put together the start, data and stop bits
    output       txd_busy
  );

  // Transmitter state machine
  parameter RegisterInputData = 1;  // in RegisterInputData mode, the input doesn't have to stay valid while the character is been transmitted
  reg [3:0] state;
  wire  BaudTick  = txd_busy ? baud1tick : 1'b0;
  wire  txd_ready;

  reg [7:0] txd_dataReg;

  // Continuous assignments
  assign txd_ready = (state==0);
  assign txd_busy  = ~txd_ready;

  always @(posedge clk) if(txd_ready & txd_start) txd_dataReg <= txd_data;
  wire [7:0] txd_dataD = RegisterInputData ? txd_dataReg : txd_data;

  always @(posedge clk)
  case(state)
    4'b0000: if(txd_start) state <= 4'b0001;
    4'b0001: if(BaudTick) state <= 4'b0100;
    4'b0100: if(BaudTick) state <= 4'b1000;  // start
    4'b1000: if(BaudTick) state <= 4'b1001;  // bit 0
    4'b1001: if(BaudTick) state <= 4'b1010;  // bit 1
    4'b1010: if(BaudTick) state <= 4'b1011;  // bit 2
    4'b1011: if(BaudTick) state <= 4'b1100;  // bit 3
    4'b1100: if(BaudTick) state <= 4'b1101;  // bit 4
    4'b1101: if(BaudTick) state <= 4'b1110;  // bit 5
    4'b1110: if(BaudTick) state <= 4'b1111;  // bit 6
    4'b1111: if(BaudTick) state <= 4'b0010;  // bit 7
    4'b0010: if(BaudTick) state <= 4'b0011;  // stop1
    4'b0011: if(BaudTick) state <= 4'b0000;  // stop2
    default: if(BaudTick) state <= 4'b0000;
  endcase

  reg muxbit;      // Output mux
  always @( * )
  case(state[2:0])
    3'd0: muxbit <= txd_dataD[0];
    3'd1: muxbit <= txd_dataD[1];
    3'd2: muxbit <= txd_dataD[2];
    3'd3: muxbit <= txd_dataD[3];
    3'd4: muxbit <= txd_dataD[4];
    3'd5: muxbit <= txd_dataD[5];
    3'd6: muxbit <= txd_dataD[6];
    3'd7: muxbit <= txd_dataD[7];
  endcase

  always @(posedge clk) txd <= (state<4) | (state[3] & muxbit);  // register the output to make it glitch free

endmodule

