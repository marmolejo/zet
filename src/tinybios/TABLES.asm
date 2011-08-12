	;
	; initialization tables
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;

	;
	; Initial initialization table (used in post2)
	;
clrtab:		db	cm_nmi+cm_b,cm_idx		;RTC: disable NMI
			db	2,cm_dat				;RTC: BCD mode, interrupt disable
			db	cm_nmi+cm_a,cm_idx		;RTC: 32768 Hz oscillator, 1ms int
			db	26h,cm_dat
	
			db	4,dma0+8				;disable dma0
			db	4,dma1+8+8				;disable dma1
			db	0,dma0+0dh				;reset dma0 (data don't care)
			db	0,dma1+0dh+0dh			;reset dma1 (data don't care)
			db	0fh,dma0+0fh			;mask all channels
			db	0fh,dma1+0fh+0fh		;mask all channels
			db	0,dma0+8				;Enable dma0
			db	0,dma1+8+8				;Enable dma1

			db	0fch,port61				;disable parity

ifdef	NO_ISAREF
			db	50h,timer+3
else
			db	54h,timer+3				;init refresh
endif
			db	12h,timer+1				;refresh interval

			db	0ffh,0ffh				;end of table
			
			;
			; Timer, DMA, PIC initialization table (used in post2)
			;
			; first data byte, then port address
			;
tdmatab:	db	0,dma1+8+8				;Enable dma1
			db	0c0h,dma1+0bh+0bh		;Cascade mode, channel 4
			db	041h,dma1+0bh+0bh		;Single mode, channel 5
			db	042h,dma1+0bh+0bh		;Single mode, channel 6
			db	043h,dma1+0bh+0bh		;Single mode, channel 7
			db	0,dma1+09h+09h			;clear DRQ4 request
			db	0,dma1+0ah+0ah			;unmask DRQ4 -> enable cascade
			db	0,dma0+8				;Enable dma0
			db	40h,dma0+0bh			;Single mode, channel 0
			db	41h,dma0+0bh			;Single mode, channel 1
			db	42h,dma0+0bh			;Single mode, channel 2
			db	43h,dma0+0bh			;Single mode, channel 3
	
			db	0,npx+1					;clear x87 interrupt
	
			db	11h,pic0				;ICW1: edge, ICW4
			db	08h,pic0+1				;ICW2: interrupt vector 08..0F
			db	04h,pic0+1				;ICW3: IRQ2 is used for cascade
			db	01h,pic0+1				;ICW4: 8086 mode
			db	0ffh,pic0+1				;OCW: mask all interrupts
	
			db	11h,pic1				;ICW1: edge, ICW4
			db	70h,pic1+1				;ICW2: interrupt vector 70..77
			db	02h,pic1+1				;ICW3: slave identification number
			db	01h,pic1+1				;ICW4: 8086 mode
			db	0ffh,pic1+1				;OCW: mask all interrupts
	
			db	26h,port92				;enable A20 gate

			db	0ffh,0ffh				;end of table
			
			;
			; baud rates, H/L swapped
			;
rs_baud:	db	04,17h	;110 baud
			db	03,00h	;150 baud
			db	01,80h	;300 baud
			db	00,0c0h	;600 baud
			db	00,60h	;1200 baud
			db	00,30h	;2400 baud
			db	00,18h	;4800 baud
			db	00,0ch	;9600 baud
			
			;
			; serial port I/O addresses (points to scratch register)
			;
rs_ports:	dw	3ffh,2ffh,3efh,2efh,287h,28fh
			dw	297h,29fh,2F7h,377h,0	;0 = end of table
			
			;
			; parallel port I/O addresses
			;
lp_ports:	dw	03bch,0378h,0278h,0		;0 = end of table

			;
			; RTC initialization table
			;
			; Note: When location cm_dia is set to 80, MS-DOS will ignore the
			; RTC date and set 1980.
			;
rtc_tab:	db	0,cm_ss					;00: second
			db	0,cm_ssa				;01: alarm second
			db	0,cm_mm					;02: minute
			db	0,cm_mma				;03: alarm minute
			db	0,cm_hh					;04: hour
			db	0,cm_hha				;05: alarm hour
			db	0,cm_day				;06: day of week
			db	1,cm_dd					;07: day
			db	1,cm_mo					;08: month
			db	00h,cm_yy				;09: year
			db	80h,cm_dia				;0E: power loss flag
			db	20h,cm_cent				;32: century
rtc_tab9:								;end of table

