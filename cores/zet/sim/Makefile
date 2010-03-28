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
DEFS   = +define+SIMULATION
VFLAGS = -work $(LIB) -lint -nologo -quiet -timescale 10ns/1ns

ZET_MODS    = zet_addsub \
              zet_alu \
              zet_bitlog \
              zet_arlog \
              zet_conv \
              zet_decode \
              zet_div_su \
              zet_div_uu \
              zet_exec \
              zet_fetch \
              zet_fulladd16 \
              zet_jmp_cond \
              zet_memory_regs \
              zet_micro_data \
              zet_micro_rom \
              zet_muldiv \
              zet_mux8_1 \
              zet_mux8_16 \
              zet_next_or_not \
              zet_nstate \
              zet_opcode_deco \
              zet_othop \
              zet_regfile \
              zet_rxr8 \
              zet_rxr16 \
              zet_shrot \
              zet \
              zet_wb_master \
              zet_signmul17 \
              zet_core
SIM_MODS    = test_zet \
              memory

SYS_MODS    = $(ZET_MODS) \
              $(SIM_MODS)

SYS_LIBS    = $(addprefix $(LIB)/, $(SYS_MODS) )

vpath %.v ../rtl
vpath %.v ../rtl/altera

all: $(LIB) $(SYS_LIBS)

$(LIB)/%: %.v
	vlog $(VFLAGS) $(DEFS) $(INC) $<

$(LIB):
	vlib $(LIB)

clean:
	vdel -all -lib $(LIB)
