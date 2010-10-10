#!/bin/bash
cd /opt/altera9.0/nios2eds
. ./nios2_sdk_shell_bashrc
cd bin/
export PATH=.:$PATH
./bin2flash --input=/home/zeus/zet/src/bios/bios.rom --output=/home/zeus/zet/src/bios/bios.flash --location=0x0; ../../quartus/bin/quartus_pgm /home/zeus/Documentos/altera/DE1_CD_v0.8/DE1_demonstrations/DE1_NIOS/DE1_NIOS.cdf; ./nios2-flash-programmer  --base=0 /home/zeus/zet/src/bios/bios.flash
