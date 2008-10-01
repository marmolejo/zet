# Conversion instructions test bench

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

# aaa  1 (adj), 2 (adj,AF), 3 (nadj), 4 (random), 5 (random)
# aas  6 (adj), 7 (adj,AF), 8 (nadj), 9 (random), 10(random)
# daa  11(adj:1,3), 12(adj:2,3), 13(adj:4), 14(adj:1), 15(nadj),
#      16(random),  17(random)
# das  18(adj:1,3), 19(adj:2,3), 20(adj:4), 21(adj:1), 22(nadj),
#      23(random),  24(random)
# cbw  25(positive), 26(negative), 27(random)
# cbw  28(negative), 29(positive), 30(random)
#
# End results, memory contents:
#
# 0x00:  0x0100  0x000f  0xff09  0x5d00  0x4706  0xff04  0xfe03  0xff09
# 0x10:  0xdc00  0x5e05  0x0012  0xff5f  0xff58  0xff91  0x0082  0x0000
# 0x20:  0x3f00  0x0046  0xff93  0xff98  0xff85  0x0082  0x0534  0x5490
# 0x30:  0x007f  0x0000  0xff80  0x0000  0xffed  0x0000  0x8000  0xffff
# 0x40:  0x7fff  0x0000  0x43f1  0x0000  0xXXXX  0xXXXX  0xXXXX  0xXXXX
# 0x50:  0xXXXX  0xXXXX  0x0097  0x0097  0x0097  0x0097  0x0097  0x0097
# 0x60:  0x0097  0x0013  0x0086  0x0092  0x0083  0x0097  0x0013  0x0046
# 0x70:  0x0046  0x0086  0x0092  0x0003  0x0017  0x0017  0x0017  0x0046
# 0x80:  0x0006  0x0017  0x0013  0x0006  0x0046  0x0006  0x0017  0x0057

.code16
start:

movw $1, %bx
movw $0, %cx
movw $144, %sp

# aaa
movw $0x000a, %ax
aaa                # (1) adjusted
movw %ax, (0)
pushf

movw $0xfff9, %ax
aaa                # (2) adjusted by AF
movw %ax, (2)
pushf

push %bx
popf
movw $0xfff9, %ax
aaa                # (3) not adjusted
movw %ax, (4)
pushf

movw $0x5d50, %ax
aaa                # (4) aaa random
movw %ax, (6)
pushf

movw $0x4726, %ax
aaa                # (5) aaa random
movw %ax, (8)
pushf

# aas
movw $0x000a, %ax
aas                # (6) adjusted
movw %ax, (10)
pushf

movw $0xfff9, %ax
aas                # (7) adjusted by AF
movw %ax, (12)
pushf

push %bx
popf
movw $0xfff9, %ax
aas                # (8) not adjusted
movw %ax, (14)
pushf

movw $0xdcc0, %ax
aas                # (9) aas random
movw %ax, (16)
pushf

movw $0x5ffb, %ax
aas                # (10) aas random
movw %ax, (18)
pushf

# daa
movw $0x00ac, %ax
daa                # (11) daa, adj 1st & 3rd cond
movw %ax, (20)
pushf

movw $0xfff9, %ax
daa
movw %ax, (22)     # (12) daa, adj 2nd & 3rd cond
pushf

push %bx
popf               # carry set
movw $0xfff8, %ax
daa                # (13) daa, adj 4th cond
movw %ax, (24)
pushf

push %cx
popf               # zero flags
movw $0xff8b, %ax
daa                # (14) daa, adj 1st cond
movw %ax, (26)
pushf

push %cx
popf
movw $0x0082, %ax
daa                # (15) daa, not adjusted
movw %ax, (28)
pushf

movw $cd3c, %ax
daa                # (16) daa, random
movw %ax, (30)
pushf

movw $0x3f00, %ax
daa                # (17) daa, random
movw %ax, (32)
pushf

# das
movw $0x00ac, %ax
das                # (18) das, adj 1st & 3rd cond
movw %ax, (34)
pushf

movw $0xfff9, %ax
das
movw %ax, (36)     # (19) das, adj 2nd & 3rd cond
pushf

push %bx
popf               # carry set
movw $0xfff8, %ax
das                # (20) das, adj 4th cond
movw %ax, (38)
pushf

push %cx
popf               # zero flags
movw $0xff8b, %ax
das                # (21) das, adj 1st cond
movw %ax, (40)
pushf

push %cx
popf
movw $0x0082, %ax
das                # (22) das, not adjusted
movw %ax, (42)
pushf

movw $0x059a, %ax
das                # (23) das, random
movw %ax, (44)
pushf

movw $0x54f6, %ax
das                # (24) das, random
movw %ax, (46)
pushf

# cbw
movw $0xff7f, %ax
cbw                # (25) cbw, positive
movw %ax, (48)
movw %dx, (50)
pushf

movw $0x0080, %ax
cbw                # (26) cbw, negative
movw %ax, (52)
movw %dx, (54)
pushf

movw $0xf1ed, %ax
cbw                # (27) cbw, random
movw %ax, (56)
movw %dx, (58)
pushf

# cwd
movw $0x8000, %ax
cwd                # (28) cwd, negative
movw %ax, (60)
movw %dx, (62)
pushf

movw $0x7fff, %ax
cwd                # (29) cwd, positive
movw %ax, (64)
movw %dx, (66)
pushf

movw $0x43f1, %ax
cwd                # (30) cwd, random
movw %ax, (68)
movw %dx, (70)
pushf

hlt

.org 65520
jmp start

.org 65535
.byte 0xff
