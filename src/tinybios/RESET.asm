	;
	; Reset vector
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	;db	0fff0h-$ dup (0ffh)	;at F000:FFF0
	org 0fff0h
	;jmp	reset
	db	0eah			; HARD CODE FAR JUMP TO SET
	dw	offset reset	;  OFFSET
	dw	0f000h			;  SEGMENT
						;jmp	far 0f000h:reset
	
	;					dw	STARTOFS	;this is used and overwritten by
										;the BIOSSUM utility.
	
;	The following items are added by the BIOSSUM utility:
;	
	db	"00/00/00"	;assembly date in mm/dd/yy format
;			;filled in by BIOSSUM utility
;	
	db	0ffh	;empty
	db	0fch	;model byte = AT
	db	0	;checksum goes here - added by BIOSSUM
;			;utility
