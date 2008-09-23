vdel -all -lib work
vlib work
vlog -work work -lint +incdir+../../rtl-model ../../rtl-model/regfile.v ../../rtl-model/alu.v ../../rtl-model/cpu.v ../../rtl-model/exec.v ../../rtl-model/fetch.v ../../rtl-model/jmp_cond.v ../../rtl-model/util/primitives.v
vlog -work work +incdir+.. ../memory.v ../testbench.v
vsim -novopt -t ns work.testbench
add wave /testbench/clk
add wave /testbench/rst
add wave -radix hexadecimal /testbench/cpu0/fetch0/pc
add wave -radix hexadecimal /testbench/cpu0/fetch0/state
add wave -radix hexadecimal /testbench/cpu0/fetch0/next_state
add wave -radix hexadecimal /testbench/cpu0/fetch0/opcode
add wave -radix hexadecimal /testbench/cpu0/fetch0/modrm
add wave /testbench/cpu0/fetch0/end_seq
add wave -radix hexadecimal sim:/testbench/rd_data
add wave -radix hexadecimal sim:/testbench/wr_data
add wave sim:/testbench/cpu0/fetch0/need_modrm
add wave sim:/testbench/cpu0/fetch0/need_off
add wave sim:/testbench/cpu0/fetch0/need_imm
add wave sim:/testbench/cpu0/fetch0/ir
add wave -radix hexadecimal sim:/testbench/cpu0/fetch0/imm
add wave -radix hexadecimal sim:/testbench/cpu0/fetch0/off
add wave -radix hexadecimal sim:/testbench/addr
add wave -radix hexadecimal sim:/testbench/cpu0/exec0/reg0/r\[15\]
add wave -radix hexadecimal sim:/testbench/cpu0/exec0/reg0/d
add wave sim:/testbench/cpu0/exec0/reg0/addr_a
add wave sim:/testbench/cpu0/exec0/reg0/addr_d
add wave sim:/testbench/cpu0/exec0/reg0/wr
add wave sim:/testbench/we
add wave sim:/testbench/ack_i
add wave sim:/testbench/cpu0/fetch_or_exec
