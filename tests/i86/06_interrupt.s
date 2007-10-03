# Interrupt instruction testbench
#
# At the end (2535ns), %ax=0x1234, %bx=0x0ed7
#
# int   1, 2 (int 3)
# iret  3
#
.code16
start:
movw $0, %dx
movw %dx, %ds
movw $0x1000, %sp
movw %sp, %ss
movw $0xebe0, (52)
movw $0xe342, (54)

movw $0x0eff, %ax
push %ax
popf

int $13        # (1)

jmp *%ax

.org 0x0cd7
pushf
pop %bx
movw $0xebe0, (12)
movw $0xe342, (14)

int $3
movw $0x1234, %ax
hlt

.org 0x2000
pushf
pop %ax
clc
iret           # (3)

.org 65520
jmp start
.org 65535
.byte 0xff
