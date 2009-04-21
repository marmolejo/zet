quit -sim
if {[file exists work]} {
  vdel -all -lib work
}

if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {/opt/altera9.0/quartus/eda/sim_lib/altera_mf.v}

vlib work
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../rtl/kotku.v ../rtl/flash.v ../rtl/pll.v ../rtl/sys_pll.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/zet/rtl/regfile.v ../../../cores/zet/rtl/alu.v ../../../cores/zet/rtl/cpu.v ../../../cores/zet/rtl/exec.v ../../../cores/zet/rtl/fetch.v ../../../cores/zet/rtl/jmp_cond.v ../../../cores/zet/rtl/util/primitives.v ../../../cores/zet/rtl/util/div_su.v ../../../cores/zet/rtl/util/div_uu.v ../../../cores/zet/rtl/rotate.v  ../../../cores/zet/rtl/util/signmul17.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/yadmc/rtl/yadmc.v ../../../cores/yadmc/rtl/yadmc_sync.v ../../../cores/yadmc/rtl/yadmc_spram.v ../../../cores/yadmc/rtl/yadmc_sdram16.v ../../../cores/yadmc/rtl/yadmc_dpram.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/sram/rtl/csr_sram.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/vga/rtl/vdu_sram.v ../../../cores/vga/rtl/char_rom.v ../rtl/domain_sync.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/pic/rtl/simple_pic.v ../../../cores/timer/rtl/timer.v ../../../cores/keyb/rtl/ps2_keyb.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim test_kotku.v s29al032d_00.v ../../../cores/sram/sim/IS61LV25616.v ../../../cores/yadmc/sim/mt48lc16m16a2.v

vsim -L altera_mf_ver -novopt -t ps work.test_kotku

add wave -label io_reg -radix hexadecimal /test_kotku/kotku/io_reg
add wave -label clk /test_kotku/kotku/zet_proc/wb_clk_i
add wave -label rst /test_kotku/kotku/rst
add wave -label pc -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/pc
add wave -divider fetch
add wave -label state -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/state
add wave -label next_state -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/next_state
add wave -label opcode -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/opcode
add wave -label modrm -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/modrm
add wave -label seq_addr /test_kotku/kotku/zet_proc/fetch0/decode0/seq_addr
add wave -label end_seq /test_kotku/kotku/zet_proc/fetch0/end_seq
add wave -label need_modrm /test_kotku/kotku/zet_proc/fetch0/need_modrm
add wave -label need_off /test_kotku/kotku/zet_proc/fetch0/need_off
add wave -label off_size /test_kotku/kotku/zet_proc/fetch0/off_size
add wave -label need_imm /test_kotku/kotku/zet_proc/fetch0/need_imm
add wave -label imm_size /test_kotku/kotku/zet_proc/fetch0/imm_size
add wave -label ir /test_kotku/kotku/zet_proc/fetch0/ir
add wave -label imm -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/imm
add wave -label off -radix hexadecimal /test_kotku/kotku/zet_proc/fetch0/off
add wave -divider regfile
add wave -label ax -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[0\]
add wave -label cx -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[1\]
add wave -label dx -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[2\]
add wave -label si -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[6\]
add wave -label di -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[7\]
add wave -label tmp -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/r\[13\]
add wave -label d -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/d\[15:0\]
add wave -label wr -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/wr
add wave -divider wb_master
add wave -label cs -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/cs
add wave -label ns -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/ns
add wave -label op -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/op
add wave -label wb_block /test_kotku/kotku/zet_proc/wb_block
add wave -label dat_o -radix hexadecimal sim:/test_kotku/kotku/dat_o
add wave -label dat_i -radix hexadecimal sim:/test_kotku/kotku/dat_i
add wave -label adr -radix hexadecimal /test_kotku/kotku/adr
add wave -label odd_word -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/odd_word
add wave -label byte_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/cpu_byte_o
add wave -label sel_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_sel_o
add wave -label stb_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_stb_o
add wave -label cyc_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_cyc_o
add wave -label ack_i -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_ack_i
add wave -label we_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_we_o
add wave -label tga_o -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/wb_tga_o
add wave -label cpu_dat_i -radix hexadecimal /test_kotku/kotku/zet_proc/wm0/cpu_dat_i
add wave -divider flash
add wave -radix hexadecimal /flash_addr
add wave -radix hexadecimal /flash_data
add wave -radix hexadecimal /flash_we_n
add wave -radix hexadecimal /flash_oe_n
add wave -radix hexadecimal /flash_rst_n
add wave -divider alu
add wave -label x -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/a
add wave -label y -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/bus_b
add wave -label t -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/alu0/t
add wave -label func -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/alu0/func
add wave -label d -radix hexadecimal /test_kotku/kotku/zet_proc/exec0/reg0/d
add wave -label addr_a /test_kotku/kotku/zet_proc/exec0/reg0/addr_a
add wave -label addr_d /test_kotku/kotku/zet_proc/exec0/reg0/addr_d
add wave -label wr /test_kotku/kotku/zet_proc/exec0/reg0/wr
add wave -label we /test_kotku/kotku/we
add wave -label ack /test_kotku/kotku/ack
add wave -label fetch_or_exec /test_kotku/kotku/zet_proc/fetch_or_exec
add wave -divider sram
add wave -radix hexadecimal -r /test_kotku/kotku/vdu/sram/*
add wave -divider vdu
add wave -radix hexadecimal -r /test_kotku/kotku/vdu/*
run 100us
