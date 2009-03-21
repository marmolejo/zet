quit -sim
vdel -all -lib work
vlib work
vlog -work work -lint ../rtl/yadmc_dpram.v ../rtl/yadmc_sdram16.v ../rtl/yadmc_spram.v ../rtl/yadmc_sync.v ../rtl/yadmc.v mt48lc16m16a2.v yadmc_test.v
vsim -L /opt/Xilinx/10.1/modelsim/verilog/unisims -novopt -t ps work.yadmc_test
add wave -radix hexadecimal -r /*

