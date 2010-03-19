quit -sim

echo "Compiling verilog modules..."
make

vsim -L altera_mf_ver -novopt -t ps zet.test_kotku

add wave -label clk kotku/clk
add wave -label rst kotku/rst
add wave -label pc -hex kotku/pc
add wave -label st -hex kotku/zet/core/fetch/state
add wave -label ns -hex kotku/zet/core/fetch/next_state
#add wave -divider ints
#add wave -label intv kotku/intv
#add wave -label intr kotku/intr
#add wave -label inta kotku/inta
#add wave -hex -r kotku/pic0/*
#add wave -divider fetch
add wave -label opcode -hex kotku/zet/core/fetch/opcode
add wave -label modrm -hex kotku/zet/core/fetch/modrm
add wave -label seq_addr kotku/zet/core/fetch/decode/seq_addr
add wave -label end_seq kotku/zet/core/fetch/end_seq
add wave -label need_modrm kotku/zet/core/fetch/need_modrm
add wave -label need_off kotku/zet/core/fetch/need_off
add wave -label off_size kotku/zet/core/fetch/off_size
add wave -label need_imm kotku/zet/core/fetch/need_imm
add wave -label imm_size kotku/zet/core/fetch/imm_size
add wave -label ir kotku/zet/core/ir
add wave -label imm -hex kotku/zet/core/imm
add wave -label off -hex kotku/zet/core/off
add wave -divider regfile
add wave -label ax -hex kotku/zet/core/exec/regfile/r\[0\]
add wave -label bx -hex kotku/zet/core/exec/regfile/r\[3\]
add wave -label cx -hex kotku/zet/core/exec/regfile/r\[1\]
add wave -label dx -hex kotku/zet/core/exec/regfile/r\[2\]
add wave -label si -hex kotku/zet/core/exec/regfile/r\[6\]
add wave -label di -hex kotku/zet/core/exec/regfile/r\[7\]
add wave -label tmp -hex kotku/zet/core/exec/regfile/r\[13\]
add wave -label d -hex kotku/zet/core/exec/regfile/d\[15:0\]
add wave -label wr -hex kotku/zet/core/exec/regfile/wr

add wave -divider wb_master
add wave -label cpu_block kotku/zet/cpu_block
add wave -label stb -hex kotku/zet/wb_stb_o
add wave -label ack -hex kotku/zet/wb_ack_i
add wave -label adr -hex kotku/adr
add wave -label sel -hex kotku/zet/wb_sel_o
add wave -label dat_w -hex kotku/zet/wb_dat_o
add wave -label dat_r -hex kotku/dat_i
add wave -label we -hex kotku/zet/wb_we_o
add wave -label tga -hex kotku/zet/wb_tga_o

#add wave -divider wb_fmlbrg
#add wave -hex kotku/wb_fmlbrg/*

#add wave -divider fmlbrg
#add wave -hex kotku/fmlbrg/*

#add wave -divider hpdmc
#add wave -hex kotku/hpdmc/*

#add wave -hex kotku/zet/wm0/*
add wave -divider flash
add wave -hex /flash_addr
add wave -hex /flash_data
add wave -hex /flash_we_n
add wave -hex /flash_oe_n
add wave -hex /flash_rst_n
add wave -divider alu
add wave -label x -hex kotku/zet/core/exec/a
add wave -label y -hex kotku/zet/core/exec/bus_b
add wave -label t -hex kotku/zet/core/exec/alu/t
add wave -label func -hex kotku/zet/core/exec/alu/func
add wave -label d -hex kotku/zet/core/exec/regfile/d
add wave -label addr_a kotku/zet/core/exec/regfile/addr_a
add wave -label addr_d kotku/zet/core/exec/regfile/addr_d
add wave -label wr kotku/zet/core/exec/regfile/wr
add wave -label we kotku/we
add wave -label ack kotku/ack
add wave -label fetch_or_exec kotku/zet/core/fetch_or_exec
#add wave -divider vga
#add wave -hex -r kotku/vga/*

#add wave -divider SDR
#add wave -hex sdram/*
#add wave -hex sdram/Cas_latency_2
#add wave -hex sdram/Cas_latency_3
#add wave -hex sdram/Sys_clk
#add wave -hex sdram/Bank0\[0\]
#add wave -hex sdram/Bank0\[1\]
#add wave -hex sdram/Bank0\[2\]
#add wave -hex sdram/Bank0\[3\]
#add wave -hex sdram/Bank0\[4\]
#add wave -hex sdram/Bank0\[5\]
#add wave -hex sdram/Bank0\[6\]
#add wave -hex sdram/Bank0\[7\]
#add wave -hex sdram/Bank0\[8\]
#add wave -hex sdram/Bank0\[9\]
#add wave -hex sdram/Bank0\[10\]
#add wave -hex sdram/Bank0\[11\]
#add wave -hex sdram/Bank0\[12\]
#add wave -hex sdram/Bank0\[13\]
#add wave -hex sdram/Bank0\[14\]
#add wave -hex sdram/Bank0\[15\]

run 5us
