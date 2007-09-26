vlog -work work cpu_gate.v
vlog -work work idt71v416s10.v
vsim -L /home/zeus/zet/altera/zet/simulation/modelsim/verilog_libs/stratixii_ver -t ps work.cpu_gate
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave sim:/cpu_gate/clk_
add wave -noupdate -format Logic /cpu_gate/cpu0/\\pll0|altpll_component|_clk0\\
add wave -noupdate -format Logic /cpu_gate/cpu0/\\pll0|altpll_component|_locked\\
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[0][15]~regout\ , \exec0|reg0|r[0][14]~regout\ , \exec0|reg0|r[0][13]~regout\ , \exec0|reg0|r[0][12]~regout\ , \exec0|reg0|r[0][11]~regout\ , \exec0|reg0|r[0][10]~regout\ , \exec0|reg0|r[0][9]~regout\ , \exec0|reg0|r[0][8]~regout\ , \exec0|reg0|r[0][7]~regout\ , \exec0|reg0|r[0][6]~regout\ , \exec0|reg0|r[0][5]~regout\ , \exec0|reg0|r[0][4]~regout\ , \exec0|reg0|r[0][3]~regout\ , \exec0|reg0|r[0][2]~regout\ , \exec0|reg0|r[0][1]~regout\ , \exec0|reg0|r[0][0]~regout\ } )} ax
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[1][15]~regout\ , \exec0|reg0|r[1][14]~regout\ , \exec0|reg0|r[1][13]~regout\ , \exec0|reg0|r[1][12]~regout\ , \exec0|reg0|r[1][11]~regout\ , \exec0|reg0|r[1][10]~regout\ , \exec0|reg0|r[1][9]~regout\ , \exec0|reg0|r[1][8]~regout\ , \exec0|reg0|r[1][7]~regout\ , \exec0|reg0|r[1][6]~regout\ , \exec0|reg0|r[1][5]~regout\ , \exec0|reg0|r[1][4]~regout\ , \exec0|reg0|r[1][3]~regout\ , \exec0|reg0|r[1][2]~regout\ , \exec0|reg0|r[1][1]~regout\ , \exec0|reg0|r[1][0]~regout\ } )} cx
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[2][15]~regout\ , \exec0|reg0|r[2][14]~regout\ , \exec0|reg0|r[2][13]~regout\ , \exec0|reg0|r[2][12]~regout\ , \exec0|reg0|r[2][11]~regout\ , \exec0|reg0|r[2][10]~regout\ , \exec0|reg0|r[2][9]~regout\ , \exec0|reg0|r[2][8]~regout\ , \exec0|reg0|r[2][7]~regout\ , \exec0|reg0|r[2][6]~regout\ , \exec0|reg0|r[2][5]~regout\ , \exec0|reg0|r[2][4]~regout\ , \exec0|reg0|r[2][3]~regout\ , \exec0|reg0|r[2][2]~regout\ , \exec0|reg0|r[2][1]~regout\ , \exec0|reg0|r[2][0]~regout\ } )} dx
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[3][15]~regout\ , \exec0|reg0|r[3][14]~regout\ , \exec0|reg0|r[3][13]~regout\ , \exec0|reg0|r[3][12]~regout\ , \exec0|reg0|r[3][11]~regout\ , \exec0|reg0|r[3][10]~regout\ , \exec0|reg0|r[3][9]~regout\ , \exec0|reg0|r[3][8]~regout\ , \exec0|reg0|r[3][7]~regout\ , \exec0|reg0|r[3][6]~regout\ , \exec0|reg0|r[3][5]~regout\ , \exec0|reg0|r[3][4]~regout\ , \exec0|reg0|r[3][3]~regout\ , \exec0|reg0|r[3][2]~regout\ , \exec0|reg0|r[3][1]~regout\ , \exec0|reg0|r[3][0]~regout\ } )} bx
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[4][15]~regout\ , \exec0|reg0|r[4][14]~regout\ , \exec0|reg0|r[4][13]~regout\ , \exec0|reg0|r[4][12]~regout\ , \exec0|reg0|r[4][11]~regout\ , \exec0|reg0|r[4][10]~regout\ , \exec0|reg0|r[4][9]~regout\ , \exec0|reg0|r[4][8]~regout\ , \exec0|reg0|r[4][7]~regout\ , \exec0|reg0|r[4][6]~regout\ , \exec0|reg0|r[4][5]~regout\ , \exec0|reg0|r[4][4]~regout\ , \exec0|reg0|r[4][3]~regout\ , \exec0|reg0|r[4][2]~regout\ , \exec0|reg0|r[4][1]~regout\ , \exec0|reg0|r[4][0]~regout\ } )} sp
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[5][15]~regout\ , \exec0|reg0|r[5][14]~regout\ , \exec0|reg0|r[5][13]~regout\ , \exec0|reg0|r[5][12]~regout\ , \exec0|reg0|r[5][11]~regout\ , \exec0|reg0|r[5][10]~regout\ , \exec0|reg0|r[5][9]~regout\ , \exec0|reg0|r[5][8]~regout\ , \exec0|reg0|r[5][7]~regout\ , \exec0|reg0|r[5][6]~regout\ , \exec0|reg0|r[5][5]~regout\ , \exec0|reg0|r[5][4]~regout\ , \exec0|reg0|r[5][3]~regout\ , \exec0|reg0|r[5][2]~regout\ , \exec0|reg0|r[5][1]~regout\ , \exec0|reg0|r[5][0]~regout\ } )} bp
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[6][15]~regout\ , \exec0|reg0|r[6][14]~regout\ , \exec0|reg0|r[6][13]~regout\ , \exec0|reg0|r[6][12]~regout\ , \exec0|reg0|r[6][11]~regout\ , \exec0|reg0|r[6][10]~regout\ , \exec0|reg0|r[6][9]~regout\ , \exec0|reg0|r[6][8]~regout\ , \exec0|reg0|r[6][7]~regout\ , \exec0|reg0|r[6][6]~regout\ , \exec0|reg0|r[6][5]~regout\ , \exec0|reg0|r[6][4]~regout\ , \exec0|reg0|r[6][3]~regout\ , \exec0|reg0|r[6][2]~regout\ , \exec0|reg0|r[6][1]~regout\ , \exec0|reg0|r[6][0]~regout\ } )} si
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[7][15]~regout\ , \exec0|reg0|r[7][14]~regout\ , \exec0|reg0|r[7][13]~regout\ , \exec0|reg0|r[7][12]~regout\ , \exec0|reg0|r[7][11]~regout\ , \exec0|reg0|r[7][10]~regout\ , \exec0|reg0|r[7][9]~regout\ , \exec0|reg0|r[7][8]~regout\ , \exec0|reg0|r[7][7]~regout\ , \exec0|reg0|r[7][6]~regout\ , \exec0|reg0|r[7][5]~regout\ , \exec0|reg0|r[7][4]~regout\ , \exec0|reg0|r[7][3]~regout\ , \exec0|reg0|r[7][2]~regout\ , \exec0|reg0|r[7][1]~regout\ , \exec0|reg0|r[7][0]~regout\ } )} di
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[13][15]~regout\ , \exec0|reg0|r[13][14]~regout\ , \exec0|reg0|r[13][13]~regout\ , \exec0|reg0|r[13][12]~regout\ , \exec0|reg0|r[13][11]~regout\ , \exec0|reg0|r[13][10]~regout\ , \exec0|reg0|r[13][9]~regout\ , \exec0|reg0|r[13][8]~regout\ , \exec0|reg0|r[13][7]~regout\ , \exec0|reg0|r[13][6]~regout\ , \exec0|reg0|r[13][5]~regout\ , \exec0|reg0|r[13][4]~regout\ , \exec0|reg0|r[13][3]~regout\ , \exec0|reg0|r[13][2]~regout\ , \exec0|reg0|r[13][1]~regout\ , \exec0|reg0|r[13][0]~regout\ } )} rtmp
quietly virtual signal -install /cpu_gate/cpu0 { (concat_range (15 to 0) )( (context /cpu_gate/cpu0 )&{\exec0|reg0|r[15][15]~regout\ , \exec0|reg0|r[15][14]~regout\ , \exec0|reg0|r[15][13]~regout\ , \exec0|reg0|r[15][12]~regout\ , \exec0|reg0|r[15][11]~regout\ , \exec0|reg0|r[15][10]~regout\ , \exec0|reg0|r[15][9]~regout\ , \exec0|reg0|r[15][8]~regout\ , \exec0|reg0|r[15][7]~regout\ , \exec0|reg0|r[15][6]~regout\ , \exec0|reg0|r[15][5]~regout\ , \exec0|reg0|r[15][4]~regout\ , \exec0|reg0|r[15][3]~regout\ , \exec0|reg0|r[15][2]~regout\ , \exec0|reg0|r[15][1]~regout\ , \exec0|reg0|r[15][0]~regout\ } )} ip
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/addr_
add wave -noupdate -format Logic /cpu_gate/cpu0/rble0_
add wave -noupdate -format Logic /cpu_gate/cpu0/rbhe0_
add wave -noupdate -format Logic /cpu_gate/cpu0/rble1_
add wave -noupdate -format Logic /cpu_gate/cpu0/rbhe1_
add wave -noupdate -format Logic -radix hexadecimal /cpu_gate/cpu0/data0_
add wave -noupdate -format Logic -radix hexadecimal /cpu_gate/cpu0/data1_
add wave -noupdate -format Logic /cpu_gate/cpu0/rwe_
add wave -noupdate -format Logic /cpu_gate/cpu0/roe_
add wave -noupdate -format Logic /cpu_gate/cpu0/roe_
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/ax
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/bx
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/cx
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/dx
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/sp
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/bp
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/si
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/di
add wave -noupdate -format Literal -radix hexadecimal /cpu_gate/cpu0/rtmp
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

run 2420420ps