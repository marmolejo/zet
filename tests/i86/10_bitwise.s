#  Bitwise logic instruction test bench

#  Copyright (c) 2008  Zeus Gomez Marmolejo <zeus@opencores.org>
#
#  This file is part of the Zet processor. This processor is free
#  hardware; you can redistribute it and/or modify it under the terms of
#  the GNU General Public License as published by the Free Software
#  Foundation; either version 3, or (at your option) any later version.
#
#  Zet is distrubuted in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
#  License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Zet; see the file COPYING. If not, see
#  <http://www.gnu.org/licenses/>.

# and  1 (w:r,r), 2 (w:m,r), 3 (w:r,m), 4 (w:i,a), 5 (w:i,r), 6 (w:i,m)
#      7 (b:r,r), 8 (b:m,r), 9 (b:r,m), 10(b:i,a), 11(b:i,r), 12(b:i,m)
# or   13(w:r,r), 14(w:m,r), 15(w:r,m), 16(w:i,a), 17(w:i,r), 18(w:i,m)
#      19(b:r,r), 20(b:m,r), 21(b:r,m), 22(b:i,a), 23(b:i,r), 24(b:i,m)
# xor  25(w:r,r), 26(w:m,r), 27(w:r,m), 28(w:i,a), 29(w:i,r), 30(w:i,m)
#      31(b:r,r), 32(b:m,r), 33(b:r,m), 34(b:i,a), 35(b:i,r), 36(b:i,m)
# test 37(w:r,r), 38(w:m,r), 39(w:r,m), 40(w:i,a), 41(w:i,r), 42(w:i,m)
#      43(b:r,r), 44(b:m,r), 45(b:r,m), 46(b:i,a), 47(b:i,r), 48(b:i,m)
# not  49(w:r), 50(w:m), 51(b:r), 52(b:m)
#
# End results, memory contents:
#
# 0x00:  0x0000  0x2400  0x30c0  0x57ff  0xff6e  0x3939  0x89ed  0x4a80
# 0x10:  0xa8a8  0x35f6  0x4f00  0xb419  0xe92d  0xXXXX  0xXXXX  0xXXXX
# 0x20:  0x4218  0x2400  0x4451  0x0208  0x0040  0x0840  0xfdf7  0x7ae8
# 0x30:  0x45e3  0xbb7d  0xf8e7  0xf7e3  0xcb0c  0x123a  0xedb7  0xa0cb
# 0x40:  0x035a  0xa201  0xdbe1  0x6549  0x4d37  0x5cc4  0x494d  0xe137
# 0x50:  0x405a  0xXXa5  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x60:  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x70:  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x80:  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x90:  0xXXXX  0xXXXX  0xXXXX  0xXXXX  0x0293  0x0293  0x0293  0x0293
# 0xa0:  0x0082  0x0082  0x0046  0x0002  0x0006  0x0006  0x0006  0x0006
# 0xb0:  0x0006  0x0006  0x0002  0x0006  0x0082  0x0082  0x0002  0x0086
# 0xc0:  0x0006  0x0006  0x0002  0x0082  0x0086  0x0006  0x0006  0x0086
# 0xd0:  0x0002  0x0082  0x0082  0x0086  0x0082  0x0086  0x0082  0x0086
# 0xe0:  0x0002  0x0002  0x0006  0x0082  0x0046  0x0002  0x0002  0x0006
# 0xf0:  0x0046  0x0002  0x0006  0x0002  0x0002  0x0046  0x0006  0x0006

.code16
start:

# Some random stuff to start with
movw $0x7659, %ax
movw $0x4bb8, %bx
movw $0x3c84, %cx
movw $0x1b76, (0)
movw $0x240b, (2)

movw $256, %sp

# Word AND
andw %ax, %bx      # (1)
pushf
movw %bx, (32)
andw (2), %cx      # (2)
pushf
movw %cx, (34)
andw %cx, (0)      # (3)
pushf
andw $0x4571, %ax  # (4)
pushf
movw %ax, (36)
andw $0x27e9, %bx  # (5)
pushf
movw %bx, (38)
andw $0x3549, (2)  # (6)
pushf

