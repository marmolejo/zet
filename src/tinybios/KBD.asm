	;
	; Keyboard BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - Doesn't call INT15 on key wait, system request key
	; - Screen dump is called, but not implemented by BIOS. This function
	;   considered risky for embedded systems, and is also highly
	;   printer specific. Recommend implementation as TSR if required.
	; - We currently don't detect whether the keyboard is enhanced
	;   (101 key) or not. Most keyboards are, so we set the status bit
	;   kb_fkbx.
	;
	; Note:
	;
	; - If interrupt latency is critical, recommend disabling keyboard
	;   LED updates -> comment out option LED_UPDATE.
	;

	;
	; Flag bit definitions
	;

	; m_kbf bits
	
kb_frsh	equ	01h	;right shift pressed
kb_flsh	equ	02h	;left shift pressed
kb_fcsh	equ	04h	;control pressed
kb_fash	equ	08h	;alt pressed
kb_fscrs	equ	10h	;scroll lock active
kb_fnums	equ	20h	;num lock active
kb_fcaps	equ	40h	;caps lock active
kb_finss	equ	80h	;ins active

	; m_kbf1 bits
	
kb_flct	equ	01h	;left control pressed
kb_flal	equ	02h	;left alt pressed
kb_fsys	equ	04h	;system key pressed
kb_fhld	equ	08h	;hold active
kb_fscr	equ	10h	;scroll lock pressed
kb_fnum	equ	20h	;num lock pressed
kb_fcap	equ	40h	;caps lock pressed
kb_fins	equ	80h	;ins key pressed

	; m_kbf2 bits

kb_fled	equ	07h	;led mask
kb_fscrl	equ	01h	;scroll lock led
kb_fnuml	equ	02h	;num lock led
kb_fcapl	equ	04h	;caps lock led
kb_fack	equ	10h	;kbd ACK received
kb_fres	equ	20h	;kbd RESEND received
kb_fcled	equ	40h	;led update
kb_ferr	equ	80h	;kbd transmit error
	
	; m_kbf3 bits

kb_fe1	equ	01h	;e1 prefix was last
kb_fe0	equ	02h	;e0 prefix was last
kb_frct	equ	04h	;right control pressed
kb_fral	equ	08h	;right alt pressed
kb_fkbx	equ	10h	;enhanced kbd installed
kb_fnumf	equ	20h	;force num lock if kbx
kb_fab	equ	40h	;ab read ID was last
;kb_fid	equ	80h	;doing a read ID
	;
	; put keystroke in buffer
	;
putbuf: 	mov 	si,[m_kbtail]
 	mov 	di,si
 	inc 	si
 	inc 	si
 	cmp 	si,[m_kbend]	;end of buffer ?
 	jnz 	pb1	;:no
 	mov 	si,[m_kbstart]	;:restart at beg
pb1: 	cmp 	si,[m_kbhead]	;buffer full ?
 	jz 	pbovr	;:overrun;:yes
 	mov 	[di.bofs],ax	;store keystroke
 	mov 	[ds:m_kbtail],si
 	clc		;ok
 	ret
pbovr: 	stc		;overrun: return error
 	ret
	;
	; wait for AT kbd
	;
waitkbd: 	push 	cx
 	xor 	cx,cx	;timeout
wk1: 	out	iowait,ax
	in 	al,kb_stat	;read status port
 	test 	al,2	;input buffer full ?
 	loopnz 	wk1	;:yes
 	pop 	cx
 	ret
	;
	; disable AT kbd
	;
disakbd: 	cli
 	call 	waitkbd
 	mov 	al,0adh	;disable
 	out 	kb_stat,al
 	sti
 	ret
	;
	; send command to AT kbd
	;
kb_send: 	push 	ax	;save
 	push 	cx
 	mov 	ah,3	;3 retries
sk1: 	cli
 	and 	byte ptr [ds:m_kbf2],kb_fled+kb_fcled+8	;clear error bits
 	push 	ax
 	call 	waitkbd
 	pop 	ax
 	out 	kb_dat,al	;store command
 	sti
 	mov 	cx,2000h	;wait
