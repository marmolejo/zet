.code16
start:
enter $2345, $1
imul   $0x6556,%bp,%sp
leave
hlt

.org 65520
jmp start
.org 65535
.byte 0xff
