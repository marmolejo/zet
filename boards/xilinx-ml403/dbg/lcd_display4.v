module lcd_display4 (
    input [63:0] f1,
    input [63:0] f2,
    input [15:0] m1,
    input [15:0] m2,

    input       clk,
    input       rst,

    output reg  rs_,
    output reg  rw_,
    output      e_,
    inout [3:0] db_,
    output reg [5:0] st
  );

  // Net declarations
  reg [3:0] wr;
  reg [3:0] x;
  wire [3:0] out_m1, out_m2;
  wire b, mask1, mask2;

  // Module instantiations
  mux16_4 mux1(x, f1[63:60], f1[59:56], f1[55:52], f1[51:48], f1[47:44], f1[43:40], 
                  f1[39:36], f1[35:32], f1[31:28], f1[27:24], f1[23:20], f1[19:16],
                  f1[15:12], f1[11:08], f1[07:04], f1[03:00], out_m1);

  mux16_4 mux2(x, f2[63:60], f2[59:56], f2[55:52], f2[51:48], f2[47:44], f2[43:40], 
                  f2[39:36], f2[35:32], f2[31:28], f2[27:24], f2[23:20], f2[19:16],
                  f2[15:12], f2[11:08], f2[07:04], f2[03:00], out_m2);

  mux16_1 mux3(x, m1[15], m1[14], m1[13], m1[12], m1[11], m1[10], m1[9], m1[8], 
                  m1[7],  m1[6],  m1[5],  m1[4],  m1[3],  m1[2],  m1[1], m1[0], mask1);

  mux16_1 mux4(x, m2[15], m2[14], m2[13], m2[12], m2[11], m2[10], m2[9], m2[8], 
                  m2[7],  m2[6],  m2[5],  m2[4],  m2[3],  m2[2],  m2[1], m2[0], mask2);

  // Assignments
  assign b = db_[3];
  assign db_ = rw_ ? 4'bz : wr;
  assign e_ = clk;

  // Behavioral
  always @(posedge clk)
    if (rst)
      begin
        st  <= 8'h4;
        rs_ <= 1'b0; // 0: Instruction reg (busy flag)
        rw_ <= 1'b1;  // 1: Read
        x   <= 4'b0;
      end
    else
      case (st)
        8'd00: if (!b) st <= 8'd04;

        // Establece el modo de operacion de 4 bits
        8'd01: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h2; st <= 8'd02; end
        8'd02: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd04; end
        8'd03: if (!b) st <= 8'd04;

        // Ahora en 4 bits, establece el modo de operacion de 4 bits y selecciona
        // el display de 2 lineas y caracteres de 5x8
        8'd04: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h2; st <= 8'd05; end
        8'd05: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h8; st <= 8'd08; end
        8'd06: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd07; end
        8'd07: if (!b) st <= 8'd08;

        // Enciende el display y enciende el cursor
        8'd08: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h0; st <= 8'd09; end
        8'd09: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'hc; st <= 8'd12; end
        8'd10: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd12; end
        8'd11: if (!b) st <= 8'd12;

        // Clear del display
        8'd12: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h0; st <= 8'd13; end
        8'd13: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h1; st <= 8'd16; end
        8'd14: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd16; end
        8'd15: if (!b) st <= 8'd16;

        // Entry mode set
        8'd16: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h0; st <= 8'd17; end
        8'd17: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h6; st <= 8'd20; end
        8'd18: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd20; end
        8'd19: if (!b) st <= 8'd20;

        // 1st row
        8'd20: begin
                 rs_ <= 1'b1; rw_ <= 1'b0; 
                 if (mask1) wr <= itoa1(out_m1);
                 else wr <= 4'h2; // Espacio en blanco
                 st <= 8'd21;
               end
        8'd21: begin
                 rs_ <= 1'b1; rw_ <= 1'b0;
                 if (mask1) wr <= itoa0(out_m1);
                 else wr <= 4'h0; // Espacio en blanco
                 x <= x + 4'd1;
                 st <= 8'd20;
               end
        8'd22: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd24; end
        8'd23: if (!b) st <= 8'd24;
        8'd24: if (x == 4'd00) st <= 8'd25; else st <= 8'd20;

        // Movemos el cursor a la segunda fila
        8'd25: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'hc; st <= 8'd26; end
        8'd26: begin rs_ <= 1'b0; rw_ <= 1'b0; wr <= 4'h0; st <= 8'd27; end
        8'd27: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd29; end
        8'd28: if (!b) st <= 8'd29;

        // 2nd row
        8'd29: begin
                 rs_ <= 1'b1; rw_ <= 1'b0;
                 if (mask2) wr <= itoa1(out_m2);
                 else wr <= 4'h2; // Espacio en blanco
                 st <= 8'd30;
               end
        8'd30: begin
                 rs_ <= 1'b1; rw_ <= 1'b0;
                 if (mask2) wr <= itoa0(out_m2);
                 else wr <= 4'h0; // Espacio en blanco
                 x <= x + 4'd1;
                 st <= 8'd31;
               end
        8'd31: begin rs_ <= 1'b0; rw_ <= 1'b1; st <= 8'd33; end
        8'd32: if (!b) st <= 8'd33;
        8'd33: if (x == 4'd00) st <= 8'd34; else st <= 8'd29;
      endcase

  // Pasa un entero de 4 bits a su carácter hexadecimal
  // Function definitions
  function [3:0] itoa1;
    input [3:0] i;
    begin
      if (i < 8'd10) itoa1 = 4'h3;
      else itoa1 = 4'h6;
    end
  endfunction

  function [3:0] itoa0;
    input [3:0] i;
    begin
      if (i < 8'd10) itoa0 = i + 4'h0;
      else itoa0 = i + 4'h7;
    end
  endfunction
endmodule

//
// Multiplexor 16:1 de 4 bits d'amplada
//
module mux16_4(sel, in0, in1, in2, in3, in4, in5, in6, in7, 
                    in8, in9, in10, in11, in12, in13, in14, in15, out);
  input  [3:0]  sel;
  input  [3:0] in0, in1, in2, in3, in4, in5, in6, in7;
  input  [3:0] in8, in9, in10, in11, in12, in13, in14, in15;
  output [3:0] out;

  reg    [3:0] out;

  always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7
               or in8 or in9 or in10 or in11 or in12 or in13 or in14 or in15)
    case(sel)
     4'd00:  out = in0;
     4'd01:  out = in1;
     4'd02:  out = in2;
     4'd03:  out = in3;
     4'd04:  out = in4;
     4'd05:  out = in5;
     4'd06:  out = in6;
     4'd07:  out = in7;
     4'd08:  out = in8;
     4'd09:  out = in9;
     4'd10:  out = in10;
     4'd11:  out = in11;
     4'd12:  out = in12;
     4'd13:  out = in13;
     4'd14:  out = in14;
     4'd15:  out = in15;
    endcase
endmodule

//
// Multiplexor 16:1 d'1 bits d'amplada
//
module mux16_1(sel, in0, in1, in2, in3, in4, in5, in6, in7, 
                    in8, in9, in10, in11, in12, in13, in14, in15, out);
  input  [3:0]  sel;
  input  in0, in1, in2, in3, in4, in5, in6, in7;
  input  in8, in9, in10, in11, in12, in13, in14, in15;
  output out;

  reg    out;

  always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7
               or in8 or in9 or in10 or in11 or in12 or in13 or in14 or in15)
    case(sel)
     4'd00:  out = in0;
     4'd01:  out = in1;
     4'd02:  out = in2;
     4'd03:  out = in3;
     4'd04:  out = in4;
     4'd05:  out = in5;
     4'd06:  out = in6;
     4'd07:  out = in7;
     4'd08:  out = in8;
     4'd09:  out = in9;
     4'd10:  out = in10;
     4'd11:  out = in11;
     4'd12:  out = in12;
     4'd13:  out = in13;
     4'd14:  out = in14;
     4'd15:  out = in15;
    endcase
endmodule
