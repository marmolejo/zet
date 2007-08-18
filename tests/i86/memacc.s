.code16
a:
movw  $0xff00,%bx
movw  $0xf4,%di
movw  $0xf000,%cx
movw  %cx,%ds
incw  -4(%bx,%di)

.org 65520
jmp a
