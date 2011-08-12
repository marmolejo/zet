	;
	; Hercules monochrome video BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - No CGA / graphics support - CGA cards / monitors are no longer
	;   available. VGA is handled by separate BIOS anyway, Hercules
	;   support is mainly for debug purposes.
	; - No light pen support
	; - No print screen function (risky for embedded systems)
	; - Video mode ignored (monochrome only supports 80x25)
	; - INT 1D (pointer to video parameters) not supported.
	; - Font not supported.
	; - Historic entry points not supported.
	; - INT 1F extended font not supported.
	; - AH=13 Write string not supported (AT only)
	;
	
	;
	; Initialize text mode
	;
vid_init:	mov	al,21h	;disable video, high res bit
	mov	dx,crtc+4
	out	dx,al

	mov	si,offset v_parm	;set text mode
	mov	bl,0
	mov	dx,crtc
hercloop:	mov	al,bl
	out	dx,al
	inc	dx
	cs	lodsb	
	out	dx,al
	dec	dx
	inc	bx
	cmp	bl,16
	jb	hercloop

	mov	ax,vidseg	;clear screen
	mov	es,ax
	mov	ax,vid_fill	;fill value
	mov	cx,2048
	mov	di,0
	rep	stosw
	
	mov	al,29h	;enable video
	mov	dx,crtc+4
	out	dx,al
	ret
	;
	; initialize video variables
	;
vid_vars:	mov	word ptr [ds:m_vcrt],crtc	;video I/O port
	mov	si,offset v_parm	;video parameters
	mov	byte ptr [ds:m_vpgno],0	;page number = 0
	mov	byte ptr [ds:m_vmsel],29h	;mode register shadow
	mov	byte ptr [ds:m_vpal],30h	;palette shadow
	mov	word ptr [ds:m_vmode],7	;force mode 7
	mov	word ptr [ds:m_vcol],80	;80 columns per line
	mov	word ptr [ds:m_vrow],24	;25-1 rows
	mov	word ptr [ds:m_vpgsz],2048	;video page size
	push	ds           	;clear video positions per page
	pop	es
	mov	di,offset m_vpage  	;& m_vcolrow
	xor	ax,ax
	mov	cx,9	;also set page offset
	rep	stosw
	mov	ax,0b0ch	;m_vcursor cursor end line, start line
	stosw
	mov	al,0
	stosb		;m_vpgno
	ret
	;
	; INT 10 entry
	;
int10:	cmp	ah,10h	;max command code
	jae	int10_ret
	sti
	cld		;forward mode
	push	ds
	push	es
	PUSH_A
	xor	si,si	;DS = BIOS segment
	mov	ds,si
	mov	si,vidseg
ifdef	VID_CGA
	cmp	byte [m_vcrt],0d4h	;CGA ?
	jnz	vid_cga1
	mov	si,0b800h	;CGA segment
vid_cga1:
endif
	mov	es,si
	mov	si,ax	;calculate jump table vector
	mov cl, 7
	shr	si,cl
	jmp	[cs:si+int10_tab]	;jump to individual routine

int10_ret: iret
	;
	; video dispatch table
	;
	even

int10_tab: dw	v_mode	;00 = set video mode
	dw	v_cursor	;01 = set cursor characteristics
	dw	v_setcur	;02 = set cursor position
	dw	v_getcur	;03 = get cursor position
	dw	v_getpen	;04 = get light pen position
	dw	v_setpage	;05	= set display page
	dw	v_scrlup	;06 = scroll up
	dw	v_scrldn	;07 = scroll down
	dw	v_rdattr	;08 = read character attribute
	dw	v_wrattr	;09 = write character attribute
	dw	v_wrchar	;0A = write character
	dw	v_exit	;0B = set palette
	dw	v_exit	;0C = write pixel
	dw	v_exit	;0D = read pixel
	dw	v_tty	;0E = write TTY
	dw	v_stat	;0F = read video status
	;
	; AH=00: set video mode
	;
