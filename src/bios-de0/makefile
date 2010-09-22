# ---------------------------------------------------------------------------- 
# ZET SHADOW BIOS FOR DE0 BUILD MAKE  09-14-2010 
# ---------------------------------------------------------------------------- 
# 
# This is the make file for the Zet SHADOW ROM BIOS and VGA BIOS Builds for the  
# DE0 Board ONLY.  There is a separate makefile for the DE1. 
#
# For this build to work,  you will need the Open Watcom compiler. If you have 
# it installed on your machine, then you should be able to just type 
# wmake and watcom should build it. There will be a small number of warning 
# messages, this is normal, just ignore them. 
# ---------------------------------------------------------------------------- 
  
# HEX ROM MAKE --------------------------------------------------------------- 
# This section converts the bios rom binary file into a hex file that the 
# DE0 loader program can use to program the Flash Ram on the DE0 board.
# ---------------------------------------------------------------------------- 
bios.hex: bios.rom hexer.exe zetbios.dat
  hexer bios.rom

# DAT SHADOW ROM MAKE -------------------------------------------------------- 
# This section converts the last 256 bytes of the bios rom to a dat file (hex)
# that needs to be included in the Quartus project build. The last 256 bytes
# of the ROM is the shadow boot rom section.
# ---------------------------------------------------------------------------- 
zetbios.dat: zetbios.rom mifer.exe
  mifer zetbios.rom
    
# ROM BUILD ------------------------------------------------------------------ 
# This section combines all 3 rom sections built below, into one 128K ROM  
# ready to be installed. When everything is done running and if all goes well 
# you should have a file BIOS_DE0.ROM of exactly 128K. For the DE0 board, you
# can not download this file directly into your DE1 board Flash RAM, it first
# has to be converted to HEX. The previous section does that.
# ---------------------------------------------------------------------------- 
bios.rom: vgabios.rom ff.rom zetbios.rom meow.exe
  meow vgabios.rom ff.rom zetbios.rom > $@
 
# FF.ROM Filler -------------------------------------------------------------- 
# This is a little utility that makes a 32k padding binary file so that it 
# comes out to exactly 128K for the flash rom. 
# ---------------------------------------------------------------------------- 
ff.rom: ff.exe
  ff 8192 >$@
 
# Make Utilities ------------------------------------------------------------- 
# This section compiles the following utilities: 
#  biossums.exe - Computes bios rom checksum value and appends it to the rom
#  vgasums.exe  - Same thing but for the vga rom
#  ff.exe       - Fills the space between vga and bios with 0xFF
#  meow.exe     - Concatenates the vga, ff and bios roms together into 1 file
#  hexer.exe    - Converts the finished bios rom to hex
#  mifer.exe    - Makes the Shadow Boot rom
# 
# The C option flags for this build are standard console build since 
# these utilities will run on your PC not on the ZET 
# ---------------------------------------------------------------------------- 
COPTS = -i="C:\WATCOM/h;C:\WATCOM/h/nt" -w4 -e25 -zq -od -d2 -6r -bt=nt -fo=.obj -mf
 
ff.exe: ff.obj .autodepend
    wlink name ff d all sys nt op m op maxe=25 op q op symf FIL ff.obj

ff.obj: ..\tools\ff.c
    wcc386 $(COPTS) ..\tools\ff.c
 
biossums.exe: biossums.obj .autodepend
    wlink name biossums d all sys nt op m op maxe=25 op q op symf FIL biossums.obj
 
biossums.obj: ..\tools\biossums.c
    wcc386 $(COPTS) ..\tools\biossums.c
 
vgasums.exe: vgasums.obj .autodepend 
    wlink name vgasums d all sys nt op m op maxe=25 op q op symf FIL vgasums.obj
 
vgasums.obj: ..\tools\vgasums.c
    wcc386 $(COPTS) ..\tools\vgasums.c
    