sk2: 	test 	byte ptr [ds:m_kbf2],kb_fack+kb_fres
 	jnz 	sk4	;:response
 	out	iowait,ax
 	loop 	sk2	;wait
sk3: 	dec 	ah
 	jnz 	sk1	;:another retry
 	or 	byte ptr [ds:m_kbf2],kb_ferr	;set error bit
 	jmp 	short sk9	;done

sk4: 	test 	byte ptr [ds:m_kbf2],kb_fres	;resend flag ?
 	jnz 	sk3	;:retry
sk9: 	cli
 	pop 	cx
 	pop 	ax
 	ret
	;
	; read char from kbd
	;
readchar:
ifndef	XTKBD

 	call 	disakbd
 	cli
 	call 	waitkbd
 	in 	al,kb_dat	;read scan code
 	sti
 	cmp 	al,0feh	;resend ?
 	jz 	rch3	;:yes
 	cmp 	al,0fah	;ack ?
 	jnz 	setled	;:no
 	mov 	al,kb_fack
 	jmp 	short rch4

rch3: 	mov 	al,kb_fres
rch4: 	cli
 	or 	byte ptr [ds:m_kbf2],al
 	pop 	bx
 	jmp 	done

setled:

ifdef	LED_UPDATE
	cli
	push	dx
	mov	dx,pic0
	call	setleds	;set mode LEDs
	pop	dx
endif
 	sti
 	ret

else	;XT keyboard

 	in 	al,kb_dat	;read char
 	xchg 	bx,ax
 	in 	al,port61	;restore kbd
 	mov 	ah,al
 	or 	al,80h
 	out 	port61,al
 	mov 	al,ah
 	out 	port61,al
 	xchg 	bx,ax	;scan code -> AL
 	ret
endif

ifdef	LED_UPDATE
	;
	; update LEDs
	;
setleds:
	push	ax
 	mov 	ah,byte ptr [ds:m_kbf]	;current mode flags
	mov al,4	; we can use al here	
 	rol	ah,al	;-> low bits
 	mov 	al,byte ptr [ds:m_kbf2]	;current LED status
 	and	ax,0707h	;LED bits only
 	cmp 	ah,al	;same ?
 	jz 	setled9	;:done
 	test 	byte ptr [ds:m_kbf2],kb_fcled	;led update pending ?
 	jnz 	setled9	;:yes, don't reenter
 	or 	byte ptr [ds:m_kbf2],kb_fcled	;set update flag
 	mov 	al,eoi	;reset interrupt controller
	out 	dx,al	;(or iowait, depending on DX)
 	mov 	al,0edh	;set mode indicators
 	call 	kb_send	;send kbd command
 	test 	byte ptr [ds:m_kbf2],kb_ferr	;transmit error ?
 	jnz 	setled8	;:yes
 	mov 	al,ah	;send mode
 	call 	kb_send
 	test 	byte ptr [ds:m_kbf2],kb_ferr	;transmit error ?
 	jnz 	setled8	;:yes
 	and 	byte ptr [ds:m_kbf2],255-kb_fled	;set new state
 	or 	byte ptr [ds:m_kbf2],ah
setled8: 	and 	byte ptr [ds:m_kbf2],3fh	;reset update flag
setled9:	pop	ax
	ret
endif
	;
	; invalid key: ignore
	;
kinval: 	ret
	;
	; left shift
	;
kshlt: 	mov 	al,kb_flsh
kshlt1: 	test	byte ptr [ds:m_kbf3],kb_fe0	;did we get E0 prefix ?
	jnz	kshlt2	;yes: ignore (extended key)
	or 	byte ptr [ds:m_kbf],al	;set flag
 	and 	cl,cl	;break ?
 	jns 	kshlt2
 	xor 	byte ptr [ds:m_kbf],al	;:clear flag
kshlt2: 	ret
	;
	; right shift
	;
kshrt: 	mov 	al,kb_frsh
 	jmp 	kshlt1
	;
	; left control
	;
kctlt: 	or 	byte ptr [ds:m_kbf1],kb_flct	;set flag
 	and 	cl,cl	;break ?
 	jns 	kctlt1
 	xor 	byte ptr [ds:m_kbf1],kb_flct	;:clear flag
