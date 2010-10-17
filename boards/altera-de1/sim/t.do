quit -sim

echo "Compiling verilog modules..."
make

vsim -L altera_mf_ver -t ps zet.test_kotku

add wave -label clk -hex kotku/clk
add wave -label rst -hex kotku/rst

add wave -label pc  -hex kotku/pc
add wave -label st  -hex kotku/zet/core/fetch/state
add wave -label ns  -hex kotku/zet/core/fetch/next_state

add wave -label opcode     -hex kotku/zet/core/opcode
add wave -label modrm      -hex kotku/zet/core/modrm
add wave -label seq_addr   -hex kotku/zet/core/seq_addr
add wave -label end_seq    -hex kotku/zet/core/end_seq
add wave -label need_modrm -hex kotku/zet/core/need_modrm
add wave -label need_off   -hex kotku/zet/core/need_off
add wave -label off_size   -hex kotku/zet/core/off_size
add wave -label need_imm   -hex kotku/zet/core/need_imm
add wave -label imm_size   -hex kotku/zet/core/imm_size
add wave -label ir         -hex kotku/zet/core/ir
add wave -label imm        -hex kotku/zet/core/imm
add wave -label off        -hex kotku/zet/core/off

add wave -divider regfile
add wave -label ax  -hex kotku/zet/core/exec/regfile/r\[0\]
add wave -label bx  -hex kotku/zet/core/exec/regfile/r\[3\]
add wave -label cx  -hex kotku/zet/core/exec/regfile/r\[1\]
add wave -label dx  -hex kotku/zet/core/exec/regfile/r\[2\]
add wave -label si  -hex kotku/zet/core/exec/regfile/r\[6\]
add wave -label di  -hex kotku/zet/core/exec/regfile/r\[7\]
add wave -label sp  -hex kotku/zet/core/exec/regfile/r\[4\]
add wave -label cs  -hex kotku/zet/core/exec/regfile/r\[9\]
add wave -label ip  -hex kotku/zet/core/exec/regfile/r\[15\]
add wave -label tmp -hex kotku/zet/core/exec/regfile/r\[13\]
add wave -label d   -hex kotku/zet/core/exec/regfile/d\[15:0\]
add wave -label wr  -hex kotku/zet/core/exec/regfile/wr

add wave -divider wb_master
add wave -label cpu_block -hex kotku/zet/cpu_block
add wave -label stb       -hex kotku/stb
add wave -label ack       -hex kotku/ack
add wave -label adr       -hex kotku/adr
add wave -label sel       -hex kotku/sel
add wave -label dat_o     -hex kotku/dat_o
add wave -label dat_i     -hex kotku/dat_i
add wave -label we        -hex kotku/we
add wave -label tga       -hex kotku/tga
add wave -label cs        -hex kotku/zet/wb_master/cs
add wave -label ns        -hex kotku/zet/wb_master/ns

add wave -divider flash
add wave -label addr  -hex /flash_addr
add wave -label data  -hex /flash_data
add wave -label we_n  -hex /flash_we_n
add wave -label oe_n  -hex /flash_oe_n
add wave -label rst_n -hex /flash_rst_n

add wave -divider alu
add wave -label x       -hex kotku/zet/core/exec/a
add wave -label y       -hex kotku/zet/core/exec/bus_b
add wave -label t       -hex kotku/zet/core/exec/alu/t
add wave -label func    -hex kotku/zet/core/exec/alu/func
add wave -label d       -hex kotku/zet/core/exec/regfile/d
add wave -label addr_a  -hex kotku/zet/core/exec/regfile/addr_a
add wave -label addr_d  -hex kotku/zet/core/exec/regfile/addr_d
add wave -label wr      -hex kotku/zet/core/exec/regfile/wr
add wave -label exec_st -hex kotku/zet/core/exec_st

add wave -divider GPIO
add wave -label ledg_   -hex kotku/ledg_
add wave -label ledr_   -hex kotku/ledr_

run 3us
