`include "defines.v"

module cpu(clk_, addr_, roe_, rwe_, rcs_, 
           data0_, data1_, rble0_, rbhe0_, rble1_, rbhe1_);
  // IO Ports
  input  clk_;
  output [17:0] addr_;
  inout  [15:0] data0_, data1_;
  output roe_, rwe_, rcs_, rble0_, rbhe0_, rble1_, rbhe1_;

  // Net declarations
  wire [15:0] cs, ip;
  wire clk, boot;
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off, imm, data;
  wire [19:0] addr, addr_exec, addr_fetch;
  wire byte_fetch, byte_m, byte_exec, fetch_or_exec;
  wire [15:0] rd_data, wr_data;
  wire we, we_cpu;

  // Instantiations
  altpll0 pll0(clk_, clk, boot);
  fetch   fetch0(clk, boot, cs, ip, rd_data, ir, off, imm, addr_fetch, 
                 byte_fetch, fetch_or_exec);
  exec    exec0(ir, off, imm, cs, ip, clk, boot, 
                rd_data, wr_data, we, addr_exec, byte_exec);
  memory  mem0( rd_data, wr_data, we_cpu, addr, byte_m, clk, clk_, boot,
                addr_, roe_, rwe_, rcs_, 
                data0_, data1_, rble0_, rbhe0_, rble1_, rbhe1_);

  // Assignments
  assign addr   = fetch_or_exec ? addr_exec : addr_fetch;
  assign byte_m = fetch_or_exec ? byte_exec : byte_fetch;
  assign we_cpu = fetch_or_exec ? we : 1'b1;
endmodule