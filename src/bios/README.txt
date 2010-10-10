----------------------------------------------------------------------------
   README FILE FOR ZET SHADOW BIOS FOR DE0 BUILD MAKE  09-14-2010
----------------------------------------------------------------------------
This readme file explains the steps needed to build and install the Shadow
BIOS for the Terasic DE0 board.

Pre-requisites:
         - Openwatcom compiler and assembler installed on your PC
         - a working Terasic DE0 board
         - the DE0 distro for Zet

Step 1.  Make a sub-directory and load the DE0 bios package into that folder.
         Open a console window and type wmake. This should make the bios for you.
         There will be a number of warning messages, this is normal, you can
         ignore those. If an error occurs the make will break.

Step 2.  There should be a file "bootrom.dat" this is the shadow bios boot
         ROM. You are going to need to copy that file into the rtl folder of
         Zet and build zet in Quartus. This file will be included into a ROM
         instantiated in the FPGA. Rename the file to whatever the file name
         is that you are using in the bootrom.v module (the default is
         "biosrom.dat" but you can make it what ever you want). This is the
         little section of code that sits up at the top end of memory that
         will copy the main BIOS into SDRAM.

Step 3.  Find the DE0_ControlPanel.exe program that was loaded from the
         CDROM that came with your DE0 board.

Step 4.  Plug in and power on your board to the USB port on your computer
         and run the program. It should load up OK. If not, you will need
         to debug that with Terasic.

Step 5.  Find the file "bios_de0.hex" this is the HEX version of the Main BIOS
         that will be loaded into the flash ram on the DE0 board. Go to the
         "Memory" tab, and select FLASH (10000h) from the drop down
         menu. Then Click on Memory Erase. It will take a minute to erase
         the flash.

Step 6.  Now click on the check box that says "File Length", then click on the
         button that says "Write a file to memory". In the file selection
         dialog, select the file "bios_de0.hex". It will take a minute or so
         to load the file into Flash.

Step 7.  Your board should now have it's bios loaded into flash. Now you will
         need to start Quartus. If all went well, it should boot up. It should
         first jump to that little 256 byte bootstrap loader that is in
         "bootrom.dat". That code will then copy the main BIOS from Flash
         into SDRAM in the right location and then jump to it.

         If all goes well at this point, the BIOS is running in SDRAM all
         except for the top 256 bytes which is running in FGPA ROM.


Note:    For the Floppy Disk, you just need to take the floppy image file you
         have and run it through the hexer.exe program to make the hex version
         of it and then go into the DE0_ControlPanel.exe and load it starting
         at 0x010000.
