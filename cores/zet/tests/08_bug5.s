.code16
start:

# Set up everything for a single iteration?
movw $0, %cx
cld

movw $0xf000, %ax
movw %ax, %ds
movw $0, %di
movw %di, %es
movw %di, %si

rep movsw

movw %di, %ax

hlt


.org 65520
jmp start

.org 65535
.byte 0xff
