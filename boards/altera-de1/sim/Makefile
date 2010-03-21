#
#  Makefile for Modelsim simulation
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
INC    = +incdir+../../../cores/zet/rtl \
         +incdir+../../../cores/uart \
         +incdir+../../../cores/zet/sim
DEFS   = +define+SIMULATION
VFLAGS = -work $(LIB) -lint

BOARD_MODS  = kotku \
              pll \
              flash
ZET_MODS    = zet_addsub \
              zet_alu \
              zet_bitlog \
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
HPDMC_MODS  = hpdmc_banktimer \
              hpdmc_busif \
              hpdmc_ctlif \
              hpdmc_datactl \
              hpdmc_mgmt \
              hpdmc_sdrio \
              hpdmc
FMLBRG_MODS = fmlbrg_datamem \
              fmlbrg
CSRBRG_MODS = csrbrg
GPIO_MODS   = hex_display \
              seg_7 \
              sw_leds
WBABRG_MODS = wb_abrgr \
              wb_abrg
WBSW_MODS   = wb_switch
SRAM_MODS   = csr_sram
VGA_MODS    = vga \
              config_iface \
              lcd \
              text_mode \
              char_rom \
              c4_iface \
              planar \
              linear \
              read_iface \
              write_iface \
              cpu_mem_iface \
              mem_arbitrer \
              dac_regs \
              palette_regs
PIC_MODS    = simple_pic
TIMER_MODS  = timer
PS2_MODS    = ps2keyb \
              ps2keyb_xtcodes
SIM_MODS    = s29al032d_00 \
              mt48lc16m16a2 \
              is61lv25616 \
              test_kotku
SDSPI_MODS  = sdspi
UART_MODS   = uart_top \
              uart_wb \
              uart_regs \
              uart_receiver \
              uart_transmitter \
              uart_tfifo \
              uart_rfifo \
              uart_sync_flops \
              raminfr

SYS_MODS    = $(BOARD_MODS) \
              $(ZET_MODS) \
              $(HPDMC_MODS) \
              $(FMLBRG_MODS) \
              $(CSRBRG_MODS) \
              $(GPIO_MODS) \
              $(WBABRG_MODS) \
              $(WBSW_MODS) \
              $(SRAM_MODS) \
              $(VGA_MODS) \
              $(PIC_MODS) \
              $(TIMER_MODS) \
              $(PS2_MODS) \
              $(SIM_MODS) \
              $(SDSPI_MODS) \
              $(UART_MODS)

SYS_LIBS    = $(addprefix $(LIB)/, $(SYS_MODS) )


vpath %.v ../rtl
vpath %.v ../../../cores/zet/rtl
vpath %.v ../../../cores/zet/rtl/altera
vpath %.v ../../../cores/hpdmc_sdr16/rtl
vpath %.v ../../../cores/fmlbrg/rtl
vpath %.v ../../../cores/csrbrg/rtl
vpath %.v ../../../cores/gpio/rtl
vpath %.v ../../../cores/wb_abrg
vpath %.v ../../../cores/wb_switch
vpath %.v ../../../cores/sram/rtl
vpath %.v ../../../cores/vga/rtl
vpath %.v ../../../cores/pic/rtl
vpath %.v ../../../cores/timer/rtl
vpath %.v ../../../cores/keyb/rtl
vpath %.v ../../../cores/sram/sim
vpath %.v ../../../cores/yadmc/sim
vpath %.v ../../../cores/sdspi/rtl
vpath %.v ../../../cores/uart/

all: $(LIB) $(SYS_LIBS)

$(LIB)/%: %.v
	vlog $(VFLAGS) $(DEFS) $(INC) $<

$(LIB):
	vlib $(LIB)

clean:
	vdel -all -lib $(LIB)