kctlt1: 	or 	byte ptr [ds:m_kbf],kb_fcsh	;set left & right flag
 	test 	byte ptr ds:[m_kbf1],kb_flct
 	jnz 	kctlt2 	;:ok
 	test 	byte ptr [ds:m_kbf3],kb_frct
 	jnz 	kctlt2	;:ok
 	xor 	byte ptr [ds:m_kbf],kb_fcsh	;clear control flag
 	ret
kctlt2: 	pop 	ax	;don't clear hold flag
 	jmp 	i12
	;
	; right control
	;
kctrt: 	test 	byte ptr [ds:m_kbf3],kb_fe0+kb_fe1	;no E0/E1: caps lock
 	jz 	kcaps
kctrt1: 	or 	byte ptr [ds:m_kbf3],kb_frct	;set flag
 	and 	cl,cl	;break ?
 	jns 	kctlt1
 	xor 	byte ptr [ds:m_kbf3],kb_frct	;:clear flag
 	jmp 	kctlt1
	;
	; left alt
	;
kallt: 	test 	byte ptr [ds:m_kbf3],kb_fe0	;E0: right alt
 	jnz 	kalrt
 	or 	byte ptr [ds:m_kbf1],kb_flal	;set flag
 	and 	cl,cl	;break ?
 	jns 	kallt1
 	xor 	byte ptr [ds:m_kbf1],kb_flal	;:clear flag
kallt1: 	or 	byte ptr [ds:m_kbf],kb_fash	;set left & right flag
 	test 	byte ptr [ds:m_kbf1],kb_flal
 	jnz 	kallt2	;:ok
 	test 	byte ptr [ds:m_kbf3],kb_fral
 	jnz 	kallt2	;:ok
 	xor 	byte ptr [ds:m_kbf],kb_fash	;clear alt flag
 	xor 	ax,ax	;any char entered via alt ?
 	xchg 	al,byte ptr [ds:m_kbnum]
 	and 	al,al
 	jz 	kallt2	;:no
 	call 	putbuf	;put it in buffer
kallt2: 	ret
	;
	; right alt
	;
kalrt: 	or 	byte ptr [ds:m_kbf3],kb_fral	;set flag
 	and 	cl,cl	;break ?
 	jns 	kallt1
 	xor 	byte ptr [ds:m_kbf3],kb_fral	;:clear flag
 	jmp 	kallt1
	;
	; handle toggle keys &pd fixed autorepeat 980115
	;
kcaps:	mov	ch,kb_fcaps	;caps lock
	jmp	short ktog
kscrl:	mov	ch,kb_fscrs	;scroll lock
	jmp	short ktog
knums:	mov	ch,kb_fnums
ktog:	and	cl,cl	;break ?
	jns	knums2	;:no
	not	ch	;clear key pressed flag
	and	byte ptr [ds:m_kbf1],ch
knums1:	ret

knums2:	test	byte ptr [ds:m_kbf1],ch	;already pressed ?
	jnz	knums3	;:don't toggle again
	xor	byte ptr [ds:m_kbf],ch	;toggle numlock flag
knums3:	or	byte ptr [ds:m_kbf1],ch	;set pressed flag
 	ret
	;
	; pause
	;
kpaus: 	and	cl,cl	;break ?
	js	knums1	;:ignore
	test	byte ptr [ds:m_kbf1],kb_fhld	;in hold mode ?
	jnz	knums1	;:yes -> ret
 	or 	byte ptr [ds:m_kbf1],kb_fhld	;set hold flag
 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
 	call	enakbd	;enable keyboard
kpaus1: 	sti		;wait for next event
	hlt
	test 	byte ptr [ds:m_kbf1],kb_fhld	;still on ?
 	jnz 	kpaus1	;yes: hold
 	pop 	ax	;remove return address
 	jmp 	done2	;exit
	;
	; print screen
	;
kprts: 	and	cl,cl
	js	knums1	;:ignore break
	cli
 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
 	int 	5	;do screen dump
 	pop 	ax	;remove return address
 	jmp 	done2	;return
	;
	; reboot system
	;
