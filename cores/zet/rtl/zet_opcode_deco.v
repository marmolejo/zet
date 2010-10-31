/*
 *  Opcode decoder lookup table for Zet
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

`include "defines.v"

module zet_opcode_deco (
    input [7:0] op,
    input [7:0] modrm,
    input       rep,
    input [2:0] sovr_pr,

    output reg [`MICRO_ADDR_WIDTH-1:0] seq_addr,
    output reg need_modrm,
    output reg need_off,
    output reg need_imm,
    output     off_size,
    output reg imm_size,

    output reg [3:0] src,
    output reg [3:0] dst,
    output [3:0] base,
    output [3:0] index,
    output [1:0] seg
  );

  // Net declarations
  wire [1:0] mod;
  wire [2:0] regm;
  wire [2:0] rm;
  wire       d, b, sm, dm;
  wire       off_size_mod, need_off_mod;
  wire [2:0] srcm, dstm;
  wire       off_size_from_mod;

  // Module instantiations
  zet_memory_regs memory_regs (rm, mod, sovr_pr, base, index, seg);

  // Assignments
  assign mod  = modrm[7:6];
  assign regm = modrm[5:3];
  assign rm   = modrm[2:0];
  assign d    = op[1];
  assign dstm = d ? regm : rm;
  assign sm   = d & (mod != 2'b11);
  assign dm   = ~d & (mod != 2'b11);
  assign srcm = d ? rm : regm;
  assign b    = ~op[0];
  assign off_size_mod = (base == 4'b1100 && index == 4'b1100) ? 1'b1 : mod[1];
  assign need_off_mod = (base == 4'b1100 && index == 4'b1100) || ^mod;
  assign off_size_from_mod = !op[7] | (!op[5] & !op[4]) | (op[6] & op[4]);
  assign off_size = !off_size_from_mod | off_size_mod;

  // Behaviour
  always @(op or dm or b or need_off_mod or srcm or sm or dstm
           or mod or rm or regm or rep or modrm)
    casex (op)
      8'b00xx_x00x: // add/or/adc/sbb/and/sub/xor/cmp r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `LOGRRB : `LOGRRW)
                                     : (b ? `LOGRMB : `LOGRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b00xx_x01x: // add/or/adc/sbb/and/sub/xor/cmp r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `LOGRRB : `LOGRRW)
                                     : (b ? `LOGMRB : `LOGMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b00xx_x10x: // add/or/adc/sbb/and/sub/xor/cmp i->r
        begin
          seq_addr   <= b ? `LOGIRB : `LOGIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b000x_x110: // push seg
        begin
          seq_addr <= `PUSHR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 2'b10, op[4:3] };
          dst <= 4'b0;
        end

      8'b000x_x111: // pop seg
        begin
          seq_addr <= `POPR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src      <= 4'b0;
          dst      <= { 2'b10, op[4:3] };
        end

      8'b0010_0111: // daa
        begin
          seq_addr   <= `DAA;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0010_1111: // das
        begin
          seq_addr   <= `DAS;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_0111: // aaa
        begin
          seq_addr   <= `AAA;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_1111: // aas
        begin
          seq_addr   <= `AAS;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0100_0xxx: // inc
        begin
          seq_addr   <= `INCRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= { 1'b0, op[2:0] };
        end

      8'b0100_1xxx: // dec
        begin
          seq_addr   <= `DECRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= { 1'b0, op[2:0] };
        end

      8'b0101_0xxx: // push reg
        begin
          seq_addr <= `PUSHR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, op[2:0] };
          dst <= 4'b0;
        end

      8'b0101_1xxx: // pop reg
        begin
          seq_addr <= `POPR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= { 1'b0, op[2:0] };
        end

      8'b0110_0000: // pusha
        begin
          seq_addr <= `PUSHA;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b0110_0001: // popa
        begin
          seq_addr <= `POPA;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b0110_10x0: // push imm
        begin
          seq_addr <= `PUSHI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= !op[1];
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b0110_10x1: // imul imm
        begin
          seq_addr <= (mod==2'b11) ? `IMULIR : `IMULIM;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= !op[1];
          src <= { 1'b0, rm };
          dst <= { 1'b0, regm };
        end

      8'b0111_xxxx: // jcc
        begin
          seq_addr <= `JCC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= { op[3:0] };
          dst <= 4'b0;
        end

      8'b1000_00xx: // add/or/adc/sbb/and/sub/xor/cmp imm
        begin
          seq_addr <= (mod==2'b11) ? (b ? `LOGIRB : `LOGIRW)
                                   : (b ? `LOGIMB : `LOGIMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b1;
          imm_size   <= !op[1] & op[0];
          dst        <= { 1'b0, modrm[2:0] };
          src        <= 4'b0;
        end

      8'b1000_010x: // test r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `TSTRRB : `TSTRRW)
                                     : (b ? `TSTMRB : `TSTMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, srcm };
          src        <= { 1'b0, dstm };
        end

      8'b1000_011x: // xchg
        begin
          seq_addr <= (mod==2'b11) ? (b ? `XCHRRB : `XCHRRW)
                                   : (b ? `XCHRMB : `XCHRMW);
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          dst <= { 1'b0, dstm };
          src <= { 1'b0, srcm };
        end
      8'b1000_10xx: // mov: r->r, r->m, m->r
        begin
          if (dm)   // r->m
            begin
              seq_addr <= b ? `MOVRMB : `MOVRMW;
              need_off <= need_off_mod;
              src <= { 1'b0, srcm };
              dst <= 4'b0;
            end
          else if(sm) // m->r
            begin
              seq_addr <= b ? `MOVMRB : `MOVMRW;
              need_off <= need_off_mod;
              src <= 4'b0;
              dst <= { 1'b0, dstm };
            end
          else     // r->r
            begin
              seq_addr <= b ? `MOVRRB : `MOVRRW;
              need_off <= 1'b0;
              dst <= { 1'b0, dstm };
              src <= { 1'b0, srcm };
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          imm_size <= 1'b0;
        end

      8'b1000_1100: // mov: s->m, s->r
        begin
          if (dm)   // s->m
            begin
              seq_addr <= `MOVRMW;
              need_off <= need_off_mod;
              src <= { 1'b1, srcm };
              dst <= 4'b0;
            end
          else     // s->r
            begin
              seq_addr <= `MOVRRW;
              need_off <= 1'b0;
              src <= { 1'b1, srcm };
              dst <= { 1'b0, dstm };
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          imm_size <= 1'b0;
        end

      8'b1000_1101: // lea
        begin
          seq_addr <= `LEA;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1000_1110: // mov: m->s, r->s
        begin
          if (sm)   // m->s
            begin
              seq_addr <= `MOVMRW;
              need_off <= need_off_mod;
              src <= 4'b0;
              dst <= { 1'b1, dstm };
            end
          else     // r->s
            begin
              seq_addr <= `MOVRRW;
              need_off <= 1'b0;
              src <= { 1'b0, srcm };
              dst <= { 1'b1, dstm };
            end
          need_modrm <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
        end

      8'b1000_1111: // pop mem or (pop reg non-standard)
        begin
          seq_addr <= (mod==2'b11) ? `POPR : `POPM;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= { 1'b0, rm };
        end

      8'b1001_0xxx: // nop, xchg acum
        begin
          seq_addr <= `XCHRRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0000;
          dst <= { 1'b0, op[2:0] };
        end

      8'b1001_1000: // cbw
        begin
          seq_addr   <= `CBW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1001_1001: // cwd
        begin
          seq_addr   <= `CWD;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1001_1010: // call different seg
        begin
          seq_addr <= `CALLF;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1011: // wait
        begin
          seq_addr <= `NOP;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1100: // pushf
        begin
          seq_addr <= `PUSHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1101: // popf
        begin
          seq_addr <= `POPF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1110: // sahf
        begin
          seq_addr <= `SAHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1111: // lahf
        begin
          seq_addr <= `LAHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_000x: // mov: m->a
        begin
          seq_addr <= b ? `MOVMAB : `MOVMAW;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_001x: // mov: a->m
        begin
          seq_addr <= b ? `MOVAMB : `MOVAMW;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_010x: // movs
        begin
          seq_addr <= rep ? (b ? `MOVSBR : `MOVSWR) : (b ? `MOVSB : `MOVSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_011x: // cmps
        begin
          seq_addr <= rep ? (b ? `CMPSBR : `CMPSWR) : (b ? `CMPSB : `CMPSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_100x: // test i->r
        begin
          seq_addr   <= b ? `TSTIRB : `TSTIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1010_101x: // stos
        begin
          seq_addr <= rep ? (b ? `STOSBR : `STOSWR) : (b ? `STOSB : `STOSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_110x: // lods
        begin
          seq_addr <= rep ? (b ? `LODSBR : `LODSWR) : (b ? `LODSB : `LODSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_111x: // scas
        begin
          seq_addr <= rep ? (b ? `SCASBR : `SCASWR) : (b ? `SCASB : `SCASW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1011_xxxx: // mov: i->r
        begin
          seq_addr <= op[3] ? `MOVIRW : `MOVIRB;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= op[3];

          src <= 4'b0;
          dst <= { 1'b0, op[2:0] };
        end

      8'b1100_000x: // ror/rol/rcr/rcl/sal/shl/sar/shr imm8/imm16
        begin
          seq_addr <= (mod==2'b11) ? (b ? `RSHIRB : `RSHIRW)
                                   : (b ? `RSHIMB : `RSHIMW);
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= rm;
          dst <= rm;
        end

      8'b1100_0010: // ret near with value
        begin
          seq_addr <= `RETNV;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_0011: // ret near
        begin
          seq_addr <= `RETN0;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_0100: // les
        begin
          seq_addr <= `LES;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1100_0101: // lds
        begin
          seq_addr <= `LDS;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1100_011x: // mov: i->m (or i->r non-standard)
        begin
          seq_addr <= (mod==2'b11) ? (b ? `MOVIRB : `MOVIRW)
                                   : (b ? `MOVIMB : `MOVIMW);
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= ~b;

          src <= 4'b0;
          dst <= { 1'b0, rm };
        end

      8'b1100_1000: // enter
        begin
          seq_addr <= `ENTER;
          need_modrm <= 1'b0;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1001: // leave
        begin
          seq_addr <= `LEAVE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1010: // ret far with value
        begin
          seq_addr <= `RETFV;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1011: // ret far
        begin
          seq_addr <= `RETF0;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1100: // int 3
        begin
          seq_addr <= `INT3;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1101: // int
        begin
          seq_addr <= `INT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1110: // into
        begin
          seq_addr <= `INTO;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1111: // iret
        begin
          seq_addr <= `IRET;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_00xx: // sal/shl
        begin
          seq_addr <= (mod==2'b11) ? (op[1] ? (b ? `RSHCRB : `RSHCRW)
                                            : (b ? `RSH1RB : `RSH1RW))
                                   : (op[1] ? (b ? `RSHCMB : `RSHCMW)
                                            : (b ? `RSH1MB : `RSH1MW));
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= rm;
          dst <= rm;
        end

      8'b1101_0100: // aam
        begin
          seq_addr <= `AAM;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_0101: // aad
        begin
          seq_addr <= `AAD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_0111: // xlat
        begin
          seq_addr <= `XLAT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_1xxx: // esc
        begin
          seq_addr <= (mod==2'b11) ? `ESCRW : `ESCMW;
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          src        <= { 1'b0, modrm[2:0] };
          dst        <= 4'b0;
        end

      8'b1110_0000: // loopne
        begin
          seq_addr <= `LOOPNE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0001: // loope
        begin
          seq_addr <= `LOOPE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0010: // loop
        begin
          seq_addr <= `LOOP;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0011: // jcxz
        begin
          seq_addr <= `JCXZ;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_010x: // in imm
        begin
          seq_addr <= b ? `INIB : `INIW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_011x: // out imm
        begin
          seq_addr <= b ? `OUTIB : `OUTIW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_1000: // call same segment
        begin
          seq_addr <= `CALLN;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_10x1: // jmp direct
        begin
          seq_addr <= `JMPI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= ~op[1];

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_1010: // jmp indirect different segment
        begin
          seq_addr <= `LJMPI;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b1;
          imm_size <= 1'b1;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_110x: // in dx
        begin
          seq_addr <= b ? `INRB : `INRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_111x: // out dx
        begin
          seq_addr <= b ? `OUTRB : `OUTRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_0100: // hlt
        begin
          seq_addr <= `NOP; // hlt processing is in zet_core.v
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_0101: // cmc
        begin
          seq_addr <= `CMC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_011x: // test, not, neg, mul, imul
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ?
             (b ? `TSTIRB : `TSTIRW) : (b ? `TSTIMB : `TSTIMW);
            3'b010: seq_addr <= (mod==2'b11) ?
             (b ? `NOTRB : `NOTRW) : (b ? `NOTMB : `NOTMW);
            3'b011: seq_addr <= (mod==2'b11) ?
             (b ? `NEGRB : `NEGRW) : (b ? `NEGMB : `NEGMW);
            3'b100: seq_addr <= (mod==2'b11) ?
             (b ? `MULRB : `MULRW) : (b ? `MULMB : `MULMW);
            3'b101: seq_addr <= (mod==2'b11) ?
             (b ? `IMULRB : `IMULRW) : (b ? `IMULMB : `IMULMW);
            3'b110: seq_addr <= (mod==2'b11) ?
             (b ? `DIVRB : `DIVRW) : (b ? `DIVMB : `DIVMW);
            3'b111: seq_addr <= (mod==2'b11) ?
             (b ? `IDIVRB : `IDIVRW) : (b ? `IDIVMB : `IDIVMW);
            default: seq_addr <= `NOP;
          endcase

          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= (regm == 3'b000); // imm on test
          imm_size   <= ~b;
          dst        <= { 1'b0, modrm[2:0] };
          src        <= { 1'b0, modrm[2:0] };
        end

      8'b1111_1000: // clc
        begin
          seq_addr <= `CLC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1001: // stc
        begin
          seq_addr <= `STC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1010: // cli
        begin
          seq_addr <= `CLI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1011: // sti
        begin
          seq_addr <= `STI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1100: // cld
        begin
          seq_addr <= `CLD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1101: // std
        begin
          seq_addr <= `STD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1110: // inc
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ? `INCRB : `INCMB;
            3'b001: seq_addr <= (mod==2'b11) ? `DECRB : `DECMB;
            default: seq_addr <= `NOP;
          endcase
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= { 1'b0, rm };
          dst <= 4'b0;
        end

      8'b1111_1111:
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ? `INCRW : `INCMW;
            3'b001: seq_addr <= (mod==2'b11) ? `DECRW : `DECMW;
            3'b010: seq_addr <= (mod==2'b11) ? `CALLNR : `CALLNM;
            3'b011: seq_addr <= `CALLFM;
            3'b100: seq_addr <= (mod==2'b11) ? `JMPR : `JMPM;
            3'b101: seq_addr <= `LJMPM;
            3'b110: seq_addr <= (mod==2'b11) ? `PUSHR : `PUSHM;
            default: seq_addr <= `NOP;
          endcase
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= { 1'b0, rm };
          dst <= 4'b0;
        end

      default: // invalid opcode
        begin
          seq_addr <= `INVOP;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

  endcase

endmodule
