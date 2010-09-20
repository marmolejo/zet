My ZET FORK INFO
------------------------------------------------------------------------------
This is my fork of ZET. My fork is focused on the DE0 implementation.
I have a separate repository for ZBC, which is a single board computer specifically
designed for ZET. If you are building ZET for the DE0, this is the correct
repository.



======================= Terasic DE0 Board=====================================
There is now just 1 version of the DE0 which implements the shadow bios. This
version also supports the PS2 mouse, the chasis speaker, the audio module and
the 16450 UART.

The DE0 has a mouse port built into it (although you need the Y cable to make 
it work), there is no need to mod the board to add the mouse.

The \boards\de0\ is the only build for the DE0, you will need to use the DE0
bios since it has shadow bios support, the DE1 bios will not work. Also, since 
the DE0 has no SRAM, there is no graphics support at this time.


Explanation of directories
-----------------------------------------------------------------------------------
\boards\              - different board implementations
\boards\de0-vdu\      - De0 using vdu text vga driver (no graphics on DE0)
\boards\de0-par\      - same as above with shadow bios for parallel flash

\src\                 - Source files for some commands used to transform ROMs
\src\DE0_BIOS\        - Shadow BIOS for DE0

\cores\               - cores i have made changes to
\cores\audio\         - my pwm audio core
\cores\PS2\           - mouse and keyboard dirvers
\cores\uart16450\     - NEW COM port driver (and it really really works)

all other cores are same. the wb_switch is specific to the DE0 so it is placed
under the boards folder for the DE0 build.




