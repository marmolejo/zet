// --------------------------------------------------------------------
// Module:      PS2_FIFO
// Description: PS2 Mouse with FIFO buffer
// --------------------------------------------------------------------
module PS2_FIFO(
    input              clk,
    input              reset,

    input        [7:0] writedata,    // data to send
    input              write,        // signal to send it 

    output  reg  [7:0] readdata,     // data read
    input              read,         // request to read from FIFO
    output             irq,          // signal data has arrived

    output             command_was_sent,
    output             error_sending_command,
    output             buffer_overrun_error,

    inout              PS2_CLK,      // PS2 Mouse Clock Line
    inout              PS2_DAT       // PS2 Mouse Data Line
);

// --------------------------------------------------------------------
// Internal wires and registers Declarations
// --------------------------------------------------------------------
wire     [7:0]    data_from_the_PS2_port;
wire              data_from_the_PS2_port_en;
wire              data_fifo_is_empty;
wire              data_fifo_is_full;
wire              write_to_buffer       =  data_from_the_PS2_port_en & ~data_fifo_is_full;
assign            irq                   = ~data_fifo_is_empty;
assign            buffer_overrun_error  =  data_fifo_is_full;

// --------------------------------------------------------------------
// Internal Modules
// --------------------------------------------------------------------
PS2_Mouse PS2_Serial_Port(
    .clk                            (clk),
    .reset                          (reset),
    
    .the_command                    (writedata),
    .send_command                   (write),

    .received_data                  (data_from_the_PS2_port),
    .received_data_en               (data_from_the_PS2_port_en),

    .command_was_sent               (command_was_sent),
    .error_communication_timed_out  (error_sending_command),

    .PS2_CLK                        (PS2_CLK),
    .PS2_DAT                        (PS2_DAT)
);

// --------------------------------------------------------------------
// FIFO Data queue
// --------------------------------------------------------------------
scfifo Incoming_Data_FIFO (
    .clock           (clk),
    .sclr            (reset),
    .rdreq           (read & ~data_fifo_is_empty),
    .wrreq           (write_to_buffer),
    .data            (data_from_the_PS2_port),
    .q               (readdata),
    .empty           (data_fifo_is_empty),
    .full            (data_fifo_is_full)

                         // synopsys translate_off
    ,                    // un-used lines
    .usedw          (),
    .almost_empty   (),
    .almost_full    (),
    .aclr           ()   // synopsys translate_on
);
defparam
    Incoming_Data_FIFO.add_ram_output_register   = "ON",
    Incoming_Data_FIFO.intended_device_family    = "Cyclone II",
    Incoming_Data_FIFO.lpm_numwords              = 256,
    Incoming_Data_FIFO.lpm_showahead             = "ON",
    Incoming_Data_FIFO.lpm_type                  = "scfifo",
    Incoming_Data_FIFO.lpm_width                 = 8,
    Incoming_Data_FIFO.lpm_widthu                = 8,
    Incoming_Data_FIFO.overflow_checking         = "OFF",
    Incoming_Data_FIFO.underflow_checking        = "OFF",
    Incoming_Data_FIFO.use_eab                   = "ON";

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:      PS2_FIFO
// Description: PS2 Mouse with FIFO buffer
// --------------------------------------------------------------------
module PS2_NO_FIFO(
    input                clk,
    input                reset,

    input       [7:0]    writedata,   // data to send
    input                write,       // signal to send it

    output      [7:0]    readdata,    // data read
    input                read,        // request to read from FIFO
    output               irq,         // signal data has arrived

    output               command_was_sent,
    output               error_sending_command,
    output               buffer_overrun_error,

    inout                PS2_CLK,
    inout                PS2_DAT
);

// --------------------------------------------------------------------
// Internal wires and registers Declarations
// --------------------------------------------------------------------
assign     buffer_overrun_error = error_sending_command;

