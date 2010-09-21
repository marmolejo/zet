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



======================= Terasic DE0 AUDIO Instructions ============================
The following are instructions on how to hook up a chasis speaker and the Line
outputs for the DE0 board. Both the Chasis speaker and Line out use the GPIO
lines, but it is easy to hook up. 

Chasis Speaker:
-----------------------------------------------------------------------------------
Here is how to hook up the chasis speaker. The build on this git hub is set to 
compile using pin AA20 of the Cyclone III chip, this equates to pin 2 of J5 (GPIO 1)
of the board, check your user manuals to be sure. Pin 12 of that same header is 
a ground pin.  You will need a small speaker (standar 8 ohm variety) and a resistor.

The maximum current the Cyclone III can put out is 8ma, so

Here is how you figure the value of the resister (ohms law) v = I * R

3.3V =  .008 * (R+8) hence R = 3.3/.008 - 8 = 405 ohms
Since resistors come in standard sizes, you will need to pick on close,
either a 390ohm or a 470ohm.  Either is probably going to be fine.

You can play with the value or even put a potentiometer on there for a volume if you want.

here is the hook up:


J5
               330
Pin  2  o----/\/\/\/\---------+
                              |
                              |
                              #/| Speaker
                              #\|
                              |
                              |
Pin 12  o---------------------+

That is it.


Line outputs:
-----------------------------------------------------------------------------------
Hooking up the line output is even easier. The reason is that line input for most
computer speaker or stereos is 10k Ohms, so no worries about driving too much
current from the GPIO. You have the same basic circuit as above except that now
you double it for stereo and the value of the resistor is less.

In this case the calculation is simple, we really do not want to go above about 2 volts
into most line inputs (although, they are very forgiving most of the time). So we just 
need to cut the voltage down a bit, by 2/3 so if we use a 4.7K resistor, that comes
pretty close (usually there is a volume control on the amplified speaker so that will 
compensate for being off a little.

The default for this build was to use pins AB19 and AB20 for the stereo outputs, which 
equate to GPIO1_D1 and GPIO1_D3, which are pins 4 and 6 on J5. 
(keep in mind, you can use whichever pins on the GPIO you want).

               4.7K     1uf
Pin  4  o----/\/\/\/\---)|----+
                              |
                              O Left line out
                              
Pin 12  o---------------------O Gnd
                              
                              O Right line out
                              |
Pin  4  o----/\/\/\/\---)|----+
               4.7K     1uf

You can experiment with the value for your speaker set up, but remember, for this 
set up, you need amplified speakers. Also, you probably will need an audio jack for this.














