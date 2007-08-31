module memory (rd_data, wr_data, we, addr_data, w_b, clk, clk2x, boot,
               addr_, roe_, rwe_, rcs_, 
               data0_, data1_, rble0_, rbhe0_, rble1_, rbhe1_);

  // IO Ports
  input [15:0] wr_data;
  input [19:0] addr_data;
  input we; // Write enable: when 0 write to mem, 1 don't write
  input w_b; // When 0, word operation, si vale 1 operación de byte
  input clk, clk2x; // Los relojes
  input boot;

  // Salidas
  output reg [15:0] rd_data;  // Salida leída de memoria
  output roe_, rcs_;                     // roe_: SRAM Output Enable
  output reg rwe_;                       // rwe_: SRAM Write Enable
  output rble0_, rbhe0_, rble1_, rbhe1_; // rcs_: SRAM Chip Select
                                         // rble_: SRAM Byte Low Enable
                                         // rbhe_: SRAM Byte High Enable
  output reg [17:0] addr_;           // addr_: la dirección física a los chips
  
  // Pins de entrada/salida
  inout [15:0] data0_, data1_;           // data_: Datos de entrada/salida

  // Net declarations
  wire [15:0] rd, bhr, blr;              // rd: word de SRAM
                                         // bhr: Byte High RAM
                                         // blr: Byte Low RAM
  wire [15:0] rddata;
  wire a0;
  wire [15:0] wr;
  wire [17:0] addr1; 
  reg  [3:0]  state;
  reg  reset;
  reg  rble, rbhe;

  // Assignments
  assign a0     = addr_data[0];
  assign rd     = addr_data[19] ? data1_ : data0_ ;  // Word de SRAM
  assign bhr    = { {8{rd[15]}}, rd[15:8] };
  assign blr    = { {8{rd[7]}}, rd[7:0] };

  assign roe_   = ~we;
  assign rcs_   = 1'b0;

  assign addr1  = addr_data[18:1] + 18'd1;

  assign data0_  = we ? 16'hzzzz : wr;
  assign data1_  = we ? 16'hzzzz : wr;
  assign wr      = a0 ? {wr_data[7:0],wr_data[15:8]} : wr_data;

  assign rddata  = w_b ? (a0 ? bhr:blr) : (a0 ? bhr:rd);

  assign rble0_  = addr_data[19] | rble;
  assign rbhe0_  = addr_data[19] | rbhe;
  assign rble1_  = ~addr_data[19] | rble;
  assign rbhe1_  = ~addr_data[19] | rbhe;

  always @(posedge clk)
    if (~boot) reset <= 1'b1;
    else reset <= 1'b0;

  always @(posedge clk2x) 
    begin
      case (state)
        4'd0: begin rble <= ~we & a0; rbhe <= ~we & w_b & ~a0; end
        4'd1: addr_ <= addr_data[18:1];
        4'd2: rwe_ <= we;
        4'd3: if (~we) rwe_ <= 1'b1; else rd_data <= rddata;
        4'd4: if (~we & ~w_b & a0) begin rble <= 1'b0; rbhe <= 1'b1; end
        4'd5: addr_ <= addr1;
        4'd6: rwe_ <= we | w_b | ~a0;
        4'd7: begin rwe_ <= 1'b1; if(~w_b & a0) rd_data[15:8] <= blr[7:0]; end
        4'd8: addr_ <= 18'hz;
      endcase
      if (reset) begin rwe_ <= 1'b1; state <= 4'd8; end
      else if (clk & state[3]) 
        begin /* rble <= ~we & a0; rbhe <= ~we & w_b & ~a0;*/ state <= 4'd0; end
      else state <= state + 4'd1;
    end
endmodule