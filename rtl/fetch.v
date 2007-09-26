`include "defines.v"

module fetch (
    input clk, 
    input rst, 
    input [15:0] cs, 
    input [15:0] ip, 
    input [15:0] data, 
    output [`IR_SIZE-1:0] ir,
    output [15:0] off,
    output [15:0] imm,
    output [19:0] pc,
    output bytefetch, 
    output fetch_or_exec
  );

  // Registers, nets and parameters
  parameter opcod_st = 3'h0;
  parameter modrm_st = 3'h1;
  parameter offse_st = 3'h2;
  parameter immed_st = 3'h3;
  parameter execu_st = 3'h4;

  wire [`IR_SIZE-1:0] rom_ir;
  wire [7:0] opcode, modrm;
  wire exec_st, end_instr;
  wire [15:0] imm_d;
  wire [2:0] next_state;

  reg [2:0] state;
  reg [7:0] opcode_l, modrm_l;
  reg [15:0] off_l, imm_l;

  // Module instantiation
  decode decode0(opcode, modrm, off_l, imm_l, clk, exec_st, 
                 need_modrm, need_off, need_imm, off_size, imm_size,
                 rom_ir, off, imm_d, end_instr);

  // Assignments
  assign pc = (cs << 4) + ip;

  assign ir     = (state == execu_st) ? rom_ir : `ADD_IP;
  assign opcode = (state == opcod_st) ? data[7:0] : opcode_l;
  assign modrm  = (state == modrm_st) ? data[7:0] : modrm_l;
  assign fetch_or_exec = (state == execu_st);
  assign bytefetch = (state == offse_st) ? ~off_size 
                   : ((state == immed_st) ? ~imm_size : 1'b1); 
  assign exec_st = (state == execu_st);
  assign imm = (state == execu_st) ? imm_d 
              : ((state == offse_st) & off_size 
                | (state == immed_st) & imm_size) ? 16'd2
              : 16'd1;
  assign next_state = (state == opcod_st) ? (need_modrm ? modrm_st : 
                         (need_off ? offse_st : (need_imm ? immed_st : execu_st)))
                     : (state == modrm_st) ? (need_off ? offse_st 
                                           : (need_imm ? immed_st : execu_st))
                     : (state == offse_st) ? (need_imm ? immed_st : execu_st)
                     : (state == immed_st) ? (execu_st)
                     : (end_instr ? opcod_st : execu_st);

  // Behaviour
  always @(posedge clk)
    if (rst) 
      begin
        state <= exec_st;
        opcode_l <= `NOP;
      end
    else
      case (next_state)
        // opcode
        default: 
          begin
            state <= opcod_st;
            off_l <= 16'd0;
          end

        modrm_st:  // modrm
          begin
            opcode_l  <= data[7:0];
            state <= modrm_st;
          end

        offse_st:  // offset
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              default: modrm_l <= data[7:0];
            endcase
            state = offse_st;
          end

        immed_st:  // immediate
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              default: off_l <= data;
            endcase
            state = immed_st;
          end

        execu_st:  // execute
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              offse_st: off_l <= data;
              immed_st: imm_l <= data;
            endcase
            state = execu_st;
          end
      endcase
endmodule


module decode (
    input [7:0] opcode,
    input [7:0] modrm,
    input [15:0] off_i,
    input [15:0] imm_i,
    input clk,
    input exec_st,

    output need_modrm,
    output need_off,
    output need_imm,
    output off_size,
    output imm_size,

    output [`IR_SIZE-1:0] ir,
    output [15:0] off_o,
    output [15:0] imm_o,
    output end_instr
  );

  // Net declarations
  wire [7:0] base_addr, seq_addr, micro_addr;
  wire [3:0] src, dst, base, index;
  wire [1:0] seg;
  reg  [7:0] seq;

  // Module instantiations
  opcode_deco opcode_deco0 (opcode, modrm, base_addr, need_modrm, need_off, 
                            need_imm, off_size, imm_size, src, dst, base, 
                            index, seg);
  seq_rom seq_rom0 (seq_addr, {end_instr, micro_addr});
  micro_data mdata0 (micro_addr, off_i, imm_i, src, dst, base, index, seg,
                     ir, off_o, imm_o);

  // Assignments
  assign seq_addr = base_addr + seq;

  // Behaviour
  always @(posedge clk) seq <= exec_st ? (seq + 8'd1) : 8'd0;
  
endmodule

module opcode_deco (
    input [7:0] opcode,
    input [7:0] modrm,
    
    output reg [7:0] seq_addr,
    output reg need_modrm,
    output reg need_off,
    output reg need_imm,
    output reg off_size,
    output reg imm_size,

    output [3:0] src_o,
    output [3:0] dst_o,
    output [3:0] base,
    output [3:0] index,
    output [1:0] seg
  );

  // Net declarations
  wire [1:0] mod;
  wire [2:0] regm;
  wire [2:0] rm;
  wire [2:0] dst, src;
  wire       d;
  wire       off_size_mod, need_off_mod;
  wire       b;
  reg        dst3, src3;

  // Module instantiations
  memory_regs mr(rm, mod, base, index);

  // Assignments
  assign mod = modrm[7:6];
  assign regm = modrm[5:3];
  assign rm  = modrm[2:0];
  assign d   = opcode[1];
  assign dst = d ? regm : rm;
  assign sm  = d & (mod != 2'b11);
  assign dm  = ~d & (mod != 2'b11);
  assign src = d ? rm : regm;
  assign b   = ~opcode[0];
  assign off_size_mod = (base == 4'b1100 && index == 4'b1100) ? 1'b1 : mod[1];
  assign need_off_mod = (base == 4'b1100 && index == 4'b1100) || ^mod;
  assign seg = 2'b11;
  assign src_o = {src3, src};
  assign dst_o = (opcode[7:4] == 4'b1011) ? {1'b0,opcode[2:0]} : {dst3, dst};

  // Behaviour
  always @(opcode or mod or need_off_mod or off_size_mod 
                   or b or sm or dm or regm)
    casex (opcode)
      8'b1000_10xx: // r->r, r->m, m->r
        begin
          if (dm)   // r->m
            begin
              seq_addr <= b ? 8'h0b : 8'h0c;
              need_off <= need_off_mod;
              src3 <= 1'b0;
            end
          else if(sm) // m->r
            begin
              seq_addr <= b ? 8'h0f : 8'h10;
              need_off <= need_off_mod;
              dst3 <= 1'b0;
            end
          else     // r->r
            begin
              seq_addr <= b ? 8'h09 : 8'h0a;
              need_off <= 1'b0;
              dst3 <= 1'b0;
              src3 <= 1'b0;
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          off_size <= off_size_mod;
        end

      8'b1000_1100: // s->m, s->r
        begin
          if (dm)   // s->m
            begin
              seq_addr <= 8'h0c;
              need_off <= need_off_mod;
              src3 <= 1'b1;
            end
          else     // s->r
            begin
              seq_addr <= 8'h0a;
              need_off <= 1'b0;
              dst3 <= 1'b0;
              src3 <= 1'b1;
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          off_size <= off_size_mod;
        end

      8'b1000_1110: // m->s, r->s
        begin
          if (sm)   // m->s
            begin
              seq_addr <= 8'h10;
              need_off <= need_off_mod;
              dst3 <= 1'b1;
            end
          else     // r->s
            begin
              seq_addr <= 8'h0a;
              need_off <= 1'b0;
              dst3 <= 1'b1;
              src3 <= 1'b0;
            end
          need_modrm <= 1'b1;
          off_size <= off_size_mod;
          need_imm <= 1'b0;
        end

      8'b1001_0000: // nop
        begin
          seq_addr <= 8'h00;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
        end
        
      8'b1010_000x: // m->a
        begin
          seq_addr <= b ? 8'h11 : 8'h12;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          off_size <= 1'b1;
        end

      8'b1010_001x: // a->m
        begin
          seq_addr <= b ? 8'h0d : 8'h0e;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          off_size <= 1'b1;
        end

      8'b1011_xxxx: // i->r
        begin
          seq_addr <= opcode[3] ? 8'h14 : 8'h13;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= opcode[3];
        end

      8'b1100_011x: // i->m
        begin
          seq_addr <= b ? 8'h15 : 8'h17;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          off_size <= off_size_mod;
          need_imm <= 1'b1;
          imm_size <= ~b;
        end

      8'b1110_10x1: // jmp direct [off8 1s, off16 2s]
        begin
          seq_addr <= opcode[1] ? 8'h01 : 8'h02;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= ~opcode[1];
        end

      8'b1110_1010: // jmp indirect different segment [5s]
        begin
          seq_addr <= 8'h05;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          off_size <= 1'b1;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
        end

      8'b1111_1111: 
        begin
          case (regm)
            3'b100: seq_addr <= (mod==2'b11) ? 8'h03 : 8'h04;
            3'b101: seq_addr <= 8'h07;
          endcase
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          off_size <= off_size_mod;
          need_imm <= 1'b0;
        end

  endcase

endmodule

module memory_regs (
    input [2:0] rm,
    input [1:0] mod,
    output reg [3:0] base,
    output reg [3:0] index
  );

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

module micro_data (
    input [7:0] n_micro,
    input [15:0] off_i,
    input [15:0] imm_i,
    input [3:0] src,
    input [3:0] dst,
    input [3:0] base,
    input [3:0] index,
    input [1:0] seg,
    output [`IR_SIZE-1:0] ir,
    output [15:0] off_o,
    output [15:0] imm_o
  );

  // Net declarations
  wire [`MICRO_SIZE-1:0] micro_o;
  wire [15:0] high_ir;
  wire var_s, var_off;
  wire [1:0] var_a, var_b, var_c, var_d;
  wire [2:0] var_imm;

  wire [3:0] addr_a, addr_b, addr_c, addr_d;
  wire [3:0] micro_a, micro_b, micro_c, micro_d;
  wire [1:0] addr_s, micro_s;

  // Module instantiations
  micro_rom m0 (n_micro, micro_o);

  // Assignments
  assign micro_s = micro_o[1:0];
  assign micro_a = micro_o[5:2];
  assign micro_b = micro_o[9:6];
  assign micro_c = micro_o[13:10];
  assign micro_d = micro_o[17:14];
  assign high_ir = micro_o[33:18];
  assign var_s   = micro_o[34];
  assign var_a   = micro_o[36:35];
  assign var_b   = micro_o[38:37];
  assign var_c   = micro_o[40:39];
  assign var_d   = micro_o[42:41];
  assign var_off = micro_o[43];
  assign var_imm = micro_o[46:44];

  assign imm_o = var_imm == 3'd0 ? (16'h0000)
               : (var_imm == 3'd1 ? (16'h0002)
               : (var_imm == 3'd2 ? (16'h0004)
               : (var_imm == 3'd3 ? off_i : imm_i )));

  assign off_o = var_off ? off_i : 16'h0000;

  assign addr_a = var_a == 2'd0 ? micro_a
                : (var_a == 2'd1 ? base 
                : (var_a == 2'd2 ? dst : src ));
  assign addr_b = var_b == 2'd0 ? micro_b
                : (var_b == 2'd1 ? index : src);
  assign addr_c = var_c == 2'd0 ? micro_c
                : (var_c == 2'd1 ? dst : src);
  assign addr_d = var_d == 2'd0 ? micro_d
                : (var_d == 2'd1 ? dst : src);
  assign addr_s = var_s ? seg : micro_s;

  assign ir = { high_ir, addr_d, addr_c, addr_b, addr_a, addr_s };
endmodule

module micro_rom (
    input [7:0] addr,
    output [(`MICRO_SIZE-1):0] q
  );

  // Registers, nets and parameters
	parameter DATA_WIDTH = `MICRO_SIZE;
	parameter ADDR_WIDTH = 8;

  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

  // Assignments
  assign q = rom[addr];

  // Behaviour
	initial $readmemb("/home/zeus/zet/rtl/micro_rom.dat", rom);
endmodule

module seq_rom (
    input [7:0] addr,
    output [(`SEQ_SIZE-1):0] q
  );

  // Registers, nets and parameters
	parameter DATA_WIDTH = `MICRO_SIZE;
	parameter ADDR_WIDTH = 8;

  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

  // Assignments
  assign q = rom[addr];

  // Behaviour
	initial $readmemh("/home/zeus/zet/rtl/seq_rom.dat", rom);
endmodule