kboot: 	mov word ptr [ds:m_rstflg],1234h	;set cookie
	;
	db	0EAh			; HARD CODE FAR JUMP TO SET
	dw	offset reset	;  OFFSET
	dw	0F000h			;  SEGMENT
	;
	; system request
	;
ksysr: 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
 	mov 	ax,8500h
 	and 	cl,cl
 	jns 	ksysr1	;:make
 	inc 	ax	;break code
ksysr1:	int 	15h	;sys req interrupt
 	pop 	ax	;remove return address
 	jmp 	done2	;exit
	;
	; break
	;
kbrk:	and	cl,cl	;ignore key release
	js	knums1
	or 	byte ptr [ds:m_brkflg],128	;set break flag
 	mov 	ax,[ds:m_kbstart]	;clear kbd buffer
 	mov 	[ds:m_kbhead],ax
 	mov 	[ds:m_kbtail],ax
 	int 	1bh	;break interrupt
 	xor 	ax,ax
 	jmp 	putbuf	;put break char
	;
	; alt + digit
	;
kdigtab: 	db 	7,8,9,0,4,5,6,0,1,2,3,0

kdig: 	and	cl,cl	;ignore break
	js	kdig1
	test 	byte ptr [ds:m_kbf3],kb_fe0	;E0 prefix ?
	jnz	kdig2	;yes: cursor keys, not Alt-number
	mov 	al,cl
 	mov 	bx,offset kdigtab-47h
 	cs 	xlat
 	mov 	ch,al
 	mov 	al,[ds:m_kbnum]	;old value * 10
 	mov 	ah,10
 	mul 	ah
 	add 	al,ch	;add digit
 	mov 	[ds:m_kbnum],al
kdig1: 	ret
 	
kdig2:	mov	ah,cl	;handle Alt-cursor keys
	add	ah,50h
	mov	al,0
	jmp	putbuf
	;
	; action vector table
	;
vectab: 	dw	kinval	;FFFF = ignore key
 	dw 	kshlt 	;FFFE = left shift
 	dw 	kshrt 	;FFFD = right shift
 	dw 	kctlt 	;FFFC = left control
 	dw 	kctrt 	;FFFB = right control
 	dw 	kallt 	;FFFA = left alt
 	dw 	kalrt 	;FFF9 = right alt
 	dw 	kcaps 	;FFF8 = caps lock
 	dw 	knums 	;FFF7 = num lock
 	dw 	kscrl 	;FFF6 = scroll lock
 	dw 	kpaus 	;FFF5 = pause
 	dw 	kprts 	;FFF4 = print screen
 	dw 	kboot 	;FFF3 = reboot system
 	dw 	ksysr 	;FFF2 = system request
 	dw 	kbrk 	;FFF1 = break
 	dw 	kctrt1 	;FFF0 = right control
 	dw 	kdig 	;FFEF = alt + digit
	;
	; shift offset table
	;
shftab: 	db 	1,3,3,3,5,5,5,5,7,7,7,7,9,9,9,9
	;
	; kbd interrupt routine
	;
irq1: 	sti		;enable interrupt
 	push 	ax	;save registers
	push 	bx
 	push 	cx
 	push 	dx
 	push 	si
 	push 	di
 	push 	ds
 	push 	es
 	cld		;forward direction
 	xor	ax,ax	;BIOS segment
 	mov 	ds,ax
 	call 	readchar
 	stc		;give TSRs an opportunity to grap
 	mov	ah,4fh	;this key: call Int15 AH=4F
 	int	15h
 	jb	irq1a	;:not taken
 	jmp	i11	;skip this key
 	
irq1a: 	mov 	cl,al	;copy scan code
	cmp 	al,0e0h	;prefix code ?
 	jnz 	i1
 	or 	byte ptr [ds:m_kbf3],kb_fe0	;set prefix flag
 	jmp 	done
 	
i1: 	cmp 	al,0e1h	;prefix code ?
 	jnz 	i2
 	or 	byte ptr [ds:m_kbf3],kb_fe1	;set prefix flag
 	jmp 	done
 	
