.code16
a:

#
# ADC
#
# 1: A negativo, B positivo: A: ffff B: 0001, A+B=0, ZAPC
movw $0xffff,%ax
movw $1,%bx
adcw %bx,%ax

# 2: A negativo, B positivo, A+B < 16 bits: A: ffff B: ffff, C A+B=ffff SAPC
movw $0xffff,%ax
movw $0xffff,%bx
adcw %bx,%ax

# 3: A positivo, B positivo, A+B < 16 bits: A: 0001 B: 0002, A+B=3, P
movw $0x0001,%ax
movw $0x0002, %bx
adcw %bx,%ax

# 4: A pos, B pos, A+B = 16 bits: A: 7fff B: 0001, A+B=8000, OSAP
movw $0x7fff,%ax
movw $0x0001,%bx
adcw %bx,%ax

# 5: A neg, B neg, A+B = 16 bits: A: 8000 B: ffff, A+B=0fff OPC
movw $0x8000,%ax
movw $0xffff,%bx
adcw %bx,%ax

# 6: A aleat, B aleat: A: 1a62 B: ed8a, A+B=
movw $0x1a62,%ax
movw $0xed8a,%bx
adcw %bx,%ax

#
# ADD
#
# 7: A negativo, B positivo: A: ffff B: 0001, A+B=0, ZAPC
movw $0xffff,%ax
movw $1,%bx
addw %bx,%ax

# 8: A negativo, B positivo, A+B < 16 bits: A: ffff B: ffff, C A+B=ffff SAPC
movw $0xffff,%ax
movw $0xffff,%bx
addw %bx,%ax

# 9: A positivo, B positivo, A+B < 16 bits: A: 0001 B: 0002, A+B=3, P
movw $0x0001,%ax
movw $0x0002, %bx
addw %bx,%ax

# 10: A pos, B pos, A+B = 16 bits: A: 7fff B: 0001, A+B=8000, OSAP
movw $0x7fff,%ax
movw $0x0001,%bx
addw %bx,%ax

# 11: A neg, B neg, A+B = 16 bits: A: 8000 B: ffff, A+B=0fff OPC
movw $0x8000,%ax
movw $0xffff,%bx
addw %bx,%ax

# 12: A aleat, B aleat: A: 027f B: 846c, A+B=
movw $0x027f,%ax
movw $0x846c,%bx
addw %bx,%ax

#
# INC
#
# 13: A-, -1: A: ffff. Da carry, no debería cambiar el flag de C
movw $0xffff,%ax
incw %ax

# 14: A+: 7fff. Overflow
movw $0x7fff,%ax
incw %ax

# 15: A aleat. 4513
movw $0x4513,%ax
incw %ax

#
# DEC
#
# 16: A: 0000.
movw $0x0000,%ax
decw %ax

# 17: B: 8000. Underflow
movw $0x8000,%ax
decw %ax

# 18: A aleat. c7db
movw $0xc7db,%ax
decw %ax

#
# NEG
#
# 19: A: 0
movw $0x0000,%ax
negw %ax

# 20: A: 8000. Overflow
movw $0x8000,%ax
negw %ax

# 21: A aleat. fac4
movw $0xfac4,%ax
negw %ax

#
# SBB
#
# 22: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 A-B=ffff SAPC
movw $0x0001,%ax
movw $0x0002,%bx
sbbw %bx,%ax

# 23: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff A-B=0 ZP
movw $0xffff,%ax
movw $0xffff,%bx
sbbw %bx,%ax

# 24: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
movw $0xffff,%ax
movw $0x0001,%bx
sbbw %bx,%ax

# 25: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
movw $0x8000,%ax
movw $0x0001,%bx
sbbw %bx,%ax

# 26: A aleat, B aleat, con carry: A: a627 B: 03c5, C A-B=
movw $0xa627,%ax
movw $0x03c5,%bx
stc
sbbw %bx,%ax

#
# SUB
#
# 27: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 A-B=ffff SAPC
movw $0x0001,%ax
movw $0x0002,%bx
subw %bx,%ax

# 28: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff A-B=0 ZP
movw $0xffff,%ax
movw $0xffff,%bx
subw %bx,%ax

# 29: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
movw $0xffff,%ax
movw $0x0001,%bx
subw %bx,%ax

# 30: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
movw $0x8000,%ax
movw $0x0001,%bx
subw %bx,%ax

# 31: A aleat, B aleat, con carry: A: a627 B: 03c5, C A-B=
movw $0xa627,%ax
movw $0x03c5,%bx
stc
subw %bx,%ax

#
# CMP
#
# 32: A+, B+, A-B siempre será menor de 16 bits: A: 0001 B: 0002 A-B=ffff SAPC
movw $0x0001,%ax
movw $0x0002,%bx
cmpw %bx,%ax

# 33: A-, B-, A-B siempre será menor de 16 bits: A: ffff B: ffff A-B=0 ZP
movw $0xffff,%ax
movw $0xffff,%bx
cmpw %bx,%ax

# 34: A-, B+, A-B < 16 bits: A: ffff B:1 A-B=fffe S
movw $0xffff,%ax
movw $0x0001,%bx
cmpw %bx,%ax

# 35: A-, B+, A-B = 16 bits: A: 8000 B:1 A-B=7fff OAP
movw $0x8000,%ax
movw $0x0001,%bx
cmpw %bx,%ax

# 36: A aleat, B aleat, con carry: A: aa97 B: 3b46, C A-B=
movw $0xaa97,%ax
movw $0x3b46,%bx
stc
cmpw %bx,%ax


.org 65520
jmp a

.org 65535
.byte 0xff
