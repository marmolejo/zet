# mov: 1 (word), 2 (word), 3 (off, base+index+off), 4, 5 (off), 
#      7 (byte,word), 8 (byte off), 9 (word base), 10 (byte,word)
#
# Result:
# 0x00000000: 0x1290 0xfbe1 0x4001 0x4001

.code16
movw $0x1000, %bx       # (10) mov word
movw %bx, %ds           # (4)  mov

movb $0xfb, %ah         # (10) mov byte
movb $0xe1, %al         # (10) mov byte
movw %ax, (0x2501)      # (1)  mov word

movw $0x1001, (0x2600)  # (11) mov word
movw (0x2600), %ss      # (3)  mov

movw %ss, (0x2601)      # (5)  mov
movb (0x2601), %dl      # (8)  mov byte
movb $0x00, %dh         # (10) mov byte
movw %dx, %di           # (7)  mov word

movw $0x2506, %bp       # (10) mov word

movw -22(%bp,%di), %ax
movw $0, %bx
movw %bx, %ds
movw %ax, (2)
movw $0x1000, %bx
movw %bx, %ds

.byte 0xc7,0xc0        # (12) movw $0x4001, %ax
.word 0x4001           # [not in a default codification]
movw $0x2501, %bx
movw %ax, (%bx)         # (9)  mov word
movw $2, %di
movb $0x00, (%bx,%di)   # (11) mov byte
movb $4, %ch
movb %ch, %cl           # (7)  mov byte
movb $0, %ch
movw %cx, %si
movb $0xf0, -1(%bx,%si)
movw $0x3, %si
movw -24(%bp,%si), %ax
movw -3(%bx,%si), %cx
movw $0x0, %dx
movw %dx, %ds
movw %ax, (4)
movw %cx, (6)
hlt

.org 0xffe3
.word 0x1290

.org 0xfff0
movw $0xf000, %bx       # (10) mov word
movw %bx, %ds           # (4)  mov
movw (0xffe3), %ax      # (2)  mov word

movw $0, %bx
movw %bx, %ds
movw %ax, (0)