v_mode:
ifdef	VID_CGA
	cmp	byte [m_vcrt],0d4h	;CGA mode ?
	jz	v_mode9	;:bail
endif
	call	vid_init	;initialize video
	call	vid_vars	;set video variables
v_mode9:	jmp	v_exit	;return
	;
	; video mode settings
	;
v_parm:	db	61h,50h,52h,0Fh,19h,06h,19h,19h,02h,0Dh,0Bh,0Ch,0,0,0,0
	;
	; AH=01: set cursor characteristics
	;
v_cursor:	mov	word ptr [ds:m_vcursor],cx	;save cursor value
	mov	al,10
	jmp	v_set
	;
	; AH=02: set cursor position
	;
v_setcur:	mov	bl,0	;page number -> index
	mov	si,bx
	mov cl,7
	shr	si,cl
	mov	[si+m_vcolrow],dx	;save position
	cmp	byte ptr [ds:m_vpgno],bh	;same page ?
	jnz	v_setc2	;:no
	jmp	v_tty3	;set cursor
v_setc2:	jmp	v_exit
	;
	; AH=03: get cursor position
	;
v_getcur:	mov	bp,sp	;access stack frame
	mov	bl,0	;page number -> index
	mov cl,7
	shr	bx,cl
	mov	ax,[bx+m_vcolrow]	;get cursor pos from table
	mov	[bp._dx],ax	;-> DX
	mov	ax,[m_vcursor]	;cursor shape
	mov	[bp._cx],ax	;-> CX
	jmp	v_exit
	;
	; AH=04: get light pen position
	;
	; anyone remember what a light pen looks like ? ;-)
	;
v_getpen:	mov	bp,sp	;access stack frame
	mov	byte ptr [ds:bp._ah],0	;not activated -> AH
	jmp	v_exit
	;
	; AH = 05: set video page
	;
v_setpage: mov byte ptr [ds:m_vpgno],al	;page number
	shl	ax,1
	mov	bx,ax	;table index
	mov cl,11
	shl	ax,cl
	mov	word ptr [ds:m_vpage],ax	;page offset
	shr	ax,1
	mov	cx,ax
ifdef	VID_CGA
	mov	dx,[m_vcrt]
else
	mov	dx,crtc
endif
	mov	al,12 	;set display offset
	mov	ah,ch
	out	dx,ax
	inc	ax
	mov	ah,cl
	out	dx,ax
	mov	dx,[bx+m_vcolrow]	;page cursor position
	jmp	v_tty3	;set cursor position
	;
	; AH=06: scroll window up
	;
v_scrlup:	mov	bl,dh	;row difference
	sub	bl,ch
	sub	bl,al	;- scroll count
	inc	bl	;+1 -> number of lines to scroll
	sub	dl,cl	;character count
	inc	dl
	mov	dh,al	;number of lines to clear
	mul	byte ptr [ds:m_vcol]	;scroll count
	add	ax,ax
	mov	si,ax	;-> start offset
	mov	al,ch	;start row
	mul	byte ptr [ds:m_vcol]	;* columns
	add	al,cl	;add start column
	adc	ah,0
	add	ax,ax
	add	ax,[m_vpage]	;+ page offset
	mov	di,ax	;DI = destination offset
	add	si,ax	;add to SI -> source offset
	mov	ax,[m_vcol]	;calculate line skip
	sub	al,dl
	add	ax,ax
	mov	bp,ax
	;
	; AX = fill character
	; BL = lines to scroll
	; DL = character count
	; DH = lines to clear
	; SI = source offset
	; DI = destination offset
	; BP = columns per line - character count
	;
v_scroll:	mov	al," "	;fill pattern
	mov	ah,bh
	xor	cx,cx
	and	dh,dh	;0 lines to clear ?
	jz	v_scroll2
	push	es
	pop	ds