// --------------------------------------------------------------------
// Internal Modules
// --------------------------------------------------------------------
PS2_Mouse PS2_Serial_Port(
    .clk                            (clk),
    .reset                          (reset),
    
    .the_command                    (writedata),
    .send_command                   (write),

    .received_data                  (readdata),
    .received_data_en               (irq),

    .command_was_sent               (command_was_sent),
    .error_communication_timed_out  (error_sending_command),

    .PS2_CLK                        (PS2_CLK),
     .PS2_DAT                       (PS2_DAT)
);

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module:      PS2 Mouse
// Description: PS2 Mouse Interface
// --------------------------------------------------------------------
module PS2_Mouse(
    input            clk,                // Clock Input
    input            reset,              // Reset Input
    inout            PS2_CLK,            // PS2 Clock, Bidirectional
    inout            PS2_DAT,            // PS2 Data, Bidirectional

    input    [7:0]   the_command,        // Command to send to mouse
    input            send_command,       // Singal to send
    output           command_was_sent,   // Signal command finished sending
    output           error_communication_timed_out,

    output   [7:0]   received_data,        // Received data
    output           received_data_en,     // If 1 - new data has been received
    output           start_receiving_data,
    output           wait_for_incoming_data
);

// --------------------------------------------------------------------
// Internal wires and registers Declarations                 
// --------------------------------------------------------------------
wire            ps2_clk_posedge;        // Internal Wires
wire            ps2_clk_negedge;

reg    [7:0]    idle_counter;            // Internal Registers
reg             ps2_clk_reg;
reg             ps2_data_reg;
reg             last_ps2_clk;

reg    [2:0]    ns_ps2_transceiver;        // State Machine Registers
reg    [2:0]    s_ps2_transceiver;

// --------------------------------------------------------------------
// Constant Declarations                           
// --------------------------------------------------------------------
localparam  PS2_STATE_0_IDLE            = 3'h0,        // states
            PS2_STATE_1_DATA_IN         = 3'h1,
            PS2_STATE_2_COMMAND_OUT     = 3'h2,
            PS2_STATE_3_END_TRANSFER    = 3'h3,
            PS2_STATE_4_END_DELAYED     = 3'h4;

