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
  reg  [2:0]  state;
  reg  reset;
  reg  rble, rbhe;

  parameter state_0 = 3'd0;
  parameter state_1 = 3'd1;
  parameter state_2 = 3'd2;
  parameter state_3 = 3'd3;
  parameter state_4 = 3'd4;
  parameter state_5 = 3'd5;
  parameter state_6 = 3'd6;
  parameter state_7 = 3'd7;

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
        state_0: begin rble <= ~we & a0; rbhe <= ~we & w_b & ~a0; state <= state_1; end
        state_1: begin addr_ <= addr_data[18:1]; state <= state_2; end
        state_2: begin rwe_ <= we; state <= state_3; end
        state_3: begin if (~we) rwe_ <= 1'b1; else rd_data <= rddata; state <= state_4; end
        state_4: begin if (~we & ~w_b & a0) begin rble <= 1'b0; rbhe <= 1'b1; end state <= state_5; end
        state_5: begin addr_ <= addr1; state <= state_6; end
        state_6: begin rwe_ <= we | w_b | ~a0; state <= state_7; end
        default: begin 
                   rwe_ <= 1'b1; 
                   if (clk) state <= state_0; 
                   addr_ <= 18'hz; 
                   if(~w_b & a0) rd_data[15:8] <= blr[7:0]; 
                 end
      endcase
      if (reset) begin rwe_ <= 1'b1; state <= state_7; end
    end
endmodule