quit -sim

echo "Compiling verilog modules..."

if {[file exists zet]} {
  vdel -all -lib zet
}

make

vsim -t ns zet.test_zet

add wave -label clk        -hex clk
add wave -label rst        -hex rst

add wave -label pc         -hex cpu/fetch0/pc
add wave -label st         -hex cpu/fetch0/state
add wave -label ns         -hex cpu/fetch0/next_state
add wave -label opcode     -hex cpu/fetch0/opcode
add wave -label modrm      -hex cpu/fetch0/modrm
add wave -label seq_addr   -hex cpu/fetch0/decode0/seq_addr
add wave -label end_seq    -hex cpu/fetch0/end_seq
add wave -label need_modrm -hex cpu/fetch0/need_modrm
add wave -label need_off   -hex cpu/fetch0/need_off
add wave -label off_size   -hex cpu/fetch0/off_size
add wave -label need_imm   -hex cpu/fetch0/need_imm
add wave -label imm_size   -hex cpu/fetch0/imm_size
add wave -label ir         -hex cpu/fetch0/ir
add wave -label imm        -hex cpu/fetch0/imm
add wave -label off        -hex cpu/fetch0/off

add wave -divider regfile
add wave -label ax  -hex cpu/exec0/reg0/r\[0\]
add wave -label bx  -hex cpu/exec0/reg0/r\[3\]
add wave -label cx  -hex cpu/exec0/reg0/r\[1\]
add wave -label dx  -hex cpu/exec0/reg0/r\[2\]
add wave -label si  -hex cpu/exec0/reg0/r\[6\]
add wave -label di  -hex cpu/exec0/reg0/r\[7\]
add wave -label sp  -hex cpu/exec0/reg0/r\[4\]
add wave -label cs  -hex cpu/exec0/reg0/r\[9\]
add wave -label ip  -hex cpu/exec0/reg0/r\[15\]
add wave -label tmp -hex cpu/exec0/reg0/r\[13\]
add wave -label d   -hex cpu/exec0/reg0/d\[15:0\]
add wave -label wr  -hex cpu/exec0/reg0/wr

add wave -divider wb_master
add wave -label cpu_block -hex cpu/cpu_block
add wave -label stb      -hex stb
add wave -label ack       -hex ack
add wave -label adr       -hex adr
add wave -label sel       -hex sel
add wave -label dat_o     -hex dat_o
add wave -label dat_i     -hex dat_i
add wave -label we        -hex we
add wave -label tga       -hex tga

add wave -divider alu
add wave -label x       -hex cpu/exec0/a
add wave -label y       -hex cpu/exec0/bus_b
add wave -label t       -hex cpu/exec0/alu0/t
add wave -label func    -hex cpu/exec0/alu0/func
add wave -label d       -hex cpu/exec0/reg0/d
add wave -label addr_a  -hex cpu/exec0/reg0/addr_a
add wave -label addr_d  -hex cpu/exec0/reg0/addr_d
add wave -label wr      -hex cpu/exec0/reg0/wr
add wave -label exec_st -hex cpu/fetch_or_exec


run 2us
