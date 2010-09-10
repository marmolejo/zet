// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      WB_Serial.v
// Description: Wishbone Compatible RS232 core.                          
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module WB_Serial(
    input             	wb_clk_i,		// Clock Input
    input             	wb_rst_i,		// Reset Input
    input       [15:0]	wb_dat_i,		// Command to send to mouse
    output      [15:0]	wb_dat_o,		// Received data
    input             	wb_cyc_i,		// Cycle
    input             	wb_stb_i,		// Strobe
    input       [ 1:0]	wb_adr_i,		// Wishbone address lines
    input       [ 1:0]	wb_sel_i,		// Wishbone Select lines
    input             	wb_we_i,		// Write enable
    output reg        	wb_ack_o,		// Normal bus termination
    output            	wb_tgc_o,		// Interrupt request

	output				rs232_tx, 		// RS232 output
	input				rs232_rx		// RS232 input
);

// --------------------------------------------------------------------
// This section is a simple WB interface
// --------------------------------------------------------------------
reg    [7:0] dat_o;
wire   [7:0] dat_i      = wb_sel_i[0] ? wb_dat_i[7:0]  : wb_dat_i[15:8]; // 8 to 16 bit WB
assign       wb_dat_o   = wb_sel_i[0] ? {8'h00, dat_o} : {dat_o, 8'h00}; // 8 to 16 bit WB
wire   [2:0] UART_Addr  = {wb_adr_i, wb_sel_i[1]}; // Computer UART Address
wire         wb_ack_i   = wb_stb_i &  wb_cyc_i;    // Immediate ack
wire         wr_command = wb_ack_i &  wb_we_i;     // Wishbone write access, Singal to send
wire         rd_command = wb_ack_i & ~wb_we_i;     // Wishbone write access, Singal to send
assign       wb_tgc_o   = ~IPEN;	      		   // If ==0 - new data has been received

