module test_alu(clk_, rs_, rw_, e_, db_, led_, sw0_, sw1_);
  // IO Ports
  output rs_, rw_;
  output reg [7:0] led_;
  inout  [7:0] db_;
  output e_;
  input  clk_, sw0_, sw1_;

  // Net declarations
  wire clk_1M, boot, busy;
  reg go;
  wire [15:0] oflags;
  wire [31:0] out;
  reg [31:0] x;
  reg [15:0] y;
  reg [15:0] iflags;
  reg [3:1] t, f;
 
  // Instantiations
  altpll1 pll1(clk_, clk_1M,, boot);
  lcd_display d1({x, 4'd0, y, 5'd0, t, 1'b0, f}, {out, 4'd0, iflags[11:0], 4'd0, oflags[11:0]}, 
                 16'b1111111101111011, 16'b1111111101110111, 
                 go, busy, clk_1M, boot, rs_, rw_, e_, db_);
  alu alu0(x, y, out, t, f, iflags, oflags, 1'b1);

  // Behaviour
  always @(posedge clk_1M)
    if (~boot)
      begin
        // 1: A negativo, B positivo: A: ffff B: 0001, A+B=0, ZAPC
        x      <= 31'h0000ffff;
        y      <= 16'h0001;
        t      <= 3'd1;
        f      <= 3'd0;
        iflags <= 16'h0002;
        led_   <= 8'd0;
        go     <= 1'b0;
      end
    else
      case (led_)
        // Primera transferencia
        8'd00: if (~busy) begin go <= 1'b1; led_ <= 8'd01; end
        8'd01: if (busy) begin go <= 1'b0; led_ <= 8'd02; end

        // Siguiente transferencia
        // 2: A negativo, B positivo, A+B < 16 bits: A: ffff B: ffff, C 
        //                A+B=ffff SAPC
        8'd02: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd0;
                   iflags <= oflags;
                   led_   <= 8'd3;
                   go     <= 1'b1;
                 end
        8'd03: if (busy) begin go <= 1'b0; led_ <= 8'd04; end
        
        // Siguiente transferencia
        // 3: A positivo, B positivo, A+B < 16 bits: A: 0001 B: 0002, A+B=3, P
        8'd04: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h0001;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd0;
                   iflags <= oflags;
                   led_   <= 8'd5;
                   go     <= 1'b1;
                 end
        8'd05: if (busy) begin go <= 1'b0; led_ <= 8'd06; end
        
        // Siguiente transferencia
        // 4: A pos, B pos, A+B = 16 bits: A: 7fff B: 0001, A+B=8000, OSAP
        8'd06: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h7fff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd0;
                   iflags <= oflags;
                   led_   <= 8'd7;
                   go     <= 1'b1;
                 end
        8'd07: if (busy) begin go <= 1'b0; led_ <= 8'd08; end
        
        // Siguiente transferencia
        // 5: A neg, B neg, A+B = 16 bits: A: 8000 B: ffff, A+B=0fff OPC
        8'd08: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd0;
                   iflags <= oflags;
                   led_   <= 8'd9;
                   go     <= 1'b1;
                 end
        8'd09: if (busy) begin go <= 1'b0; led_ <= 8'd10; end
        
        // Siguiente transferencia
        // 6: A aleat, B aleat: A: 1a62 B: ed8a, A+B=
        8'd10: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h1a62;
                   y      <= 16'hed8a;
                   t      <= 3'd1;
                   f      <= 3'd0;
                   iflags <= oflags;
                   led_   <= 8'd11;
                   go     <= 1'b1;
                 end
        8'd11: if (busy) begin go <= 1'b0; led_ <= 8'd12; end
        
        // Siguiente transferencia
        // 7: A negativo, B positivo: A: ffff B: 0001, A+B=0, ZAPC
        8'd12: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd13;
                   go     <= 1'b1;
                 end
        8'd13: if (busy) begin go <= 1'b0; led_ <= 8'd14; end
        
        // Siguiente transferencia
        // 8: A negativo, B positivo, A+B < 16 bits: A: ffff B: ffff, C 
        //    A+B=ffff SAPC
        8'd14: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd15;
                   go     <= 1'b1;
                 end
        8'd15: if (busy) begin go <= 1'b0; led_ <= 8'd16; end
        
        // Siguiente transferencia
        // 9: A positivo, B positivo, A+B < 16 bits: A: 0001 B: 0002, A+B=3, P
        8'd16: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h0001;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd17;
                   go     <= 1'b1;
                 end
        8'd17: if (busy) begin go <= 1'b0; led_ <= 8'd18; end
        
        // Siguiente transferencia
        // 10: A pos, B pos, A+B = 16 bits: A: 7fff B: 0001, A+B=8000, OSAP
        8'd18: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h7fff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd19;
                   go     <= 1'b1;
                 end
        8'd19: if (busy) begin go <= 1'b0; led_ <= 8'd20; end

        // Siguiente transferencia
        // 11: A neg, B neg, A+B = 16 bits: A: 8000 B: ffff, A+B=0fff OPC
        8'd20: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd21;
                   go     <= 1'b1;
                 end
        8'd21: if (busy) begin go <= 1'b0; led_ <= 8'd22; end
        
        // Siguiente transferencia
        // 12: A aleat, B aleat: A: 027f B: 846c, A+B=
        8'd22: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h027f;
                   y      <= 16'h846c;
                   t      <= 3'd1;
                   f      <= 3'd1;
                   iflags <= oflags;
                   led_   <= 8'd23;
                   go     <= 1'b1;
                 end
        8'd23: if (busy) begin go <= 1'b0; led_ <= 8'd24; end
        
        // Siguiente transferencia
        // 13: A-, -1: A: ffff. Da carry, no debería cambiar el flag de C
        8'd24: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'h3b46;
                   t      <= 3'd1;
                   f      <= 3'd2;
                   iflags <= oflags;
                   led_   <= 8'd25;
                   go     <= 1'b1;
                 end
        8'd25: if (busy) begin go <= 1'b0; led_ <= 8'd26; end
        
        // Siguiente transferencia
        // 14: A+: 7fff. Overflow
        8'd26: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h7fff;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd2;
                   iflags <= oflags;
                   led_   <= 8'd27;
                   go     <= 1'b1;
                 end
        8'd27: if (busy) begin go <= 1'b0; led_ <= 8'd28; end
        
        // Siguiente transferencia
        // 15: A aleat. 4513
        8'd28: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h4513;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd2;
                   iflags <= oflags;
                   led_   <= 8'd29;
                   go     <= 1'b1;
                 end
        8'd29: if (busy) begin go <= 1'b0; led_ <= 8'd30; end
        
        // Siguiente transferencia
        // 16: A: 0000.
        8'd30: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h0000;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd3;
                   iflags <= oflags;
                   led_   <= 8'd31;
                   go     <= 1'b1;
                 end
        8'd31: if (busy) begin go <= 1'b0; led_ <= 8'd32; end
        
        // Siguiente transferencia
        // 17: B: 8000. Underflow
        8'd32: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd3;
                   iflags <= oflags;
                   led_   <= 8'd33;
                   go     <= 1'b1;
                 end
        8'd33: if (busy) begin go <= 1'b0; led_ <= 8'd34; end
        
        // Siguiente transferencia
        // 18: A aleat. c7db
        8'd34: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hc7db;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd3;
                   iflags <= oflags;
                   led_   <= 8'd35;
                   go     <= 1'b1;
                 end
        8'd35: if (busy) begin go <= 1'b0; led_ <= 8'd36; end
        
        // Siguiente transferencia
        // 19: A: 0
        8'd36: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h0000;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd4;
                   iflags <= oflags;
                   led_   <= 8'd37;
                   go     <= 1'b1;
                 end
        8'd37: if (busy) begin go <= 1'b0; led_ <= 8'd38; end
        
        // Siguiente transferencia
        // 20: A: 8000. Overflow
        8'd38: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd4;
                   iflags <= oflags;
                   led_   <= 8'd39;
                   go     <= 1'b1;
                 end
        8'd39: if (busy) begin go <= 1'b0; led_ <= 8'd40; end
        
        // Siguiente transferencia
        // 21: A aleat. fac4
        8'd40: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hfac4;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd4;
                   iflags <= oflags;
                   led_   <= 8'd41;
                   go     <= 1'b1;
                 end
        8'd41: if (busy) begin go <= 1'b0; led_ <= 8'd42; end
        
        // Siguiente transferencia
        // 22: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 
        //             A-B=ffff SAPC
        8'd42: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h0001;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd5;
                   iflags <= oflags;
                   led_   <= 8'd43;
                   go     <= 1'b1;
                 end
        8'd43: if (busy) begin go <= 1'b0; led_ <= 8'd44; end
        
        // Siguiente transferencia
        // 23: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff A-B=0 ZP
        8'd44: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd5;
                   iflags <= oflags;
                   led_   <= 8'd45;
                   go     <= 1'b1;
                 end
        8'd45: if (busy) begin go <= 1'b0; led_ <= 8'd46; end
        
        // Siguiente transferencia
        // 24: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
        8'd46: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd5;
                   iflags <= oflags;
                   led_   <= 8'd47;
                   go     <= 1'b1;
                 end
        8'd47: if (busy) begin go <= 1'b0; led_ <= 8'd48; end
        
        // Siguiente transferencia
        // 25: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
        8'd48: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd5;
                   iflags <= oflags;
                   led_   <= 8'd49;
                   go     <= 1'b1;
                 end
        8'd49: if (busy) begin go <= 1'b0; led_ <= 8'd50; end
        
        // Siguiente transferencia
        // 26: A aleat, B aleat, con carry: A: a627 B: 03c5, C A-B=
        8'd50: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'ha627;
                   y      <= 16'h03c5;
                   t      <= 3'd1;
                   f      <= 3'd5;
                   iflags <= {oflags[15:1], 1'b1};
                   led_   <= 8'd51;
                   go     <= 1'b1;
                 end
        8'd51: if (busy) begin go <= 1'b0; led_ <= 8'd52; end
        
        // Siguiente transferencia
        // 27: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 
        //             A-B=ffff SAPC
        8'd52: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h0001;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd6;
                   iflags <= oflags;
                   led_   <= 8'd53;
                   go     <= 1'b1;
                 end
        8'd53: if (busy) begin go <= 1'b0; led_ <= 8'd54; end
        
        // Siguiente transferencia
        // 28: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff 
        //             A-B=0 ZP
        8'd54: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd6;
                   iflags <= oflags;
                   led_   <= 8'd55;
                   go     <= 1'b1;
                 end
        8'd55: if (busy) begin go <= 1'b0; led_ <= 8'd56; end
        
        // Siguiente transferencia
        // 29: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
        8'd56: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd6;
                   iflags <= oflags;
                   led_   <= 8'd57;
                   go     <= 1'b1;
                 end
        8'd57: if (busy) begin go <= 1'b0; led_ <= 8'd58; end
        
        // Siguiente transferencia
        // 30: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
        8'd58: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd6;
                   iflags <= oflags;
                   led_   <= 8'd59;
                   go     <= 1'b1;
                 end
        8'd59: if (busy) begin go <= 1'b0; led_ <= 8'd60; end
        
        // Siguiente transferencia
        // 31: A aleat, B aleat, con carry: A: a627 B: 03c5, C A-B=
        8'd60: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'ha627;
                   y      <= 16'h03c5;
                   t      <= 3'd1;
                   f      <= 3'd6;
                   iflags <= {oflags[15:1], 1'b1};
                   led_   <= 8'd61;
                   go     <= 1'b1;
                 end
        8'd61: if (busy) begin go <= 1'b0; led_ <= 8'd62; end
        
        // Siguiente transferencia
        // 32: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 
        //             A-B=ffff SAPC
        8'd62: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'h0001;
                   y      <= 16'h0002;
                   t      <= 3'd1;
                   f      <= 3'd7;
                   iflags <= oflags;
                   led_   <= 8'd63;
                   go     <= 1'b1;
                 end
        8'd63: if (busy) begin go <= 1'b0; led_ <= 8'd64; end
        
        // Siguiente transferencia
        // 33: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff A-B=0 ZP
        8'd64: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'hffff;
                   t      <= 3'd1;
                   f      <= 3'd7;
                   iflags <= oflags;
                   led_   <= 8'd65;
                   go     <= 1'b1;
                 end
        8'd65: if (busy) begin go <= 1'b0; led_ <= 8'd66; end
        
        // Siguiente transferencia
        // 34: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
        8'd66: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'hffff;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd7;
                   iflags <= oflags;
                   led_   <= 8'd67;
                   go     <= 1'b1;
                 end
        8'd67: if (busy) begin go <= 1'b0; led_ <= 8'd68; end
        
        // Siguiente transferencia
        // 35: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
        8'd68: if (~sw1_ && ~busy) 
                 begin
                   x      <= 31'h8000;
                   y      <= 16'h0001;
                   t      <= 3'd1;
                   f      <= 3'd7;
                   iflags <= oflags;
                   led_   <= 8'd69;
                   go     <= 1'b1;
                 end
        8'd69: if (busy) begin go <= 1'b0; led_ <= 8'd70; end
        
        // Siguiente transferencia
        // 36: A aleat, B aleat, con carry: A: aa97 B: 3b46, C A-B=
        8'd70: if (~sw0_ && ~busy) 
                 begin
                   x      <= 31'haa97;
                   y      <= 16'h3b46;
                   t      <= 3'd1;
                   f      <= 3'd7;
                   iflags <= {oflags[15:1], 1'b1};
                   led_   <= 8'd71;
                   go     <= 1'b1;
                 end
        8'd71: if (busy) begin go <= 1'b0; led_ <= 8'd72; end
               
      endcase
endmodule