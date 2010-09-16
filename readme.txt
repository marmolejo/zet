Quick help
----------
This is my fork of ZET. My fork is focused on the DE0 and DE1 implementations.
I have a separate repository for ZBC.


=== Altera DE1 ===
To build the system for the Altera DE1 board, just open the file
"boards/altera-de1/syn/kotku.qpf" in Quartus II and compile the system.

As a result, you will have a file named "kotku.sof", which is the conf-
iguration stream for the FPGA.

======================= Terasic DE0 Board=====================================
There are 2 versions of the DE0, since it has a mouse port built into it (although
you need the Y cable to make it work), there is no need to mod the board to add 
the mouse.

The \boards\de0-vdu\ is the same as the DE1 implementation except that it uses the 
vdu text only vga driver. This is because the DE0 does not have SRAM for graphics.
Eventually we will get the video to work using the SDRAM.

The \boards\de0-par\ version is a special version that runs the shadow
bios. This is now completed, it also includes the pwm audio module.

For it to work, you have to use the special bios
that is listed under \src\shadowbios\.


Explanation of directories
-----------------------------------------------------------------------------------
\boards\              - different board implementations
\boards\de0-vdu\      - De0 using vdu text vga driver (no graphics on DE0)
\boards\de0-par\      - same as above with shadow bios for parallel flash

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
