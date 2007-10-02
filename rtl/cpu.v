`timescale 1ns/10ps

`include "defines.v"

module cpu(
    input clk,
    input rst,
    input  [15:0] rd_data, 
    output [15:0] wr_data,
    output [19:0] addr,
    output we,
    output m_io,
    output byte_m
  );

  // Net declarations
  wire [15:0] cs, ip;
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off, imm, data;
  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, byte_exec, fetch_or_exec;

  // Module instantiations
  fetch   fetch0(clk, rst, cs, ip, rd_data, ir, off, imm, addr_fetch, 
                 byte_fetch, fetch_or_exec);
  exec    exec0(ir, off, imm, cs, ip, clk, rst, 
                rd_data, wr_data, addr_exec, we, m_io, byte_exec);
  
  // Assignments 
  assign addr   = fetch_or_exec ? addr_exec : addr_fetch;
  assign byte_m = fetch_or_exec ? byte_exec : byte_fetch;

endmodule
