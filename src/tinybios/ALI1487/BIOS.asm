	;
	; TinyBIOS, configured for ALI M1487 chipset, ESA TF-486 board
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;

	; start offset

STARTOFS	equ	0c000	;start offset, must be multiple of 256

	db	STARTOFS dup 0	;(start data cut out by BIOSSUM.EXE)

; general options

BOOTBEEP:			;enables beep on bootup

;DEBUG:			;debug mode (Int 13 trace etc).

;NO_NMI:			;disable NMI code

;NO_RTCFAIL:		;skip hang on RTC failure

;QUICKMEM:			;no memory test (fill only)

; hard disk, boot options

BOOT_AC:			;Boot A: first, then C:
			;comment out for C: then A:

HD_WAIT	equ	20	;Hard disk wait, max. x seconds
HD_ENA	equ	3	;don't check HDD status before x seconds

HDD_LBA:			;enable LBA support

HD_EDD:			;enable extended disk drive support

HDD_NOSLAVE:		;don't look (and wait) for slave device

;HD_TIME	equ	080	;commented out = HDD power down disabled
			;0 = code included, but no timeout
			;1..240 = timeout x * 5 s units
			;241..251 = timeout (x-240)*30 min

; keyboard options

;NO_KBC:			;don't fail if KBC not present

LED_UPDATE:		;Define to enable keyboard LED updates
			;(NumLock, CapsLock, ScrollLock).
			;Not recommended for real-time apps.
	
KEY_RATE	equ	0102h	;key repeat rate
			;500 ms delay, 20 / second

; serial port options

;CONSOLE	equ	003E8	;serial port for console = COM3
;CONINT	equ	4	;interrupt for console

; PCI options

INTA	equ	10	;PCI interrupt assignment
INTB	equ	0ffh	;also see PCI_TAB
INTC	equ	0ffh
INTD	equ	0ffh

INT0	equ	0ffh	;no interrupt assigned

; platform specific options

;C000_ROM			;if enabled, ROM in C000 area (VGA BIOS)
	;
	; Signon prompt
	;
copyrt:	db	"ALI M1487",13,10
	include	..\message.asm
	;
	; Include files
	;	
	include	..\equ.asm	;general equates
	include	ali.asm	;chipset / system specific code
	include	win977.asm	;super I/O initialization
	include	..\post.asm	;POST
	include ..\post2.asm	;POST routines
	include	..\debug.asm	;& Debug routines, comment out
	include ..\fdd.asm	;floppy BIOS
	include	..\hdd.asm	;hard disk BIOS
	include ..\kbd.asm	;keyboard BIOS
	include ..\pci.asm	;PCI BIOS
	include	..\pcipnp.asm	;PCI plug & play
	;
	; OEM decision: verify diagnostic flags to decide
	; whether to boot or display error messages
	;
decide:	
	;cmp	byte [tmp_rtc],0	;1 -> RTC battery failure
	;cmp	byte [tmp_tim],0	;1 -> timer / RTC update failure
			;(see above)
	;cmp	byte [tmp_kbfail],0	;1 -> keyboard failure
	;cmp	byte [m_fdmed0],0	;0 -> floppy failure / not present
	ret
	;
	; INT 10 legacy entry point
	;
	db	0f065-$ dup 0ffh
	jmp	int10

	include ..\vid.asm	;video BIOS
	include ..\lpt.asm	;printer BIOS
	include	..\rtc.asm	;timer / RTC BIOS
	include	..\com.asm	;serial BIOS
	include	..\int1x.asm	;miscellaneous interrupts
	include	..\kbtab.asm	;keyboard table
	;
	; INT 1A legacy entry point
	;
	db	(0fe6e-$) dup 0ffh	;explicitly documented in the
	jmp	int1a	;PCI BIOS spec.
	;
	; BIOS writeable configuration data
	;
	include	..\data.asm
	;
	; PCI interrupt assignment table
	;
PCI_TAB:	db	INT0,INT0,INT0,INT0	;device 0 - chipset
	db	INT0,INT0,INT0,INT0	;device 1
	db	INT0,INT0,INT0,INT0	;device 2
	db	INT0,INT0,INT0,INT0	;device 3
	db	INT0,INT0,INT0,INT0	;device 4
	db	INT0,INT0,INT0,INT0	;device 5
	db	INT0,INT0,INT0,INT0	;device 6
	db	INT0,INT0,INT0,INT0	;device 7
	db	INT0,INT0,INT0,INT0	;device 8
	db	INT0,INT0,INT0,INT0	;device 9
	db	INT0,INT0,INT0,INT0	;device 10
	db	INT0,INT0,INT0,INT0	;device 11
	db	INTA,INTB,INTC,INTD	;device 12 - PCI slot
	db	INT0,INT0,INT0,INT0	;remaining devices
pci_tab9:			;end of table

	include	..\tables.asm	;ISA initialization tables
	include	..\reset.asm	;reset vector
