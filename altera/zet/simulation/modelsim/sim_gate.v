`timescale 10ns/100ps

module sim_gate;

  // Registers
  reg clk_;
  reg [32:0] ir;
  reg [15:0] off, imm;

  // Net declarations
  wire roe_, rwe_, rcs_, rble_, rbhe_;
  wire [17:0] addr_;
  wire [15:0] data_;

  // Module instantiations
  test_exec t0(clk_, ir, off, imm, addr_, data_, roe_, rwe_, rcs_, rble_, rbhe_);
  idt71v416s10 idt0(data_, addr_, rwe_, roe_, rcs_, rble_, rbhe_);

  // Behavioral
  initial clk_ <= 1'b0;

  always #2 clk_ = ~clk_;

  initial
    begin            // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #35 ir      = 33'b0__0__0__0__0_000_000__0__0__0__0_0000_0000_0000_0000_00;
           imm     = 16'h0000;
           off     = 16'h0000;

       // mov immediates to registers and memory in byte and word modes
                     // MODO 4 word
                     // mov ax, 0001h
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'b0__1__1__0_001_001__0__1__0__0_0000_xxxx_xxxx_1100_xx;
           imm     = 16'h0001;
           off     = 16'hxxxx;

                     // MODO 5 word
                     // mov [bx], 3241h
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__x__1__1__0_001_001__0__1__0__0_1101_xxxx_xxxx_1100_xx;
           imm     = 16'h3241;
           off     = 16'hxxxx;
                     // MODO 2 word (implícito en el modo 5)
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'b0__0__0__x__0_000_111__0__0__1__0_xxxx_1101_0011_1100_11;
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 3 word
                     // mov dx, [cx]
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__0__0__0__0_000_111__0__1__0__0_0010_xxxx_0001_1100_11;
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 1 word
                     // mov cx, dx
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__0__1__1__0_001_001__0__1__0__0_0001_xxxx_xxxx_0010_xx;
           imm     = 16'h0000;
           off     = 16'hxxxx;

                     // MODO 2 word, Store en dirección impar
                     // mov [ax], cx ; mem[01] = 3241h
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'b0__0__0__x__0_000_111__0__0__1__0_xxxx_0001_0000_1100_11;  // st
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 2 word, Load en dirección impar
                     // mov dx, [ax]
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__0__0__0__0_000_111__0__1__0__0_0010_xxxx_0000_1100_11;  // ld
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 4 byte
                     // mov ch, 76h
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__x__1__1__1_001_001__0__1__0__0_0101_xxxx_xxxx_1100_xx;
           imm     = 16'hxx76;
           off     = 16'hxxxx;

                     // MODO 5 byte: mov [bx], 79h; store, dirección par
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__x__1__1__1_001_001__0__1__0__0_1101_xxxx_xxxx_1100_xx;
           imm     = 16'hxx79;
           off     = 16'hxxxx;
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__0__0__x__1_000_111__0__0__1__0_xxxx_1101_0011_1100_11;
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 2 byte: mov [ax], ch; store, dirección impar
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'b1__0__0__x__1_000_111__0__0__1__0_xxxx_0101_0000_1100_11;
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 3 byte: mov dl, [bx]
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__0__0__0__1_000_111__0__1__0__0_0010_xxxx_0011_1100_11;
           imm     = 16'hxxxx;
           off     = 16'h0000;

                     // MODO 1 byte: mov dl, dh
                     // ac ab im ma by fun  t  wh wr wm wf ad_d ad_c ad_b ad_a  s
       #40 ir      = 33'bx__1__1__1__1_001_001__0__1__0__0_0010_xxxx_xxxx_0110_xx;
           imm     = 16'h0000;
           off     = 16'hxxxx;

    end

endmodule