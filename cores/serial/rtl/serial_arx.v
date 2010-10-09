/*
 *  RS-232 asynchronous RX module
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

module serial_arx (
    input  clk,
    input  rxd,
    input  baud8tick, // Desired baud rate

    output reg [7:0] rxd_data,
    output reg       rxd_data_ready, // on clock pulse when rxd_data is valid

    // We also detect if a gap occurs in the received stream of
    // characters whuich can be useful if multiple characters are
    // sent in burst so that multiple characters can be treated as a "packet"
    output reg rxd_endofpacket,  // one clock pulse, when no more data
                             // is received (rxd_idle is going high)
    output rxd_idle  // no data is being received
  );

  reg [1:0] rxd_sync_inv;  // we invert rxd, so that the idle becomes "0", to prevent a phantom character to be received at startup
  always @(posedge clk) if(baud8tick) rxd_sync_inv <= {rxd_sync_inv[0], ~rxd};

  reg [1:0] rxd_cnt_inv;
  reg rxd_bit_inv;

  always @(posedge clk)
  if(baud8tick) begin
    if( rxd_sync_inv[1] && rxd_cnt_inv!=2'b11) rxd_cnt_inv <= rxd_cnt_inv + 2'h1;
    else
    if(~rxd_sync_inv[1] && rxd_cnt_inv!=2'b00) rxd_cnt_inv <= rxd_cnt_inv - 2'h1;
    if(rxd_cnt_inv==2'b00) rxd_bit_inv <= 1'b0;
    else
    if(rxd_cnt_inv==2'b11) rxd_bit_inv <= 1'b1;
  end

  reg [3:0] state;
  reg [3:0] bit_spacing;

  // "next_bit" controls when the data sampling occurs depending on how noisy the rxd is, different
  // values might work better with a clean connection, values from 8 to 11 work
  wire next_bit = (bit_spacing==4'd10);

  always @(posedge clk)
  if(state==0)bit_spacing <= 4'b0000;
  else
  if(baud8tick) bit_spacing <= {bit_spacing[2:0] + 4'b0001} | {bit_spacing[3], 3'b000};

  always @(posedge clk)
  if(baud8tick)
  case(state)
    4'b0000: if(rxd_bit_inv)state <= 4'b1000;  // start bit found?
    4'b1000: if(next_bit)  state <= 4'b1001;  // bit 0
    4'b1001: if(next_bit)  state <= 4'b1010;  // bit 1
    4'b1010: if(next_bit)  state <= 4'b1011;  // bit 2
    4'b1011: if(next_bit)  state <= 4'b1100;  // bit 3
    4'b1100: if(next_bit)  state <= 4'b1101;  // bit 4
    4'b1101: if(next_bit)  state <= 4'b1110;  // bit 5
    4'b1110: if(next_bit)  state <= 4'b1111;  // bit 6
    4'b1111: if(next_bit)  state <= 4'b0001;  // bit 7
    4'b0001: if(next_bit)  state <= 4'b0000;  // stop bit
    default:         state <= 4'b0000;
  endcase

  always @(posedge clk)
  if(baud8tick && next_bit && state[3]) rxd_data <= {~rxd_bit_inv, rxd_data[7:1]};

  //reg rxd_data_error;
  always @(posedge clk)
  begin
    rxd_data_ready <= (baud8tick && next_bit && state==4'b0001 && ~rxd_bit_inv);  // ready only if the stop bit is received
    //rxd_data_error <= (baud8tick && next_bit && state==4'b0001 &&  rxd_bit_inv);  // error if the stop bit is not received
  end

  reg [4:0] gap_count;
  always @(posedge clk) if (state!=0) gap_count<=5'h00; else if(baud8tick & ~gap_count[4]) gap_count <= gap_count + 5'h01;
  assign rxd_idle = gap_count[4];
  always @(posedge clk) rxd_endofpacket <= baud8tick & (gap_count==5'h0F);

endmodule
