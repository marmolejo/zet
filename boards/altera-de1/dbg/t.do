quit -sim
if {[file exists work]} {
  vdel -all -lib work
}

if ![file isdirectory verilog_libs] {
  file mkdir verilog_libs
  vlib verilog_libs/altera_mf_ver
  vlog -vlog01compat -work altera_mf_ver {/opt/altera9.0/quartus/eda/sim_lib/altera_mf.v}
}

vmap altera_mf_ver ./verilog_libs/altera_mf_ver

vlib work
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/vga/rtl/vdu.v ../../../cores/vga/rtl/ram_2k.v ../../../cores/vga/rtl/char_rom.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../../../cores/sram/rtl/csr_sram.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim ../dbg/mem_dump.v ../dbg/mem_dump_test.v ../dbg/mem_dump_top.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim  ../rtl/pll.v
vlog -work work -lint +incdir+../../../cores/zet/rtl +incdir+../../../cores/zet/sim  ../../../cores/sram/sim/IS61LV25616.v 
vsim -L altera_mf_ver -novopt -t ps work.mem_dump_test

add wave -radix hexadecimal -r /mem_dump_test/mem_dump_top0/mem_dump0/*
add wave -divider vga
add wave -radix hexadecimal -r /mem_dump_test/mem_dump_top0/vdu0/*
add wave -divider char_buff
add wave -radix hexadecimal -r /mem_dump_test/mem_dump_top0/vdu0/char_buff_ram/*


run 200us