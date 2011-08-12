	;
	; Printer BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - Doesn't call INT15 function 90FE on busy wait.
	;
	; pd 991003 fixed lp_test loop
	;
	; INT 17 entry
	;
int17:	sti		;reenable interrupts
	push	ds	;save registers
	push	si
	push	bx
	push	cx
	push	dx
	mov	bx,ax	;save AX	
	xor	ax,ax	;access BIOS segment
	mov	ds,ax
	cmp	dx,3	;max port ?
	jae	lp_exit	;:return
	mov	si,dx	;-> table index
	mov	cl,[si+m_lptime]	;get time-out value
	shl	si,1
	mov	dx,[si+m_lpio]	;get I/O port base
	and	dx,dx	;0 -> not present
	jz	lp_exit
	mov	al,bh	;get command code
	and	al,al
	jz	lp_out	;AH=0 -> output character
	dec	ax
	jz	lp_init	;AH=1 -> initialize
	dec	ax
	jz	lp_stat	;AH=2 -> get status
lp_exit:	mov	al,bl	;restore AL
	pop	dx	;restore registers
	pop	cx
	pop	bx
	pop	si
	pop	ds
	iret
	;
	; AH=00: output character
	;
lp_out:	mov	al,bl	;output character
	out	dx,al	;[DX+0]
	inc	dx
	xor	si,si
lp_wait:	in	al,dx	;[DX+1] get status
	mov	ah,al
	and	al,al	;busy ?
	js	lp_ok	;:no
	dec	si
	jnz	lp_wait
	dec	cl
	jnz	lp_wait
	or	ah,1	;time-out
	and	ah,0f9h
	jmp	short lp_out2	;flip bits, exit

lp_ok:	inc	dx
	mov	al,0dh	;activate strobe
	out	dx,al	;[DX+2]
	out	iowait,ax
lp_in2:	mov	al,0ch	;deactivate strobe
	out	dx,al	;[DX+2]
	dec	dx
	dec	dx
	out	iowait,ax
	;
	; get printer status
	;
lp_stat:	inc	dx	;get status
	in	al,dx	;[DX+1]
	and	al,0f8h
	mov	ah,al
lp_out2:	mov	al,bl	;restore AL
	xor	ah,048h
	jmp	lp_exit
	;
	; initialize printer
	;
lp_init:	mov	al,8	;reset printer
	inc	dx
	inc	dx
	out	dx,al	;[DX+2]
	mov	cx,5000	;wait a bit
lp_in1:	loop	lp_in1
	jmp	lp_in2
	;
	; test printer ports
	;
lp_test:	mov	ax,1414h	;init printer time-out
	mov	word ptr [ds:m_lptime],ax
	mov	word ptr [ds:m_lptime+2],ax
	mov	si,offset lp_ports
	mov	di,offset m_lpio	;destination for I/O port
lp_test0:
	cs	lodsw	;get I/O port to test
	and	ax,ax
	jz	lp_test0a	;:end of table
	xchg	dx,ax	;AX -> DX port address
	call	lp_test2	;test the port
	jmp	lp_test0	;try next
	
lp_test0a: mov	dx,2
lp_test1:	mov	ah,1	;init port
	int	17h
	dec	dx
	jns	lp_test1
	ret

lp_test2:	mov	ax,0aa55h	;write test pattern
	out	dx,al
	out	iowait,ax	;invert bus
	out	iowait,ax
	in	al,dx	;read back test pattern
	cmp	al,55h	;correct ?
	jnz	lp_test9	;:no printer
	mov	[di],dx	;store port address
	inc	di
	inc	di
	add	byte ptr [ds:m_devflg+1],40h	;count printer ports in equipment flag
lp_test9:	ret	