// --------------------------------------------------------------------
// Finite State Machine(s)                           
// --------------------------------------------------------------------
always @(posedge clk) begin
    if(reset == 1'b1) s_ps2_transceiver <= PS2_STATE_0_IDLE;
    else              s_ps2_transceiver <= ns_ps2_transceiver;
end

always @(*) begin
    ns_ps2_transceiver = PS2_STATE_0_IDLE;        // Defaults

    case (s_ps2_transceiver)
    PS2_STATE_0_IDLE:
        begin
            if((idle_counter == 8'hFF) && (send_command == 1'b1))
                ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
            else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
                ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
            else ns_ps2_transceiver = PS2_STATE_0_IDLE;
        end
    PS2_STATE_1_DATA_IN:
        begin
//            if((received_data_en == 1'b1)  && (ps2_clk_posedge == 1'b1))
            if((received_data_en == 1'b1))   ns_ps2_transceiver = PS2_STATE_0_IDLE;
            else                             ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
        end
    PS2_STATE_2_COMMAND_OUT:
        begin
            if((command_was_sent == 1'b1) || (error_communication_timed_out == 1'b1))
                ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
            else ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
        end
    PS2_STATE_3_END_TRANSFER:
        begin
            if(send_command == 1'b0) ns_ps2_transceiver = PS2_STATE_0_IDLE;
            else if((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
                ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
            else ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
        end
    PS2_STATE_4_END_DELAYED:    
        begin
            if(received_data_en == 1'b1) begin
                if(send_command == 1'b0) ns_ps2_transceiver = PS2_STATE_0_IDLE;
                else                     ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
            end
            else ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
        end    

    default:
            ns_ps2_transceiver = PS2_STATE_0_IDLE;
    endcase
end

// --------------------------------------------------------------------
// Sequential logic                              
// --------------------------------------------------------------------
always @(posedge clk) begin
    if(reset == 1'b1)     begin
        last_ps2_clk    <= 1'b1;
        ps2_clk_reg     <= 1'b1;
        ps2_data_reg    <= 1'b1;
    end
    else begin
        last_ps2_clk    <= ps2_clk_reg;
        ps2_clk_reg     <= PS2_CLK;
        ps2_data_reg    <= PS2_DAT;
    end
end

always @(posedge clk) begin
    if(reset == 1'b1) idle_counter <= 6'h00;
    else if((s_ps2_transceiver == PS2_STATE_0_IDLE) && (idle_counter != 8'hFF))
        idle_counter <= idle_counter + 6'h01;
    else if (s_ps2_transceiver != PS2_STATE_0_IDLE)
        idle_counter <= 6'h00;
end

// --------------------------------------------------------------------
// Combinational logic                            
// --------------------------------------------------------------------
assign ps2_clk_posedge = ((ps2_clk_reg == 1'b1) && (last_ps2_clk == 1'b0)) ? 1'b1 : 1'b0;
assign ps2_clk_negedge = ((ps2_clk_reg == 1'b0) && (last_ps2_clk == 1'b1)) ? 1'b1 : 1'b0;

assign start_receiving_data      = (s_ps2_transceiver == PS2_STATE_1_DATA_IN);
assign wait_for_incoming_data    = (s_ps2_transceiver == PS2_STATE_3_END_TRANSFER);

// --------------------------------------------------------------------
// Internal Modules                             
// --------------------------------------------------------------------
PS2_Mouse_Command_Out Mouse_Command_Out (
    .clk                            (clk),            // Inputs
    .reset                          (reset),
    .the_command                    (the_command),
    .send_command                   (send_command),
    .ps2_clk_posedge                (ps2_clk_posedge),
    .ps2_clk_negedge                (ps2_clk_negedge),
    .PS2_CLK                        (PS2_CLK),        // Bidirectionals
     .PS2_DAT                       (PS2_DAT),
    .command_was_sent               (command_was_sent),    // Outputs
    .error_communication_timed_out  (error_communication_timed_out)
);

PS2_Mouse_Data_In PS2_Data_In (
    .clk                            (clk),        // Inputs
    .reset                          (reset),
    .wait_for_incoming_data         (wait_for_incoming_data),
    .start_receiving_data           (start_receiving_data),
    .ps2_clk_posedge                (ps2_clk_posedge),
    .ps2_clk_negedge                (ps2_clk_negedge),
    .ps2_data                       (ps2_data_reg),
    .received_data                  (received_data),   // Outputs
    .received_data_en               (received_data_en)
);

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:       PS2_Mouse_Command_Out
// Description:  This module sends commands to the PS2 interface
// --------------------------------------------------------------------
module PS2_Mouse_Command_Out (
    clk,
    reset,
    the_command,
    send_command,
    ps2_clk_posedge,
    ps2_clk_negedge,
    PS2_CLK,
    PS2_DAT,
    command_was_sent,
    error_communication_timed_out
);

// --------------------------------------------------------------------
// Port Declarations 
// --------------------------------------------------------------------
input                clk;
input                reset;
input          [7:0] the_command;
input                send_command;
input                ps2_clk_posedge;
input                ps2_clk_negedge;
inout                PS2_CLK;
inout                PS2_DAT;
output    reg        command_was_sent;
output    reg        error_communication_timed_out;

// --------------------------------------------------------------------
// Parameter Declarations , 1/12.5mhz => 0.08us
// --------------------------------------------------------------------
parameter    CLOCK_CYCLES_FOR_101US      = 1262;      // Timing info for initiating  
parameter    NUMBER_OF_BITS_FOR_101US    = 13;        // Host-to-Device communication 
parameter    COUNTER_INCREMENT_FOR_101US = 13'h0001;  //  when using a 12.5MHz system clock
parameter    CLOCK_CYCLES_FOR_15MS       = 187500;    // Timing info for start of 
parameter    NUMBER_OF_BITS_FOR_15MS     = 20;        // transmission error when
parameter    COUNTER_INCREMENT_FOR_15MS  = 20'h00001; // using a 12.5MHz system clock
parameter    CLOCK_CYCLES_FOR_2MS        = 25000;     // Timing info for sending 
parameter    NUMBER_OF_BITS_FOR_2MS      = 17;        // data error when 
parameter    COUNTER_INCREMENT_FOR_2MS   = 17'h00001; // using a 12.5MHz system clock

// --------------------------------------------------------------------
// Constant Declarations 
// --------------------------------------------------------------------
parameter   PS2_STATE_0_IDLE                    = 3'h0,
            PS2_STATE_1_INITIATE_COMMUNICATION  = 3'h1,
            PS2_STATE_2_WAIT_FOR_CLOCK          = 3'h2,
            PS2_STATE_3_TRANSMIT_DATA           = 3'h3,
            PS2_STATE_4_TRANSMIT_STOP_BIT       = 3'h4,
            PS2_STATE_5_RECEIVE_ACK_BIT         = 3'h5,
            PS2_STATE_6_COMMAND_WAS_SENT        = 3'h6,
            PS2_STATE_7_TRANSMISSION_ERROR      = 3'h7;

// --------------------------------------------------------------------
// Internal wires and registers Declarations 
// --------------------------------------------------------------------
reg            [3:0]    cur_bit;            // Internal Registers
reg            [8:0]    ps2_command;

reg            [NUMBER_OF_BITS_FOR_101US:1]    command_initiate_counter;

reg            [NUMBER_OF_BITS_FOR_15MS:1]        waiting_counter;
reg            [NUMBER_OF_BITS_FOR_2MS:1]        transfer_counter;

reg            [2:0]    ns_ps2_transmitter;            // State Machine Registers
reg            [2:0]    s_ps2_transmitter;

// --------------------------------------------------------------------
// Finite State Machine(s)
// --------------------------------------------------------------------
always @(posedge clk) begin
    if(reset == 1'b1) s_ps2_transmitter <= PS2_STATE_0_IDLE;
    else              s_ps2_transmitter <= ns_ps2_transmitter;
end

always @(*) begin        // Defaults
    ns_ps2_transmitter = PS2_STATE_0_IDLE;

    case (s_ps2_transmitter)
    PS2_STATE_0_IDLE:
        begin
            if (send_command == 1'b1) ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
            else                      ns_ps2_transmitter = PS2_STATE_0_IDLE;
        end
    PS2_STATE_1_INITIATE_COMMUNICATION:
        begin
            if (command_initiate_counter == CLOCK_CYCLES_FOR_101US)
                ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
            else
                ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
        end
    PS2_STATE_2_WAIT_FOR_CLOCK:
        begin
            if (ps2_clk_negedge == 1'b1)
                ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
            else if (waiting_counter == CLOCK_CYCLES_FOR_15MS)
                ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
            else
                ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
        end
    PS2_STATE_3_TRANSMIT_DATA:
        begin
            if ((cur_bit == 4'd8) && (ps2_clk_negedge == 1'b1))
                ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
            else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
            else
                ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
        end
    PS2_STATE_4_TRANSMIT_STOP_BIT:
        begin
            if (ps2_clk_negedge == 1'b1)
                ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
            else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
            else
                ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
        end
    PS2_STATE_5_RECEIVE_ACK_BIT:
        begin
            if (ps2_clk_posedge == 1'b1)
                ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
            else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
            else
                ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
        end
    PS2_STATE_6_COMMAND_WAS_SENT:
        begin
            if (send_command == 1'b0)
                ns_ps2_transmitter = PS2_STATE_0_IDLE;
            else
                ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
        end
    PS2_STATE_7_TRANSMISSION_ERROR:
        begin
            if (send_command == 1'b0)
                ns_ps2_transmitter = PS2_STATE_0_IDLE;
            else
                ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
        end
    default:
        begin
            ns_ps2_transmitter = PS2_STATE_0_IDLE;
        end
    endcase
end

// --------------------------------------------------------------------
// Sequential logic
// --------------------------------------------------------------------
always @(posedge clk) begin
    if(reset == 1'b1)     ps2_command <= 9'h000;
    else if(s_ps2_transmitter == PS2_STATE_0_IDLE)
        ps2_command <= {(^the_command) ^ 1'b1, the_command};
end

always @(posedge clk) begin
    if(reset == 1'b1) command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};
    else if((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) &&
            (command_initiate_counter != CLOCK_CYCLES_FOR_101US))
        command_initiate_counter <= 
            command_initiate_counter + COUNTER_INCREMENT_FOR_101US;
    else if(s_ps2_transmitter != PS2_STATE_1_INITIATE_COMMUNICATION)
        command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};
end

always @(posedge clk) begin
    if(reset == 1'b1)     waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};
    else if((s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) &&
            (waiting_counter != CLOCK_CYCLES_FOR_15MS))
        waiting_counter <= waiting_counter + COUNTER_INCREMENT_FOR_15MS;
    else if(s_ps2_transmitter != PS2_STATE_2_WAIT_FOR_CLOCK)
        waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};
end

always @(posedge clk) begin
    if(reset == 1'b1) transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
    else begin
        if((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ||
            (s_ps2_transmitter == PS2_STATE_4_TRANSMIT_STOP_BIT) ||
            (s_ps2_transmitter == PS2_STATE_5_RECEIVE_ACK_BIT))
        begin
            if(transfer_counter != CLOCK_CYCLES_FOR_2MS)
               transfer_counter <= transfer_counter + COUNTER_INCREMENT_FOR_2MS;
        end
        else transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
    end
end

always @(posedge clk) begin
    if(reset == 1'b1)  cur_bit <= 4'h0;
    else if((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) &&
            (ps2_clk_negedge == 1'b1))
        cur_bit <= cur_bit + 4'h1;
    else if(s_ps2_transmitter != PS2_STATE_3_TRANSMIT_DATA)
        cur_bit <= 4'h0;
end

always @(posedge clk) begin
    if(reset == 1'b1)     command_was_sent <= 1'b0;
    else if(s_ps2_transmitter == PS2_STATE_6_COMMAND_WAS_SENT)
        command_was_sent <= 1'b1;
    else if(send_command == 1'b0)     command_was_sent <= 1'b0;
end

always @(posedge clk) begin
    if(reset == 1'b1)     error_communication_timed_out <= 1'b0;
    else if(s_ps2_transmitter == PS2_STATE_7_TRANSMISSION_ERROR)
        error_communication_timed_out <= 1'b1;
    else if(send_command == 1'b0)
        error_communication_timed_out <= 1'b0;
end

// --------------------------------------------------------------------
// Combinational logic
// --------------------------------------------------------------------
assign PS2_CLK    = (s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) ? 1'b0 : 1'bz;

assign PS2_DAT    = (s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ? ps2_command[cur_bit] :
                  (s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) ? 1'b0 :
                  ((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) && 
                  (command_initiate_counter[NUMBER_OF_BITS_FOR_101US] == 1'b1)) ? 1'b0 : 1'bz;

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module:       PS2_Mouse_Data_In                                       
// Description:  This module accepts incoming data from PS2 interface.
// --------------------------------------------------------------------
module PS2_Mouse_Data_In (
    clk,
    reset,

    wait_for_incoming_data,
    start_receiving_data,

    ps2_clk_posedge,
    ps2_clk_negedge,
    ps2_data,

    received_data,
    received_data_en            // If 1 - new data has been received
);

// --------------------------------------------------------------------
// Port Declarations                             
// --------------------------------------------------------------------
input                clk;
input                reset;
input                wait_for_incoming_data;
input                start_receiving_data;
input                ps2_clk_posedge;
input                ps2_clk_negedge;
input                ps2_data;
output reg    [7:0]  received_data;
output reg           received_data_en;

// --------------------------------------------------------------------
// Constant Declarations                           
// --------------------------------------------------------------------
localparam    PS2_STATE_0_IDLE            = 3'h0,
            PS2_STATE_1_WAIT_FOR_DATA    = 3'h1,
            PS2_STATE_2_DATA_IN            = 3'h2,
            PS2_STATE_3_PARITY_IN        = 3'h3,
            PS2_STATE_4_STOP_IN            = 3'h4;

// --------------------------------------------------------------------
// Internal wires and registers Declarations                 
// --------------------------------------------------------------------
reg            [3:0]    data_count;
reg            [7:0]    data_shift_reg;

// State Machine Registers
reg            [2:0]    ns_ps2_receiver;
reg            [2:0]    s_ps2_receiver;

// --------------------------------------------------------------------
// Finite State Machine(s)                           
// --------------------------------------------------------------------
always @(posedge clk) begin
    if (reset == 1'b1) s_ps2_receiver <= PS2_STATE_0_IDLE;
    else               s_ps2_receiver <= ns_ps2_receiver;
end

always @(*) begin     // Defaults
    ns_ps2_receiver = PS2_STATE_0_IDLE;

    case (s_ps2_receiver)
    PS2_STATE_0_IDLE:
        begin
            if((wait_for_incoming_data == 1'b1) && (received_data_en == 1'b0))
                ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;
            else if ((start_receiving_data == 1'b1) && (received_data_en == 1'b0))
                ns_ps2_receiver = PS2_STATE_2_DATA_IN;
            else ns_ps2_receiver = PS2_STATE_0_IDLE;
        end
    PS2_STATE_1_WAIT_FOR_DATA:
        begin
            if((ps2_data == 1'b0) && (ps2_clk_posedge == 1'b1)) 
                ns_ps2_receiver = PS2_STATE_2_DATA_IN;
            else if (wait_for_incoming_data == 1'b0)
                ns_ps2_receiver = PS2_STATE_0_IDLE;
            else
                ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;
        end
    PS2_STATE_2_DATA_IN:
        begin
            if((data_count == 3'h7) && (ps2_clk_posedge == 1'b1))
                ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
            else
                ns_ps2_receiver = PS2_STATE_2_DATA_IN;
        end
    PS2_STATE_3_PARITY_IN:
        begin
            if (ps2_clk_posedge == 1'b1)
                ns_ps2_receiver = PS2_STATE_4_STOP_IN;
            else
                ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
        end
    PS2_STATE_4_STOP_IN:
        begin
            if (ps2_clk_posedge == 1'b1)
                ns_ps2_receiver = PS2_STATE_0_IDLE;
            else
                ns_ps2_receiver = PS2_STATE_4_STOP_IN;
        end
    default:
        begin
            ns_ps2_receiver = PS2_STATE_0_IDLE;
        end
    endcase
end

// --------------------------------------------------------------------
// Sequential logic                              
// --------------------------------------------------------------------
always @(posedge clk) begin
    if (reset == 1'b1)     data_count <= 3'h0;
    else if((s_ps2_receiver == PS2_STATE_2_DATA_IN) && (ps2_clk_posedge == 1'b1))
        data_count    <= data_count + 3'h1;
    else if(s_ps2_receiver != PS2_STATE_2_DATA_IN)
        data_count    <= 3'h0;
end

always @(posedge clk) begin
    if(reset == 1'b1)     data_shift_reg <= 8'h00;
    else if((s_ps2_receiver == PS2_STATE_2_DATA_IN) && (ps2_clk_posedge == 1'b1))
        data_shift_reg    <= {ps2_data, data_shift_reg[7:1]};
end

always @(posedge clk) begin
    if(reset == 1'b1) received_data <= 8'h00;
    else if(s_ps2_receiver == PS2_STATE_4_STOP_IN)
        received_data    <= data_shift_reg;
end

always @(posedge clk) begin
    if(reset == 1'b1) received_data_en <= 1'b0;
    else if((s_ps2_receiver == PS2_STATE_4_STOP_IN) && (ps2_clk_posedge == 1'b1))
        received_data_en    <= 1'b1;
    else
        received_data_en    <= 1'b0;
end


// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

