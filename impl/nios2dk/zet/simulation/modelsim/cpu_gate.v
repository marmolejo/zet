`timescale 10ns/100ps

module cpu_gate;

  // Registers
  reg clk_;

  // Net declarations
  wire roe_, rwe_, rcs_, rble0_, rbhe0_, rble1_, rbhe1_;
  wire [17:0] addr_;
  wire [15:0] data0_, data1_;

  // Module instantiations
  cpu cpu0(clk_, addr_, roe_, rwe_, rcs_, 
           data0_, data1_, rble0_, rbhe0_, rble1_, rbhe1_);
  idt71v416s10 mem0(data0_, addr_, rwe_, roe_, rcs_, rble0_, rbhe0_);
  idt71v416s10 mem1(data1_, addr_, rwe_, roe_, rcs_, rble1_, rbhe1_);

  // Behavioral
  initial clk_ <= 1'b0;

  always #1 clk_ = ~clk_;

  initial 
    begin
      $readmemh("bios0.dat", mem1.mem1, 229376);
      $readmemh("bios1.dat", mem1.mem2, 229376);
    end
endmodule