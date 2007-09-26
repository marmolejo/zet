`timescale 10ns/100ps

module testbench;

  // Net declarations
  wire [15:0] rd_data;
  wire [15:0] wr_data;
  wire        we;
  wire [19:0] addr;
  wire        byte_m;  

  reg         clk, rst;

  // Module instantiations
  memory mem0 (clk, addr, wr_data, we, byte_m, rd_data);
  cpu    cpu0 (clk, rst, rd_data, wr_data, we, addr, byte_m);

  // Behaviour
  always #1 clk = ~clk;

  initial 
    begin
         clk <= 1'b1;
         rst <= 1'b0;
      #5 rst <= 1'b1;
      #2 rst <= 1'b0;
    end
   
endmodule
