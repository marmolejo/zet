Quick help
----------
This is my fork of ZET. My fork is focused on the DE0 and DE1 implementations.
I have a separate repository for ZBC.


=== Altera DE1 ===
To build the system for the Altera DE1 board, just open the file
"boards/altera-de1/syn/kotku.qpf" in Quartus II and compile the system.

As a result, you will have a file named "kotku.sof", which is the conf-
iguration stream for the FPGA.

Explanation of directories
--------------------------
bin/        - Some scripts to prepare ROMs, download microcode, etc...
doc/        - Documentation stub
boards/     - Different boards supported (implementation dependent files)
cores/      - Different cores for the SOC PC system
cores/zet/  - Zet processor RTL code
src/        - Source files for some commands used to transform ROMs
src/bios/     - ROM BIOS and VIDEO BIOS implementation
src/zetbios/  - Zet specific Bios for DE1
tests/        - 8086 test benches (exactly the same as in the web)
