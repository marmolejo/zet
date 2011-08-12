	;
	; Serial BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; pd010207 integrate serial console support here
	; pd991127 fix m_devflg
	;
	; Serial console notes:
	;
	; Variable CONSOLE must be equal to the I/O port of the COM port used.
	; Define CONINT=3 or CONINT=4 to select the serial port interrupt.
	; VGA BIOS will take over Int 10, and inhibit serial console output.

ifndef	COM_INIT	;default value:
COM_INIT	equ	11100011b	;9600 8N1 serial port initialization
endif
	;
	; INT 14 entry
	;
int14:	sti		;reenable interrupts
	push	ds	;save registers
	push	si
	push	dx
	push	cx
	push	bx
	mov	bx,ax	;save AX
	xor	ax,ax	;access BIOS segment
	mov	ds,ax
	cmp	dx,4	;max port ?
	jae	rs_exit	;:return
	mov	si,dx	;-> table index
	mov	cl,[si.m_rstime]	;get time-out value
	shl	si,1
	mov	dx,[si.m_rsio]	;get I/O port base
	and	dx,dx	;0 -> not present
	jz	rs_exit
	mov	al,bh	;get command code
	and	al,al
	jz	rs_init	;AH=0 -> initialize
	dec	ax
	jz	rs_xmit	;AH=1 -> transmit
	dec	ax
	jz	rs_recv	;AH=2 -> receive
	dec	ax
	jz	rs_stat	;AH=3 -> get status
rs_exit:	pop	bx	;restore registers
	pop	cx
	pop	dx
	pop	si
	pop	ds
	iret
	;
	; AH=0: initialize serial port
	;
rs_init:	mov	al,bl	;AH=0; get baud rate
	push cx
	mov cl, 4
	shr	al,cl	;-> table index
	pop cx
	and	al,1110b
ifdef	CONSOLE
	cmp	dx,CONSOLE	;console ?
	jz	rs_stat	;if yes, don't let DOS change the
			;parameters
endif
	mov	si,ax
	add	dl,3
	mov	al,80h	;base+3 DLAB=1: access baud rate register
	out	dx,al
	dec	dx
	dec	dx
	mov	ax,word ptr [cs:si+rs_baud]	;get baudrate
	out	dx,al	;base+1 baudrate MSB
	mov	al,ah
	dec	dx
	out	dx,al	;base+0 baudrate LSB
	add	dl,3
	mov	al,bl
	and	al,1fh	;set parameters
	out	dx,al	;base+3
	dec	dx
	dec	dx
ifdef	CONSOLE		;don't disable interrupt on console
	in	al,dx	;base+1
	and	al,1
	cmp	dx,CONSOLE+1
	jz	rs_init1
endif
	mov	al,0	;disable interrupts
rs_init1:	out	dx,al	;base+1
	dec	dx	;base+0
	;
	; AH=3: get status
	;
rs_stat:	add	dl,5
	in	al,dx
	mov	ah,al
	inc	dx
	in	al,dx
	jmp	rs_exit
	;
	; AH=1: transmit character
	;
rs_xmit:	mov	al,3	;modem control: set DTR, RTS
	add	dl,4
	out	dx,al
	inc	dx                	;modem status: wait for DSR, CTS
	inc	dx
	mov	bh,30h	
	call	rs_wait
	jnz	rs_xmtime	;:time-out
	dec	dx
	mov	bh,20h	;line status: wait for xmit ready
	call	rs_wait
	jnz	rs_xmtime
	sub	dl,5
	mov	al,bl	;character to send
	out	dx,al	;send it
	jmp	rs_exit
	;
	; time-out error
	;
rs_xmtime: mov	al,bl	;restore character
rs_rxtime: or	ah,80h	;set time-out flag
	jmp	rs_exit
	;
	; AH=2: receive character
	;
rs_recv:	mov	al,1	;modem control: set DTR
	add	dl,4
	out	dx,al
	inc	dx	;modem status: wait for DSR
	inc	dx
	mov	bh,20h
	call	rs_wait
	jnz	rs_rxtime	;:time-out
	dec	dx
	mov	bh,1	;line status: wait for receive data
	call	rs_wait
	jnz	rs_rxtime	;:time-out
	and	ah,1eh	;mask status
	and	dl,0f8h	;receive register
	in	al,dx	;read character
	jmp	rs_exit	;exit
	;
	; serial port wait
	;
rs_wait:	mov	ch,cl	;copy time-out value
	xor	si,si	;clear counter
rs_wait2:	in	al,dx
	mov	ah,al	;save status
	and	al,bh	;check status
	cmp	al,bh	;set ?
	jz	rs_wait9	;:yes
	dec	si
	jnz	rs_wait2	;:try again
	dec	ch
	jnz	rs_wait2
	or	bh,bh	;time-out
rs_wait9:	ret
	;
	; test & initialize serial ports
	;
