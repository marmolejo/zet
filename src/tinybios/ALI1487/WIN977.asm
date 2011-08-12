	;
	; Initialize Winbond W83977EF super I/O
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
sio_idx	equ	03f0h
	;
	; initialize super I/O
	;
	; (interrupts disabled on entry)
	;
sio_init:	pushf		;disable interrupts, preserve old status
	cli
	cld
	
	; enter configuration mode
	
	mov	dx,sio_idx
	mov	al,87h
	out	dx,al
	out	dx,al
	
	; set super I/O registers
	
;	mov	dx,sio_idx
	mov	si,offset sio_tab
	call	sio_set

	; leave configuration mode

;	mov	dx,sio_idx	;leave configuration mode
	mov	al,0aah
	out	dx,al
	
	popf		;restore flags
	ret
	;
	; set super I/O registers from table
	;
sio_set1:	out	dx,al	;set index register
	inc	dx
	mov	al,ah
	out	dx,al	;set data register
	dec	dx
sio_set:	cs:	lodsw
	cmp	al,0ffh	;end of table ?
	jnz	sio_set1
	ret
	;
	; Winbond W83977EF SIO configuration
	;
sio_tab:	db	002,001	;Soft reset 94
;	db	020,052	;SID register 94 RO
;	db	021,0F4	;SID register 94 RO
	db	022,0FF	;Power control 94
	db	023,0FE	;Power management 94
	db	024,084	;clock control 95
	db	025,000	;tristate 95
	db	026,000	;mode select 96
	db	028,000	;IRQ sharing, LPT mode 97
	db	02A,000	;pin select 97
	db	02B,000	;pin select 98
	db	02C,000	;pin select 98

	db	007,000	;FDC
	db	060,003	;base MSB
	db	061,0F0	;base LSB
	db	070,006	;FDC int
	db	074,002	;DMA channel
	db	0F0,00C	;FDC config 100
	db	0F1,000	;FDD option 101
	db	0F2,0FF	;FDD type 102
	db	0F4,000	;FDD drive type select 102
	db	0F5,000	;FDD drive type select 103
	db	030,001	;Activate FDC

	db	007,001	;LPT
	db	060,003	;Base MSB
	db	061,078	;Base LSB
	db	070,007	;LPT int
	db	074,003	;DMA channel
	db	0F0,000	;LPT config 104
	db	030,001	;Activate LPT

	db	007,002	;COM1
	db	060,003	;Base MSB
	db	061,0F8	;Base LSB
	db	070,004	;COM1 int
	db	0F0,000	;COM mode register 105
	db	030,001	;Activate COM1

	db	007,003	;COM2
	db	060,002	;Base MSB
	db	061,0F8	;Base LSB
	db	070,003	;COM2 int
	db	074,0FF	;DMA channel
	db	0F0,000	;COM2 config 106
	db	0F1,000	;COM2 config 106
	db	030,001	;Activate COM2

	db	007,005	;Keyboard
	db	060,000	;Base MSB
	db	061,060	;Base LSB
	db	062,000	;Base MSB
	db	063,064	;Base LSB
	db	070,000	;KBC int
	db	072,000	;Mouse int
	db	0F0,083	;KBC config 108
	db	030,000	;Activate KBD -> disable

	db	007,006	;CIR
	db	060,000	;Base MSB
	db	061,000	;Base LSB
	db	070,000	;CIR int
	db	030,000	;Activate CIR -> disable

	db	007,007	;GPIO1
	db	060,000	;Base MSB
	db	061,000	;Base LSB
	db	062,000	;GP14 Base MSB
	db	063,000	;GP14 Base LSB
	db	064,000	;GP15 Base MSB
	db	065,000	;GP15 Base LSB
	db	070,000	;GP10 int
	db	072,000	;GP11 int
	db	0E0,001	;GP10 110 input
	db	0E1,001	;GP11 110 input
	db	0E2,001	;GP12 111 input
	db	0E3,001	;GP13 111 input
	db	0E4,001	;GP14 111 input
	db	0E5,001	;GP15 112 input
	db	0E6,001	;GP16 112 input
	db	0E7,001	;GP17 112 input
	db	0F1,000	;I/O decode enable 113 -> disable
	db	030,001	;Activate GPIO

	db	007,008	;GPIO2
	db	060,000	;Base MSB
	db	061,000	;Base LSB
	db	070,000	;GP20..26 int
	db	072,000	;watch dog int
	db	0E8,010	;GP20 114 keyboard reset output
	db	0E9,001	;GP21 114 input
	db	0EA,001	;GP22 114 input
	db	0EB,001	;GP23 114 input
	db	0EC,001	;GP24 115 input
	db	0ED,008	;GP25 115 A20 gate output
	db	0F0,000	;interrupt filter 116
	db	0F2,000	;watchdog timer 116
	db	0F3,000	;watchdog timer 116
	db	0F4,000	;watchdog timer 117
	db	030,001	;Activate GPIO2

	db	007,00A	;ACPI
	db	070,000	;SCI# int
	db	0E0,000	;enable 118
	db	0E1,005	;keyboard wake-up index 119
	db	0E2,000	;keyboard wake-up data 119
;	db	0E3,000	;kb/ms wake status 119
	db	0E4,000	;power loss control 119
	db	0E5,000	;compare code length 120
	db	0E6,000	;CIR rate divisor 120
	db	0E7,000	;CIR mode 120
	db	0F0,000	;auto power management enable 120
	db	0F1,08F	;trap status 121
	db	0F3,034	;IRQ status 122
	db	0F4,000	;IRQ status 122
	db	0F6,000	;SCI# enable 123
	db	0F7,000	;SCI# enable 123
	db	0F9,000	;SCI# enable 124
	db	030,000	;Activate GPIO2 -> disable

	db	0ff	;end of table

