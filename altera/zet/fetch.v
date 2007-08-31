`include "defines.v"

module fetch(clk, boot, cs, ir, off, imm, pc, data, bytefetch, fetch_or_exec);
  // IO ports
  input clk, boot;
  input [15:0] cs;
  input [15:0] data;
  output reg [`IR_SIZE-1:0] ir;
  output reg [15:0] off, imm;
  output [19:0] pc;
  output bytefetch;
  output fetch_or_exec; 

  // Registers
  reg [15:0] ip;
  reg [3:0] state;
  reg [7:0] opcode_r, modrm_r;
  reg [15:0] off_m, imm_m;

  // Net declarations
  wire [19:0] pc;
  wire [7:0] opcode, modrm;
  wire b, sm, dm, need_modrm, need_off, need_imm, off_size, imm_size;
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
  lookup_op op0(opcode, b, dst, sm, dm, src, base, index, 2'b11, off_m, mod, imm_m,
                need_off, off_size, need_imm, imm_size, need_modrm, 
                ir0, ir1, ir2, off0, off1, off2, imm0, imm1, imm2, ninstrs, 
                clk);
  memory_regs mr(rm, mod, base, index);

  // Assignments
  assign pc = (cs << 4) + ip;
  assign mod = modrm[7:6];
  assign regm = modrm[5:3];
  assign rm = modrm[2:0];
  assign b = ~opcode[0];
  assign d = opcode[1];
  assign opcode = state ? opcode_r : data[7:0];
  assign modrm  = (state == 4'd1) ? data[7:0] : modrm_r;
  assign fetch_or_exec = (state > 4'h3 && state != 4'h8);

  assign dst = d ? regm : rm;
  assign sm  = d & (mod != 2'b11);
  assign dm  = ~d & (mod != 2'b11);
  assign src = d ? rm : regm;
  assign bytefetch = state[1] ? (state[0] ? ~imm_size : ~off_size) : 1'b1;

  // Behaviour
  always @(posedge clk)
    if (~boot)
      begin
        ip    <= 16'h0000; // Cuando estén los saltos debería ser 0xfff0
        ir    <= `IR_SIZE'h0;
        state <= 4'h8;
     end
   else
     case (state)
       4'h0: // opcode fetch
         begin 
           opcode_r <= data[7:0]; 
           ip       <= ip + 16'd1; 
           state    <= need_modrm ? 4'h1 : 
                       (need_off ? 4'h2 : need_imm ? 4'h3 : 4'h4);
           off_m    <= 16'h0;
         end

       4'h1: // need modrm
         begin
           modrm_r <= data[7:0]; 
           ip      <= ip + 16'd1;
           state   <= need_off ? 4'h2 : (need_imm ? 4'h3 : 4'h4);           
         end

       4'h2: // need off
         begin
           off_m <= data;
           ip    <= ip + 16'd1 + off_size;
           state <= need_imm ? 4'h3: 4'h4;
         end

       4'h3: // need imm
         begin
           imm_m <= data;
           ip    <= ip + 16'd1 + imm_size;
           state <= 4'h4;
         end

       4'h4: // exec 1st IR
         begin
           ir    <= ir0;
           off   <= off0;
           imm   <= imm0;
           state <= (ninstrs == 2'd1) ? 4'h7 : 4'h5;
         end

       4'h5: // exec 2nd IR
         begin
           ir    <= ir1;
           off   <= off1;
           imm   <= imm1;
           state <= (ninstrs == 2'd2) ? 4'h7 : 4'h6;
         end

       4'h6: // exec 3rd IR
         begin
           ir    <= ir2;
           off   <= off2;
           imm   <= imm2;
           state <= 4'h7;
         end

       4'h7: begin ir <= `IR_SIZE'h0; state <= 4'h8; end
       4'h8: state <= 4'h0;
     endcase

endmodule

module lookup_op (opcode, b, dst, sm, dm, src, base, index, seg, off, mod, imm,
                  need_off, off_size, need_imm, imm_size, need_modrm, 
                  ir0, ir1, ir2, off0, off1, off2, imm0, imm1, imm2, ninstrs, 
                  clk);
  // IO Ports
  input [7:0] opcode;
  input       b;    // byte operation ?
  input [2:0] dst;  // destination register
  input       sm;   // source in memory?
  input       dm;   // dest in memory?
  input [2:0] src;  // source register
  input [3:0] base, index; // for memory access
  input [1:0] seg;  // segment register for memory ops
  input [15:0] off, imm; // offset and immediate operands
  input [1:0] mod; // offset mode
  input       clk;

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

  // Assignments
  assign off_size_mod = (base == 4'b1100 && index == 4'b1100) ? 1'b1 : mod[1];
  assign need_off_mod = (base == 4'b1100 && index == 4'b1100) || ^mod;

  assign ir0  = irs[0]; assign ir1 = irs[1]; assign ir2 = irs[2];
  assign off0 = offs[0]; assign off1 = offs[1]; assign off2 = offs[2];
  assign imm0 = imms[0]; assign imm1 = imms[1]; assign imm2 = imms[2];

  // Behaviour
  always @(negedge clk)
    casex (opcode)
8'b1000_10xx, 8'b1000_1100, 8'b1000_1110: begin // mov
  if (dm) begin 
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b  ad_a    s
    irs[0] <= { b, 1'b0, 1'b0, 1'bx, b, 3'b000, 3'b111, 1'b0, 1'b0, 1'b1, 1'b0, 4'bxxxx, 1'b0, src, index, base, seg };
    need_off <= need_off_mod;
  end else if(sm) begin 
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b  ad_a    s
    irs[0] <= { b, 1'b0, 1'b0, 1'b0, b, 3'b000, 3'b111, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, dst, 4'bxxxx, index, base, seg };
    need_off <= need_off_mod;
  end else begin
             //   ac  ab   im    ma  by    fun      t    wh    wr    wm    wf    ad_d      ad_c       ad_b      ad_a      s
    irs[0] <= { 1'bx, b, 1'b1, 1'b1, b, 3'b001, 3'b001, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, dst, 4'bxxxx, 4'bxxxx, 1'b0, src, 2'bxx };
    imms[0] <= 16'd0;
    need_off <= 1'b0;
  end
  need_imm <= 1'b0; need_modrm <= 1'b1; off_size <= off_size_mod; offs[0] <= off; ninstrs <= 2'd1;
 end

8'b1010_00xx: begin // mov
  if (dm)
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d     ad_c     ad_b     ad_a     s
    irs[0] <= { b, 1'b0, 1'b0, 1'bx, b, 3'b000, 3'b111, 1'b0, 1'b0, 1'b1, 1'b0, 4'bxxxx, 4'b0000, 4'b1100, 4'b1100, seg };
  else
             // ac   ab    im    ma  by    fun       t    wh    wr    wm    wf    ad_d      ad_c     ad_b    ad_a     s
    irs[0] <= { b, 1'b0, 1'b0, 1'b0, b, 3'b000, 3'b111, 1'b0, 1'b1, 1'b0, 1'b0, 4'b0000, 4'bxxxx, 4'b1100, 4'b0000, seg };

  need_off <= 1'b1; need_imm <= 1'b0; need_modrm <= 1'b0; off_size <= 1'b1; offs[0] <= off; ninstrs <= 2'd1;
  end

8'b1011_xxxx: begin // mov
             //   ac    ab   im    ma       by        fun      t    wh    wr    wm    wf         ad_d           ad_c    ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'bx, 1'b1, 1'b1, ~opcode[3], 3'b001, 3'b001, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, opcode[2:0], 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    imms[0] <= imm;
    need_off <= 1'b0; need_imm <= 1'b1; imm_size <= opcode[3]; need_modrm <= 1'b0; off_size <= 1'bx;
    ninstrs <= 2'd1;
  end

8'b1100_011x: begin // mov
             //   ac    ab   im    ma  by     fun      t    wh    wr    wm    wf     ad_d     ad_c    ad_b     ad_a      s
    irs[0] <= { 1'bx, 1'bx, 1'b1, 1'b1, b, 3'b001, 3'b001, 1'b0, 1'b1, 1'b0, 1'b0, 4'b1101, 4'bxxxx, 4'bxxxx, 4'b1100, 2'bxx };
    irs[1] <= { 1'bx, 1'b0, 1'b0, 1'bx, b, 3'b000, 3'b111, 1'b0, 1'b0, 1'b1, 1'b0, 4'bxxxx, 4'b1101, index,   base,    seg };
    imms[0] <= imm;
    offs[1] <= off;
    need_off <= need_off_mod; need_imm <= 1'b1; imm_size <= ~b; need_modrm <= 1'b1; off_size <= off_size_mod;
    ninstrs <= 2'd2;
  end

    endcase
endmodule

module memory_regs(rm, mod, base, index);
  // IO Ports
  input  [2:0] rm;
  input  [1:0] mod;
  output reg [3:0] base, index;

  // Behaviour
  always @(rm)
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
