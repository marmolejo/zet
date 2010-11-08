#
#  Makefile common options between Linux and Windows
#  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
#  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
#
#  This file is part of the Zet processor. This program is free software;
#  you can redistribute it and/or modify it under the terms of the GNU
#  General Public License as published by the Free Software Foundation;
#  either version 3, or (at your option) any later version.
#
#  Zet is distrubuted in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
#  License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Zet; see the file COPYING. If not, see
#  <http://www.gnu.org/licenses/>.
#

#
# This is a little utility that makes a 32k padding binary file so that it
# comes out to exactly 128K for the flash rom.
#
ff.rom: ff$(E)
	$(CDIR)ff 8192 >$@

#
# Compiler flags for ZET Code:
#  -0   generate 8086 code
#  -wx  set to maximum warning level
#  -w3  set to warning level 3
#  -zu  assume that SS != DS
#  -s   remove runtime stack checks
#  -ecc force use of __cedecl calls
#  -ms  forces small model
#  -d0  no debugging information
#  -d3  full symbolic debugging with unreferenced type names
#  -od  disable all optimizations
#  -ot  Optimize for time of execution rather than size
#  -q   operate quietly
#
CF_DBG = -0 -wx -zu -s -ecc -ms -d3 -od -q
CF_REL = -0 -wx -zu -s -ecc -ms -d0 -ot -q
CFLAGS = $(CF_REL)

AF_DBG = -0 -d1 -w3 -q
AF_REL = -0 -w3 -q
AFLAGS = $(AF_REL)


#
# This section compiles and links the ROM BIOS module. The result of this
# operation will be later fed through the biossums program in order to
# compute the checksum and tag that on the end.
#
zetbios.rom: zetbios_vers$(O) entry$(O) biossums$(E)
	wlink name $@ system dos &
        OPTION quiet &
        OPTION NOFARCALLS &
        OPTION FILLCHAR=0xFF &
        OPTION NOFARCALLS , MAP  &
        OUTPUT raw offset=0xf0000  &
        ORDER &
        clname DATA segment _DATA    segaddr=0xf000 offset=0x0000 &
        clname CODE segment _TEXT    segaddr=0xf000 offset=0x1000 &
                    segment _BIOSSEG segaddr=0xf000 offset=0xe000 &
        FILE { zetbios_vers$(O) entry$(O) } &
        LIBRARY clibs.lib &
        disable 1014
	$(CDIR)biossums $@


#
# This section tells make to compile only if the files have been changed
#
zetbios_vers$(O): zetbios_vers.c .autodepend
	wcc $(CFLAGS) zetbios_vers.c

entry$(O): .autodepend
	wasm $(AFLAGS) entry.asm

#
# This section compiles and links the VGA BIOS module. The result of this
# operation will be later fed through the vgasums program in order to
# compute the checksum and tag that on the end.
#
vgabios.rom: vgabios$(O) vga_vers$(O) vgasums$(E)
	wlink name $@ system dos &
        OPTION quiet &
        OPTION FILLCHAR=0xFF &
        OPTION NOFARCALLS , map &
        output raw offset=0xC0000 order &
        clname CODE &
	               segment _VGASEG segaddr=0xC000 offset=0x0000 &
	               segment _TEXT   segaddr=0xC000 offset=0x1000 &
        clname DATA  segment _DATA   segaddr=0xC000 offset=0x4000 &
        file { vgabios$(O) vga_vers$(O) } &
        library clibs.lib &
        disable 1014
	$(CDIR)vgasums $@

#
# This section tells make to compile only if the files have been changed
#
vgabios$(O): .autodepend
	wcc $(CFLAGS) vgabios.c

vga_vers$(O): vga_vers.asm
	wasm $(AFLAGS) vga_vers.asm
