# Interrupt instruction testbench
#
# At the end (3737ns in rtl-model, 275.9us in spartan3), 
#  %ax=0x1234, %bx=0x0ed7
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

int $13                 # (1)

jmp *%ax

.org 0x0cd7
pushf
pop %bx
movw $0xebe0, (12)
movw $0xe342, (14)

int $3                  # (2)

movw $0x3001, (16)
movw $0xf000, (18)

into                    # (3) branch taken
hlt

.org 0x2000
pushf
pop %ax
clc
iret                    # (4)

.org 0x3001
pop %cx
movw $0x4002, %cx
push %cx
iret

.org 0x4002
movw $0x4ff, %dx
push %dx
popf
movw $0x5000, (16)

into                    # (3) branch not taken
movw $0x1234, %ax
hlt 

.org 0x5000
hlt

.org 65520
jmp start
.org 65535
.byte 0xff
