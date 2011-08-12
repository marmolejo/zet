	;
	; BIOS configuration data
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; This data is modified to store system configuration, such as
	; PCI data, hard disk parameters, etc.
	;
	; pd 991020 add hd_top
	;
	even
	db	"_DAT"			;header for checksum utility
						;start of data	
	dw	(d_sum - d_beg) ;pointer to checksum
d_beg:
	;
	; Hard disk parameters
	;
hd_prm0:	db	dpt_len dup (0)
hd_prm1:	db	dpt_len dup (0)
hd_top:		db	82h		;top HDD + 1

	;
	; PCI data
	;
	
	; this is a procedure to avoid problems in protected mode access...
	
getlbus:	db	0b0h	;MOV AL
d_lastbus:	db	0		;last PCI bus
			ret

ifdef	CDBOOT
			even
d_cdlba:	dw	0,0		;base LBA for last session
d_cdbase:	dw	0		;CD-ROM port base
d_cddrv:	db	0b0h	;slave drive
d_cdsec:	db	15		;sectors per track
d_cdflag:	db	0		;1 = enable CD emulation

endif

	;
	; Data checksum
	;
d_sum:		db	0		;checksum, end of data block
						;(filled in by utility)
						;
						; calculate data checksum
						;
d_dosum:	mov	al,0
			mov	si,offset d_beg
			mov	cx,d_sum-d_beg
d_dosum1:	add 	al,[cs:si]	;calculate checksum
			inc	si
			loop	d_dosum1
			neg	al
			mov 	[cs:si],al
			ret
