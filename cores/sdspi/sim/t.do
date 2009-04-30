quit -sim
if {[file exists work]} {
  vdel -all -lib work
}

vlib work
vlog -work work -lint ../rtl/sdspi.v test_sdpi.v

vsim -novopt -t ns work.test_sdspi
add wave -radix hexadecimal -r /*
run 100us