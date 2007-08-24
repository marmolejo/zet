module memory (rd_data, wr_data, we, addr_data, w_b, clk, clk2x,
               addr_, data_, roe_, rwe_, rcs_, rble_, rbhe_);

  // IO Ports
  input [15:0] wr_data;
  input [19:0] addr_data;
  input we; // Write enable: when 0 write to mem, 1 don't write
  input w_b; // When 0, word_operation operación de word, si vale 1 operación de byte
  input clk, clk2x; // Los relojes

  // Salidas
  output [15:0] rd_data;  // Salida leída de memoria
  output roe_, rwe_, rcs_, rble_, rbhe_; // roe_: SRAM Output Enable
                                         // rwe_: SRAM Write Enable
                                         // rcs_: SRAM Chip Select
                                         // rble_: SRAM Byte Low Enable
                                         // rbhe_: SRAM Byte High Enable
  output [17:0] addr_;               // addr_: la dirección física a los chips
  
  // Pins de entrada/salida
  inout [15:0] data_;                    // data_: Datos de entrada/salida

  // Net declarations
  wire [15:0] rd, bhr, blr;              // rd: word de SRAM
                                         // bhr: Byte High RAM
                                         // blr: Byte Low RAM
  wire a0, odd_word, rwe;
  wire [15:0] wr;
  wire [18:0] addr1; 
  reg  [7:0]  bhreg;

  // Assignments
  assign a0     = addr_data[0];
  assign odd_word = a0 & ~w_b;
  assign rd     = data_;  // Word de SRAM
  assign bhr    = { {8{rd[15]}}, rd[15:8] };
  assign blr    = { {8{rd[7]}}, rd[7:0] };

  assign roe_   = ~we;
  assign rcs_   = 1'b0;
  assign rwe    = we | (~clk & ~odd_word);
  assign rwe_   = ~clk2x | rwe;

  assign rble_  = ~we & (clk & a0 | ~clk & (~a0 | w_b)); // Doc. en el wiki
  assign rbhe_  = ~we & ~clk | ~we & w_b & ~a0;          // Doc. en el wiki

  assign addr_  = (~clk & odd_word) ? addr1[17:0] :addr_data[18:1];
  assign addr1  = addr_data[19:1] + 18'd1;

  assign data_   = we ? 16'hzzzz : wr; 
  assign wr      = a0 ? {wr_data[7:0],wr_data[15:8]} : wr_data;

  assign rd_data = w_b ? (a0 ? bhr:blr) : (a0 ? {blr[7:0],bhreg} :rd);

  always @(negedge clk) bhreg <= bhr[7:0];
endmodule