module char_rom (
    input  [11:0] addr,
    output [ 7:0] q
  );

  // Registers, nets and parameters
  reg [7:0] rom[0:4095];

  // Assignments
  assign q = rom[addr];

  // Behaviour
  initial $readmemh("/home/zeus/zet/cores/vga/rtl/char_rom.dat", rom);
endmodule
