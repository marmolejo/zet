	;
	; Timer / RTC functions
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.

	;
	; Limitations:
	;
	; - Wait function not supported.
	; - Reinitialization doesn't set SET bit.
	; - We don't use CMOS RAM for configuration data
	;   (exception: extended memory size).
	; - There is no CMOS checksum.
	;
	
	; Year 2000 issue:
	;
	; - Years below 1980 are considered century roll-over, replaced
	;   by year 2000.
	; - Please note that DOS will force default date for anything
	;   before 1980.

	; pd 000817 add TICK_RATE option to support AMD Elan SC520
	;           (needs modified tick rate)
	; pd 990211 move tests from cm_shut to cm_test	
	; pd 980416 fix alarm function (interrupt mask, CX saved)
	
	;
	; INT1A timer BIOS
	;
int1a:
ifdef	PCI		;transfer to PCI BIOS if necessary
	cmp	ah,0b1h	;PCI
	jnz	int1a1
	jmp	pci_i1a	;go to PCI BIOS
int1a1:
endif
	sti		;enable interrupts
	push	ds
	push	bx
	xor	bx,bx	;BIOS segment
	mov	ds,bx
	cmp	ah,7
	ja	int1a_err	;:bad command code
	mov	bl,ah
	shl	bx,1
	cli		;disable interrupts
	jmp	[cs:bx+int1atab]	;dispatch function
	;
	; AH=2: get RTC time
	;
rtc_get:	call	rtc_uip	;check for RTC update
	jb	int1a_err	;:error
	mov	ah,cm_ss	;read seconds -> DH
	call	rtc_read
	mov	dh,al
	mov	ah,cm_mm	;read minutes -> CL
	call	rtc_read
	mov	cl,al
	mov	ah,cm_hh	;read hours -> CH
	call	rtc_read
	mov	ch,al
	mov	ah,cm_b	;read daylight savings bit -> DL
	call	rtc_read
	and	al,1
	mov	dl,al
	jmp	short int1a_ok
	;
	; AH=3: set RTC time
	;
rtc_set:	push	cx
	call	rtc_uip	;check for RTC update
	pop	cx
	mov	ah,cm_ss	;DH -> seconds
	mov	al,dh
	call	rtc_write
	mov	ah,cm_mm	;CL -> minutes
	mov	al,cl
	call	rtc_write
	mov	ah,cm_hh	;CH -> hours
	mov	al,ch
	call	rtc_write
	mov	ah,cm_b	;read status register B
	call	rtc_read
	and	al,01100010b	;mask off set, update interrupt,
			;square wave, daylight savings
	or	al,2	;set 24 hour mode
	or	al,dl	;add daylight savings bit from DL
	call	rtc_write	;update status register B
int1a_ok:	clc
int1a_ret: sti
	pop	bx
	pop	ds
	retf	2

int1a_err: stc
	jmp	short int1a_ret
	;
	; AH=4: get RTC date
	;
rtc_date:	call	rtc_uip	;check for RTC update
	jb	int1a_err
	mov	ah,cm_dd	;day -> DL
	call	rtc_read
	mov	dl,al
	mov	ah,cm_mo	;month -> DH
	call	rtc_read
	mov	dh,al
	mov	ah,cm_yy	;year -> CL
	call	rtc_read
	mov	cl,al
	mov	ah,cm_cent	;century -> CH
	call	rtc_read
	mov	ch,al
	cmp	cx,1980h	;century roll-over ?
	jae	rtc_date9
	mov	ax,cm_cent*256+20h	;update century register
	call	rtc_write
	mov	ch,20h	;force 2000
rtc_date9: jmp	int1a_ok
	;
	; AH=5: set RTC date
	;
rtc_sdat:	push	cx
	call	rtc_uip	;check for RTC update
	pop	cx
	mov	ax,cm_day*256	;0 -> day of week (not used)
	call	rtc_write
	mov	ah,cm_dd	;DL -> day
	mov	al,dl
	call	rtc_write
	mov	ah,cm_mo	;DH -> month
	mov	al,dh
	call	rtc_write
	mov	ah,cm_yy	;CL -> year
	mov	al,cl
	call	rtc_write
	mov	ah,cm_cent	;CH -> century
	mov	al,ch
	call	rtc_write
	jmp	int1a_ok
	;
	; AH=6: set RTC alarm
	;