rs_test:	mov	ax,0101h	;init serial port time-out
	mov	word ptr [ds:m_rstime],ax
	mov	word ptr [ds:m_rstime+2],ax
	
	mov	di,m_rsio	;destination for I/O port value
	mov	si,offset rs_ports	;port addresses
rs_test1:	lods 	word ptr [cs:si]	;get port address
	and	ax,ax	;end of table ?
	jz	rs_test3	;:end
	xchg	dx,ax	;AX -> DX, points to scratch register
	mov	ax,0aa55h
	out	dx,al
	out	iowait,ax	;invert bus
	out	iowait,ax
	in	al,dx
	cmp	al,55h	;pattern ok ?
	jnz	rs_test1	;:no, port not present, try next
	and	dl,0f8h	;clear low bits of I/O address
	mov	[di],dx	;write port address
	inc	di
	inc	di
	add	byte ptr [ds:m_devflg+1],2	;increment serial port count
	cmp	di,m_rsio+8	;space for more ports ?
	jnz	rs_test1	;:yes
rs_test3:	mov	dx,3	;init serial ports
rs_test4:	mov	ax,COM_INIT
	int	14h
	dec	dx
	jns	rs_test4
	ret
	;
	; serial port console
	;
ifdef	CONSOLE

con_init:	mov	byte [m_conkey],0	;clear key buffer
	mov	byte [m_console],0	;disable serial console

	; hook serial interrupt

	cli		;set INT 3 vector = COM2
	xor	ax,ax
	mov	ds,ax
if (CONINT = 3)
	mov	word [11*4],con_int
	mov	word [11*4+2],cs
endif
if (CONINT = 4)
	mov	word [12*4],con_int
	mov	word [12*4+2],cs
endif
	sti

	mov	dx,CONSOLE
	in	al,dx	;clear receive buffer
	out	iowait,ax
	mov	dl,low(CONSOLE+1)
	mov	al,1	;enable receive interrupt
	out	dx,al
	out	iowait,ax
	mov	dl,low(CONSOLE+4)	;enable interrupt driver
	in	al,dx
	or	al,8
	out	dx,al

	in	al,pic0+1	;enable serial interrupt (int 3)
if (CONINT = 3)
	and	al,0f7
endif
if (CONINT = 4)
	and	al,0ef
endif
	out	iowait,ax
	out	pic0+1,al

	mov	byte [m_conkey],0	;clear key buffer
	mov	byte [m_console],1	;set serial console flag
	ret
	;
	; serial interrupt handler for serial console
	;
con_int:	pusha
	push	ds
	xor	ax,ax
	mov	ds,ax
	
	mov	dx,CONSOLE	;read data
	in	al,dx
	test	byte [m_console],1	;serial console enabled ?
	jz	con_int49	;:no, ignore
	
	; we need to handle Esc xx and Esc Esc sequences to emulate
	; function / cursor keys
	
	xor	ah,ah	;clear high part of scan code
	cmp	al,27	;escape ?
	jz	con_int41
	cmp	byte [m_conkey],1	;Esc previous character ?
	jb	con_int48	;0: take this key
	jz	con_int43	;store key, need another for sequence
	mov	ah,al	;current key -> AH
	mov	al,[m_conkey]	;previous key -> AL
	mov	si,offset ansitab
	mov	cx,(ansitab9-ansitab) / 4
con_int44: cmp 	ax,[cs:si]	;compare with sequence
	jz	con_int45
	lea	si,[si+4]	;skip to next
	loop	con_int44	;try next
	jmp	short con_int47	;not found - skip

con_int45: mov 	ax,[cs:si+2]	;get scan code from table
con_int48: call	putbuf	;place in keyboard buffer	
con_int47: mov	byte [m_conkey],0	;clear key buffer
	
con_int49: mov	al,eoi	;end of interrupt
	out	pic0,al
	pop	ds
	popa
	iret

	; handle escape

con_int41: cmp	byte [m_conkey],1	;Esc previous key ?
	jz	con_int48	;yes: enter escape
	mov	byte [m_conkey],1	;set escape flag
	jmp	con_int49
	
con_int43: mov	byte [m_conkey],al	;store key
	jmp	con_int49	;skip
	;
	; ANSI to scan code translation table
	;
	even
ansitab:	db	"OP",000,03b	;F1
	db	"OQ",000,03c	;F2
	db	"Ow",000,03d	;F3
	db	"Ox",000,03e	;F4
	db	"Ot",000,03f	;F5
	db	"Ou",000,040	;F6
	db	"Oq",000,041	;F7
	db	"Or",000,042	;F8
	db	"Op",000,043	;F9 (F10 gives same)
	db	"[A",000,048	;cursor up
	db	"[B",000,050	;cursor down
	db	"[D",000,04b	;cursor left
	db	"[C",000,04d	;cursor right
	db	"[H",000,047	;home
	db	"[K",000,04f	;end
ansitab9:
endif	;CONSOLE
