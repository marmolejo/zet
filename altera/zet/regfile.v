module regfile(a, b, c, cs, d, s, oflags, wr, wrfl, wrhi, clk, boot,
               addr_a, addr_b, addr_c, addr_d, addr_s, iflags, word_op, o_byte, c_byte);
  // IO Ports
  output [15:0] a, b, c, s, oflags;
  output [15:0] cs;
  input  [3:0]  addr_a, addr_b, addr_c, addr_d;
  input  [1:0]  addr_s;
  input  [15:0] iflags;
  input  [31:0] d;
  input         wrfl, wrhi, word_op, clk, boot, o_byte, c_byte;
  input  [1:0]  wr;

  // Net declarations
  reg [15:0] r[15:0];
  reg [8:0] flags;
  reg [4:0] i;  
  wire [7:0] a8, b8, c8;
  wire [3:0] addr_a2, addr_b2, addr_c2;

  // Assignments
  assign a = (o_byte & ~addr_a[3]) ? { {8{a8[7]}}, a8} : r[addr_a];
  assign a8 = addr_a[2] ? r[addr_a2][15:8] : r[addr_a][7:0];
  assign addr_a2 = {2'b0, addr_a[1:0]};

  assign b = (o_byte & ~addr_b[3]) ? { {8{b8[7]}}, b8} : r[addr_b];
  assign b8 = addr_b[2] ? r[addr_b2][15:8] : r[addr_b][7:0];
  assign addr_b2 = {2'b0, addr_b[1:0]};

  assign c = (c_byte & ~addr_c[3]) ? { {8{c8[7]}}, c8} : r[addr_c];
  assign c8 = addr_c[2] ? r[addr_c2][15:8] : r[addr_c][7:0];
  assign addr_c2 = {2'b0, addr_c[1:0]};

  assign s = r[{2'b10,addr_s}];
  assign oflags = { 4'd0, flags[8:3], 1'b0, flags[2], 1'b0, 
                    flags[1], 1'b1, flags[0] };

  assign cs = r[9];

  // Behaviour
  always @(posedge clk)
    if (~boot) begin
      for (i=5'd0; i<5'd16; i=i+5'd1) r[i] = 16'd0;
      r[9][15:12] <= 4'hf;
      r[15] <= 16'hfff0;
    end else
      begin
        if (wr[0] & ( ~wr[1] | wr[1] & r[addr_c][0])) begin
          if (word_op | addr_d[3:2]==2'b10) r[addr_d] <= d[15:0];
          else if (addr_d[3]~^addr_d[2]) r[addr_d][7:0] <= d[7:0];
          else r[{2'b0,addr_d[1:0]}][15:8] = d[7:0];
        end
        if (wrfl) flags <= { iflags[11:6], iflags[4], iflags[2], iflags[0] };
        if (wrhi) r[4'd2] <= d[31:16];
      end
endmodule