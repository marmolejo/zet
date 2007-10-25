`timescale 1ns/10ps

module alu(x, y, out, t, func, iflags, oflags, word_op, seg, off);
  // IO ports
  input  [/* 31 */ 15:0] x;
  input  [15:0] y;
  input  [2:0]  t, func;
  input  [15:0] iflags;
  input         word_op;
  input  [15:0] seg, off;
  output [31:0] out;
  output  [8:0] oflags;

  // Net declarations
  wire [15:0] add /* adj, log, shi, rot */;
  wire  [8:0] othflags;
  wire [19:0] oth;
//  wire [31:0] cnv, mul;
//  wire af_add, af_adj;
//  wire cf_adj, cf_add, cf_mul, cf_log, cf_shi, cf_rot;
//  wire of_adj, of_add, of_mul, of_log, of_shi, of_rot;
  wire /* ofi, */ sfi, zfi, /* afi, */ pfi, cfi;
  wire /* ofo, */ sfo, zfo, /* afo, */ pfo /*, cfo */;
  wire flags_unchanged;

  // Module instances
  addsub ad0(x[15:0], y, add, func, word_op, cfi, /* cf_add */, /* af_add, */
            /* of_add */);
/*
  adj    adj0(x[15:0], y, {cf_adj, adj}, func, afi, cfi, af_adj, of_adj);
  conv   cnv0(x[15:0], cnv, func[0]);
  muldiv mul0(x, y, mul, func[1:0], word_op, cf_mul, of_mul);
  bitlog lo0(x[15:0], y, log, func, cf_log, of_log);
  shifts sh0(x[15:0], y, shi, func[1:0], word_op, cfi, ofi, cf_shi, of_shi);
  rotat  rot0(x[15:0], y, rot, func[1:0], word_op, cfi, cf_rot, of_rot);
*/
  othop  oth0(x[15:0], y, seg, off, iflags, func, word_op, oth, othflags);

  mux8_16 m0(t, 16'd0/* adj */, add, 16'd0/* cnv[15:0] */, 
             16'd0 /* mul[15:0] */, 16'd0 /* log */, 16'd0 /* shi */,
             16'd0 /* rot */, oth[15:0], out[15:0]);
  mux8_16 m1(t, 16'd0, 16'd0, 16'd0 /* cnv[31:16] */, 16'd0 /* mul[31:16] */,
             16'd0, 16'd0, 16'd0, {12'b0,oth[19:16]}, out[31:16]);
//  mux8_1  a1(t, cf_adj, cf_add, cfi, cf_mul, cf_log, cf_shi, cf_rot, 1'b0, cfo);
//  mux8_1  a2(t, af_adj, af_add, afi, 1'b0, 1'b0, 1'b0, afi, 1'b0, afo);
//  mux8_1  a3(t, of_adj, of_add, ofi, of_mul, of_log, of_shi, of_rot, 1'b0, ofo);

  // Flags
  assign pfo = flags_unchanged ? pfi : ^~ out[7:0];
  assign zfo = flags_unchanged ? zfi : (word_op ? ~|out[15:0] : ~|out[7:0]);
  assign sfo = flags_unchanged ? sfi : (word_op ? out[15] : out[7]);

  assign oflags = (t == 3'd7) ? othflags 
                 : { 1'b0 /* ofo */, iflags[10:8], sfo, zfo, 1'b0 /* afo */,
                   pfo, 1'b0 /* cfo */ };

//  assign ofi = iflags[11];
  assign sfi = iflags[7];
  assign zfi = iflags[6];
//  assign afi = iflags[4];
  assign pfi = iflags[2];
  assign cfi = iflags[0];

  assign flags_unchanged = (t == 4'd6 || t == 4'd2 || t == 4'd4 && func == 4'd1);
endmodule

module addsub(x, y, out, func, word_op, cfi, cfo, /* afo, */ ofo);
  // IO ports
  input  [15:0] x, y;
  input  [2:0]  func;
  input         cfi, word_op;
  output        cfo, /* afo, */ ofo;
  output [15:0] out;

  // Net declarations
  wire [16:0] adc, add, ad8, dec, neg, sbb, sub, cmp;
//  wire [4:0]  tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
  wire        resta, bneg, bincdec, cfo8, cfo16, ofo8, ofo16, cfoneg8, cfoneg16;
// wire        afo_adc, afo_add, afo_inc, afo_dec, afo_neg, afo_sbb, afo_sub, afo_cmp;
  wire [16:0] out17;

  // Module instances
  mux8_17 m0(func, adc, add, ad8, dec, neg, sbb, sub, cmp, out17);
/*  mux8_1  m1(func, afo_adc, afo_add, afo_inc, afo_dec,
                   afo_neg, afo_sbb, afo_sub, afo_cmp, afo); */

  // Assignments
  assign adc = x + y + cfi;
  assign add = x + y;
  assign ad8 = x + y[7:0];
  assign dec = x - 8'b1;
  assign neg = {x==16'd0 ? 1'b0 : 1'b1, -x};
  assign sbb = x - y - cfi;
  assign sub = x - y;
  assign cmp = x - y;
/*
  assign tmp0 = x[3:0] + y[3:0] + cfi;
  assign tmp1 = x[3:0] + y[3:0];
  assign tmp2 = x[3:0] + 4'b1;
  assign tmp3 = x[3:0] - 4'b1;
  assign tmp4 = -x[3:0];
  assign tmp5 = x[3:0] - y[3:0] -cfi;
  assign tmp6 = x[3:0] - y[3:0];
  assign tmp7 = x[3:0] - y[3:0];

  assign afo_adc = tmp0[4];
  assign afo_add = tmp1[4];
  assign afo_inc = tmp2[4];
  assign afo_dec = tmp3[4];
  assign afo_neg = tmp4[4];
  assign afo_sbb = tmp5[4];
  assign afo_sub = tmp6[4];
  assign afo_cmp = tmp7[4];
*/
  assign resta = (func > 3'd2);
  assign bneg  = (func == 3'd4);
  assign ofo16 = resta ? ( bneg ? x[15] & out[15] : 
                               (~x[15] & y[15] & out[15] | x[15] & ~y[15] & ~out[15]))
                     : (~x[15] & ~y[15] & out[15] | x[15] & y[15] & ~out[15]);

  assign ofo8  = resta ? ( bneg ? x[7] & out[7] :
                               (~x[7] & y[7] & out[7] | x[7] & ~y[7] & ~out[7]))
                     : (~x[7] & ~y[7] & out[7] | x[7] & y[7] & ~out[7]);

  assign cfoneg8  = x[7:0]!=8'd0;
  assign cfoneg16 = x[15:0]!=16'd0;
  assign bincdec = (func == 3'd2 || func == 3'd3);
  assign cfo8  = bneg ? cfoneg8  : out17[8];
  assign cfo16 = bneg ? cfoneg16 : out17[16];
  assign out   = out17[15:0];
  assign cfo   = bincdec ? cfi : (word_op ? cfo16 : cfo8);
  assign ofo   = word_op ? ofo16 : ofo8;
endmodule

/*
module adj(x, y, out, func, afi, cfi, afo, cfo);
  // IO ports
  input  [15:0] x, y;
  input  [2:0]  func;
  input         afi, cfi;
  output        afo, cfo;
  output [16:0] out;

  // Net declarations
  wire [16:0] aaa, aad, aam, aas, daa, das, aad16;
  wire [7:0]  ala, als, alout;
  wire        alcnd;

  // Module instances
  mux8_17 m0(func, aaa, aad, aam, aas, 
                   daa, das, {9'd0, y[7:0]}, {1'b0, y}, out);
  
  // Assignments
  assign aaa = afo ? { x[15:8] + 8'd1, (x[7:0] + 8'd6) & 8'h0f } : x;
  assign aad16 = x[15:8] * 8'd10 + x[7:0];
  assign aad = { 8'b0, aad16[7:0] };
  assign aam = 16'd0; // FIXME: { x[7:0] / 8'd10, x[7:0] % 8'd10 };
  assign aas = afo ? { x[15:8] - 8'd1, (x[7:0] - 8'd6) & 8'h0f } : x;

  assign ala = afo ? x[7:0] + 8'd6 : x[7:0];
  assign als = afo ? x[7:0] - 8'd6 : x[7:0]; 
  assign alout = (func == 3'd4) ? ala : als;
  assign alcnd = (alout > 8'h9f) | cfi;
  assign daa = alcnd ? { x[15:8], x[3:0] + 8'h60 } : { x[15:8], alout };
  assign das = alcnd ? { x[15:8], x[3:0] - 8'h60 } : { x[15:8], alout };

  assign afo = (x[3:0] > 4'd9) | afi;
  assign cfo = func[2] ? alcnd : afo;
endmodule

module conv(x, out, func);
  // IO ports
  input  [15:0] x;
  input         func;  // type = 010 and func = 111 is reserved for INTO
  output [31:0] out;
  
  // Net declarations
  wire [31:0] cbw, cwd;
  wire [23:0] x7_24;
  wire [15:0] x15_16;

  // Assignments
  assign x7_24  = { 24{x[7]} };
  assign x15_16 = { 16{x[15]} };
  assign cbw = { x7_24, x[7:0] };
  assign cwd = { x15_16, x[7:0] };
  assign out = func ? cwd : cbw;
endmodule

module muldiv(x, y, out, func, word_op, cfo, ofo);
  // IO ports
  input  [31:0] x;
  input  [15:0] y;
  input  [1:0] func;
  input        word_op;
  output [31:0] out;
  output        cfo, ofo;

  // Net declarations
  wire signed [31:0] x_s, imul, idiv32, mods32;
  wire signed [15:0] y_s, idivr16, modsr16, idiv16, mods16;
  wire signed [7:0]  idivr8, modsr8; 
  wire [31:0] mul, div32, modu32, div, idiv;
  wire [15:0] divr16, modur16, div16, modu16;
  wire [7:0]  divr8, modur8;
  wire cfo8, cfo16;

  // Module instantiations
  mux4_32 m0(func, mul, imul, div, idiv, out);

  // Assignments
  assign x_s = x;
  assign y_s = y;
  assign mul  = x[15:0] * y;
  assign imul = x_s[15:0] * y_s;

  assign div32  = x / y;
  assign modu32 = x % y;
  assign idiv32 = x_s / y_s;
  assign mods32 = x_s % y_s;
  assign divr16  = div32[15:0];
  assign modur16 = modu32[15:0];
  assign idivr16 = idiv32[15:0];
  assign modsr16 = mods32[15:0];

  assign div16  = x[15:0] / y[7:0];
  assign modu16 = x[15:0] % y[7:0];
  assign idiv16 = x_s[15:0] / y_s[7:0];
  assign mods16 = x_s[15:0] % y_s[7:0];
  assign divr8  = div16[7:0];
  assign modur8 = modu16[7:0];
  assign idivr8 = idiv16[7:0];
  assign modsr8 = mods16[7:0];

  assign div   = word_op ? { modur16, divr16 } : { 16'd0, modur8, divr8 };
  assign idiv  = word_op ? { modsr16, idivr16 } : { 16'd0, modsr8, idivr8 };

  assign cfo16 = (out[31:16] != { 16{out[15]} });
  assign cfo8  = (out[15:8]  != {  8{out[7]} });
  assign cfo = word_op ? cfo16 : cfo8;
  assign ofo = cfo;
endmodule

module bitlog(x, y, out, func, cfo, ofo);
  // IO ports
  input  [15:0] x, y;
  input  [2:0]  func;
  output [15:0] out;
  output        cfo, ofo;

  // Net declarations
  wire [15:0] and_n, or_n, not_n, xor_n, test_n;
  
  // Module instantiations
  mux8_16 m0(func, and_n, or_n, not_n, xor_n, test_n, 16'd0, 16'd0, 16'd0, out);

  // Assignments
  assign and_n  = x & y;
  assign or_n   = x | y;
  assign not_n  = ~x;
  assign xor_n  = x ^ y;
  assign test_n = x & y;

  assign cfo = 1'b0;
  assign ofo = 1'b0;
endmodule

module shifts(x, y, out, func, word_op, cfi, ofi, cfo, ofo);
  // IO ports
  input  [15:0] x, y;
  input   [1:0] func;
  input         cfi, ofi;
  input         word_op;
  output [15:0] out;
  output        cfo, ofo;

  // Net declarations
  wire [15:0] sal_shl, sar, shr, sar16, shr16;
  wire [7:0]  sar8, shr8;
  wire signed [15:0] x_s;
  wire ofo_shl, ofo_sar, ofo_shr, ofo_o, cfo16, cfo8;

  // Module instantiations
  mux4_16 m0(func, sal_shl, sar, shr, 16'd0, out);
  mux4_1  m1(func, ofo_shl, ofo_sar, ofo_shr, 1'b0, ofo_o);

  // Assignments
  assign x_s     = x;
  assign sal_shl = x << y[7:0];
  assign sar16   = x_s >>> y[7:0];
  assign shr16   = x >> y[7:0];
  assign sar8    = x_s[7:0] >>> y[7:0];
  assign shr8    = x[7:0] >> y[7:0];
  assign shr     = word_op ? shr16 : {8'd0, shr8};
  assign sar     = word_op ? sar16 : {8'd0, sar8};

  assign cfo16 = (y == 16'd0) ? cfi : 
                ( (func==2'd0) ? |(x & (16'h8000 >> (y-1))) : |(x & (16'h1 << (y-1))));
  assign cfo8  = (y[7:0] == 8'd0) ? cfi : 
                ( (func==2'd0) ? |(x[7:0] & (8'h80 >> (y-1))) 
                               : |(x[7:0] & (8'h1 << (y-1))));
  assign cfo = word_op ? cfo16 : cfo8;
  assign ofo = (y == 16'd0) ? ofi : ofo_o;
  assign ofo_shl = word_op ? (out[15] != cfo) : (out[7] != cfo);
  assign ofo_sar = 1'b0;
  assign ofo_shr = word_op ? x[15] : x[7];
endmodule

module rotat(x, y, out, func, word_op, cfi, cfo, ofo);
  // IO ports
  input  [15:0] x, y;
  input   [1:0] func;
  input         cfi, word_op;
  output [15:0] out;
  output        cfo;
  output        ofo;

  // Net declarations
  wire [15:0] rcl16, rcr16, rol16, ror16, rcl, rcr, rol, ror;
  wire [7:0]  yce16, ye16, yce8, ye8, rcl8, rcr8, rol8, ror8, yc16, yc8;
  wire        cfo_rcl, cfo_rcr, cfo_rol, cfo_ror;

  // Module instantiations
  mux4_16 m0(func, rcl, rcr, rol, ror, out);
  mux4_1  m1(func, cfo_rcl, cfo_rcr, cfo_rol, cfo_ror, cfo);

  // Assignments
  assign yce16 = ye16; // FIXME: y[7:0] % 8'd17;
  assign ye16  = y[7:0] % 8'd16;
  assign rcl16 = yce16 ? (x << yce16 | cfi << (yce16-8'd1)  | x >> (8'd17-yce16)) : x;
  assign rcr16 = yce16 ? (x >> yce16 | cfi << (8'd16-yce16) | x << (8'd17-yce16)) : x;
  assign rol16 = (x << ye16 | x >> (8'd16-ye16));
  assign ror16 = (x >> ye16 | x << (8'd16-ye16));

  assign yce8 = ye8; // FIXME: y[7:0] % 8'd9;
  assign ye8  = y[7:0] % 8'd8;
  assign rcl8 = yce8 ? (x[7:0] << yce8 | cfi << (yce8-8'd1) | x[7:0] >> (8'd9-yce8)) : x[7:0];
  assign rcr8 = yce8 ? (x[7:0] >> yce8 | cfi << (8'd8-yce8) | x[7:0] << (9'd9-yce8)) : x[7:0];
  assign rol8 = (x[7:0] << ye8 | x[7:0] >> (8'd8-ye8));
  assign ror8 = (x[7:0] >> ye8 | x[7:0] << (8'd8-ye8));

  assign rcl = word_op ? rcl16 : { 8'd0, rcl8 };
  assign rcr = word_op ? rcr16 : { 8'd0, rcr8 };
  assign rol = word_op ? rol16 : { 8'd0, rol8 };
  assign ror = word_op ? ror16 : { 8'd0, ror8 };

  // Carry
  assign yc16 = (y[7:0]-8'd1)%8'd16;
  assign yc8  = (y[7:0]-8'd1)%8'd8;
  assign cfo_rcl = word_op ? (yce16==8'd0 ? cfi : x[16-yce16]) 
                            : (yce8==8'd0 ? cfi : x[8-yce8]);
  assign cfo_rcr = word_op ? (yce16==8'd0 ? cfi : x[yce16-1])
                            : (yce8==8'd0 ? cfi : x[yce8-1]);
  assign cfo_rol = word_op ? (y[7:0]==8'd0 ? cfi : x[15-yc16])
                            : (y[7:0]==8'd0 ? cfi : x[7-yc8]);
  assign cfo_ror = word_op ? (y[7:0]==8'd0 ? cfi : x[yc16])
                            : (y[7:0]==8'd0 ? cfi : x[yc8]);

  // Overflow
  assign ofo = func[0] ? // right 
                        (word_op ? out[15]^out[14] : out[7]^out[6])
                        : // left 
                         (word_op ? cfo^out[15] : cfo^out[7]);
endmodule
*/

module othop (x, y, seg, off, iflags, func, word_op, out, oflags);
  // IO ports
  input [15:0] x, y, off, seg, iflags;
  input [2:0] func;
  input word_op;
  output [19:0] out;
  output [8:0] oflags;

  // Net declarations
  wire [15:0] deff, deff2, outf, clcm, setf, intf, strf;
  wire [19:0] dcmp, dcmp2; 
  wire dfi;

  // Module instantiations
  mux8_16 m0(func, dcmp[15:0], dcmp2[15:0], deff, outf, clcm, setf, 
                   intf, strf, out[15:0]);
  assign out[19:16] = func ? dcmp2[19:16] : dcmp[19:16];

  // Assignments
  assign dcmp  = (seg << 4) + deff;
  assign dcmp2 = (seg << 4) + deff2;
  assign deff  = x + y + off;
  assign deff2 = x + y + off + 16'd2;
  assign outf  = y;
  assign clcm  = y[2] ? (y[1] ? /* -1: clc */ {iflags[15:1], 1'b0} 
                         : /* 4: cld */ {iflags[15:11], 1'b0, iflags[9:0]})
                     : (y[1] ? /* 2: cli */ {iflags[15:10], 1'b0, iflags[8:0]}
                       : /* 0: cmc */ {iflags[15:1], ~iflags[0]});
  assign setf  = y[2] ? (y[1] ? /* -1: stc */ {iflags[15:1], 1'b1} 
                         : /* 4: std */ {iflags[15:11], 1'b1, iflags[9:0]})
                     : (y[1] ? /* 2: sti */ {iflags[15:10], 1'b1, iflags[8:0]}
                       : /* 0: outf */ iflags);

  assign intf = {iflags[15:10], 2'b0, iflags[7:0]};
  assign dfi  = iflags[10];
  assign strf = dfi ? (x - y) : (x + y);

  assign oflags = word_op ? { out[11:6], out[4], out[2], out[0] }
                           : { iflags[11:8], out[7:6], out[4], out[2], out[0] };
endmodule