v_scroll1: mov	cl,dl	;character count
	rep	movsw	;scroll a line
	add	si,bp	;go to next line
	add	di,bp	
	dec	bl
	jnz	v_scroll1	;:another line
	mov	bl,dh
v_scroll2: mov	cl,dl	;character count
	rep	stosw	;clear a line
	add	di,bp
	dec	bl
	jnz	v_scroll2
	jmp	v_exit
	;
	; AH=07: scroll window down
	;
v_scrldn:	sub	dl,cl	;number of characters
	inc	dl
	mov	bl,dh	;row difference
	sub	bl,ch
	sub	bl,al	;- scroll count
	inc	bl	;+1 -> number of lines to scroll
	mov	ch,al	;number of lines to clear
	mul	byte ptr [ds:m_vcol]	;scroll count
	add	ax,ax
	neg	ax
	mov	si,ax	;-> start offset
	mov	al,dh	;end row
	mul	byte ptr [ds:m_vcol]	;* columns
	add	al,cl	;add start column
	adc	ah,0
	add	ax,ax
	add	ax,[m_vpage]	;+ page offset
	mov	di,ax	;DI = destination offset
	add	si,ax	;add to SI -> source offset
	mov	ah,0	;calculate line skip
	mov	al,dl	;- characters per line - window width
	add	ax,[m_vcol]	;(move is forward)
	add	ax,ax
	neg	ax
	mov	bp,ax
	mov	dh,ch	;number of lines to clear
	jmp	v_scroll	;do the actual scroll
	;
	; AH=08: read character + attribute
	;
v_rdattr:	call	v_pos	;calculate position
	mov	bp,sp
	mov 	ax,[es:di]	;read character
	mov	[bp._ax],ax	;-> AX
	jmp	v_exit
	;
	; calculate video offset
	;
	; -> DI offset
	; -> AX character, attribute
	; -> SI page number * 2
	;
v_pos:	mov	dh,bl	;attribute
	mov	dl,al	;character
	mov	di,bx	;save BX &pd 980406 fixed
	mov	bl,0	;page -> index
	mov	si,bx
	mov cl, 7
	shr	si,cl
	mov	ax,[si+m_vcolrow]	;get cursor position for page
	mov cl, 4
	shl	bx,cl	;-> page offset
	add	bl,al	;column offset
	adc	bl,0
	mov	al,ah	;row offset
	mul	byte ptr [ds:m_vcol]
	add	bx,ax
	add	bx,bx
	xchg	di,bx	;-> page offset, restore BX
	mov	ax,dx	;restore character, attribute
	ret
	;
	; AH=09: write character + attribute
	;
v_wrattr:	call	v_pos	;calculate position
	rep	stosw	;write characters
	jmp	short v_exit
	;
	; AH=0A: write character only, no attribute
	;
v_wrchar:	call	v_pos	;calculate position
v_wrc1:	stosb
	inc	di
	loop	v_wrc1
	jmp	short v_exit
	;
	; AH=0E: write character TTY
	;	
v_tty:

ifdef	CONSOLE

	; serial port console
	;
	; if m_vpal bit 0 is set, we copy characters to the console.

	test	byte [m_console],1	;serial port redirect ?
	jz	v_ttys9	;:no
	push	dx
	push	ax
	mov	dx,CONSOLE+5
v_ttys1:	in	al,dx    	;wait for transmit ready
	out	iowait,ax
	test	al,40h
	jz	v_ttys1
	mov	dl,low(CONSOLE)
	pop	ax
	out	dx,al
	pop	dx
v_ttys9:

endif
	call	v_pos
	mov	dx,[si+m_vcolrow]	;get cursor position
	cmp	al,cr
	jbe	v_ctrl
v_tty1:	stosb
	inc	dl	;inc column
	cmp	dl, byte ptr [ds:m_vcol]	;max ?
	jz	v_lf0	;yes: line feed
	;
	; set cursor position
	;
v_tty2:
	mov	[si+m_vcolrow],dx	;save position
	cmp	byte ptr [ds:m_vpgno],bh	;same page ?
	jnz	v_exit	;:no
