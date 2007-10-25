.code16
start:
movw $0xb800, %dx
movw %dx, %ds
movw $0x034d, (4)
movw (1), %cx
hlt

.org 65520
jmp start

.org 65535
.byte 0xff
