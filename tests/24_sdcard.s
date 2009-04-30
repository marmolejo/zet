.code16
start:
movw $0x00ff, %ax
movw $0x0100, %dx
movw $10, %cx
# initialization
a:
outb %al, %dx
loop a

# CMD0, reset the SD card
movw $0x40, %ax # CS = 0, CMD0
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit zero value
outb %al, %dx
outb %al, %dx
outb %al, %dx
movb $0x95, %al
outb %al, %dx   # CRC fixed value
movb $0xff, %al
outb %al, %dx   # wait
inb  %dx, %al   # status
movb %al, %cl
movw $0xffff, %ax
outw %ax, %dx

cmpb $1, %cl
je init_again
hlt

# SECOND COMMAND, activates the init sequence
init_again:
# CMD1
movw $0x41, %ax # CS = 0, CMD1
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit zero value
outb %al, %dx
outb %al, %dx
outb %al, %dx
movb $0xff, %al
outb %al, %dx   # CRC (not used)
outb %al, %dx   # wait
inb  %dx, %al   # status
movb %al, %cl
movw $0xffff, %ax
outw %ax, %dx

testb $0xff, %cl
jnz init_again

# THIRD COMMAND, set block length
# CMD16
movw $0x50, %ax # CS = 0, CMD16
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit value
outb %al, %dx
movb $0x2, %al  # 512 bytes
outb %al, %dx
xorb %al, %al
outb %al, %dx
movb $0xff, %al
outb %al, %dx   # CRC (not used)
outb %al, %dx   # wait
inb  %dx, %al   # status
movb %al, %cl
movw $0xffff, %ax
outw %ax, %dx

testb $0xff, %cl
jz read_single
hlt

read_single:

# FOURTH COMMAND, read single block
# CMD17
movw $0x51, %ax # CS = 0, CMD17
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit value
outb %al, %dx
#movb $2, %al
outb %al, %dx
xorb %al, %al
outb %al, %dx
movb $0xff, %al
outb %al, %dx   # CRC (not used)
outb %al, %dx   # wait

read_res_cmd17:
inb %dx, %al   # card response
cmpb $0, %al
jne read_res_cmd17

# read data token
read_tok_cmd17:
inb %dx, %al
cmpb $0xfe, %al
jne read_tok_cmd17

movw $0x200, %cx
read_sect:
inb %dx, %al  # first byte of sector
loop read_sect

movw $0xffff, %ax
outb %al, %dx  # Checksum, 1st byte
outb %al, %dx  # Checksum, 2nd byte
outb %al, %dx  # wait
outb %al, %dx  # wait
outw %ax, %dx

# CMD24
movw $0x58, %ax # CS = 0, CMD17
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit value
outb %al, %dx
#movb $2, %al
outb %al, %dx
xorb %al, %al
outb %al, %dx
movb $0xff, %al
outb %al, %dx   # CRC (not used)
outb %al, %dx   # wait

read_res_cmd24:
inb %dx, %al    # card response
cmpb $0, %al
jne read_res_cmd24

movb $0xff, %al # wait
outb %al, %dx
movb $0xfe, %al # start of block
outb %al, %dx

# send sector byte by byte
movw $0x200, %cx
wr_sect:
movb %cl, %al
outb %al, %dx
loop wr_sect

movb $0xff, %al # Dummy checksum
outb %al, %dx
outb %al, %dx

inb  %dx, %al   # Data response
andb $0xf, %al
cmpb $0x5, %al
je   data_acc

movw $0xf100, %dx
xorb %ah, %ah
outw %ax, %dx

hlt

data_acc:
inb  %dx, %al
cmpb $0, %al
je   data_acc   # write finished?

movw $0xffff, %ax
outb %al, %dx  # wait
outb %al, %dx  # wait
outw %ax, %dx


# CMD17
movw $0x51, %ax # CS = 0, CMD17
outw %ax, %dx
xorb %al, %al
outb %al, %dx   # 32-bit value
outb %al, %dx
movb $2, %al
outb %al, %dx
xorb %al, %al
outb %al, %dx
movb $0xff, %al
outb %al, %dx   # CRC (not used)
outb %al, %dx   # wait

read_res_cmd17_2:
inb %dx, %al   # card response
cmpb $0, %al
jne read_res_cmd17_2

# read data token
read_tok_cmd17_2:
inb %dx, %al
cmpb $0xfe, %al
jne read_tok_cmd17_2

movw $0x200, %cx
read_sect_2:
inb %dx, %al  # first byte of sector
loop read_sect_2

movw $0xffff, %ax
outb %al, %dx  # Checksum, 1st byte
outb %al, %dx  # Checksum, 2nd byte
outb %al, %dx  # wait
outb %al, %dx  # wait
outw %ax, %dx


# output status to leds
movw $0xf100, %dx
xorb %ah, %ah
outw %ax, %dx

hlt

.org 65520
jmp start

.org 65535
.byte 0xff
