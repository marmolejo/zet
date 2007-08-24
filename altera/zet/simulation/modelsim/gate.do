vlog -work work sim_gate.v
vlog -work work idt71v416s10.v
vsim -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/stratixii_ver -t ps work.sim_gate
onerror {resume}
quietly WaveActivateNextPane {} 0
quietly virtual signal -install /sim_gate/t0 { (concat_range (15 to 0) )( (context /sim_gate/t0 )&{\exec0|reg0|r[0][15]~regout\ , \exec0|reg0|r[0][14]~regout\ , \exec0|reg0|r[0][13]~regout\ , \exec0|reg0|r[0][12]~regout\ , \exec0|reg0|r[0][11]~regout\ , \exec0|reg0|r[0][10]~regout\ , \exec0|reg0|r[0][9]~regout\ , \exec0|reg0|r[0][8]~regout\ , \exec0|reg0|r[0][7]~regout\ , \exec0|reg0|r[0][6]~regout\ , \exec0|reg0|r[0][5]~regout\ , \exec0|reg0|r[0][4]~regout\ , \exec0|reg0|r[0][3]~regout\ , \exec0|reg0|r[0][2]~regout\ , \exec0|reg0|r[0][1]~regout\ , \exec0|reg0|r[0][0]~regout\ } )} ax
quietly virtual signal -install /sim_gate/t0 { (concat_range (15 to 0) )( (context /sim_gate/t0 )&{\exec0|reg0|r[1][15]~regout\ , \exec0|reg0|r[1][14]~regout\ , \exec0|reg0|r[1][13]~regout\ , \exec0|reg0|r[1][12]~regout\ , \exec0|reg0|r[1][11]~regout\ , \exec0|reg0|r[1][10]~regout\ , \exec0|reg0|r[1][9]~regout\ , \exec0|reg0|r[1][8]~regout\ , \exec0|reg0|r[1][7]~regout\ , \exec0|reg0|r[1][6]~regout\ , \exec0|reg0|r[1][5]~regout\ , \exec0|reg0|r[1][4]~regout\ , \exec0|reg0|r[1][3]~regout\ , \exec0|reg0|r[1][2]~regout\ , \exec0|reg0|r[1][1]~regout\ , \exec0|reg0|r[1][0]~regout\ } )} cx
quietly virtual signal -install /sim_gate/t0 { (concat_range (15 to 0) )( (context /sim_gate/t0 )&{\exec0|reg0|r[2][15]~regout\ , \exec0|reg0|r[2][14]~regout\ , \exec0|reg0|r[2][13]~regout\ , \exec0|reg0|r[2][12]~regout\ , \exec0|reg0|r[2][11]~regout\ , \exec0|reg0|r[2][10]~regout\ , \exec0|reg0|r[2][9]~regout\ , \exec0|reg0|r[2][8]~regout\ , \exec0|reg0|r[2][7]~regout\ , \exec0|reg0|r[2][6]~regout\ , \exec0|reg0|r[2][5]~regout\ , \exec0|reg0|r[2][4]~regout\ , \exec0|reg0|r[2][3]~regout\ , \exec0|reg0|r[2][2]~regout\ , \exec0|reg0|r[2][1]~regout\ , \exec0|reg0|r[2][0]~regout\ } )} dx
quietly virtual signal -install /sim_gate/t0 { (concat_range (15 to 0) )( (context /sim_gate/t0 )&{\exec0|reg0|r[3][15]~regout\ , \exec0|reg0|r[3][14]~regout\ , \exec0|reg0|r[3][13]~regout\ , \exec0|reg0|r[3][12]~regout\ , \exec0|reg0|r[3][11]~regout\ , \exec0|reg0|r[3][10]~regout\ , \exec0|reg0|r[3][9]~regout\ , \exec0|reg0|r[3][8]~regout\ , \exec0|reg0|r[3][7]~regout\ , \exec0|reg0|r[3][6]~regout\ , \exec0|reg0|r[3][5]~regout\ , \exec0|reg0|r[3][4]~regout\ , \exec0|reg0|r[3][3]~regout\ , \exec0|reg0|r[3][2]~regout\ , \exec0|reg0|r[3][1]~regout\ , \exec0|reg0|r[3][0]~regout\ } )} bx
quietly virtual signal -install /sim_gate/t0 { (concat_range (15 to 0) )( (context /sim_gate/t0 )&{\exec0|reg0|r[13][15]~regout\ , \exec0|reg0|r[13][14]~regout\ , \exec0|reg0|r[13][13]~regout\ , \exec0|reg0|r[13][12]~regout\ , \exec0|reg0|r[13][11]~regout\ , \exec0|reg0|r[13][10]~regout\ , \exec0|reg0|r[13][9]~regout\ , \exec0|reg0|r[13][8]~regout\ , \exec0|reg0|r[13][7]~regout\ , \exec0|reg0|r[13][6]~regout\ , \exec0|reg0|r[13][5]~regout\ , \exec0|reg0|r[13][4]~regout\ , \exec0|reg0|r[13][3]~regout\ , \exec0|reg0|r[13][2]~regout\ , \exec0|reg0|r[13][1]~regout\ , \exec0|reg0|r[13][0]~regout\ } )} rtmp
add wave -noupdate -format Logic /sim_gate/t0/clk_
add wave -noupdate -format Logic /sim_gate/t0/\\pll0|altpll_component|_clk0\\
add wave -noupdate -format Logic /sim_gate/t0/\\pll0|altpll_component|_clk1\\
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/addr_
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/data_
add wave -noupdate -format Logic /sim_gate/t0/rble_
add wave -noupdate -format Logic /sim_gate/t0/rbhe_
add wave -noupdate -format Logic /sim_gate/t0/rwe_
add wave -noupdate -format Logic /sim_gate/t0/roe_
add wave -noupdate -format Literal /sim_gate/ir
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/imm
add wave -noupdate -format Logic /sim_gate/t0/\\pll0|altpll_component|_locked\\
add wave -noupdate -format Literal /sim_gate/t0/\\exec0|reg0|flags\\
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/ax
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/bx
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/cx
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/dx
add wave -noupdate -format Literal -radix hexadecimal /sim_gate/t0/rtmp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {239876 ps} 0}
configure wave -namecolwidth 337
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