hexer.exe: hexer.obj .autodepend 
    wlink name hexer d all sys nt op m op maxe=25 op q op symf FIL hexer.obj
 
hexer.obj: ..\tools\hexer.c
    wcc386 $(COPTS) ..\tools\hexer.c
    
meow.exe: meow.obj .autodepend 
    wlink name meow d all sys nt op m op maxe=25 op q op symf FIL meow.obj
 
meow.obj: ..\tools\meow.c
    wcc386 $(COPTS) ..\tools\meow.c

mifer.exe: mifer.obj .autodepend 
    wlink name mifer d all sys nt op m op maxe=25 op q op symf FIL mifer.obj
 
mifer.obj: ..\tools\mifer.c
    wcc386 $(COPTS) ..\tools\mifer.c
 
# ---------------------------------------------------------------------------- 
# Compiler flags for ZET Code: 
#  -0   generate 8086 code 
#  -ms  forces small model 
#  -ot  Optimize for time of execution rather than size 
#  -zu  assume that SS != DS 
#  -ecc force use of __cedecl calls 
#  -wx  set to maximum warning level 
# ---------------------------------------------------------------------------- 
CFLAGS = -0 -wx -zu -s -ot -d0 -ecc -ms
AFLAGS = -0 -wx

# Link BIOS ------------------------------------------------------------------ 
# This section compiles and links the ROM BIOS module. The result of this 
# operation will be later fed through the biossums program in order to  
# compute the checksum and tag that on the end. 
# ---------------------------------------------------------------------------- 
zetbios.rom: zetbios.obj entry.obj biossums.exe
    wlink name $@ system dos &
        OPTION quiet &
        OPTION NOFARCALLS &
        OPTION FILLCHAR=0xFF &
        OPTION NOFARCALLS, MAP &
        OUTPUT raw offset=0xf0000 &
        ORDER &
        clname DATA segment _DATA    segaddr=0xf000 offset=0x0000 &
        clname CODE segment _TEXT    segaddr=0xf000 offset=0x1000 &
                    segment _BIOSSEG segaddr=0xf000 offset=0xe000 &
        FILE { zetbios.obj entry.obj } &
        LIBRARY clibs.lib &
        disable 1014
    biossums $@

# Make BIOS Object files ----------------------------------------------------- 
# This section tells make to compile only if the files have been changed  
# ---------------------------------------------------------------------------- 
zetbios.obj: .autodepend
  wcc $(CFLAGS) zetbios.c

entry.obj: .autodepend
  wasm $(AFLAGS) entry.asm

# Link VGA BIOS Object Files ------------------------------------------------- 
# This section compiles and links the VGA BIOS module. The result of this 
# operation will be later fed through the vgasums program in order to  
# compute the checksum and tag that on the end. 
# ---------------------------------------------------------------------------- 
vgabios.rom: vgabios.obj vga.obj vgasums.exe
    wlink name $@ system dos &
        OPTION quiet &
        OPTION FILLCHAR=0xFF &
        OPTION NOFARCALLS, map &
        OUTPUT raw offset=0xC0000 order &
        clname CODE &
                    segment _VGASEG segaddr=0xC000 offset=0x0000 &
                    segment _TEXT   segaddr=0xC000 offset=0x1000 &
        clname DATA segment _DATA   segaddr=0xC000 offset=0x4000 &
        FILE { vgabios.obj vga.obj } &
        LIBRARY clibs.lib &
        disable 1014
    vgasums $@
 
# Make VGA Object files ------------------------------------------------------ 
# This section tells make to compile only if the files have been changed  
# ---------------------------------------------------------------------------- 
vgabios.obj: .autodepend
    wcc $(CFLAGS) vgabios.c

vga.obj: .autodepend
    wasm $(AFLAGS) vga.asm

# ---------------------------------------------------------------------------- 
#  End of make. 
# ---------------------------------------------------------------------------- 
 
