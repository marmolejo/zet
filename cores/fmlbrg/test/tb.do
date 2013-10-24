quit -sim

if {[file exists work]} {
  vdel -all -lib work
}

vlib work
vlog -work work -lint tb_fmlbrg.v
vlog -work work -lint ../rtl/*

vsim -novopt -t ps work.tb_fmlbrg

add wave -divider test
add wave -hex *

add wave -divider fmlbrg
add wave -hex dut/*

add wave -divider fmlbrg_datamem
add wave -hex dut/datamem/*

add wave -divider ram1
add wave -hex dut/datamem/ram1
add wave -divider ram0
add wave -hex dut/datamem/ram0

run 4us
