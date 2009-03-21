quit -sim
vdel -all -lib work
vmap unisims /opt/Xilinx/10.1/modelsim/verilog/unisims
vlib work
vlog -work work -lint +incdir+../../../rtl-model ../../../impl/virtex4-ml403ep/sim/CY7C1354BV25.v ../rtl/vdu.v vdu_tb.v ../test/test_vdu.v ../test/tmp/clock.v ../rtl/char_rom.v ../rtl/ram2k_b16.v ../rtl/ram2k_b16_attr.v ../../../impl/virtex4-ml403ep/mem/zbt_cntrl.v
vlog -work work /opt/Xilinx/10.1/ISE/verilog/src/glbl.v
vsim -L /opt/Xilinx/10.1/modelsim/verilog/unisims -novopt -t ps work.vdu_tb work.glbl
add wave -divider tb
add wave -radix hexadecimal /vdu_tb/*
add wave -divider VDU
add wave -radix hexadecimal /vdu_tb/vdu0/vdu0/*
add wave -divider ZBT
add wave -radix hexadecimal /vdu_tb/vdu0/zbt0/*
run 1ms
