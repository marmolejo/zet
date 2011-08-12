	;
	; BIOS messages
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; DO NOT DELETE the following string ! (does not need to be displayed)
	db	"tinyBIOS V1.3a (C)1997-2001 PC Engines",13,10,10,0
	;
	; Error messages
	;
msg_parit: db	"Parity Error !",13,10,0
msg_iochk: db	"I/O channel NMI !",13,10,0
msg_halt:	db	"System halted.",0
msg_noboot: db	"No boot device available, press Enter to continue.",13,10,0
msg_base:	db	" KB Base Memory",13,10,0
msg_ext: 	db	" KB Extended Memory",13,10,0
msg_crlf:	db	13,10,0
msg_kbd:	db	"Keyboard failure.",13,10,0
msg_bs:	db	8,8,8,8,8,0

ifdef	HD_WAIT
msg_wait:	db	"Waiting for HDD "
msg_dot:	db	".",0
endif
