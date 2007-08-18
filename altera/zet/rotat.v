module rotat(x, y, out, func, word_op, cfi, cfo, ofo);
  // IO ports
  input  [15:0] x, y;
  input   [1:0] func;
  input         cfi, word_op;
  output [15:0] out;
  output        cfo;
  output        ofo;

  // Net declarations
  

  // Assignments
  assign rcl16_0  = x;
  assign rcl16_1  = { x[14:0], cfi };
  assign rcl16_2  = { x[13:0], cfi, x[15] };
  assign rcl16_3  = { x[12:0], cfi, x[15:14] };
  assign rcl16_4  = { x[11:0], cfi, x[15:13] };
  assign rcl16_5  = { x[10:0], cfi, x[15:12] };
  assign rcl16_6  = { x[9:0], cfi, x[15:11] };
  assign rcl16_7  = { x[8:0], cfi, x[15:10] };
  assign rcl16_8  = { x[7:0], cfi, x[15:9] };
  assign rcl16_9  = { x[6:0], cfi, x[15:8] };
  assign rcl16_10 = { x[5:0], cfi, x[15:7] };
  assign rcl16_11 = { x[4:0], cfi, x[15:6] };
  assign rcl16_12 = { x[3:0], cfi, x[15:5] };
  assign rcl16_13 = { x[2:0], cfi, x[15:4] };
  assign rcl16_14 = { x[1:0], cfi, x[15:3] };
  assign rcl16_15 = { x[0], cfi, x[15:2] };
  assign rcl16_16 = { cfi, x[15:1] };
endmodule