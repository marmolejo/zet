`timescale 10ns/100ps

module testbench;

  // Net declarations
  wire [15:0] rd_data;
  wire [15:0] wr_data, mem_data, io_data;
  wire [19:0] addr;
  wire        we;
  wire        m_io;
  wire        byte_m;
  wire        ack_i;

  reg         clk, rst;
  reg [15:0]  io_reg;
  reg [ 1:0]  ack;

  // Module instantiations
  memory mem0 (clk, addr, wr_data, mem_data, we & ~m_io, byte_m);

  cpu cpu0 (
    .clk_i  (clk),
    .rst_i  (rst),
    .dat_i  (rd_data),
    .dat_o  (wr_data),
    .adr_o  (addr),
    .we_o   (we),
    .mio_o  (m_io),
    .byte_o (byte_m),
    .ack_i  (ack_i)
  );

  // Assignments
  assign io_data = (addr[15:0]==16'hb7) ? io_reg : 16'd0;
  assign rd_data = m_io ? io_data : mem_data;
  assign ack_i   = (ack==2'b10);

  // Behaviour
  // IO Stub
  always @(posedge clk) 
    if (addr==20'hb7 & we & m_io) 
      io_reg <= byte_m ? { io_reg[15:8], wr_data[7:0] } : wr_data;

  always #1 clk = ~clk;
  always #2.13 ack = ack + 2'd1;

  initial 
    begin
         clk <= 1'b1;
         rst <= 1'b0;
         ack <= 2'b0;
      #5 rst <= 1'b1;
      #2 rst <= 1'b0;
    end

endmodule
