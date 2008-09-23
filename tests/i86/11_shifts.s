#  Shift logic instruction test bench

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

# sal  1 (w:1,r), 2 (w:1,m), 3 (w:cl,r), 4 (w:cl,m)
#      5 (b:1,r), 6 (b:1,m), 7 (b:cl,r), 8 (b:cl,m)
# sar  9 (w:1,r), 10(w:1,m), 11(w:cl,r), 12(w:cl,m)
#      13(b:1,r), 14(b:1,m), 15(b:cl,r), 16(b:cl,m)
# shr  17(w:1,r), 18(w:1,m), 19(w:cl,r), 20(w:cl,m)
#      21(b:1,r), 22(b:1,m), 23(b:cl,r), 24(b:cl,m)
#
# End results, memory contents:
#
# 0x00:  0xa670  0x31e0  0x66c0  0x6480  0x0f5d  0x7402  0xe5d4  0x6eff
# 0x10:  0x5d55  0x3403  0x1d26  0x8d00  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x20:  0xdd8a  0xb1a8  0x0000  0xa800  0x8493  0x9580  0xfdb9  0xdfb9
# 0x30:  0xffff  0xfefd  0x3388  0x93ff  0x3dd0  0x54e8  0x0000  0x054e
# 0x40:  0x0b28  0x0400  0x0046  0x0046  0x0007  0x0002  0x0006  0x0007
# 0x50:  0x0046  0x0806  0x0806  0x0003  0x0087  0x0086  0x0082  0x0006
# 0x60:  0x0003  0x0083  0x0087  0x0003  0x0003  0x0082  0x0083  0x0083
# 0x70:  0x0006  0x0886  0x0083  0x0087  0x0046  0x0882  0x0882  0x0882

.code16
start:

# sal/shl word operations
movw $0x6ec5, %ax
movw $0xb1a8, %bx
movw $0x5338, (0)
movw $0x31fe, (2)

movw $128, %sp

sal  %ax        # (1)
pushf
mov  %ax, (32)

shlw (0)        # (2)
pushf

movw $0x100, %cx
shl  %cl, %bx   # (3), zero bit shift
pushf
movw %bx, (34)

movw $0xffff, %cx
movw %bx, %dx
sal  %cl, %dx   # (3), -1, result 0
pushf
movw %dx, (36)

movb $0x8, %cl
sal  %cl, %bx   # (3) normal
pushf
movw %bx, (38)

movb $0x4, %cl
sal  %cl, (2)   # (4)
pushf

# sal/shl byte operations
movw $0x956f, %dx
movw $0x4293, %ax
movw $0x33c0, (4)
movw $0x64ff, (6)

shl  %ah        # (5)
pushf
mov  %ax, (40)

salb (5)        # (6)
pushf

movb $0x7, %cl
shl  %cl, %dl   # (7)
pushf
movw %dx, (42)

salb %cl, (6)   # (8)
pushf

# sar word operations
movw $0xfb72, %ax
movw $0xdfb9, %bx
movw $0x1ebb, (8)
movw $0x742f, (10)

sar  %ax        # (9)
pushf
mov  %ax, (44)

sarw (8)        # (10)
pushf

movw $0x100, %cx
sar  %cl, %bx   # (11), zero bit shift
pushf
movw %bx, (46)

movw $0xffff, %cx
movw %bx, %dx
sar  %cl, %dx   # (11), -1, result 0
pushf
movw %dx, (48)

movb $0x5, %cl
sar  %cl, %bx   # (11) normal
pushf
movw %bx, (50)

movb $0x4, %cl
sar  %cl, (10)  # (12)
pushf

# sar byte operations
movw $0x93b8, %dx
movw $0x6688, %ax
movw $0xcad4, (12)
movw $0x6ec9, (14)

sar  %ah        # (13)
pushf
mov  %ax, (52)

sarb (13)       # (14)
pushf

movb $0x7, %cl
sar  %cl, %dl   # (15)
pushf
movw %dx, (54)

sarb %cl, (14)  # (16)
pushf

# shr word operations
movw $0x7ba1, %ax
movw $0x54e8, %bx
movw $0xbaaa, (16)
movw $0x3431, (18)

shr  %ax        # (17)
pushf
mov  %ax, (56)

shrw (16)       # (18)
pushf

movw $0x100, %cx
shr  %cl, %bx   # (19), zero bit shift
pushf
movw %bx, (58)

movw $0xffff, %cx
movw %bx, %dx
shr  %cl, %dx   # (19), -1, result 0
pushf
movw %dx, (60)

movb $0x4, %cl
shr  %cl, %bx   # (19) normal
pushf
movw %bx, (62)

movb $0x4, %cl
shr  %cl, (18)  # (20)
pushf

# shr byte operations
movw $0x0410, %dx
movw $0x1628, %ax
movw $0x3b26, (20)
movw $0x8d0d, (22)

shr  %ah        # (21)
pushf
mov  %ax, (64)

shrb (21)       # (22)
pushf

movb $0x7, %cl
shr  %cl, %dl   # (23)
pushf
movw %dx, (66)

shrb %cl, (22)  # (24)
pushf




hlt

.org 65520
jmp start
.org 65535
.byte 0xff
