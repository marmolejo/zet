quit -sim

if {[file exists work]} {
  vdel -all -lib work
}

vlib work
vlog -work work -lint tb_hpdmc.v
vlog -work work -lint mt48lc16m16a2.v
vlog -work work -lint ../rtl/*

vsim -novopt -t ps work.tb_hpdmc

add wave -divider test
add wave -hex fml_*
add wave -hex {0 {m/Bank0[0]}}
add wave -hex {1 {m/Bank0[1]}}
add wave -hex {2 {m/Bank0[2]}}
add wave -hex {3 {m/Bank0[3]}}
add wave -hex {4 {m/Bank0[4]}}
add wave -hex {5 {m/Bank0[5]}}
add wave -hex {6 {m/Bank0[6]}}
add wave -hex {7 {m/Bank0[7]}}
add wave -hex {8 {m/Bank0[8]}}

add wave -divider hpdmc
add wave -hex dut/*

add wave -divider hpdmc_mgmt
add wave -hex dut/mgmt/*

add wave -divider hpdmc_datactl
add wave -hex dut/datactl/*

add wave -divider SDR
add wave -hex m/Clk
add wave -hex m/Sys_clk
add wave -hex m/Row
add wave -hex m/Col
add wave -hex m/Command\[0\]
add wave -hex m/Data_in_enable
run 250us