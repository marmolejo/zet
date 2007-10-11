vlog -work work cpu_gate.v
vlog -work work idt71v416s10.v
vsim -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/altera_mf_ver -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/stratixii_ver -l msim_transcript -i -t ps work.cpu_gate
add wave sim:/cpu_gate/clk_
add wave sim:/cpu_gate/cpu0/clk
add wave sim:/cpu_gate/cpu0/boot
add wave -radix hexadecimal sim:/cpu_gate/cpu0/fetch0/pc
add wave -radix hexadecimal sim:/cpu_gate/cpu0/fetch0/state
add wave -radix hexadecimal sim:/cpu_gate/cpu0/fetch0/opcode
add wave -radix hexadecimal sim:/cpu_gate/cpu0/rd_data
add wave sim:/cpu_gate/cpu0/fetch0/need_modrm
add wave sim:/cpu_gate/cpu0/fetch0/need_off
add wave sim:/cpu_gate/cpu0/fetch0/need_imm
add wave sim:/cpu_gate/cpu0/fetch0/ir
add wave -radix hexadecimal sim:/cpu_gate/cpu0/fetch0/imm
add wave -radix hexadecimal sim:/cpu_gate/cpu0/fetch0/off
add wave -radix hexadecimal sim:/cpu_gate/addr_
add wave -radix hexadecimal sim:/cpu_gate/data0_
add wave -radix hexadecimal sim:/cpu_gate/data1_
add wave -radix hexadecimal sim:/cpu_gate/cpu0/mem0/state
add wave sim:/cpu_gate/cpu0/mem0/reset
add wave sim:/cpu_gate/rble0_
add wave sim:/cpu_gate/rbhe0_
add wave sim:/cpu_gate/rble1_
add wave sim:/cpu_gate/rbhe1_
add wave sim:/cpu_gate/roe_
add wave sim:/cpu_gate/rwe_
add wave -radix hexadecimal sim:/cpu_gate/cpu0/exec0/reg0/r\[15\]
add wave -radix hexadecimal sim:/cpu_gate/cpu0/exec0/reg0/d
add wave sim:/cpu_gate/cpu0/exec0/reg0/addr_a
add wave sim:/cpu_gate/cpu0/exec0/reg0/addr_d
add wave sim:/cpu_gate/cpu0/exec0/reg0/wr

run 35us