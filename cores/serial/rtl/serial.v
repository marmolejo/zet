/*
 *  Wishbone Compatible RS232 core
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

module serial (
    // Wishbone slave interface
    input         wb_clk_i,  // Clock Input
    input         wb_rst_i,  // Reset Input
    input  [15:0] wb_dat_i,  // Command to send to mouse
    output [15:0] wb_dat_o,  // Received data
    input         wb_cyc_i,  // Cycle
    input         wb_stb_i,  // Strobe
    input  [19:1] wb_adr_i,  // Wishbone address lines
    input  [ 1:0] wb_sel_i,  // Wishbone Select lines
    input         wb_we_i,   // Write enable
    output reg    wb_ack_o,  // Normal bus termination
    output        wb_tgc_o,  // Interrupt request

    output rs232_tx,  // RS232 output
    input  rs232_rx   // RS232 input
  );

  // --------------------------------------------------------------------
  // This section is a simple WB interface
  // --------------------------------------------------------------------
  reg    [7:0] dat_o;
  wire   [7:0] dat_i;
  wire   [2:0] UART_Addr;
  wire         wb_ack_i;
  wire         wr_command;
  wire         rd_command;

  // Unused output
  wire rxd_endofpacket;

  // --------------------------------------------------------------------
  // Wires for Interrupt Enable Register (IER)
  // --------------------------------------------------------------------
  wire EDAI;
  wire ETXH;
  //wire ERLS = ier[2];            // Enable Receive Line Status Interrupt
  wire EMSI;
  wire [7:0] INTE;

  // --------------------------------------------------------------------
  // Wires for Interrupt Identification Register (IIR)
  // --------------------------------------------------------------------
  reg          IPEN;             // 0 if intereupt pending
  reg      IPEND;        // Interupt pending
  reg  [1:0]   INTID;            // Interrupt ID Bits
  wire [7:0]   ISTAT;

  // --------------------------------------------------------------------
  // Wires for Line Status Register (LSR)
  // --------------------------------------------------------------------
  wire TSRE;
  wire PE;
  wire BI;
  wire FE;
  wire OR;
  reg  rx_rden;                // Receive data enable
  reg  DR;                             // Data Ready
  reg  THRE;                           // Transmitter Holding Register Empty
  wire [7:0] LSTAT;

  // --------------------------------------------------------------------
  // Wires for Modem Control Register (MCR)
  // --------------------------------------------------------------------
  wire DTR;
  wire RTS;
  wire OUT1;
  wire OUT2;
  wire LOOP;
  wire [7:0] MCON;

  // --------------------------------------------------------------------
  // Wires for Modem Status Register (MSR)
  // --------------------------------------------------------------------
  wire RLSD;
  wire RI;
  wire DSR;
  wire CTS;
  wire DRLSD;
  wire TERI;
  wire DDSR;
  wire DCTS;
  wire [7:0] MSTAT;

  // --------------------------------------------------------------------
  // Wires for Line Control Register (LCRR)
  // --------------------------------------------------------------------
  wire [7:0] LCON;
  wire dlab;

  // --------------------------------------------------------------------
  //  8250A Registers
  // --------------------------------------------------------------------
  wire [7:0] output_data;        // Wired to receiver
  reg  [7:0] input_data;         // Transmit register
  reg  [3:0] ier;                // Interrupt enable register
  reg  [7:0] lcr;                // Line Control register
  reg  [7:0] mcr;                // Modem Control register
  reg  [7:0] dll;                // Data latch register low
  reg  [7:0] dlh;                // Data latch register high

  // --------------------------------------------------------------------
  // Instantiate the UART
  // --------------------------------------------------------------------
  //reg    rx_read;        // Signal to read next byte in the buffer
  wire    rx_drdy;                // Indicates new data has come in
  wire    rx_idle;                // Indicates Receiver is idle
  wire    rx_over;                // Indicates buffer over run error
  reg     tx_send;                // Signal to send data
  wire    to_error;               // Indicates a transmit error occured
  wire    tx_done;
  wire    tx_busy;                // Signal transmitter is busy

  // --------------------------------------------------------------------
  // Baud Clock Generator
  // --------------------------------------------------------------------
  wire [18:0] Baudiv;
  wire     Baud1Tick;
  wire     Baud8Tick;
  reg  [18:0] BaudAcc1;
  reg  [15:0] BaudAcc8;
  wire [18:0] BaudInc;

  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
    if (wb_rst_i) wb_ack_o <= 1'b0;
    else          wb_ack_o <= wb_ack_i & ~wb_ack_o; // one clock delay on acknowledge output
  end

  // --------------------------------------------------------------------
  // This section is a simple 8250 Emulator that front ends the UART
  // --------------------------------------------------------------------

  // --------------------------------------------------------------------
  // Register addresses and defaults
  // --------------------------------------------------------------------
  `define UART_RG_TR   3'h0    // RW - Transmit / Receive register
  `define UART_RG_IE   3'h1    // RW - Interrupt enable
  `define UART_RG_II   3'h2    // R  - Interrupt identification (no fifo on 8250)
  `define UART_RG_LC   3'h3    // RW - Line Control
  `define UART_RG_MC   3'h4    // W  - Modem control
  `define UART_RG_LS   3'h5    // R  - Line status
  `define UART_RG_MS   3'h6    // R  - Modem status
  `define UART_RG_SR   3'h7    // RW - Scratch register

  `define UART_DL_LSB  8'h60    // Divisor latch least significant byte, hard coded to 9600 baud
  `define UART_DL_MSB  8'h00    // Divisor latch most  significant byte
  `define UART_IE_DEF  8'h00    // Interupt Enable default
  `define UART_LC_DEF  8'h03    // Line Control default
  `define UART_MC_DEF  8'h00    // Line Control default

  // --------------------------------------------------------------------
  //  UART Interrupt Behavior
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
      if(wb_rst_i) begin
          IPEN    <= 1'b1;                 // Interupt Enable default
          IPEND   <= 1'b0;          // Interupt pending
          INTID   <= 2'b00;                // Interupt ID
      end
      else begin
          if(DR & EDAI) begin           // If enabled
              IPEN  <= 1'b0;                // Set latch (inverted)
              IPEND <= 1'b1;          // Indicates an Interupt is pending
              INTID <= 2'b10;               // Set Interupt ID
          end

          if(THRE & ETXH) begin          // If enabled
              IPEN  <= 1'b0;                // Set latch (inverted)
              IPEND <= 1'b1;          // Indicates an Interupt is pending
              INTID <= 2'b01;               // Set Interupt ID
          end

          if((CTS | DSR | RI |RLSD) && EMSI) begin    // If enabled
              IPEN  <= 1'b0;                    // Set latch (inverted)
              IPEND <= 1'b1;          // Indicates an Interupt is pending
              INTID <= 2'b00;                   // Interupt ID
          end

          if(rd_command)                      // If a read was requested
              case(UART_Addr)                 // Determine which register was read
                  `UART_RG_TR: IPEN <= 1'b1;  // Resets interupt flag
                  `UART_RG_II: IPEN <= 1'b1;  // Resets interupt flag
                  `UART_RG_MS: IPEN <= 1'b1;  // Resets interupt flag
                  default:   ;                // Do nothing if anything else
              endcase                         // End of case

          if(wr_command)                      // If a write was requested
              case(UART_Addr)                 // Determine which register was writen to
                  `UART_RG_TR: IPEN <= 1'b1;  // Resets interupt flag;
                  default:   ;                // Do nothing if anything else
              endcase                         // End of case

      if(IPEN & IPEND) begin
        INTID <= 2'b00;          // user has cleared the Interupt
        IPEND <= 1'b0;          // Interupt pending
      end
      end
  end    // Synchrounous always

  // --------------------------------------------------------------------
  //  UART Line Status Behavior
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
      if(wb_rst_i) begin
      // rx_read  <= 1'b0;          // Singal to get the data out of the buffer
      rx_rden  <= 1'b1;          // Singal to get the data out of the buffer
          DR      <= 1'b0;          // Indicates data is waiting to be read
          THRE    <= 1'b0;          // Transmitter holding register is empty
      end
      else begin
          if(rx_drdy) begin             // If enabled
              DR    <= 1'b1;          // Indicates data is waiting to be read
        if(rx_rden) /*rx_read  <= 1'b1*/;   // If reading enabled, request another byte
        else begin            // of data out of the buffer, else..
          //rx_read  <= 1'b0;      // on next clock, do not request anymore
          rx_rden <= 1'b0;      // block your fifo from reading
        end                // until ready
      end

          if(tx_done) begin            // If enabled
              THRE  <= 1'b1;          // Transmitter holding register is empty
          end

      if(IPEN && IPEND) begin        // If the user has cleared the and there is not one pending
        rx_rden <= 1'b1;         // User has digested that byte, now enable reading some more
              DR      <= 1'b0;        // interrupt, then clear
              THRE    <= 1'b0;        // the flags in the Line status register
      end
    end
  end

  // --------------------------------------------------------------------
  // UART Register behavior
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
      if(wb_rst_i) begin
          dat_o   <= 8'h00;            // Default value
      end
      else
      if(rd_command) begin
          case(UART_Addr)                            // Determine which register was read
              `UART_RG_TR: dat_o <= dlab ? dll : output_data;
              `UART_RG_IE: dat_o <= dlab ? dlh : INTE;
              `UART_RG_II: dat_o <= ISTAT;        // Interupt ID
              `UART_RG_LC: dat_o <= LCON;         // Line control
              `UART_RG_MC: dat_o <= MCON;        // Modem Control Register
              `UART_RG_LS: dat_o <= LSTAT;        // Line status
              `UART_RG_MS: dat_o <= MSTAT;        // Modem Status
              `UART_RG_SR: dat_o <= 8'h00;        // No Scratch register
              default:     dat_o <= 8'h00;        // Default
          endcase                                 // End of case
      end
  end  // Synchrounous always

  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
      if(wb_rst_i) begin
          dll     <= `UART_DL_LSB;    // Set default to 9600 baud
          dlh     <= `UART_DL_MSB;    // Set default to 9600 baud
          ier     <= 4'h01;           // Interupt Enable default
          lcr     <= 8'h03;           // Default value
          mcr     <= 8'h00;           // Default value
      end
      else if(wr_command) begin                   // If a write was requested
          case(UART_Addr)                         // Determine which register was writen to
              `UART_RG_TR: if(dlab) dll <= dat_i; else input_data <= dat_i;
              `UART_RG_IE: if(dlab) dlh <= dat_i; else ier        <= dat_i[3:0];
              `UART_RG_II: ;                      // Read only register
              `UART_RG_LC: lcr <= dat_i;          // Line Control
              `UART_RG_MC: mcr <= dat_i;          // Modem Control Register
              `UART_RG_LS: ;                      // Read only register
              `UART_RG_MS: ;                      // Read only register
              `UART_RG_SR: ;                  // No scratch register
              default:     ;                      // Default
          endcase                                 // End of case
      end
  end  // Synchrounous always

  // --------------------------------------------------------------------
  // Transmit behavior
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i or posedge wb_rst_i) begin    // Synchrounous
      if(wb_rst_i) tx_send <= 1'b0;                  // Default value
      else         tx_send <= (wr_command && (UART_Addr == `UART_RG_TR) && !dlab);
  end  // Synchrounous always

  serial_arx arx (
    .clk             (wb_clk_i),
    .baud8tick       (Baud8Tick),
    .rxd             (rs232_rx),
    .rxd_data_ready  (rx_drdy),
    .rxd_data        (output_data),
    .rxd_endofpacket (rxd_endofpacket),
    .rxd_idle        (rx_idle)
  );

  serial_atx atx (
    .clk       (wb_clk_i),
    .baud1tick (Baud1Tick),
    .txd       (rs232_tx),
    .txd_start (tx_send),
    .txd_data  (input_data),
    .txd_busy  (tx_busy)
  );

  // --------------------------------------------------------------------
  //  1.8432Mhz Baud Clock Generator:
  //  This module generates the standard 1.8432Mhz Baud Clock. Using this clock
  //  The Baud Rate Generator below can then derive all the standard
  //  Bauds. Make the accumulator 1 more bit for carry out than what is
  //  Needed. Example: Main Clock =  12.5Mhz =    12,500,000 Hence
  //  1024/151 = 6.78, => 12,500,000 / 6.78 =    1,843,261.72  , .003% error, Good !
  //  so the accumulator should be 11 bits (log2(1024) +1
  //
  // --------------------------------------------------------------------
  //  Baud Rate Generator:
  //  Once we have our little 1.8432Mhz Baud Clock, deriving the bauds is
  //  simple simon. Just divide by 16 to get the 1x baud for transmitting
  //  and divide by 2 to get the 8x oversampling clock for receiving.
  //
  // Baud Clock = 1.8432Mhz
  // Divisor    = 16
  //
  //   Baud   Divsr %Error
  // ------   ----- -----
  //     50  2304  0.000%
  //     75  1536  0.000%
  //    110  1047  0.026%
  //    150   768  0.000%
  //    300   384  0.000%
  //    600   192  0.000%
  //   1200    96  0.000%
  //   2400    48  0.000%
  //   4800    24  0.000%
  //   7200    16  0.000%
  //   9600    12  0.000%
  //  14400     8  0.000%
  //  19200     6  0.000%
  //  28800     4  0.000%
  //  38400     3  0.000%
  //  57600     2  0.000%
  // 115200     1  0.000%
  //
  // --------------------------------------------------------------------

  always @(posedge wb_clk_i)
    BaudAcc1 <= {1'b0, BaudAcc1[17:0]} + BaudInc;
  always @(posedge wb_clk_i)
    BaudAcc8 <= {1'b0, BaudAcc8[14:0]} + BaudInc[15:0];

  // Combinatorial logic
  assign dat_i = wb_sel_i[0] ? wb_dat_i[7:0]  : wb_dat_i[15:8]; // 8 to 16 bit WB
  assign wb_dat_o   = wb_sel_i[0] ? {8'h00, dat_o} : {dat_o, 8'h00}; // 8 to 16 bit WB
  assign UART_Addr = {wb_adr_i[2:1], wb_sel_i[1]}; // Computer UART Address
  assign wb_ack_i = wb_stb_i &  wb_cyc_i;    // Immediate ack
  assign wr_command = wb_ack_i &  wb_we_i;     // WISHBONE write access, Singal to send
  assign rd_command = wb_ack_i & ~wb_we_i;     // WISHBONE write access, Singal to send
  assign wb_tgc_o   = ~IPEN;               // If ==0 - new data has been received

  assign EDAI = ier[0];             // Enable Data Available Interrupt
  assign ETXH = ier[1];            // Enable Tx Holding Register Empty Interrupt
  assign EMSI = ier[3];            // Enable Modem Status Interrupt
  assign INTE = {4'b0000, ier};
  assign ISTAT = { 5'b0000_0,INTID,IPEN};
  assign TSRE = tx_done;                      // Tx Shift Register Empty
  assign PE = 1'b0;                       // Parity Error
  assign BI = 1'b0;                         // Break Interrupt, hard coded off
  assign FE = to_error;                     // Framing Error, hard coded off
  assign OR = rx_over;                     // Overrun Error, hard coded off
  assign LSTAT = {1'b0,TSRE,THRE,BI,FE,PE,OR,DR};

  assign DTR = mcr[0];
  assign RTS = mcr[1];
  assign OUT1 = mcr[2];
  assign OUT2 = mcr[3];
  assign LOOP = mcr[4];
  assign MCON = {3'b000, mcr[4:0]};
  assign RLSD = LOOP ? OUT2 : 1'b0;    // Received Line Signal Detect
  assign RI = LOOP ? OUT1 : 1'b1;    // Ring Indicator
  assign DSR = LOOP ? DTR  : 1'b0;    // Data Set Ready
  assign CTS = LOOP ? RTS  : 1'b0;    // Clear To Send
  assign DRLSD = 1'b0;                  // Delta Rx Line Signal Detect
  assign TERI = 1'b0;                  // Trailing Edge Ring Indicator
  assign DDSR = 1'b0;                  // Delta Data Set Ready
  assign DCTS = 1'b0;                  // Delta Clear to Send
  assign MSTAT = {RLSD,RI,DSR,CTS,DCTS,DDSR,TERI,DRLSD};

  assign LCON = lcr;              // Data Latch Address Bit
  assign dlab = lcr[7];           // Data Latch Address Bit
  assign tx_done = ~tx_busy;     // Signal command finished sending
  assign rx_over  = 1'b0;
  assign to_error = 1'b0;

  assign Baudiv = {3'b000,dlh,dll};
  assign Baud1Tick = BaudAcc1[18];
  assign BaudInc =  19'd2416/Baudiv;

endmodule
