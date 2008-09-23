# Interrupt instruction testbench
#
# Memory contents at the end should be:
# 0x00:  0x0100  0x0302  0x0504  0xXX06  0x0cd7  0x0ed7  0x4002  0x04ff
# 0x10:  0x1000  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX
#
# int   1, 2 (int 3)
# into  3
# iret  4
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
movb $0, (0)
int $13                 # (1)
movb $2, (2)
jmp *%ax

.org 0x0cd7
movb $3, (3)
pushf
pop %bx
movw $0xebe0, (12)
movw $0xe342, (14)

int $3                  # (2)
movb $4, (4)
movw $0x3001, (16)
movw $0xf000, (18)

into                    # (3) branch taken
hlt

.org 0x2000
movb $1, (1)
pushf
pop %ax
clc
iret                    # (4)

.org 0x3001
movb $5, (5)
pop %cx
movw $0x4002, %cx
push %cx
iret

.org 0x4002
movb $6, (6)
movw $0x4ff, %dx
push %dx
popf
movw $0x5000, (16)

into                    # (3) branch not taken
movw %ax, (8)
movw %bx, (10)
movw %cx, (12)
movw %dx, (14)
movw %sp, (16)
hlt 

.org 0x5000
hlt

.org 65520
jmp start
.org 65535
.byte 0xff