i2: 	cmp 	al,0ffh	;overrun ?
	jnz	i2a	;:no
 	jmp 	overrun
 	
i2a: 	test 	byte ptr [ds:m_kbf1],kb_fhld	;hold mode ?
 	jz 	i3	;:no
 	and 	cl,cl	;make code ?
 	js 	i3	;no - break
 	xor 	byte ptr [ds:m_kbf1],kb_fhld	;clear hold mode
i3: 	and 	al,127	;make = break
 	jz	overrun1	;zero: ignore
 	cmp 	al,maxscan	;too high ?
 	ja 	overrun1	;yes: ignore char
 	mov	ah,11	;11 bytes per key entry
 	mul	ah
 	add	ax,offset kb_tab-11	;add offset of key table
 	mov	si,ax
 	mov 	ah,[cs:si]	;get control byte
 	mov 	al,[ds:m_kbf]	;get shift flag
 	test 	al,kb_flsh+kb_frsh	;shift set ?
 	jz 	i4	;:no
 	or 	al,kb_flsh+kb_frsh	;set both bits
i4: 	shr 	ah,1	;caps lock ?
 	jnb 	i5	;:no
 	test 	al,kb_fcaps
 	jnz 	i6	;:set
i5: 	shr 	ah,1	;num lock ?
 	jnb 	i7	;:no
 	test	byte ptr [ds:m_kbf3],kb_fe0	;E0 prefix ?
 	jz	i5a	;:no
 	and	al,255-kb_flsh-kb_frsh	;extended key - force unshifted scan
 	jmp	short i7
i5a: 	test 	al,kb_fnums
 	jz 	i7	;:not set
i6: 	xor 	al,kb_flsh+kb_frsh	;toggle shift
i7: 	and 	ax,15
 	mov 	bx,offset shftab	;shift state
 	cs 	xlat
 	xchg 	bx,ax	;-> entry offset
 	mov 	ax,[cs:bx+si]	;get scan/action code
 	cmp 	ax,vecmin
 	jb 	ikey	;:scan code
 	not 	ax	;action key: convert to jump vector
 	shl 	ax,1
 	xchg 	bx,ax

 	; Dispatch special keys.

  	mov 	bx,[cs:bx+vectab]	;get vector of special key handler
 	call 	bx	;call special key handler
iact2: 	jmp 	short i11	;done

overrun1:	jmp	short overrun

ikey: 	and 	cl,cl	;is it break ?
 	js 	i11	;yes: ignore
 	
 	test 	byte ptr [ds:m_kbf3],kb_fe0	;E0 prefix ?
 	jz	ikey9	;:no
 	test	al,al
 	jnz	ikey4
 	
 	cmp	ah,96h	;Ctrl * -> Ctrl PrtSc
 	jnz	ikey1
 	mov	ah,72h
 	jmp	short ikey9
 	
ikey1: 	cmp	ah,1ch	;Alt keypad enter -> A600
	jnz	ikey2
	mov	ah,0a6h

ikey2:	cmp	ah,35h	;Alt keypad -> A400
	jnz	ikey3
	mov	ah,0a4h

ikey3:	cmp	ah,84h	;high extended keys -> no change
 	jae	ikey9
 	mov	al,0e0h	;remember this was a extended key
 	jmp	short ikey9

ikey4:	cmp	ah,1ch	;keypad enter ?
	jz	ikey8
	cmp	ah,35h	;keypad / ?
	jnz	ikey9
ikey8:	mov	ah,0e0h	;extended key, translated back by
			;kb_xlat
ikey9: 	call 	putbuf	;put scan code in buffer
 	jnb 	i11	;:ok
overrun: 	cli
 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
 	call 	beep
 	jmp 	short done2
i11:
i12: 	and 	byte ptr [ds:m_kbf3],255-kb_fe0-kb_fe1	;reset prefix flag

ifndef	XTKBD		;if AT

 	cli
 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
 	call 	enakbd
 	jmp 	short done3
endif

done: 	cli
 	mov 	al,eoi	;reset interrupt controller
 	out 	pic0,al
