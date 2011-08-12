;
; TinyBIOS, configured for Zet Fpga PC
;
; (C)2011 G.J.Laanstra
; 
;
;  Zet PC system BIOS helper functions in 8086 assembly
;  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
;  Copyright (C) 2010        Donna Polehn <dpolehn@verizon.net>
;  Modified      2011        Geert Jan Laanstra 
;
;  This file is part of the Zet processor. This program is free software;
;  you can redistribute it and/or modify it under the terms of the GNU
;  General Public License as published by the Free Software Foundation;
;  either version 3, or (at your option) any later version.
;
;  Zet is distrubuted in the hope that it will be useful, but WITHOUT
;  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
;  License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with Zet; see the file COPYING. If not, see
;  <http://www.gnu.org/licenses/>.
;
; general options

BOOTBEEP equ 1				;enables beep on bootup
;DEBUG:						;debug mode (Int 13 trace etc).
;NO_NMI:					;disable NMI code
;NO_RTCFAIL:				;skip hang on RTC failure
;QUICKMEM:					;no memory test (fill only)

; hard disk, boot options
BOOT_AC equ 1				;Boot A: first, then C:
							;comment out for C: then A:
HD_WAIT	equ	20				;Hard disk wait, max. x seconds
HD_ENA	equ	3				;don't check HDD status before x seconds
HDD_LBA equ 1				;enable LBA support
HD_EDD equ 1				;enable extended disk drive support
HDD_NOSLAVE equ 1			;don't look (and wait) for slave device
;HD_TIME	equ	080			;commented out = HDD power down disabled
							;0 = code included, but no timeout
							;1..240 = timeout x * 5 s units
							;241..251 = timeout (x-240)*30 min

; keyboard options
;NO_KBC:					;don't fail if KBC not present
LED_UPDATE equ 1			;Define to enable keyboard LED updates
							;(NumLock, CapsLock, ScrollLock).
							;Not recommended for real-time apps.
KEY_RATE	equ	0102h		;key repeat rate
							;500 ms delay, 20 / second
							
; serial port options
;CONSOLE	equ	003E8		;serial port for console = COM3
;CONINT	equ	4				;interrupt for console

; PCI options
INTA	equ	10				;PCI interrupt assignment
INTB	equ	0ffh			;also see PCI_TAB
INTC	equ	0ffh
INTD	equ	0ffh
INT0	equ	0ffh			;no interrupt assigned

; platform specific options
;C000_ROM equ 1				;if enabled, ROM in C000 area (VGA BIOS)

;;--------------------------------------------------------------------------
;; This value is subtracted from all the values that have to be placed to an
;; absolute location. The reason is so we can assemble a module that the linker
;; will start linking at F000:E000 offset. If we do not, then the linker will
;; fill F000:0000 to F000:DFFF with zeros and we will not be able to linke the
;; C module in. This trick makes the assembler thing we are starting at F000:0000 
;; then we set the linker script in the make file with an ofset of E000 in this
;; _BIOSSEG segment only. If you followed that then congratulations.
;;--------------------------------------------------------------------------
startofrom              equ     0E000h

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        .Model  Huge    ;; this forces it to nears on code and data
                        .8086           ;; this forces it to use 80186 and lower
_BIOSSEG                SEGMENT 'CODE'
                        assume  cs:_BIOSSEG
bootrom:                org     00000h           ;; start of ROM, get placed at 0E000h
copyrt:
bios_name_string:       db      "zetbios 1.1"   ;; version string, not used by code
                        db      0,0,0,0         ;; padding

                        org     (0e05bh - startofrom)

						include	..\message.asm
						include ..\equ.asm
dpt_len					equ 16						
						include	..\data.asm
						include	..\tables.asm	;ISA initialization tables
						
						include macro.asm

						include zet.asm
						include ext.asm
						include entry.asm	
				
						;include ..\hdd.asm

						include	reset.asm	;reset vector

_BIOSSEG				ends                    ;; End of code segment
						end             bootrom ;; End of this program					