rtc_alrm:	mov	ah,cm_b	;read status B
	call	rtc_read
	and	al,20h	;alarm enabled ?
	jnz	int1a_err	;:error
	push	cx	;save CX !
	call	rtc_uip	;check for RTC update
	pop	cx	;restore...
	mov	ah,cm_ssa	;DH -> alarm second
	mov	al,dh
	call	rtc_write
	mov	ah,cm_mma	;CL -> alarm minute
	mov	al,cl
	call	rtc_write
	mov	ah,cm_hha	;CH -> alarm hour
	mov	al,ch
	call	rtc_write
	
	in	al,pic1+1	;read mask register
	and	al,0feh	;enable RTC interrupt (8)
	out	pic1+1,al
	
	mov	ah,cm_b	;read status B
	call	rtc_read
	or	al,20h	;enable alarm
	call	rtc_write
	jmp	int1a_ok
	;
	; AH=7: clear RTC alarm
	;
rtc_snz:	mov	ah,cm_b	;read status B
	call	rtc_read
	and	al,5fh	;disable alarm interrupt
	call	rtc_write
	jmp	int1a_ok
	;
	; AH=0: get time
	;
tm_get:	mov	dx,[m_timer]	;DX = timer low
	mov	cx,[m_timer+2]	;CX = timer high
	mov	al,0
	xchg	al,byte ptr [ds:m_timofl]	;AL = timer overflow, reset flag
	jmp	int1a_ok
	;
	; AH=1: set time
	;
tm_set:	mov	byte ptr [ds:m_timofl],0	;clear timer overflow flag
	mov	word ptr [ds:m_timer],dx	;DX = timer low
	mov	word ptr [ds:m_timer+2],cx	;CX = timer high
	jmp	int1a_ok
	;
	; INT1A dispatch table
	;
	even
int1atab:	dw	tm_get	;AH=0: get time
	dw	tm_set	;AH=1: set time
	dw	rtc_get	;AH=2: get RTC time
	dw	rtc_set	;AH=3: set RTC time
	dw	rtc_date	;AH=4: get RTC date
	dw	rtc_sdat	;AH=5: set RTC date
	dw	rtc_alrm	;AH=6: set RTC alarm
	dw	rtc_snz	;AH=7: clear RTC alarm
	;
	; Clear RTC interrupt, test shutdown byte
	;
	; Be sure to leave cm_test non-zero, as this is used by the
	; master reset code in cs_clr to determine whether to reset
	; the bus.
	;
rtc_test:	mov	al,cm_nmi+cm_c	;clear pending interrupt
	out	cm_idx,al
	out	iowait,al
	in	al,cm_dat

	mov	bx,8000h+cm_nmi+cm_test	;bit to test, test register
rtc_test1: mov	al,bl	;write pattern
	out	cm_idx,al
	out	iowait,al
	mov	al,bh
	out	cm_dat,al
	out	iowait,al
	
	mov	al,bl	;read back
	out	cm_idx,al
	out	iowait,al
	in	al,cm_dat
	out	iowait,al
	cmp	al,bh
	jnz	rtc_test8	;:error - clc -> inverted -> error
	shr	bh,1	;shift pattern right
	jnb	rtc_test1	;:another bit
rtc_test8: cmc		;last bit inverted -> no carry if ok
	ret
	;
	; Wait for RTC UIP bit cleared
	;
	; This bit is set about 250æs before the next update. If clear,
	; we have at least 250æs to read or write the RTC without
	; updates coming in between.
	;
rtc_uip:	mov	cx,1000
	mov	ah,cm_a
rtc_uip1:	cli
	call	rtc_read
	and	al,80h	;UIP ?
	jz	rtc_uip9	;:ok, carry clear
	sti		;give interrupts a chance
	loop	rtc_uip1	;:try again
	mov	ax,cm_a*256+26h	;set 32768 Hz oscillator, 1 ms int
	call	rtc_write	;to restart...
	stc
rtc_uip9:	ret
	;
	; read RTC register [AH] -> AL
	;
rtc_read:	mov	al,ah
	out	cm_idx,al
	out	iowait,al
	in	al,cm_dat
	out	iowait,al
	ret
	;
	; write RTC register AL -> [AH]
	;
