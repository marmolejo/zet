vdel -all -lib work
vmap unisims /opt/Xilinx/10.1/modelsim/verilog/unisims
vlib work
vlog -work work -lint +incdir+../../rtl-model ../../rtl-model/regfile.v ../../rtl-model/alu.v ../../rtl-model/cpu.v ../../rtl-model/exec.v ../../rtl-model/fetch.v ../../rtl-model/jmp_cond.v ../../rtl-model/util/primitives.v ../../rtl-model/rotate.v
vlog -work work +incdir+.. ../memory.v ../testbench.v ../mult.v
vlog -work unisims /opt/Xilinx/10.1/ISE/verilog/src/glbl.v
vsim -L /opt/Xilinx/10.1/modelsim/verilog/unisims -novopt -t ns work.testbench work.glbl
add wave -label clk /testbench/clk
add wave -label rst /testbench/rst
add wave -label pc -radix hexadecimal /testbench/cpu0/fetch0/pc
add wave -divider fetch
add wave -label state -radix hexadecimal /testbench/cpu0/fetch0/state
add wave -label next_state -radix hexadecimal /testbench/cpu0/fetch0/next_state
add wave -label opcode -radix hexadecimal /testbench/cpu0/fetch0/opcode
add wave -label modrm -radix hexadecimal /testbench/cpu0/fetch0/modrm
add wave -label seq_addr /testbench/cpu0/fetch0/decode0/seq_addr
add wave -label end_seq /testbench/cpu0/fetch0/end_seq
add wave -label need_modrm /testbench/cpu0/fetch0/need_modrm
add wave -label need_off /testbench/cpu0/fetch0/need_off
add wave -label need_imm /testbench/cpu0/fetch0/need_imm
add wave -label ir /testbench/cpu0/fetch0/ir
add wave -label imm -radix hexadecimal /testbench/cpu0/fetch0/imm
add wave -label off -radix hexadecimal /testbench/cpu0/fetch0/off
add wave -divider alu
add wave -label x -radix hexadecimal /testbench/cpu0/exec0/a
add wave -label y -radix hexadecimal /testbench/cpu0/exec0/bus_b
add wave -label t -radix hexadecimal /testbench/cpu0/exec0/alu0/t
add wave -label func -radix hexadecimal /testbench/cpu0/exec0/alu0/func
add wave -label rd_data -radix hexadecimal sim:/testbench/rd_data
add wave -label wr_data -radix hexadecimal sim:/testbench/wr_data
add wave -label addr -radix hexadecimal /testbench/addr
add wave -label r\[15\] -radix hexadecimal /testbench/cpu0/exec0/reg0/r\[15\]
add wave -label d -radix hexadecimal /testbench/cpu0/exec0/reg0/d
add wave -label addr_a /testbench/cpu0/exec0/reg0/addr_a
add wave -label addr_d /testbench/cpu0/exec0/reg0/addr_d
add wave -label wr /testbench/cpu0/exec0/reg0/wr
add wave -label we /testbench/we
add wave -label ack_i /testbench/ack_i
add wave -label fetch_or_exec /testbench/cpu0/fetch_or_exec
#run 50us
