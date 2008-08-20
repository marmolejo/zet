vdel -all -lib work
vlib work

# Hardware part

vlog -lint -work work zet_soc_synthesis.v

# Simulation

vcom -lint -work work ../../../sim/flash-prom/generic_data.vhd ../../../sim/flash-prom/test_stub.vhd ../../../sim/flash-prom/utility_pack.vhd  ../../../sim/flash-prom/m29dw323d.vhd
vlog -lint -work work +incdir+../../../rtl ../../../sim/board.v


vmap unisims /home/zeus/opt/xilinx92i/modelsim/verilog/unisims
vsim -novopt -L /home/zeus/opt/xilinx92i/modelsim/verilog/unisims -t ps work.board work.glbl
onerror {resume}
add wave -divider Clocks
add wave -radix hexadecimal /board/sys_clk
add wave -radix hexadecimal /board/rst
add wave -radix hexadecimal /board/fpga0/clk50M
add wave -radix hexadecimal /board/fpga0/clk25M
add wave -radix hexadecimal /board/fpga0/cpu_clk
add wave -radix hexadecimal /board/fpga0/reset
add wave -divider Memory
# add wave -radix hexadecimal /board/rst
add wave -radix hexadecimal /fpga0/addr
add wave -radix hexadecimal /fpga0/wr_data
add wave -radix hexadecimal /fpga0/we
add wave -radix hexadecimal /fpga0/byte_m
add wave -radix hexadecimal /fpga0/rd_data
add wave -radix hexadecimal /fpga0/ready
add wave -divider CPU
# add wave -radix hexadecimal /fpga0/cpu0/cs
# add wave -radix hexadecimal /fpga0/cpu0/ip
add wave -radix hexadecimal /fpga0/cpu0/fetch0/decode0/seq_rom0/addr
add wave -radix hexadecimal /fpga0/cpu0/addr_exec
add wave -radix hexadecimal /fpga0/cpu0/fetch_or_exec
add wave -radix hexadecimal /fpga0/cpu0/addr_exec
add wave -radix hexadecimal /fpga0/cpu0/addr_fetch
add wave -radix hexadecimal /fpga0/cpu0/fetch0/state
add wave -radix hexadecimal /fpga0/cpu0/fetch0/next_state
add wave -radix hexadecimal /fpga0/cpu0/fetch0/block
# add wave -radix hexadecimal /fpga0/cpu0/fetch0/opcode
add wave -divider Flash
add wave -radix hexadecimal /board/NF_WE
add wave -radix hexadecimal /board/NF_CE
add wave -radix hexadecimal /board/NF_OE
add wave -radix hexadecimal /board/NF_BYTE
add wave -radix hexadecimal /board/NF_RP
add wave -radix hexadecimal /board/NF_A
add wave -radix hexadecimal /board/NF_D
add wave -divider Memory
add wave -radix hexadecimal -r /fpga0/mem_ctrlr_0/*
# add wave -divider VDU
# add wave -radix hexadecimal /fpga0/vdu0/*
# add wave -divider ddr2
# add wave -radix hexadecimal /fpga0/mem_ctrlr_0/sdram0/*
# add wave -divider Flash
# add wave -radix hexadecimal /fpga0/mem_ctrlr_0/flash0/*
