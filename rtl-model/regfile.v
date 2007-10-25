`timescale 1ns/10ps

module regfile(a, b, c, cs, ip, d, s, flags, wr, wrfl, wrhi, clk, rst,
               addr_a, addr_b, addr_c, addr_d, addr_s, iflags, word_op, 
               o_byte, c_byte, cx_zero);
  // IO Ports
  output [15:0] a, b, c, s;
  output [15:0] cs;
  input  [3:0]  addr_a, addr_b, addr_c, addr_d;
  input  [1:0]  addr_s;
  input  [8:0]  iflags;
  input  [31:0] d;
  input         wrfl, wrhi, word_op, clk, rst, o_byte, c_byte;
  input         wr;
  output        cx_zero;
  output [15:0] ip;
  output reg [8:0] flags;

  // Net declarations
  reg [15:0] r[15:0];
  wire [7:0] a8, b8, c8;

  // Assignments
  assign a = (o_byte & ~addr_a[3]) ? { {8{a8[7]}}, a8} : r[addr_a];
  assign a8 = addr_a[2] ? r[addr_a[1:0]][15:8] : r[addr_a][7:0];

  assign b = (o_byte & ~addr_b[3]) ? { {8{b8[7]}}, b8} : r[addr_b];
  assign b8 = addr_b[2] ? r[addr_b[1:0]][15:8] : r[addr_b][7:0];

  assign c = (c_byte & ~addr_c[3]) ? { {8{c8[7]}}, c8} : r[addr_c];
  assign c8 = addr_c[2] ? r[addr_c[1:0]][15:8] : r[addr_c][7:0];

  assign s = r[{2'b10,addr_s}];

  assign cs = r[9];
  assign cx_zero = (addr_d==4'd1) ? (d==16'd0) : (r[1]==16'd0);

  assign ip = r[15];

  // Behaviour
  always @(posedge clk)
    if (rst) begin
      r[0]  <= 16'd0; r[1]  <= 16'd0; 
      r[2]  <= 16'd0; r[3]  <= 16'd0; 
      r[4]  <= 16'd0; r[5]  <= 16'd0; 
      r[6]  <= 16'd0; r[7]  <= 16'd0; 
      r[8]  <= 16'd0; r[9]  <= 16'hf000;
      r[10] <= 16'd0; r[11] <= 16'd0; 
      r[12] <= 16'd0; r[13] <= 16'd0; 
      r[14] <= 16'd0; r[15] <= 16'hfff0;
      flags <= 9'd0;
    end else
      begin
        if (wr) begin
          if (word_op | addr_d[3:2]==2'b10) 
             r[addr_d] <= word_op ? d[15:0] : {{8{d[7]}},d[7:0]};
          else if (addr_d[3]~^addr_d[2]) r[addr_d][7:0] <= d[7:0];
          else r[{2'b0,addr_d[1:0]}][15:8] <= d[7:0];
        end
        if (wrfl) flags <= iflags;
        if (wrhi) r[4'd2] <= d[31:16];
      end
endmodule