# Byte AND
andb %al, %ah      # (7)
pushf
movb %ah, (40)
andb (1), %cl      # (8)
pushf
movb %cl, (41)
andb %ch, (3)      # (9)
pushf
andb $0x46, %al    # (10)
pushf
movb %al, (42)
andb $0x2d, %bl    # (11)
pushf
movb %bl, (43)
andb $0xc6, (2)    # (12)
pushf

movw $0x05e3, %ax
movw $0xf877, %bx
movw $0x4ae8, %cx
movw $0x3b69, %dx
movw $0x30c0, (4)
movw $0x5775, (6)
movw $0xfe66, (8)

# Word OR
orw  %ax, %bx      # (13)
pushf
movw %bx, (44)
orw  (4), %cx      # (14)
pushf
movw %cx, (46)
orw  %ax, (6)      # (15)
pushf
orw  $0x41c3, %ax  # (16)
pushf
movw %ax, (48)
orw  $0xb05d, %dx  # (17)
pushf
movw %dx, (50)
orw  $0x8d4c, (8)  # (18)
pushf

# Byte OR
orb %al, %ah       # (19)
pushf
movb %ah, (52)
orb (5), %cl       # (20)
pushf
movb %cl, (53)
orb %ch, (6)       # (21)
pushf
orb $0x43, %al     # (22)
pushf
movb %al, (54)
orb $0x57, %bl     # (23)
pushf
movb %bl, (55)
orb $0x54, (7)     # (24)
pushf

movw $0xd0b4, %ax
movw $0x1bb8, %bx
movw $0x2b03, %cx
movw $0xc3e6, %dx
movw $0x3939, (10)
movw $0x864b, (12)
movw $0x8587, (14)

# Word XOR
xorw  %ax, %bx     # (25)
pushf
movw %bx, (56)
xorw (10), %cx     # (26)
pushf
movw %cx, (58)
xorw %ax, (12)     # (27)
pushf
xorw $0x3d03, %ax  # (28)
pushf
movw %ax, (60)
xorw $0x632d, %dx  # (29)
pushf
movw %dx, (62)
xorw $0xcf07, (14) # (30)
pushf

# Byte XOR
xorb %al, %ah      # (31)
pushf
movb %ah, (64)
xorb (11), %cl     # (32)
pushf
movb %cl, (65)
xorb %ch, (12)     # (33)
pushf
xorb $0xb6, %al    # (34)
pushf
movb %al, (66)
xorb $0xae, %bl    # (35)
pushf
movb %bl, (67)
xorb $0xdf, (13)   # (36)
pushf

movw $0x4d37, %ax
movw $0xdbe1, %bx
movw $0x6549, %cx
movw $0x5cc4, %dx
movw $0xa8a8, (16)
movw $0x35f6, (18)
movw $0x4f00, (20)

# Word TEST
testw  %ax, %bx     # (37)
pushf
movw %bx, (68)
testw (16), %cx     # (38)
pushf
movw %cx, (70)
testw %ax, (18)     # (39)
pushf
testw $0xdc6f, %ax  # (40)
pushf
movw %ax, (72)
testw $0x3046, %dx  # (41)
pushf
movw %dx, (74)
testw $0x96e4, (20) # (42)
pushf

# Byte TEST
testb %al, %ah      # (43)
pushf
movb %ah, (76)
testb (15), %cl     # (44)
pushf
movb %cl, (77)
testb %ch, (16)     # (45)
pushf
testb $0xc0, %al    # (46)
pushf
movb %al, (78)
testb $0xe0, %bl    # (47)
pushf
movb %bl, (79)
testb $0xbb, (17)   # (48)
pushf

movw $0xbfa5, %dx
movw $0x4be6, (22)
movw $0xe9d2, (24)

movw $0x12b1, %ax
pushw %ax
popf

# Word NOT
notw %dx            # (49)
pushf
movw %dx, (80)
notw (22)           # (50)
pushf

# Byte NOT
notb %dl            # (51)
pushf
movb %dl, (82)
notb (24)           # (52)
pushf

hlt


.org 65520
jmp start
.org 65535
.byte 0xff
