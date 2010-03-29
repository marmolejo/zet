quit -sim

echo "Compiling verilog modules..."
make

vsim -t ns zet.test_zet

add wave -label clk        -hex clk
add wave -label rst        -hex rst

add wave -label pc         -hex zet/pc
add wave -label st         -hex zet/core/fetch/st
add wave -label ns         -hex zet/core/fetch/ns
add wave -label opcode     -hex zet/core/opcode
add wave -label modrm      -hex zet/core/modrm
add wave -label seq_addr   -hex zet/core/seq_addr
add wave -label end_seq    -hex zet/core/end_seq
add wave -label need_modrm -hex zet/core/need_modrm
add wave -label need_off   -hex zet/core/need_off
add wave -label off_size   -hex zet/core/off_size
add wave -label need_imm   -hex zet/core/need_imm
add wave -label imm_size   -hex zet/core/imm_size
add wave -label ir         -hex zet/core/ir
add wave -label imm        -hex zet/core/imm
add wave -label off        -hex zet/core/off

add wave -divider regfile
add wave -label ax  -hex zet/core/exec/regfile/r\[0\]
add wave -label bx  -hex zet/core/exec/regfile/r\[3\]
add wave -label cx  -hex zet/core/exec/regfile/r\[1\]
add wave -label dx  -hex zet/core/exec/regfile/r\[2\]
add wave -label si  -hex zet/core/exec/regfile/r\[6\]
add wave -label di  -hex zet/core/exec/regfile/r\[7\]
add wave -label sp  -hex zet/core/exec/regfile/r\[4\]
add wave -label cs  -hex zet/core/exec/regfile/r\[9\]
add wave -label ss  -hex zet/core/exec/regfile/r\[10\]
add wave -label ds  -hex zet/core/exec/regfile/r\[11\]
add wave -label ip  -hex zet/core/exec/regfile/r\[15\]
add wave -label tmp -hex zet/core/exec/regfile/r\[13\]
add wave -label d   -hex zet/core/exec/regfile/d\[15:0\]
add wave -label wr  -hex zet/core/exec/regfile/wr

add wave -divider wb_master
add wave -hex zet/wb_master/*

add wave -divider f-e
add wave -label ir  -hex zet/core/ir
add wave -label imm -hex zet/core/imm
add wave -label off -hex zet/core/off

#add wave -label cpu_block -hex zet/cpu_block
#add wave -label stb       -hex stb
#add wave -label ack       -hex ack
#add wave -label adr       -hex adr
#add wave -label sel       -hex sel
#add wave -label dat_o     -hex dat_o
#add wave -label dat_i     -hex dat_i
#add wave -label we        -hex we
#add wave -label tga       -hex tga

#add wave -divider alu
#add wave -label x       -hex zet/core/exec/a
#add wave -label y       -hex zet/core/exec/bus_b
#add wave -label t       -hex zet/core/exec/alu/t
#add wave -label func    -hex zet/core/exec/alu/func
#add wave -label d       -hex zet/core/exec/regfile/d
#add wave -label addr_a  -hex zet/core/exec/regfile/addr_a
#add wave -label addr_d  -hex zet/core/exec/regfile/addr_d
#add wave -label wr      -hex zet/core/exec/regfile/wr
#add wave -label exec_st -hex zet/core/exec_st

add wave -divider decode
add wave -hex zet/core/decode/*

#add wave -divider fetch
#add wave -hex zet/core/fetch/*

#add wave -divider core
#add wave -hex zet/core/*

#add wave -divider micro_data
#add wave -hex zet/core/micro_data/*

run 10us
