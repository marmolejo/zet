`timescale 1ns/10ps

`include "defines.v"

module cpu (
    // Wishbone signals
    input         clk_i,
    input         rst_i,
    input  [15:0] dat_i,
    output [15:0] dat_o,
    output [19:0] adr_o,
    output        we_o,
    output        mio_o,
    output        byte_o,
    output        stb_o,
    input         ack_i,
    output [15:0] cs,
    output [15:0] ip
  );

  // Net declarations
  // wire [15:0] cs, ip;
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off, imm;
  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, byte_exec, fetch_or_exec;
  wire of, zf, cx_zero;

  // Module instantiations
  fetch   fetch0(clk_i, rst_i, cs, ip, of, zf, cx_zero, dat_i, ir, off, 
                 imm, addr_fetch, byte_fetch, fetch_or_exec, ack_i);
  exec    exec0(ir, off, imm, cs, ip, of, zf, cx_zero, clk_i, rst_i, 
                dat_i, dat_o, addr_exec, we_o, mio_o, byte_exec, ack_i);

  // Assignments 
  assign adr_o   = fetch_or_exec ? addr_exec : addr_fetch;
  assign byte_o = fetch_or_exec ? byte_exec : byte_fetch;
  assign stb_o = rst_i ? 1'b1 : ir[`MEM_OP];
endmodule
