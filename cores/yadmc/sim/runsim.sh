#!/bin/sh
cver yadmc_test.v mt48lc16m16a2.v ../../rtl/yadmc/yadmc_dpram.v ../../rtl/yadmc/yadmc_spram.v ../../rtl/yadmc/yadmc_sync.v ../../rtl/yadmc/yadmc_sdram16.v ../../rtl/yadmc/yadmc.v

#iverilog -o sim yadmc_test.v mt48lc16m16a2.v ../../rtl/yadmc/yadmc_dpram.v ../../rtl/yadmc/yadmc_spram.v ../../rtl/yadmc/yadmc_sync.v ../../rtl/yadmc/yadmc_sdram16.v ../../rtl/yadmc/yadmc.v
#./sim
