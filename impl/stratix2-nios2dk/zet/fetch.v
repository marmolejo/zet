`include "defines.v"

module fetch(clk, reset, cs, ip, data, ir, off, imm, pc, bytefetch, fetch_or_exec);
  // IO ports
  input clk, reset;
  input [15:0] cs, ip;
  input [15:0] data;
  output [`IR_SIZE-1:0] ir;
  output reg [15:0] off;
  output [15:0] imm;
  output [19:0] pc;
  output bytefetch;
  output fetch_or_exec; 

  // Registers
  reg [3:0] state;
  reg [7:0] opcode_r, modrm_r;
  reg [15:0] off_m, imm_m, imm_r;
  reg [`IR_SIZE-1:0] ir_r;

  // Net declarations
  wire [19:0] pc;
  wire [7:0] opcode, modrm;
  wire sm, dm, need_modrm, need_off, need_imm, off_size, imm_size;
  wire [1:0] mod;
  wire [2:0] regm;
  wire [2:0] rm;
  wire       d;
  wire [2:0] dst, src;
  wire [3:0] base, index;
  wire [`IR_SIZE-1:0] ir0, ir1, ir2, ir3;
  wire [15:0] off0, off1, off2, off3;
  wire [15:0] imm0, imm1, imm2, imm3;
  wire [1:0] ninstrs; // Number of IRs

  // Module instantiation
  lookup_op op0(opcode, dst, sm, dm, src, base, index, 2'b11, off_m, mod, regm,
                imm_m, need_off, off_size, need_imm, imm_size, need_modrm, 
                ir0, ir1, ir2, off0, off1, off2, imm0, imm1, imm2, ninstrs, 
                clk);
  memory_regs mr(rm, mod, base, index);

  // Assignments
  assign pc = (cs << 4) + ip;
  assign mod = modrm[7:6];
  assign regm = modrm[5:3];
  assign rm = modrm[2:0];
  assign d = opcode[1];
  assign opcode = state ? opcode_r : data[7:0];
  assign modrm  = (state == 4'd1) ? data[7:0] : modrm_r;
  assign fetch_or_exec = (state > 4'h3 && state != 4'h8);

  assign dst = d ? regm : rm;
  assign sm  = d & (mod != 2'b11);
  assign dm  = ~d & (mod != 2'b11);
  assign src = d ? rm : regm;
  assign bytefetch = state[1] ? (state[0] ? ~imm_size : ~off_size) : 1'b1;
  assign imm = (state < 4'h4) ? 
   (((state == 4'h2) & off_size | (state==4'h3) & imm_size) ? 16'd2 : 16'd1) : imm_r;
  assign ir  = (state < 4'h4) ? `ADD_IP : ir_r;

  parameter state_0 = 4'h0;
  parameter state_1 = 4'h1;
  parameter state_2 = 4'h2;
  parameter state_3 = 4'h3;
  parameter state_4 = 4'h4;
  parameter state_5 = 4'h5;
  parameter state_6 = 4'h6;
  parameter state_7 = 4'h7;
  parameter state_8 = 4'h8;

  // Behaviour
  always @(posedge clk)
    if (~reset) state <= state_7;
    else
     case (state)

       state_0: // opcode fetch
         begin 
           opcode_r <= data[7:0]; 
           state    <= need_modrm ? state_1 : 
                       (need_off ? state_2 : need_imm ? state_3 : state_4);
           off_m    <= 16'h0;
         end

       state_1: // need modrm
         begin
           modrm_r <= data[7:0]; 
           state   <= need_off ? state_2 : (need_imm ? state_3 : state_4);
         end

       state_2: // need off
         begin
           off_m <= data;
           state <= need_imm ? state_3 : state_4;
         end

       state_3: // need imm
         begin
           imm_m <= data;
           state <= state_4;
         end

       state_4: // exec 1st IR
         begin
           ir_r  <= ir0;
           off   <= off0;
           imm_r <= imm0;
           state <= (ninstrs == 2'd1) ? state_7 : state_5;
         end

       state_5: // exec 2nd IR
         begin
           ir_r  <= ir1;
           off   <= off1;
           imm_r <= imm1;
           state <= (ninstrs == 2'd2) ? state_7 : state_6;
         end

       state_6: // exec 3rd IR
         begin
           ir_r  <= ir2;
           off   <= off2;
           imm_r <= imm2;
           state <= state_7;
         end

       state_7: begin ir_r <= `IR_SIZE'h0; state <= state_8; end
       state_8: state <= state_0;
       default: begin ir_r <= `IR_SIZE'h0; state <= state_8; end
     endcase

endmodule

module lookup_op (opcode, dst, sm, dm, src, base, index, seg, off, mod, regm, imm,
                  need_off, off_size, need_imm, imm_size, need_modrm, 
                  ir0, ir1, ir2, off0, off1, off2, imm0, imm1, imm2, ninstrs, 
                  clk);
  // IO Ports
  input [7:0] opcode;
  input [2:0] dst;  // destination register
  input       sm;   // source in memory?
  input       dm;   // dest in memory?
  input [2:0] src;  // source register
  input [3:0] base, index; // for memory access
  input [1:0] seg;  // segment register for memory ops
  input [15:0] off, imm; // offset and immediate operands
  input [1:0] mod; // offset mode
  input       clk;
  input [2:0] regm;

  output reg need_off, need_imm, imm_size, need_modrm, off_size;
  output [`IR_SIZE-1:0] ir0, ir1, ir2;
  output [15:0] off0, off1, off2;
  output [15:0] imm0, imm1, imm2;

  reg [`IR_SIZE-1:0] irs[2:0]; // irs for the operation
  reg [15:0] offs[2:0]; // offsets for the IRs
  reg [15:0] imms[2:0]; // Immediates for the IRs
  output reg [1:0] ninstrs; // Number of IRs

  // Net declarations
  wire off_size_mod, need_off_mod;
  wire b;

  // Assignments
  assign off_size_mod = (base == 4'b1100 && index == 4'b1100) ? 1'b1 : mod[1];
  assign need_off_mod = (base == 4'b1100 && index == 4'b1100) || ^mod;

  assign ir0  = irs[0]; assign ir1 = irs[1]; assign ir2 = irs[2];
  assign off0 = offs[0]; assign off1 = offs[1]; assign off2 = offs[2];
  assign imm0 = imms[0]; assign imm1 = imms[1]; assign imm2 = imms[2];

  assign b = ~opcode[0];

  // Behaviour
  always @(negedge clk)
    casex (opcode)
// r->r, r->m, m->r  s->m, s->r   r->s, m->s
   8'b1000_10xx,    8'b1000_1100, 8'b1000_1110: begin // mov
  if (dm) begin // [byte bs, word cs] r->m, s->m
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b  ad_a    s
    irs[0] <= { b, 1'b0, 1'b0, 1'bx, b & ~opcode[2], 3'b000, 3'b111, 1'b0, 2'b00, 1'b1, 1'b0, 4'bxxxx, opcode[2] & ~opcode[1], src, index, base, seg };
    need_off <= need_off_mod;
  end else if(sm) begin // [byte ds, word es] m->r, m->s
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b  ad_a    s
    irs[0] <= { b, 1'b0, 1'b0, 1'b0, b & ~opcode[2], 3'b000, 3'b111, 1'b0, 2'b01, 1'b0, 1'b0, opcode[2] & opcode[1], dst, 4'bxxxx, index, base, seg };
    need_off <= need_off_mod;
  end else begin // [byte 9s, word as] r->r s->r r->s
             //   ac  ab   im    ma  by    fun      t    wh    wr    wm    wf    ad_d      ad_c       ad_b      ad_a      s
    irs[0] <= { 1'bx, b & ~opcode[2], 1'b1, 1'b1, b, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, opcode[2] & opcode[1], dst, 4'bxxxx, 4'bxxxx, opcode[2] & ~opcode[1], src, 2'bxx };
    imms[0] <= 16'd0;
    need_off <= 1'b0;
  end
  need_imm <= 1'b0; need_modrm <= 1'b1; off_size <= off_size_mod; offs[0] <= off; ninstrs <= 2'd1;
 end

8'b1010_00xx: begin // mov
  if (opcode[1]) // a->m [byte bs, word cs]
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d     ad_c     ad_b     ad_a     s
    irs[0] <= { b, 1'b0, 1'b0, 1'bx, b, 3'b000, 3'b111, 1'b0, 2'b00, 1'b1, 1'b0, 4'bxxxx, 4'b0000, 4'b1100, 4'b1100, seg };
  else // m->a [byte ds, word es]
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b    ad_a     s
    irs[0] <= { b, 1'b0, 1'b0, 1'b0, b, 3'b000, 3'b111, 1'b0, 2'b01, 1'b0, 1'b0, 4'b0000, 4'bxxxx, 4'b1100, 4'b0000, seg };

  need_off <= 1'b1; need_imm <= 1'b0; need_modrm <= 1'b0; off_size <= 1'b1; offs[0] <= off; ninstrs <= 2'd1;
  end

8'b1011_xxxx: begin // mov [byte 13s, word 14s]
             //   ac    ab   im    ma       by        fun      t    wh    wr    wm    wf         ad_d           ad_c    ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'bx, 1'b1, 1'b1, ~opcode[3], 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 1'b0, opcode[2:0], 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    imms[0] <= imm;
    need_off <= 1'b0; need_imm <= 1'b1; imm_size <= opcode[3]; need_modrm <= 1'b0; off_size <= 1'bx;
    ninstrs <= 2'd1;
  end

8'b1100_011x: begin // mov [byte 15s, word 17s]
             //   ac    ab   im    ma  by     fun      t    wh    wr    wm    wf     ad_d     ad_c    ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'bx, 1'b1, 1'b1, b, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1101, 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    irs[1] <= { 1'bx, 1'b0, 1'b0, 1'bx, b, 3'b000, 3'b111, 1'b0, 2'b00, 1'b1, 1'b0, 4'bxxxx, 4'b1101, index,   base,    seg };
    imms[0] <= imm;
    offs[1] <= off;
    need_off <= need_off_mod; need_imm <= 1'b1; imm_size <= ~b; need_modrm <= 1'b1; off_size <= off_size_mod;
    ninstrs <= 2'd2;
  end

8'b1110_10x1: begin // jmp direct [off8 1s, off16 2s]
             //   ac    ab   im    ma    by     fun      t     wh    wr    wm    wf     ad_d     ad_c     ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'b0, 1'b1, 1'b1, 1'b0, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1111, 4'bxxxx, 4'bxxxx, 4'b1111, 2'bxx };
    imms[0] <= imm;
    need_off <= 1'b0; need_imm <= 1'b1; imm_size <= ~opcode[1]; need_modrm <= 1'b0; off_size <= 1'bx;
    ninstrs <= 2'd1;
  end

8'b1110_1010: begin // jmp indirect different segment [5s]
             //   ac    ab   im    ma    by     fun      t    wh      wr    wm    wf     ad_d     ad_c    ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'b0, 1'b1, 1'b1, 1'b0, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1001, 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    irs[1] <= { 1'bx, 1'b0, 1'b1, 1'b1, 1'b0, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1111, 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    imms[0] <= imm;
    imms[1] <= off;
    need_modrm <= 1'b0; need_off <= 1'b1; off_size <= 1'b1; need_imm <= 1'b1; imm_size <= 1'b1; 
    ninstrs <= 2'd2;
  end

8'b1111_1111: begin 
  case (regm)
    3'b100: begin // jmp indirect, same seg
      if (mod==2'b11) begin // [3s]
        irs[0] <= { 1'bx, 1'b0, 1'b1, 1'b1, 1'b0, 3'b001, 3'b001, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1111, 4'bxxxx, 4'bxxxx, 1'b0, src, 2'bxx };
        imms[0] <= 16'd0;
      end else // [4s]
        irs[0] <= { 1'bx, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'b111, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1111, 4'bxxxx, index, base, 2'b10 };
      ninstrs <= 2'd1;
    end 
    3'b101: begin // jmp indirect, different seg [7s]
               //   ac    ab   im    ma    by     fun      t    wh      wr    wm    wf     ad_d     ad_c    ad_b  ad_a   s
      irs[0] <= { 1'bx, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'b111, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1111, 4'bxxxx, index, base, 2'b10 };
      irs[1] <= { 1'bx, 1'b0, 1'b0, 1'b0, 1'b0, 3'b001, 3'b111, 1'b0, 2'b01, 1'b0, 1'b0, 4'b1001, 4'bxxxx, index, base, 2'b10 };
      offs[1] <= off;
      ninstrs <= 2'd2;    
    end
  endcase
  offs[0] <= off;
  need_modrm <= 1'b1; need_off <= need_off_mod; off_size <= off_size_mod; need_imm <= 1'b0; imm_size <= 1'bx; 
  end

    endcase
endmodule

module memory_regs(rm, mod, base, index);
  // IO Ports
  input  [2:0] rm;
  input  [1:0] mod;
  output reg [3:0] base, index;

  // Behaviour
  always @(rm or mod)
    case (rm)
      3'b000: begin base <= 4'b0011; index <= 4'b0110; end
      3'b001: begin base <= 4'b0011; index <= 4'b0111; end
      3'b010: begin base <= 4'b0101; index <= 4'b0110; end
      3'b011: begin base <= 4'b0101; index <= 4'b0111; end
      3'b100: begin base <= 4'b1100; index <= 4'b0110; end
      3'b101: begin base <= 4'b1100; index <= 4'b0111; end
      3'b110: begin base <= mod ? 4'b0101 : 4'b1100; index <= 4'b1100; end
      3'b111: begin base <= 4'b0011; index <= 4'b1100; end
    endcase
endmodule
