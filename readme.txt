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
-----------------------------------------------------------------------------------
\boards\              - different board implementations
\boards\de0-vdu\      - De0 using vdu text vga driver (no graphics on DE0)
\boards\de0-shadow\   - same as above with shadow bios

\src\                 - Source files for some commands used to transform ROMs
\src\zetbios\         - Zet specific Bios for DE1 & DE0 
\src\DE0\             - Shadow BIOS for DE0

\cores\               - cores i have made changes to
\cores\audio\         - my pwm audio core
\cores\PS2\           - mouse and keyboard dirvers
\cores\uart16450\     - NEW COM port driver (and it really really works)
\cores\Ethernet\      - Ethernet driver for simple 10BaseT phy shown in zbc

all other cores are same. the wb_switch is messed around with for some of the 
board implementations. For those, I put the special version of the wb_switch in
the rtl directory under the board folder.
