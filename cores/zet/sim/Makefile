#
#  zet core Makefile for Modelsim simulation
#  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
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
#

LIB    = zet
INC    = +incdir+../rtl
VFLAGS = -work $(LIB) -lint

ZET_MODS    = cpu \
              alu \
              fetch \
              exec \
              jmp_cond \
              regfile \
              rotate \
              div_su \
              div_uu \
              primitives \
              signmul17
SIM_MODS    = test_zet \
              memory

SYS_MODS    = $(ZET_MODS) \
              $(SIM_MODS)

SYS_LIBS    = $(addprefix $(LIB)/, $(SYS_MODS) )

vpath %.v ../rtl
vpath %.v ../rtl/util

all: $(LIB) $(SYS_LIBS)

$(LIB)/%: %.v
	vlog $(VFLAGS) $(INC) $<

$(LIB):
	vlib $(LIB)

clean:
	vdel -all -lib $(LIB)
