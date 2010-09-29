quit -sim
vdel -all -lib work
vlib work
vlog -work work -lint sim_addr.v send_addr.v clk_uart.v send_serial.v
vsim -novopt -t ns work.sim_addr
add wave -radix hexadecimal -r /*
run 500us
