module test_exec(clk_, ir, off, imm, 
                 addr_, data_, roe_, rwe_, rcs_, rble_, rbhe_);
  // IO Ports
  input  clk_;
  output [17:0] addr_;
  inout  [15:0] data_;
  output roe_, rwe_, rcs_, rble_, rbhe_;

  // Net declarations
  wire clk_5M, clk2x, boot;
  input [32:0] ir;
  input [15:0] off, imm;

  // Instantiations
  altpll0 pll0(clk_, clk_5M, clk2x, boot);
  exec exec0(ir, off, imm, clk_5M, clk2x, boot, 
             addr_, data_, roe_, rwe_, rcs_, rble_, rbhe_);
endmodule