done2 :

ifndef	XTKBD
 	call 	enakbd
endif

done3: 	pop 	es
 	pop 	ds
 	pop 	di
 	pop 	si
 	pop 	dx
 	pop 	cx
 	pop 	bx
 	pop 	ax
 	iret
	;
	; INT 16 entry
	;
int16:	sti		;enable interrupts
	push	bx
	push	cx
	push	dx
	push	ds
	
	xor	dx,dx	;access BIOS segment
	mov	ds,dx
	add	dl,ah	;command code
	jz	kb_get	;AH=00: get key
	dec	dx
	jz	kb_check	;AH=01: check if key available
	dec	dx
	jz	kb_shift	;AH=02: return shift status
	dec	dx
	jz	kb_rate	;AH=03: set repetition rate
	dec	dx
	dec	dx
	jz	kb_write	;AH=05: place scan code in buffer
	sub	dl,11
	jz	kb_extrd	;AH=10: extended read
	dec	dx
	jz	kb_extst	;AH=11: extended status
	dec	dx
	jz	kb_extsh	;AH=12: extended shift status
kb_exit:	pop	ds
	pop	dx
	pop	cx
	pop	bx
	iret
	;
	; AH=00: get key from buffer
	;
kb_get:	call	kb_getch	;get character from buffer
	call	kb_xlat	;translate extended characters
	jb	kb_get	;:extended character, try again
	jmp	kb_exit
	;
	; AH=01: check if key available
	;
kb_check0: call	kb_getch	;skip extended character
kb_check:	call	kb_chk	;check for character
	jz	kb_exitst	;:nothing available
	call	kb_xlat	;check if extended character
	jb	kb_check0	;:extended character, skip
kb_extst2: inc	dx	;clear Z flag
kb_exitst: pop	ds	;exit, flags modified
	pop	dx
	pop	cx
	pop	bx
	retf	2
	;
	; AH=10: extended read
	;
kb_extrd:	call	kb_getch	;get character
	call	kb_exlat	;convert extended codes
	jmp	kb_exit
	;
	; AH=11: extended status
	;
kb_extst:	call	kb_chk	;check status
	jz	kb_exitst	;:nothing, return Z flag
	call	kb_exlat
	jmp	kb_extst2	;return result
	;
	; AH=12: extended shift status
	;
kb_extsh:	xor	ah,ah
	mov	al,[ds:m_kbf1]	;system request shift
	test	al,kb_fsys	;system request ?
	jz	kb_extsh2
	mov	ah,80h	;yes: set bit 7
kb_extsh2: and	al,01110011b
	or	ah,al
	mov	al,[ds:m_kbf3]	;right control and alt keys
	and	al,00001100b
	or	ah,al
	;
	; AH=02: return current shift status
	;
kb_shift:	mov	al,[ds:m_kbf]	;get shift status
	jmp	kb_exit
	;
	; AH=03: set key repetition rate
	;
kb_rate:	cmp	al,5	;correct command ?
	jnz	kb_exit
	cmp	bl,31	;test rate
	ja	kb_exit
	cmp	bh,3	;test delay
	ja	kb_exit
	push	ax	;save AX
	mov al,5	; we can use al here
	shl	bh,al
	mov	al,0f3h	;set repeat rate / delay command
	call	kb_send	;send to keyboard
	mov	al,bl	;combine delay, rate
	add	al,bh
	call	kb_send
	pop	ax	;restore AX
	jmp	kb_exit
	;
	; AH=05: place scan code in buffer
	;
kb_write:	mov	al,1	;error status
	cli		;prevent conflict
	mov	bx,[ds:m_kbtail]	;^kb buffer
	inc	bx	;increment
	inc	bx
	cmp	bx,[ds:m_kbend]  	;at end ?
	jnz	kb_write2
          mov	bx,[ds:m_kbstart]	;yes: go to start
kb_write2: cmp	bx,[ds:m_kbhead]	;buffer full ?
	jz	kb_write3	;:yes
	xchg	bx,[ds:m_kbtail]	;update tail, get old value
	dec	ax	;clear AL
	mov	[ds:bx+bofs],cx	;store scan code
