quit -sim
if {[file exists work]} {
  vdel -all -lib work
}

vlib work
vlog -work work -lint +define+SIMULATION +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../rtl/kotku.v ../rtl/flash.v ../rtl/pll.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/zet/rtl/regfile.v ../../../cores/zet/rtl/alu.v ../../../cores/zet/rtl/cpu.v ../../../cores/zet/rtl/exec.v ../../../cores/zet/rtl/fetch.v ../../../cores/zet/rtl/jmp_cond.v ../../../cores/zet/rtl/util/primitives.v ../../../cores/zet/rtl/util/div_su.v ../../../cores/zet/rtl/util/div_uu.v ../../../cores/zet/rtl/rotate.v  ../../../cores/zet/rtl/util/signmul17.v
vlog -work work -lint ../../../cores/hpdmc_sdr16/rtl/*
vlog -work work -lint ../../../cores/fmlbrg/rtl/*
vlog -work work -lint ../../../cores/csrbrg/rtl/*
vlog -work work -lint ../../../cores/gpio/rtl/*
vlog -work work -lint ../../../cores/wb_abrg/*
vlog -work work -lint ../../../cores/wb_switch/*
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/sram/rtl/csr_sram.v
#vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/vga/rtl/vdu_sram.v ../../../cores/vga/rtl/char_rom.v ../rtl/domain_sync.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/vga/rtl/vga.v ../../../cores/vga/rtl/config_iface.v ../../../cores/vga/rtl/lcd.v ../../../cores/vga/rtl/text_mode.v ../../../cores/vga/rtl/char_rom.v ../../../cores/vga/rtl/c4_iface.v ../../../cores/vga/rtl/planar.v ../../../cores/vga/rtl/linear.v ../../../cores/vga/rtl/read_iface.v ../../../cores/vga/rtl/write_iface.v ../../../cores/vga/rtl/cpu_mem_iface.v ../../../cores/vga/rtl/mem_arbitrer.v ../../../cores/vga/rtl/dac_regs.v ../../../cores/vga/rtl/palette_regs.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/pic/rtl/simple_pic.v ../../../cores/timer/rtl/timer.v ../../../cores/keyb/rtl/ps2_keyb.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim test_kotku.v s29al032d_00.v ../../../cores/sram/sim/IS61LV25616.v ../../../cores/yadmc/sim/mt48lc16m16a2.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/gpio/rtl/hex_display.v ../../../cores/gpio/rtl/seg_7.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/sdspi/rtl/sdspi.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/ems/rtl/ems.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/uart ../../../cores/uart/uart_top.v ../../../cores/uart/uart_wb.v ../../../cores/uart/uart_regs.v ../../../cores/uart/uart_receiver.v ../../../cores/uart/uart_transmitter.v ../../../cores/uart/uart_tfifo.v ../../../cores/uart/uart_rfifo.v ../../../cores/uart/uart_sync_flops.v ../../../cores/uart/raminfr.v
#vcom -work work -lint ../../../cores/sb16/sb16.vhd ../rtl/audio_if.vhd
#vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../rtl/I2C_AV_Config.v ../rtl/I2C_Controller.v

vsim -L altera_mf_ver -novopt -t ps work.test_kotku

add wave -label clk kotku/zet_proc/wb_clk_i
add wave -label rst kotku/rst
add wave -label pc -hex kotku/zet_proc/fetch0/pc
add wave -label st -hex kotku/zet_proc/fetch0/state
add wave -label ns -hex kotku/zet_proc/fetch0/next_state
#add wave -divider ints
#add wave -label intv kotku/intv
#add wave -label intr kotku/intr
#add wave -label inta kotku/inta
#add wave -hex -r kotku/pic0/*
#add wave -divider fetch
add wave -label opcode -hex kotku/zet_proc/fetch0/opcode
add wave -label modrm -hex kotku/zet_proc/fetch0/modrm
add wave -label seq_addr kotku/zet_proc/fetch0/decode0/seq_addr
add wave -label end_seq kotku/zet_proc/fetch0/end_seq
add wave -label need_modrm kotku/zet_proc/fetch0/need_modrm
add wave -label need_off kotku/zet_proc/fetch0/need_off
add wave -label off_size kotku/zet_proc/fetch0/off_size
add wave -label need_imm kotku/zet_proc/fetch0/need_imm
add wave -label imm_size kotku/zet_proc/fetch0/imm_size
add wave -label ir kotku/zet_proc/fetch0/ir
add wave -label imm -hex kotku/zet_proc/fetch0/imm
add wave -label off -hex kotku/zet_proc/fetch0/off
add wave -divider regfile
add wave -label ax -hex kotku/zet_proc/exec0/reg0/r\[0\]
add wave -label bx -hex kotku/zet_proc/exec0/reg0/r\[3\]
add wave -label cx -hex kotku/zet_proc/exec0/reg0/r\[1\]
add wave -label dx -hex kotku/zet_proc/exec0/reg0/r\[2\]
add wave -label si -hex kotku/zet_proc/exec0/reg0/r\[6\]
add wave -label di -hex kotku/zet_proc/exec0/reg0/r\[7\]
add wave -label tmp -hex kotku/zet_proc/exec0/reg0/r\[13\]
add wave -label d -hex kotku/zet_proc/exec0/reg0/d\[15:0\]
add wave -label wr -hex kotku/zet_proc/exec0/reg0/wr

add wave -divider wb_master
add wave -label wb_block kotku/zet_proc/wb_block
add wave -label stb -hex kotku/zet_proc/wb_stb_o
add wave -label ack -hex kotku/zet_proc/wb_ack_i
add wave -label adr -hex kotku/adr
add wave -label sel -hex kotku/zet_proc/wb_sel_o
add wave -label dat_w -hex kotku/zet_proc/wb_dat_o
add wave -label dat_r -hex kotku/dat_i
add wave -label we -hex kotku/zet_proc/wb_we_o
add wave -label tga -hex kotku/zet_proc/wb_tga_o

#add wave -divider wb_fmlbrg
#add wave -hex kotku/wb_fmlbrg/*

#add wave -divider fmlbrg
#add wave -hex kotku/fmlbrg/*

#add wave -divider hpdmc
#add wave -hex kotku/hpdmc/*

#add wave -hex kotku/zet_proc/wm0/*
add wave -divider flash
add wave -hex /flash_addr
add wave -hex /flash_data
add wave -hex /flash_we_n
add wave -hex /flash_oe_n
add wave -hex /flash_rst_n
add wave -divider alu
add wave -label x -hex kotku/zet_proc/exec0/a
add wave -label y -hex kotku/zet_proc/exec0/bus_b
add wave -label t -hex kotku/zet_proc/exec0/alu0/t
add wave -label func -hex kotku/zet_proc/exec0/alu0/func
add wave -label d -hex kotku/zet_proc/exec0/reg0/d
add wave -label addr_a kotku/zet_proc/exec0/reg0/addr_a
add wave -label addr_d kotku/zet_proc/exec0/reg0/addr_d
add wave -label wr kotku/zet_proc/exec0/reg0/wr
add wave -label we kotku/we
add wave -label ack kotku/ack
add wave -label fetch_or_exec kotku/zet_proc/fetch_or_exec
#add wave -divider vga
#add wave -hex -r kotku/vga/*

#add wave -divider SDR
#add wave -hex sdram/*
#add wave -hex sdram/Cas_latency_2
#add wave -hex sdram/Cas_latency_3
#add wave -hex sdram/Sys_clk
#add wave -hex sdram/Bank0\[0\]
#add wave -hex sdram/Bank0\[1\]
#add wave -hex sdram/Bank0\[2\]
#add wave -hex sdram/Bank0\[3\]
#add wave -hex sdram/Bank0\[4\]
#add wave -hex sdram/Bank0\[5\]
#add wave -hex sdram/Bank0\[6\]
#add wave -hex sdram/Bank0\[7\]
#add wave -hex sdram/Bank0\[8\]
#add wave -hex sdram/Bank0\[9\]
#add wave -hex sdram/Bank0\[10\]
#add wave -hex sdram/Bank0\[11\]
#add wave -hex sdram/Bank0\[12\]
#add wave -hex sdram/Bank0\[13\]
#add wave -hex sdram/Bank0\[14\]
#add wave -hex sdram/Bank0\[15\]

run 5us
