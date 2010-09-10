# Compiler flags:
#  -0   generate 8086 code
#  -ms  forces small model
#  -s   remove runtime stack checks
#  -ot  Optimize for time of execution rather than size
#  -zu  assume that SS != DS
#  -ecc force use of __cedecl calls
#
CFLAGS = -0 -wx -zu -s -ot -d0 -ecc -ms 

AFLAGS = -0 -wx 

.c.obj : .autodepend
	wcc $(CFLAGS) $<

.asm.obj : .autodepend
	wasm $(AFLAGS) $<

OBJS = vgabios_c.obj vgabios_a.obj

vgabios.rom : $(OBJS) $(__MAKEFILES__)
	wlink name $@ system dos OPTION NOFARCALLS , map &
	 output raw offset=0xC0000 order &
	 clname CODE &
	               segment _VGASEG segaddr=0xC000 offset=0x0000 &
	               segment _TEXT   segaddr=0xC000 offset=0x1000 &
	 clname DATA   segment _DATA   segaddr=0xC000 offset=0x4000 &
	 file { $(OBJS) } &
	 library clibs.lib &
	 disable 1014