always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
    if(wb_rst_i) wb_ack_o <= 1'b0;
    else         wb_ack_o <= wb_ack_i & ~wb_ack_o; // one clock delay on acknowledge output
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
// Wires for Interrupt Enable Register (IER)
// --------------------------------------------------------------------
wire EDAI = ier[0];           	// Enable Data Available Interrupt
wire ETXH = ier[1];        		// Enable Tx Holding Register Empty Interrupt
wire ERLS = ier[2];        		// Enable Receive Line Status Interrupt
wire EMSI = ier[3];        		// Enable Modem Status Interrupt
wire [7:0] INTE = {4'b0000, ier};

// --------------------------------------------------------------------
// Wires for Interrupt Identification Register (IIR)
// --------------------------------------------------------------------
reg        	IPEN;             // 0 if intereupt pending 
reg  		IPEND;			  // Interupt pending
reg  [1:0] 	INTID;            // Interrupt ID Bits
wire [7:0] 	ISTAT = { 5'b0000_0,INTID,IPEN}; 

// --------------------------------------------------------------------
//  UART Interrupt Behavior
// --------------------------------------------------------------------
always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
    if(wb_rst_i) begin
        IPEN  	<= 1'b1;           			// Interupt Enable default
        IPEND 	<= 1'b0;					// Interupt pending
        INTID 	<= 2'b00;          			// Interupt ID
    end
    else begin
        if(DR & EDAI) begin     			// If enabled
            IPEN  <= 1'b0;            		// Set latch (inverted)
            IPEND <= 1'b1;					// Indicates an Interupt is pending
            INTID <= 2'b10;           		// Set Interupt ID
        end

        if(THRE & ETXH) begin  				// If enabled
            IPEN  <= 1'b0;            		// Set latch (inverted)
            IPEND <= 1'b1;					// Indicates an Interupt is pending
            INTID <= 2'b01;           		// Set Interupt ID
        end

        if((CTS | DSR | RI |RLSD) && EMSI) begin    // If enabled
            IPEN  <= 1'b0;            				// Set latch (inverted)
            IPEND <= 1'b1;					// Indicates an Interupt is pending
            INTID <= 2'b00;           				// Interupt ID
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
			INTID <= 2'b00;					// user has cleared the Interupt
			IPEND <= 1'b0;					// Interupt pending
		end
    end
end		// Synchrounous always

// --------------------------------------------------------------------
// Wires for Line Status Register (LSR)
// --------------------------------------------------------------------
wire TSRE  = tx_done;                    	// Tx Shift Register Empty 
wire PE    = 1'b0;        		         	// Parity Error
wire BI    = 1'b0;                       	// Break Interrupt, hard coded off
wire FE    = to_error;                   	// Framing Error, hard coded off
wire OR    = rx_over;	                 	// Overrun Error, hard coded off
reg  rx_rden;								// Receive data enable
reg  DR;			                     	// Data Ready
reg  THRE;      			             	// Transmitter Holding Register Empty
wire [7:0] LSTAT = {1'b0,TSRE,THRE,BI,FE,PE,OR,DR};

// --------------------------------------------------------------------
//  UART Line Status Behavior
// --------------------------------------------------------------------
always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
    if(wb_rst_i) begin
		rx_read	<= 1'b0;					// Singal to get the data out of the buffer
		rx_rden	<= 1'b1;					// Singal to get the data out of the buffer
        DR    	<= 1'b0;					// Indicates data is waiting to be read
        THRE  	<= 1'b0;					// Transmitter holding register is empty
    end
    else begin
        if(rx_drdy) begin     				// If enabled
            DR    <= 1'b1;					// Indicates data is waiting to be read
			if(rx_rden) rx_read	<= 1'b1; 	// If reading enabled, request another byte 
			else begin						// of data out of the buffer, else..
				rx_read	<= 1'b0;			// on next clock, do not request anymore
				rx_rden <= 1'b0;			// block your fifo from reading 
			end								// until ready
		end

        if(tx_done) begin  					// If enabled
            THRE  <= 1'b1;					// Transmitter holding register is empty
        end

		if(IPEN && IPEND) begin				// If the user has cleared the and there is not one pending
			rx_rden <= 1'b1;	 			// User has digested that byte, now enable reading some more
            DR    	<= 1'b0;				// interrupt, then clear
            THRE  	<= 1'b0;				// the flags in the Line status register
		end
	end
end        

// --------------------------------------------------------------------
// Wires for Modem Control Register (MCR)
// --------------------------------------------------------------------
wire DTR   = mcr[0];
wire RTS   = mcr[1];
wire OUT1  = mcr[2];
wire OUT2  = mcr[3];
wire LOOP  = mcr[4];
wire [7:0] MCON  = {3'b000, mcr[4:0]};

// --------------------------------------------------------------------
// Wires for Modem Status Register (MSR)
// --------------------------------------------------------------------
wire RLSD  = LOOP ? OUT2 : 1'b0;    // Received Line Signal Detect 
wire RI    = LOOP ? OUT1 : 1'b1;    // Ring Indicator
wire DSR   = LOOP ? DTR  : 1'b0;    // Data Set Ready
wire CTS   = LOOP ? RTS  : 1'b0;    // Clear To Send
wire DRLSD = 1'b0;                  // Delta Rx Line Signal Detect
wire TERI  = 1'b0;                  // Trailing Edge Ring Indicator
wire DDSR  = 1'b0;                  // Delta Data Set Ready
wire DCTS  = 1'b0;                  // Delta Clear to Send
wire [7:0] MSTAT = {RLSD,RI,DSR,CTS,DCTS,DDSR,TERI,DRLSD};    

// --------------------------------------------------------------------
// Wires for Line Control Register (LCRR)
// --------------------------------------------------------------------
wire [7:0] LCON = lcr;              // Data Latch Address Bit
wire dlab       = lcr[7];           // Data Latch Address Bit

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
// UART Register behavior
// --------------------------------------------------------------------
always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
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
            `UART_RG_MC: dat_o <= MCON ;        // Modem Control Register
            `UART_RG_LS: dat_o <= LSTAT;        // Line status
            `UART_RG_MS: dat_o <= MSTAT;        // Modem Status
            `UART_RG_SR: dat_o <= 8'h00;        // No Scratch register
            default:     dat_o <= 8'h00;        // Default
        endcase                                 // End of case
    end
end  // Synchrounous always

always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
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
            `UART_RG_SR: ;			            // No scratch register
            default:     ;                      // Default
        endcase                                 // End of case
    end
end  // Synchrounous always

// --------------------------------------------------------------------
// Transmit behavior
// --------------------------------------------------------------------
always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
    if(wb_rst_i) tx_send <= 1'b0;                  // Default value
    else         tx_send <= (wr_command && (UART_Addr == `UART_RG_TR) && !dlab);
end  // Synchrounous always

// --------------------------------------------------------------------
// Instantiate the UART
// --------------------------------------------------------------------
reg		rx_read;				// Signal to read next byte in the buffer
wire    rx_drdy;                // Indicates new data has come in
wire    rx_idle;                // Indicates Receiver is idle
wire    rx_over;                // Indicates buffer over run error
reg     tx_send;                // Signal to send data
wire    to_error;               // Indicates a transmit error occured
wire    tx_done = ~tx_busy;     // Signal command finished sending
wire    tx_busy;                // Signal transmitter is busy

async_receiver RX(.clk(wb_clk_i), .BaudRate({dlh,dll}), .RxD(rs232_rx), .RxD_data_ready(rx_drdy), .RxD_data(output_data), .RxD_idle(rx_idle) );
async_transmitter TX(.clk(wb_clk_i), .BaudRate({dlh,dll}), .TxD(rs232_tx), .TxD_start(tx_send), .TxD_data(input_data), .TxD_busy(tx_busy));

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// --------------------------------------------------------------------
// RS-232 RX module
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module async_receiver(clk, BaudRate, RxD, RxD_data_ready, RxD_data, RxD_endofpacket, RxD_idle);
input 			 clk;
input 			 RxD;
input     [15:0] BaudRate;			// Desired baud rate
output     [7:0] RxD_data;
output 			 RxD_data_ready;  	// on clock pulse when RxD_data is valid

parameter Baud8GeneratorAccWidth = 16;

//parameter ClkFrequency = 12500000; // 12.5MHz
//parameter Baud = 115200;
// parameter Baud8 = Baud*8; // Baud generator (we use 8 times oversampling)
//wire [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = ((Baud8<<(Baud8GeneratorAccWidth-7))+(ClkFrequency>>8))/(ClkFrequency>>7);

wire [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = 4832;

reg [Baud8GeneratorAccWidth:0] Baud8GeneratorAcc;
always @(posedge clk) Baud8GeneratorAcc <= Baud8GeneratorAcc[Baud8GeneratorAccWidth-1:0] + Baud8GeneratorInc;
wire Baud8Tick = Baud8GeneratorAcc[Baud8GeneratorAccWidth];


// We also detect if a gap occurs in the received stream of characters whuich can be useful if 
// multiple characters are sent in burst so that multiple characters can be treated as a "packet"
output RxD_endofpacket;  	// one clock pulse, when no more data is received (RxD_idle is going high)
output RxD_idle;  			// no data is being received

reg [1:0] RxD_sync_inv;	// we invert RxD, so that the idle becomes "0", to prevent a phantom character to be received at startup
always @(posedge clk) if(Baud8Tick) RxD_sync_inv <= {RxD_sync_inv[0], ~RxD};

reg [1:0] RxD_cnt_inv;
reg RxD_bit_inv;

always @(posedge clk)
if(Baud8Tick) begin
	if( RxD_sync_inv[1] && RxD_cnt_inv!=2'b11) RxD_cnt_inv <= RxD_cnt_inv + 2'h1;
	else 
	if(~RxD_sync_inv[1] && RxD_cnt_inv!=2'b00) RxD_cnt_inv <= RxD_cnt_inv - 2'h1;

	if(RxD_cnt_inv==2'b00) RxD_bit_inv <= 1'b0;
	else
	if(RxD_cnt_inv==2'b11) RxD_bit_inv <= 1'b1;
end

reg [3:0] state;
reg [3:0] bit_spacing;

// "next_bit" controls when the data sampling occurs depending on how noisy the RxD is, different 
// values might work better with a clean connection, values from 8 to 11 work
wire next_bit = (bit_spacing==4'd10);

always @(posedge clk)
if(state==0)
	bit_spacing <= 4'b0000;
else
if(Baud8Tick) bit_spacing <= {bit_spacing[2:0] + 4'b0001} | {bit_spacing[3], 3'b000};

always @(posedge clk)
if(Baud8Tick)
case(state)
	4'b0000: if(RxD_bit_inv)state <= 4'b1000;  // start bit found?
	4'b1000: if(next_bit)	state <= 4'b1001;  // bit 0
	4'b1001: if(next_bit)	state <= 4'b1010;  // bit 1
	4'b1010: if(next_bit)	state <= 4'b1011;  // bit 2
	4'b1011: if(next_bit)	state <= 4'b1100;  // bit 3
	4'b1100: if(next_bit)	state <= 4'b1101;  // bit 4
	4'b1101: if(next_bit)	state <= 4'b1110;  // bit 5
	4'b1110: if(next_bit)	state <= 4'b1111;  // bit 6
	4'b1111: if(next_bit)	state <= 4'b0001;  // bit 7
	4'b0001: if(next_bit)	state <= 4'b0000;  // stop bit
	default: 				state <= 4'b0000;
endcase

reg [7:0] RxD_data;
always @(posedge clk)
if(Baud8Tick && next_bit && state[3]) RxD_data <= {~RxD_bit_inv, RxD_data[7:1]};

reg RxD_data_ready, RxD_data_error;
always @(posedge clk)
begin
	RxD_data_ready <= (Baud8Tick && next_bit && state==4'b0001 && ~RxD_bit_inv);  // ready only if the stop bit is received
	RxD_data_error <= (Baud8Tick && next_bit && state==4'b0001 &&  RxD_bit_inv);  // error if the stop bit is not received
end

reg [4:0] gap_count;
always @(posedge clk) if (state!=0) gap_count<=5'h00; else if(Baud8Tick & ~gap_count[4]) gap_count <= gap_count + 5'h01;
assign RxD_idle = gap_count[4];
reg RxD_endofpacket; always @(posedge clk) RxD_endofpacket <= Baud8Tick & (gap_count==5'h0F);

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// --------------------------------------------------------------------
// RS-232 TX module
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module async_transmitter(clk, BaudRate, TxD_start, TxD_data, TxD, TxD_busy);
input 			 clk;
input 			 TxD_start;
input     [15:0] BaudRate;					 // Desired baud rate
input      [7:0] TxD_data;
output 			 TxD;
output 			 TxD_busy;

parameter BaudGeneratorAccWidth = 16;

// parameter ClkFrequency = 12500000;	// 12.5MHz
// parameter Baud = 115200;
//wire [BaudGeneratorAccWidth:0] BaudGeneratorInc = ((Baud<<(BaudGeneratorAccWidth-4))+(ClkFrequency>>5))/(ClkFrequency>>4);

reg  [BaudGeneratorAccWidth:0] BaudGeneratorAcc;
wire [BaudGeneratorAccWidth:0] BaudGeneratorInc = 604;

wire BaudTick = BaudGeneratorAcc[BaudGeneratorAccWidth];
wire TxD_busy;
always @(posedge clk) if(TxD_busy) BaudGeneratorAcc <= BaudGeneratorAcc[BaudGeneratorAccWidth-1:0] + BaudGeneratorInc;

// Transmitter state machine
parameter RegisterInputData = 1;	// in RegisterInputData mode, the input doesn't have to stay valid while the character is been transmitted
reg [3:0] state;
wire TxD_ready = (state==0);
assign TxD_busy = ~TxD_ready;

reg [7:0] TxD_dataReg;
always @(posedge clk) if(TxD_ready & TxD_start) TxD_dataReg <= TxD_data;
wire [7:0] TxD_dataD = RegisterInputData ? TxD_dataReg : TxD_data;

always @(posedge clk)
case(state)
	4'b0000: if(TxD_start) state <= 4'b0001;
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

reg muxbit;			// Output mux
always @( * )
case(state[2:0])
	3'd0: muxbit <= TxD_dataD[0];
	3'd1: muxbit <= TxD_dataD[1];
	3'd2: muxbit <= TxD_dataD[2];
	3'd3: muxbit <= TxD_dataD[3];
	3'd4: muxbit <= TxD_dataD[4];
	3'd5: muxbit <= TxD_dataD[5];
	3'd6: muxbit <= TxD_dataD[6];
	3'd7: muxbit <= TxD_dataD[7];
endcase

reg TxD;	// Put together the start, data and stop bits
always @(posedge clk) TxD <= (state<4) | (state[3] & muxbit);  // register the output to make it glitch free

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
//  Baud Rate Generator:
//  Baud register is baud/2, simple, divide by 2 so 115200 can fit into
//  a 16 bit register
//
//  Example Bauds	Divisor
//     300			150
//	  1200			600
//    2400			1200
//	  4800
//	  9600
//	 19200
//	 38400
//	 57600
//	115200
//  
// --------------------------------------------------------------------
module baud_rs232 #(
    parameter ClkFrequency           = 12500000,    // 12.5MHz
	parameter BaudDefault            = 115200,      // Baud Rate 
	parameter Baud8GeneratorAccWidth = 16,			// Accumulator size
	parameter BaudGeneratorAccWidth  = 16 			// Accumulator size
  ) 
  (
    input  			 clk,		 // Input clock
    input     [15:0] BaudRate,	 // Desired baud rate /2
	input  			 BaudEnable, // Enable 1x Baud output
    output 			 BaudTick,	 // 1x baud for transmitting
    output 			 Baud8Tick	 // 8x baud for oversampling
  );

// Baud generator (we use 8 times oversampling)
parameter Baud8 = BaudDefault*8;  // 921600

// Baud generator             inc = ((921600 * 512) + 12500000 /256) / (12500000 / 128)
// Baud generator             inc = 471859200  + 48828.125 / 97656.25  = 4832.338208

wire [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = ((Baud8<<(Baud8GeneratorAccWidth-7))+(ClkFrequency>>8))/(ClkFrequency>>7);
reg [Baud8GeneratorAccWidth:0] Baud8GeneratorAcc;
always @(posedge clk) Baud8GeneratorAcc <= Baud8GeneratorAcc[Baud8GeneratorAccWidth-1:0] + Baud8GeneratorInc;
assign Baud8Tick = Baud8GeneratorAcc[Baud8GeneratorAccWidth];

//                            inc = ((Baud   << AccWidth-4) + ClkFrequency>>5) / (ClkFrequency >>4)
// Baud generator             inc = ((Baud *  2^(AccWidth-4)) + 12500000>>5) / (12500000 >>4)

// Baud generator             inc = ((115200 <<12) + 12500000>>5) / (12500000 >>4)

// Baud generator             inc = ((115200 * 4096) + 12500000 /32) / (12500000 /16)
//                            inc = (471859200 + 390625) / 781250 = 604.479776
//                            131072 / 604
parameter Baud = BaudDefault;
reg [BaudGeneratorAccWidth:0] BaudGeneratorAcc;
wire [BaudGeneratorAccWidth:0] BaudGeneratorInc = ((Baud<<(BaudGeneratorAccWidth-4))+(ClkFrequency>>5))/(ClkFrequency>>4);
always @(posedge clk) if(BaudEnable) BaudGeneratorAcc <= BaudGeneratorAcc[BaudGeneratorAccWidth-1:0] + BaudGeneratorInc;
assign BaudTick = BaudGeneratorAcc[BaudGeneratorAccWidth];

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------



// --------------------------------------------------------------------
// End of WB Serial Modules
// --------------------------------------------------------------------
