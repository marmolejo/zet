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
zetbios.bin: zetbios.obj
	echo $@ 
	wlink name $@ &
		SYSTEM DOS &
		OPTION quiet &
        OPTION NOFARCALLS &
        OPTION FILLCHAR=0xFF &
        OPTION NOFARCALLS , MAP  &
        OUTPUT raw offset=0xf0000  &
        ORDER &
#        clname DATA segment _DATA    segaddr=0xe000 offset=0x0000 &
#        clname CODE segment _TEXT    segaddr=0xe000 offset=0x1000 &
          clname CODE segment _BIOSSEG segaddr=0xf000 offset=0x0000 &
        FILE { zetbios.obj } &
        LIBRARY clibs.lib &
        disable 1014 &
		disable 2120 &
		disable 2021


#
# This section tells make to compile only if the files have been changed
#
zetbios.obj: .autodepend
	wasm $(AFLAGS) zetbios.asm