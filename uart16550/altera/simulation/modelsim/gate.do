vsim -L /home/zeus/zet/uart16550/rtl/altera/simulation/modelsim/verilog_libs/stratixii_ver -do uart_top_run_msim_gate_verilog.do -l msim_transcript -i -t ps work.uart_test 
add wave sim:/uart_test/clk_
add wave sim:/uart_test/stxo_
add wave sim:/uart_test/led_
add wave sim:/uart_test/\\pll0|altpll_component|_clk0\\
add wave sim:/uart_test/\\pll0|altpll_component|_locked\\
force -freeze sim:/uart_test/clk_ 1 0, 0 {10 ns} -r 20ns
run 50us