`include "rom_def.v"

`define IR_SIZE 36
`define MEM_OP  31
`define ADD_IP `IR_SIZE'bx__0__1__0__1__10_001_001__0__01__0__0_1111_xxxx_xxxx_1111_xx
`define OP_NOP 8'h90