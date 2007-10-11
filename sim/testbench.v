`timescale 10ns/100ps

module testbench;

  // Net declarations
  wire [15:0] rd_data;
  wire [15:0] wr_data, mem_data, io_data;
  wire [19:0] addr;
  wire        we;
  wire        m_io;
  wire        byte_m;  

  reg         clk, rst;
  reg [15:0]  io_reg;

  // Module instantiations
  memory mem0 (clk, addr, wr_data, mem_data, we & ~m_io, byte_m);
  cpu    cpu0 (clk, rst, rd_data, wr_data, addr, we, m_io, byte_m,, 1'b1);

  // Assignments
  assign io_data = (addr[15:0]==16'hb7) ? io_reg : 16'd0;
  assign rd_data = m_io ? io_data : mem_data;

  // Behaviour
  // IO Stub
  always @(posedge clk) 
    if (addr==20'hb7 & ~we & m_io) 
      io_reg <= byte_m ? { io_reg[15:8], wr_data[7:0] } : wr_data;

  always #1 clk = ~clk;

  initial 
    begin
         clk <= 1'b1;
         rst <= 1'b0;
      #5 rst <= 1'b1;
      #2 rst <= 1'b0;
    end
   
endmodule
