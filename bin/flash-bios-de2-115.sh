#!/bin/bash
cd $HOME/opt/altera-sub/10.0/nios2eds
. ./nios2_sdk_shell_bashrc
cd bin/
export PATH=.:$PATH
./bin2flash --input=$HOME/zet/src/bios/bios.rom --output=$HOME/zet/src/bios/bios.flash --location=0x0; ../../quartus/bin/quartus_pgm $HOME/Documentos/altera/DE2-115_v.1.0.2_CDROM/DE2_115_demonstrations/DE2_115_SD_CARD/DE2_115_SD_CARD.cdf; ./nios2-flash-programmer  --base=0x0a800000 $HOME/zet/src/bios/bios.flash