rtc_write: xchg	al,ah
	out	cm_idx,al
	out	iowait,al
	xchg	al,ah
	out	cm_dat,al
	ret
	;
	; clock tick (IRQ0)
	;
irq0:	sti		;enable interrupts
	push	ax
	push	dx
	push	ds

ifdef	debug
	call	diag_csip	;debug: display CS:IP on MDA
endif

	xor	ax,ax	;access BIOS segment
	mov	ds,ax

	mov	ax,[m_timer]	;update timer
	mov	dx,[m_timer+2]
	add	ax,1
	adc	dx,0
	cmp	ax,00b2h	;24 hours ?
	jnz	irq0_1
	cmp	dx,0018h
	jnz	irq0_1
	xor	ax,ax	;timer overflow - back to 0
	xor	dx,dx
	mov	byte ptr [ds:m_timofl],1
irq0_1:	mov	word ptr [ds:m_timer],ax
	mov	word ptr [ds:m_timer+2],dx
	
	dec	byte ptr [ds:m_fdcnt]	;floppy motor timer
	jnz	irq0_2	;:not yet
	mov	al,0ch
	mov	dx,fdc_ctrl
	out	dx,al	;turn off motor
	and	byte ptr [ds:m_fdmot],0f0h	;turn off motor bits

irq0_2:	int	1ch	;call user hook
	
	pop	ds
	pop	dx
	mov	al,eoi	;signal end of interrupt
	cli
	out	pic0,al
	pop	ax
	iret
	;
	; RTC interrupt (IRQ8)
	;
irq8:	push	ax
	mov	al,cm_c	;check alarm interrupt bit
	out	cm_idx,al
	out	iowait,al
	in	al,cm_dat
	test	al,20h
	jz	irq8_1
	push	ax
	int	4ah	;call user hook
	pop	ax
irq8_1:	mov	al,eoi	;signal end of interrupt
	out	pic1,al
	out	pic0,al
	pop	ax
	iret
	;
	; Timer initialization -> 18.2 Hz tick
	; Unmask timer and keyboard interrupts
	;
tim_init:	mov	al,36h
	out	timer+3,al
ifdef	TICK_RATE
	mov	al,low(TICK_RATE)	;LSB
	out	timer,al
	mov	al,high(TICK_RATE)	;MSB
	out	timer,al
else
	mov	al,0
	out	timer,al
	out	timer,al
endif

	in	al,pic0+1	;enable timer, keyboard interrupt
	and	al,11111100b
	out	iowait,al
	out	pic0+1,al
	out	iowait,al
	mov	al,eoi
	out	pic0,al
	ret
	;
	; RTC init
	;
rtc_ini:	mov	ah,cm_d	;read status register D
	call	rtc_read
	and	al,80h	;battery low ?
	jz	rtc_ini0	;:yes

	; battery ok - validate the time / date

	mov	ah,2	;get RTC time
	int	1ah
	jb	rtc_ini0	;:error
	mov	al,dh	;validate seconds
	mov	ah,60h
	call	rtc_val
	jb	rtc_ini0	;:bad
	mov	al,cl	;validate minutes	
	mov	ah,60h
	call	rtc_val
	jb	rtc_ini0	;:bad
	mov	al,ch	;validate hours
	mov	ah,24h
	call	rtc_val
	jb	rtc_ini0	;:bad

	mov	ah,4	;get RTC date
	int	1ah
	mov	al,dl	;day
	mov	ah,31h
	call	rtc_val
	jb	rtc_ini0	;:bad
	mov	al,dh	;month
	mov	ah,12h
	call	rtc_val
	jb	rtc_ini0	;:bad
	mov	ax,cx
	cmp	ax,1980h	;minimum 1980
	jb	rtc_ini0
	cmp	ax,2099h	;maximum 2099
	ja	rtc_ini0
	mov	ah,99h	;maximum year
	call	rtc_val
	jb	rtc_ini0	;:bad
	
	mov	ax,cm_dia*256	;clear diag register
	call	rtc_write
	jmp	short rtc_ini2
	
	; battery was low or invalid time - initialize the RTC	

rtc_ini0:	inc	byte ptr [ds:tmp_rtc]	;set RTC failure flag
	mov	si,offset rtc_tab
