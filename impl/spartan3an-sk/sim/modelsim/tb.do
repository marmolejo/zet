# vdel -all -lib work
vlib work

# Hardware part

vlog -lint -work work +incdir+../../rtl/ ../../rtl/ddr2cntrl/ddr2sdram.v ../../rtl/ddr2cntrl/vlog_xst_bl4.v ../../rtl/ddr2cntrl/vlog_xst_bl4_top_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_controller_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_read_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_rd_gray_ctr.v ../../rtl/ddr2cntrl/vlog_xst_bl4_RAM8D_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_RAM8D_1.v ../../rtl/ddr2cntrl/vlog_xst_bl4_fifo_1_wr_en_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_read_controller_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_dqs_delay.v ../../rtl/ddr2cntrl/vlog_xst_bl4_fifo_0_wr_en_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure_top_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_cal_top.v ../../rtl/ddr2cntrl/vlog_xst_bl4_tap_dly_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_cal_ctl_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_clk_dcm.v ../../rtl/ddr2cntrl/vlog_xst_bl4_wr_gray_ctr.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_write_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_rst.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure.v ../../rtl/ddr2cntrl/vlog_xst_bl4_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_controller_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_s3_dqs_iob.v ../../rtl/ddr2cntrl/vlog_xst_bl4_s3_ddr_iob.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_ddr2_dm_0.v
vlog -lint -work work ../../rtl/flash-prom/flashcntrlr.v
vlog -lint -work work ../../rtl/memory.v

vlog -lint -work work ../../rtl/vga/vdu.v ../../rtl/vga/char_rom_b16.v ../../rtl/vga/ram2k_b16_attr.v ../../rtl/vga/ram2k_b16.v

vlog -lint -work work +incdir+../../../../rtl-model ../../../../rtl-model/regfile.v ../../../../rtl-model/alu.v ../../../../rtl-model/cpu.v ../../../../rtl-model/exec.v ../../../../rtl-model/fetch.v ../../../../rtl-model/jmp_cond.v ../../../../rtl-model/util/primitives.v

# Simulation

vlog -lint -work work +incdir+../ddr2sdram/ ../ddr2sdram/glbl.v ../ddr2sdram/ddr2.v
vcom -lint -work work ../flash-prom/generic_data.vhd ../flash-prom/test_stub.vhd ../flash-prom/utility_pack.vhd  ../flash-prom/m29dw323d.vhd
vlog -lint -work work +incdir+../../rtl ../board.v ../../rtl/clocks.v ../../rtl/zet_soc.v


vmap unisims /home/zeus/opt/xilinx92i/modelsim/verilog/unisims
vsim -novopt -L /home/zeus/opt/xilinx92i/modelsim/verilog/unisims -t ps work.board work.glbl
onerror {resume}
add wave -divider Clocks
add wave -radix hexadecimal /board/fpga0/cpu_clk
add wave -radix hexadecimal /board/fpga0/mem_rst
add wave -divider Memory
add wave -radix hexadecimal /board/rst
add wave -radix hexadecimal /fpga0/addr
add wave -radix hexadecimal /fpga0/wr_data
add wave -radix hexadecimal /fpga0/we
add wave -radix hexadecimal /fpga0/byte_m
add wave -radix hexadecimal /fpga0/rd_data
add wave -radix hexadecimal /fpga0/ready
add wave -divider CPU
add wave -radix hexadecimal /fpga0/cpu0/fetch0/decode0/seq_rom0/addr
add wave -radix hexadecimal /fpga0/cpu0/fetch0/decode0/seq_rom0/q
add wave -radix hexadecimal /fpga0/cpu0/fetch0/state
add wave -radix hexadecimal /fpga0/cpu0/fetch0/next_state
add wave -radix hexadecimal /fpga0/cpu0/fetch0/block
add wave -radix hexadecimal /fpga0/cpu0/fetch0/opcode
add wave -radix hexadecimal /fpga0/cpu0/fetch_or_exec
# add wave -divider VDU
# add wave -radix hexadecimal /fpga0/vdu0/*
# add wave -divider ddr2
# add wave -radix hexadecimal /fpga0/mem_ctrlr_0/sdram0/*
add wave -divider Flash
add wave -radix hexadecimal /fpga0/mem_ctrlr_0/flash0/*
