transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/lpm_ver
vmap lpm_ver verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {/home/zeus/opt/altera7.1/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/altera_ver
vmap altera_ver verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {/home/zeus/opt/altera7.1/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {/home/zeus/opt/altera7.1/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {/home/zeus/opt/altera7.1/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/stratixii_ver
vmap stratixii_ver verilog_libs/stratixii_ver
vlog -vlog01compat -work stratixii_ver {/home/zeus/opt/altera7.1/quartus/eda/sim_lib/stratixii_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/altpll0.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/test_exec.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/memory.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/exec.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/regfile.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/primitives.v}
vlog -vlog01compat -work work +incdir+/home/zeus/zet/altera/zet {/home/zeus/zet/altera/zet/alu.v}

