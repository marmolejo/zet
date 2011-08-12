	;
	; Debug routines - don't include for production version
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
ifdef	DEBUG
	;
	; display a hex byte on first line of screen
	;
diaghex:	push	ds
	push	es
	push	ax
	push	di
	xor	di,di
	mov	ds,ax
	mov	ah,al	;save AL
	mov	di,vidseg
	mov	es,di
	mov	di,[tmp_diag]
	mov 	word [es:di]," "	;clear current mark
	cmp	di,1000	;156	;limit ?
	jb	diaghex1
	xor	di,di
diaghex1:	inc	di
	inc	di
	shr	al,4	;display high nibble
	call	diaghex2
	mov	al,ah	;display low nibble
	call	diaghex2
	
	mov	al,"*"	;mark current location
	mov 	[es:di],al
	mov	[tmp_diag],di
	
	pop	di
	pop	ax
	pop	es
	pop	ds
	ret

diaghex2:	and	al,15	;display a byte
	cmp	al,10
	jb	diaghex3
	add	al,7
diaghex3:	add	al,"0"
	mov 	[es:di],al
	inc	di
	inc	di	;skip attribute byte
	ret
	;
	; display a hex byte -> INT 10
	;
hexbyt:	push	ax
	shr	al,4
	call	hexout
	pop	ax
		
hexout:	push	ax
	and	al,15
	cmp	al,10
	jb	hexout2
	add	al,7
hexout2:	add	al,"0"
	mov	bl,0
	mov	ah,0eh
	int	10h
	pop	ax
	ret	
	;
	; get key and display scan code
	;
scancode:	mov	ah,0	;get key
	int	16h
	push	ax
	mov	al,ah
	call	hexbyt
	pop	ax
	call	hexbyt
	mov	al,13
	mov	bl,0
	mov	ah,0eh
	int	10h
	jmp	scancode
	;
	; display word AX at screen location [BX]
	;
diagword:	push	ax
	mov	al,ah
	call	diagbyte
	pop	ax
diagbyte:	push	ax
	shr	al,4
	call	diagnib
	pop	ax
diagnib:	and	al,15
	cmp	al,10
	jb	diagnib2
	add	al,7
diagnib2:	add	al,"0"
	mov	[bx],al
	inc	bx
	inc	bx
	ret	
	;
	; display registers [BP]
	;
v_dump:	pusha
	mov	ax,[bp._ax]
	call	hex
	mov	ax,[bp._bx]
	call	hex
	mov	ax,[bp._cx]
	call	hex
	mov	ax,[bp._dx]
	call	hex
	mov	ax,[bp._es]
	call	hex
	mov	si,offset msg_arr
	call	v_msg
	popa
	ret
	;
	; display registers [BP]
	;
v_dump2:	pusha
	pushf
	mov	ax,[bp._ax]
	call	hex
	mov	ax,[bp._bx]
	call	hex
	mov	ax,[bp._cx]
	call	hex
	mov	ax,[bp._dx]
	call	hex
	mov	si,offset msg_cr
	test	byte [bp+18h],1	;carry ?
	jz	v_dump3	;no: ok
	mov	al,[m_fdfile]
	call	hex2
	mov	al,[m_fdfile+1]
	call	hex2
	mov	al,[m_fdfile+2]
	call	hex2
	mov	si,offset msg_cy
v_dump3:	call	v_msg
	popf
	popa
	ret
	
msg_arr:	db	" -> ",0
msg_cy:	db	" CY"
msg_cr:	db	13,10,0
          ;
          ; display hex word
          ;
hex:	push	ax
	mov	al,ah
	call	hexb
	pop	ax
hex2:	call	hexb
	mov	al," "
	jmp	short putc
	
hexb:	push	ax
	shr	al,4
	call	hexn
	pop	ax
hexn:	and	al,15
	cmp	al,10
	jb	hexn2
	add	al,7
hexn2:	add	al,"0"
putc:	mov	ah,0eh
	mov	bh,0
	int	10h
	ret
	;
	; display CS:IP on video
	;
diag_csip: mov	ax,vidseg	;increment video location
	mov	ds,ax
	inc	byte [158]	;end of first text line
	
	push	bp	;display current address
	mov	bp,sp
	push	bx
	mov	ax,[bp+10]	;CS:
	mov	bx,0
	call	diagword
	mov	byte [bx],":"
	inc	bx
	inc	bx
	mov	ax,[bp+8]	;IP
	call	diagword
	pop	bx
	pop	bp
	ret
	;
	; Debug messages
	;
deb_dskch: db	"Disk change",13,10,0

endif	;DEBUG
