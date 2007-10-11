vdel -all -lib work
vlib work

# Hardware part

vlog -work work +incdir+../../rtl/ ../../rtl/ddr2cntrl/ddr2sdram.v ../../rtl/ddr2cntrl/vlog_xst_bl4.v ../../rtl/ddr2cntrl/vlog_xst_bl4_top_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_controller_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_read_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_rd_gray_ctr.v ../../rtl/ddr2cntrl/vlog_xst_bl4_RAM8D_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_RAM8D_1.v ../../rtl/ddr2cntrl/vlog_xst_bl4_fifo_1_wr_en_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_read_controller_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_dqs_delay.v ../../rtl/ddr2cntrl/vlog_xst_bl4_fifo_0_wr_en_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure_top_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_cal_top.v ../../rtl/ddr2cntrl/vlog_xst_bl4_tap_dly_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_cal_ctl_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_clk_dcm.v ../../rtl/ddr2cntrl/vlog_xst_bl4_wr_gray_ctr.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_write_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_rst.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure.v ../../rtl/ddr2cntrl/vlog_xst_bl4_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_infrastructure_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_controller_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_s3_dqs_iob.v ../../rtl/ddr2cntrl/vlog_xst_bl4_s3_ddr_iob.v ../../rtl/ddr2cntrl/vlog_xst_bl4_data_path_iobs_0.v ../../rtl/ddr2cntrl/vlog_xst_bl4_ddr2_dm_0.v
vlog -work work ../../rtl/flash-prom/flashcntrlr.v
vlog -work work ../../rtl/memory.v

vlog -work work +incdir+../../../../rtl ../../../../rtl/regfile.v ../../../../rtl/alu.v ../../../../rtl/cpu.v ../../../../rtl/exec.v ../../../../rtl/fetch.v ../../../../rtl/jmp_cond.v ../../../../rtl/util/primitives.v

# Simulation

vlog -work work +incdir+../ddr2sdram/ ../ddr2sdram/glbl.v ../ddr2sdram/ddr2.v
vcom -work work ../flash-prom/generic_data.vhd ../flash-prom/test_stub.vhd ../flash-prom/utility_pack.vhd  ../flash-prom/m29dw323d.vhd
vlog -work work +incdir+../../rtl ../board.v


vmap unisims /home/zeus/opt/xilinx92i/modelsim/verilog/unisims
vsim -L /home/zeus/opt/xilinx92i/modelsim/verilog/unisims -t ps work.board work.glbl
add wave -divider Clocks
add wave -radix hexadecimal /board/cpu_clk
add wave -radix hexadecimal /board/mem_rst
add wave -divider Memory
add wave -radix hexadecimal /board/rst
add wave -radix hexadecimal /board/addr
add wave -radix hexadecimal /board/wr_data
add wave -radix hexadecimal /board/we
add wave -radix hexadecimal /board/byte_m
add wave -radix hexadecimal /board/rd_data
add wave -radix hexadecimal /board/ready
add wave -divider CPU
add wave -radix hexadecimal /board/cpu0/fetch0/state
add wave -radix hexadecimal /board/cpu0/fetch0/next_state
add wave -radix hexadecimal /board/cpu0/fetch0/block
add wave -radix hexadecimal /board/cpu0/fetch0/opcode
add wave -divider Flash
add wave -radix hexadecimal /board/mem_ctrlr_0/flash0/*
add wave -divider ddr2
add wave -radix hexadecimal /board/mem_ctrlr_0/sdram0/*