v_tty3:	mov	cx,[m_vpage]	;page offset / 2
	shr	cx,1
	mov	cl,dl	;column
	mov	al,dh	;row * column width
	mul	byte ptr [ds:m_vcol]
	add	cx,ax	;get address
	mov	al,14 	;set cursor offset
v_set:
ifdef	VID_CGA
	mov	dx,[m_vcrt]
else
	mov	dx,crtc
endif
	mov	ah,ch
	out	dx,ax
	inc	ax
	mov	ah,cl
	out	dx,ax
v_exit:	POP_A	
	pop	es
	pop	ds
	iret
	;
	; display control characters
	;	
v_ctrl:	jnz	v_ctrl2	;:not carriage return
	;
	; carriage return
	;
v_cr:	mov	dl,0	;beginning of line
	jmp	v_tty2	;set cursor position

v_ctrl2:	cmp	al,lf
	jz	v_lf
	cmp	al,bs
	jz	v_bs
	cmp	al,bell
	jz	v_bell
ifdef	MEDIAGX
	cmp	al,0bh	;clear to beginning of line
	jz	v_cr
endif
	jmp	v_tty1
	;
	; line feed
	;
v_lf0:	mov	dl,0	;beginning of line
v_lf:	inc	dh	;increment line
ifdef	VID_CGA
	cmp	dh,[m_vrow]	;last line ?
	jbe	v_tty2	;:no scroll, set cursor
else
	cmp	dh,25	;last line ?
	jb	v_tty2	;:no scroll, set cursor
endif
	dec	dh	;restore
	push	si	;pd 980422: fix LF bug
	and	di,0f000h	;keep page offset
ifdef	VID_CGA
	mov	al,[m_vcol]	;columns
	mov	ah,0
	push	ax	;save columns
	mov	si,di	;SI = point to next line
	add	si,ax
	add	si,ax
	mov	bx,ax	;save...
	mul	byte [m_vrow]	;* rows -> characters to scroll
	mov	cx,ax
else
	lea	si,[di+160]
	mov	cx,24*80	;scroll full screen
endif
	mov	ax,es	;DS = video segment
	mov	ds,ax
	rep	movsw
	mov	al," "	;fill with same attribute
	mov	ah,[di+1]
ifdef	VID_CGA
	pop	cx	;number of columns
else
	mov	cx,80	;fill bottom line
endif
	rep	stosw
	xor	ax,ax	;restore DS
	mov	ds,ax
	pop	si	;pd 980422: fix LF bug
	jmp	v_tty2
	;
	; backspace
	;
v_bs:	sub	dl,1
	adc	dl,0	;limit to 0
	jmp	v_tty2	;set cursor position
	;
	; bell
	;
v_bell:	call	beep
	jmp	v_exit
	;
	; AH=0F: get video status
	;
v_stat:	mov	bp,sp
	mov	ax,[m_vmode]	;& m_vcol
 	mov	[bp._ax],ax
 	mov	al, byte ptr [ds:m_vpgno]	;page number
 	mov	[bp._bh],al
 	jmp	v_exit
	;
	; display string [SI] -> TTY
	;
v_msg:	
	cs 	lodsb	;get character
	and	al,al	;0 = end
	jz	v_msg9
	mov	ah,0eh	;TTY output
	mov	bh,0	;page 0
	int	10h
	jmp	v_msg
v_msg9:	ret
	;
	; ring bell
	;
beep:	push	ax
	push	cx
	mov	al,0b6h     	;set beep timer
	out	timer+3,al
	mov	al,33h	;beep frequency
	out	timer+2,al
	mov	al,05h
	out	timer+2,al
	in	al,port61             ;enable beep
	mov	ah,al
	or	al,3	
	out	port61,al
	xor	cx,cx	;delay
bell1:	out	iowait,ax
	loop	bell1
	mov	al,ah
	out	port61,al
	pop	cx
	pop	ax
	ret
