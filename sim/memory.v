`timescale 1ns/10ps

module memory (
    input         clk,
    input  [19:0] addr,
    input  [15:0] wr_data,
    output [15:0] rd_data,
    input         we,
    input         byte_m
  );

  // Registers and nets
  wire [19:0] addr1;

  reg [7:0] ram[2**20-1:0];

  // Assignments
  assign rd_data = byte_m ? { {8{ram[addr][7]}}, ram[addr]} 
                  : {ram[addr1], ram[addr]};
  assign addr1   = addr + 20'd1;

  // Behaviour
  always @(posedge clk) 
    if (we) if (byte_m) ram[addr] <= wr_data[7:0];
            else { ram[addr1], ram[addr] } <= wr_data;

  initial $readmemh("/home/zeus/zet/sim/13_bcdcnv.rtlrom", ram, 20'hf0000);
endmodule
