vlog -work work sim_exec.v
vlog -work work idt71v416s10.v
vlog -work work ../../altpll0_syn.v
vsim -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/altera_mf_ver -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/stratixii_ver -l msim_transcript -i -t ps work.sim_exec
add wave sim:/sim_exec/clk_
add wave sim:/sim_exec/boot
add wave sim:/sim_exec/clk
add wave sim:/sim_exec/clk2x
add wave sim:/sim_exec/estado
add wave sim:/sim_exec/idt0/we_
add wave sim:/sim_exec/e0/mem0/we
add wave sim:/sim_exec/e0/mem0/odd_word
add wave sim:/sim_exec/e0/mem0/a0
add wave sim:/sim_exec/e0/mem0/rwe
