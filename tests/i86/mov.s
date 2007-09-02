.code16
movw $1, %si
movw $0x3241, (%bx)
movw (0x0001), %ax
movw (%bp), %dx
movw %dx, %cx
movw %dx, (%si)
movw (0x0001), %di
movb $0x76, %ch
movb $0x79, (%bx)
movb %ch, (%si)
movb (%bx), %dl
movb %dh, %dl