kb_write3: sti		;end of critical section
	jmp	kb_exit
	;
	; get scan code from buffer
	;
kb_getch0: sti		;reenable interrupts
	hlt		;wait for next event
kb_getch:	cli		;critical section
	mov	bx,[m_kbhead]	;^head of buffer
	cmp	bx,[m_kbtail]	;= tail of buffer ?
	jz	kb_getch0	;yes: wait
	mov	ax,[bx+bofs]	;get scan code
	inc	bx	;increment pointer
	inc	bx
	cmp	bx,[m_kbend]  	;at end ?
	jnz	kb_getch2
          mov	bx,[ds:m_kbstart]	;yes: go to start
kb_getch2: mov	[ds:m_kbhead],bx	;update pointer
	sti		;end of critical section
	ret
	;
	; check if there is anything in buffer (Z set if not)
	;
kb_chk:	cli		;critical section
	mov	bx,[m_kbhead]	;^head of buffer
	cmp	bx,[m_kbtail]	;= tail of buffer ?
	sti		;end of critical section
	mov	ax,[bx+bofs]	;get scan code
	ret
	;
	; check if extended character, set C if yes
	;
kb_xlat:	cmp	ah,84h	;extended ?
	jbe	kb_xlat83
	cmp	ah,0e0h
	jnz	kb_stc1	;:bad
	mov	ah,1ch	;keypad Enter fixed code
	cmp	al,13	;keypad Enter ?
	jz	kb_xlatok	;:yes
	cmp	al,10	;keypad ^Enter
	jz	kb_xlatok	;:yes
	mov	ah,35h	;keypad /
	jmp	short kb_xlatok
	
kb_xlat83: cmp	ax,00e0h	;extension ?
	jz	kb_xlatok
	cmp	ax,00f0h
	jz	kb_xlatok
	cmp	al,0f0h	;fill-in ?
	jz	kb_stc1
	cmp	al,0e0h
	jnz	kb_xlatok
	mov	al,0
kb_xlatok: clc		;ok to use
	ret
	
kb_stc1:	stc		;extended code - bad
	ret
	;
	; translate extended characters
	;
kb_exlat:	cmp	al,0f0h	;special ?
	jnz	kb_exlat2
	or	ah,ah	;0: more special
	jz	kb_exlat2
	mov	al,0
kb_exlat2: ret
	;
	; initialize keyboard controller
	;
kb_ini:

ifndef	XTKBD

ifdef	NO_KBC		;bail quickly if no KBC present
	in	al,kb_stat	;check status
	cmp	al,0ffh	;nothing ?
	jnz	kb_ini0
	mov	byte [tmp_kbc],0ffh	;set flag - KBC not present
	stc
	ret
kb_ini0:
endif
	xor	cx,cx
kb_ini1:	in	al,kb_stat	;check status
	mov	bl,al
	and	al,1	;buffer full ?
	jz	kb_ini2
	in	al,kb_dat	;flush data
kb_ini2:	and	bl,2
	jz	kb_ini3	;:empty
	loop	kb_ini1
kb_ini9:	stc		;error
	ret
	
kb_ini3:	mov	al,0aah	;self test command
	call	kb_cmd
	jb	kb_ini9	;:timeout
	call	kb_read	;wait for data
	jb	kb_ini9
	cmp	al,55h	;expect $55 response
	jnz	kb_ini9
	
	mov	al,0abh	;test interface
	call	kb_cmd
	jb	kb_ini9	;:timeout
	call	kb_read	;wait for data
	jb	kb_ini9
	cmp	al,0	;expect 0 response
	jnz	kb_ini9

	mov	al,60h	;write mode register
	call	kb_cmd
	jb	kb_ini9
	mov	al,6dh 	;initial mode (keep system flag off,
			;disable mouse interface)
	call	kb_writ
	jb	kb_ini9

else	;XT keyboard

	in	al,port61
	out	iowait,ax
	or	al,0c0h	;set reset bit
	out	port61,al
	out	iowait,ax
	and	al,7fh	;clear reset bit
	out	port61,al
