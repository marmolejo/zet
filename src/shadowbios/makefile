# Compiler flags:
#  -0   generate 8086 code
#  -ms  forces small model
#  -s   remove runtime stack checks
#  -ot  Optimize for time of execution rather than size
#  -zu  assume that SS != DS
#  -ecc force use of __cedecl calls
#
bios.rom: vgabios.rom ff.rom zetbios.rom .autodepend
          cat vgabios.rom ff.rom zetbios.rom > $@    

CFLAGS = -0 -wx -zu -s -ot -d0 -ecc -ms 

AFLAGS = -0 -wx 

.c.obj : .autodepend
       wcc $(CFLAGS) $<

.asm.obj : .autodepend
       wasm $(AFLAGS) $<
	
OBJS = zetbios_c.obj zetbios_a.obj

zetbios.rom : $(OBJS) $(__MAKEFILES__)
    wlink name $@ system dos &
         OPTION quiet &
         OPTION NOFARCALLS &
         OPTION FILLCHAR=0xFF, MAP  &
         OUTPUT raw offset=0xf0000  &
         ORDER &
         clname DATA segment _DATA    segaddr=0xf000 offset=0x0000 &
         clname CODE segment _TEXT    segaddr=0xf000 offset=0x1000 &
                     segment _BIOSSEG segaddr=0xf000 offset=0xe000 &
         FILE { $(OBJS) } &
         LIBRARY clibs.lib &
         disable 1014
    biossums $@