rtc_ini1:
	cs	lodsw	;get value from table
	call	rtc_write	;write to RTC
	cmp	si,offset rtc_tab9	;end of table ?
	jb	rtc_ini1	;:no
	
	; Set timer tick value from RTC time
	;
	; Please note that there are different algorithms with varying
	; accuracy for doing this, there can be slight time discrepancies
	; depending on what algorithm is used by the OS.
rtc_ini2:
	mov	ah,2	;get RTC time
	int	1ah
	jb	rtc_ini9	;:error
	mov	byte ptr [ds:tmp_ss],dh	;save second for run check
	mov	byte ptr [ds:tmp_mm],cl	;save minute for run check
	;
	mov		al, ch				; get hours
	mov		dl, 4
	shr		al, dl				; get msb bcd hours
	mov		dl, 10
	mul		dl					; ax = binary 10th hours
	and		ch, 0fh				; get lsb bcd hours
	add		ch, al				; ch = hours (binary)
	;
	mov		al, cl				; get minutes
	mov		dl, 4
	shr		al, dl				; get msb bcd minutes
	mov		dl, 10
	mul		dl					; ax = binary 10th minutes
	and		cl, 0fh				; get lsb bcd minutes
	add		cl, al				; cl = minutes
	;
	mov		al, dh				; get seconds
	mov		dl, 4
	shr		al, dl				; get msb bcd seconds
	mov		dl, 10
	mul		dl					; ax = binary 10th seconds
	and		dh, 0fh				; get lsb bcd seconds
	add		dh, al				; dh = seconds
	;
	mov		al, ch				; get hours
	mov		ah, 60
	mul		ah					; ax = hours * 60
	;
	xor 	ch, ch				; cx = minutes
	add		ax, cx				; ax = hours * 60 + minutes
	mov		cl, dh				; cx = seconds
	;
	mov		dx, 60
	mul		dx					; dx:ax = (hours*60 + minutes)*60
	;
	add		ax, cx
	adc		dx, 0				; dx:ax = (hours*60 + minutes)*60 + seconds
	;
	mov		bx, dx				; save msb part
	;
	mov		dx, 18206
	mul		dx					; multiply lsb part 
	;
	;							; store lsb result
	mov 	word ptr [ds:m_timer], ax
	mov	    word ptr [ds:tmp_timer], ax
	;
	mov 	ax, bx				; restore msb part
	mov		bx, dx				; save lsb carry
	mov		dx, 18206
	mul		dx					; multiply msb part
	;
	add		ax, bx				; add msb result and lsb carry
	;							; store lsb result
	mov 	word ptr [ds:m_timer+2], ax
rtc_ini9:
	ret
	;
	; validate a BCD number in AL, AH = limit
	;
rtc_val:	cmp	al,ah	;exceed limit ?
	ja	rtc_val9	;(no carry -> cmc -> error)
	and	al,15	;high digit is ok, now check low digit
	cmp	al,10	;(less than 10 -> carry -> cmc -> ok)
rtc_val9:	cmc		;return error status
	ret
	;
	; Timer & RTC test
	;
tim_test:	mov	ax,[m_timer]	;did we get at least one timer tick ?
	cmp	ax,[tmp_timer]
	jnz	tim_test0	;:ok
	
	; Could fail if floppy and IDE init were super fast. Give it
	; another chance.
	
	mov	bx,60	;wait 60 ms
	call	cs_waitbx
	mov	ax,[m_timer]	;did we get at least one timer tick ?
	cmp	ax,[tmp_timer]
	jz	tim_test8	;no: error

tim_test0: add	ax,20	;wait max. of one second
	xchg	ax,bx
tim_test1: mov	ah,2	;read RTC
	int	1ah
	jb	tim_test8	;:error
	cmp	dh, byte ptr [ds:tmp_ss]	;compare second
	jnz	tim_test9	;:ok
	cmp	cl, byte ptr [ds:tmp_mm]	;compare minute
	jnz	tim_test9	;:ok
	cmp	bx, word ptr [ds:m_timer]	;time-out ?
	js	tim_test8	;:yes
	hlt		;wait for next interrupt
	jmp	tim_test1	;look again

tim_test8: inc	byte ptr [ds:tmp_tim]	;set error flag	
tim_test9: ret