endif
kb_clc1:	clc		;ok
	ret
	;
	; send keyboard command AL
	;
kb_cmd:	out	kb_stat,al	;send command
kb_cmd1:	out	iowait,ax
	;
	; wait until input (to 8042) buffer empty, C if timeout
	;	
kb_ibf:	xor	cx,cx
kb_ibf2:	out	iowait,ax
	in	al,kb_stat
	and	al,2	;input buffer full ?
	jz	kb_clc1	;:ok return
	loop	kb_ibf2
	stc
	ret
	;
	; send keyboard data AL
	;
kb_writ:	out	kb_dat,al
	jmp	kb_cmd1
	;
	; wait until output (from 8042) buffer full, read data -> AL
	;	
kb_read:	xor	cx,cx
kb_obf2:	out	iowait,ax
	in	al,kb_stat
	and	al,1	;output buffer full ?
	jnz	kb_obf3
	loop	kb_obf2
	stc
	ret
	
kb_obf3:	in	al,kb_dat
	clc
	ret
	;
	; second keyboard initialization (after base memory test)
	;
kb_inb:	

ifdef	NO_KBC		;skip if no KBC present
	ror	byte [tmp_kbc],1
	jb	kb_inb9
endif

	call	kb_ibf	;wait for 8042 ready
	
	in	al,kb_stat	;anything in 8042 output buffer ?
	and	al,1
	jz	kb_inb2	;:no
	in	al,kb_dat
	mov	[ds:tmp_kbd],al	;save keyboard response
	cmp	al,0aah	;keyboard test ok ?
	jz	kb_inb9	;:yes, don't reset again

kb_inb2:	mov	al,0ffh	;reset keyboard
	out	kb_dat,al
	call	kb_read	;get acknowledge

kb_inb9: 	mov 	byte ptr [ds:m_kbf],kb_fnums	;set Numlock
	mov	byte ptr [ds:m_kbf3],kb_fkbx	;assume enhanced keyboard
 	mov	ax,m_kbbuf-bofs	;initialize keyboard buffer pointers
 	mov 	[ds:m_kbstart],ax
 	mov 	[ds:m_kbhead],ax
 	mov 	[ds:m_kbtail],ax
 	mov 	word ptr [ds:m_kbend],m_kbbuf9-bofs
	ret
	;
	; third keyboard initialization (after extended memory test)
	;
kb_inc:	
ifdef	NO_KBC		;skip if no KBC present
	ror	byte ptr [ds:tmp_kbc],1
	jnb	kb_inc1
	ret
kb_inc1:
endif
	cmp	byte ptr [ds:tmp_kbd],0aah	;keyboard reset ok ?
	jz	kb_inc2	;:yes
	call	kb_read	;wait until data in buffer
	jb	kb_err
	cmp	al,0aah	;AA = keyboard response
	jz	kb_inc2	;:ok
kb_err:
;	jb	kb_err2	;&
;	call	hexbyt	;&
;kb_err2:			;&
	inc	byte ptr [ds:tmp_kbfail]
ifndef	NO_KBC
	mov	si,offset msg_kbd	;"Keyboard failure"
	call	v_msg
endif
kb_inc2:	call	kb_ibf	;wait for 8042 ready
	mov	al,0f4h	;enable keyboard
	out	kb_dat,al
	jmp	kb_read	;get acknowledge
	;
	; set keyboard LEDs, enable keyboard
	;
kb_ind:	
ifdef	NO_KBC		;skip if no KBC present
	ror	byte [tmp_kbc],1
	jnb	kb_ind1
	ret
kb_ind1:
endif

ifdef	KEY_RATE
	mov	ax,0305h	;set keyboard repeat rate
	mov	bx,KEY_RATE
	int	16h
endif
	
	call	disakbd	;disable keyboard interface

ifdef	LED_UPDATE
	mov	dx,iowait
	call	setleds	;set keyboard LEDs
endif
	;-> fall through
	;
	; enable AT kbd
	;
enakbd: 	cli
 	call 	waitkbd
 	mov 	al,0aeh
 	out 	kb_stat,al
 	sti
 	ret
