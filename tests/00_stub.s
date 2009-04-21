.code16
start:
movw $0x7654, %ax
movw $0x1, %bx
movw %ax, (%bx)
movw $0xf100, %dx
movw $0x1234, %ax
outw %ax, %dx
movw (1), %cx
movw %cx, %ax
outw %ax, %dx
hlt

.org 65520
hlt
jmp start

.org 65535
.byte 0xff
