#!/bin/bash
cd $HOME/opt/altera-sub/10.0/nios2eds
. ./nios2_sdk_shell_bashrc
cd bin/
export PATH=.:$PATH
./bin2flash --input=/home/zeus/zet/src/bios/bios.rom --output=$HOME/zet/src/bios/bios.flash --location=0x0; ../../quartus/bin/quartus_pgm $HOME/Documentos/altera/DE0_CD-ROM_v.1.1/Demonstrations/DE0_NIOS_SDCARD/DE0_TOP.cdf; ./nios2-flash-programmer  --base=0x02400000 $HOME/zet/src/bios/bios.flash
