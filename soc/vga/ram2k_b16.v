`timescale 1ns/10ps

module ram_2k (clk, rst, cs, we, addr, rdata, wdata);
  // IO Ports
  input clk;
  input rst;
  input cs;
  input we;
  input [10:0] addr;
  output [7:0] rdata;
  input [7:0] wdata;

  // Net declarations
  wire dp;

  // Module instantiations
  RAMB16_S9 ram (.DO(rdata),
                 .DOP (dp),
                 .ADDR (addr),
                 .CLK (clk),
                 .DI (wdata),
                 .DIP (dp),
                 .EN (cs),
                 .SSR (rst),
                 .WE (we));

    defparam ram.INIT_00 = 256'h554456_2043504F53_20302E3176_20726F737365636F7270_2074655A;

endmodule