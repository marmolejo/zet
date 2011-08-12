	;
	; POST (power on self test) routines
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - Ctrl-Alt-Del does not get any special treatment by POST, goes
	;   through full memory test etc.
	;
	; pd000424 add QUICKMEM option
	; pd991127 add PS/2 mouse vector
	
	;
	; handle error: hang if C=1, return otherwise
	;
post_err:	jb	post_err1	;:error
	ret
	
post_err1: cli	
	hlt		;hang
	;
	; verify BIOS checksum, return C=1 if error
	;
post_sum:	mov	si,offset startofs	;start offset, must be multiple of 256
	xor	bx,bx	;clear sum
post_sum1:
	cs	lodsw
	add	bl,al
	add	bl,ah
	cs	lodsw
	add	bl,al
	add	bl,ah
	and	si,si
	jnz	post_sum1	;:more to test
	and	bl,bl	;sum = 0 ?
	jnz	post_stc1	;no: error
post_clc1: clc
	ret
	;
	; Test memory refresh (and indirectly, 8254 timer)
	;
ifdef	NO_ISAREF
post_ref:	clc		;skip test
	ret
post_stc1: stc
	ret
else
post_ref:	mov	cx,256
post_ref1: in	al,port61	;wait for refresh bit = 0
	and	al,10h
	jz	post_ref2
	loop	post_ref1
post_stc1: stc		;timeout
	ret

post_ref2: in	al,port61	;wait for refresh bit = 1
	and	al,10h
	jnz	post_clc1	;yes: return clc
	loop	post_ref2
	stc		;timeout
	ret
endif
	;
	; Test DMA registers
	;
post_dma:	mov	dx,dma1	;I/O port
	mov	si,2	;port increment
post_dma1: mov	di,dx	;save I/O port
	mov	bx,8000h	;starting pattern
post_dma2: call	post_dma3	;test
	jb	post_stc1	;:error
	mov	dx,di	;restore I/O port
	ror	bx,1	;next pattern
	jnb	post_dma2	;:another bit
	mov	dl,dma0
	shr	si,1	;do dma0 ?
	jnb	post_dma1	;:yes
	clc		;passed test
	ret

post_dma3: mov	cx,8	;8 address and count registers
post_dma4: mov	al,bl	;write test pattern (16 bit = 2 writes)
	out	dx,al
	out	iowait,al
	mov	al,bh
	out	dx,al
	out	iowait,al
	in	al,dx	;read back and compare
	cmp	al,bl
	jnz	post_stc1
	out	iowait,al
	in	al,dx
	cmp	al,bh
	jnz	post_stc1
	out	iowait,al
	add	dx,si	;next port
	loop	post_dma4
	clc		;ok return
	ret
	;
	; Test IRQ mask registers
	;
post_irq:	mov	dx,pic0+1
	call	post_reg
	jb	post_irq2
	mov	dl,pic1+1
	call	post_reg
post_irq2: mov	al,0ffh	;mask off all interrupts
	out	pic0+1,al
	out	pic1+1,al
	ret
	;
	; test register [DX]
	;
post_reg:	mov	bl,80h	;starting pattern
post_reg2: mov	al,bl	;write pattern
	out	dx,al
	not	al	;write inverted pattern to prevent
	out	iowait,al	;capacitive hold
	in	al,dx	;read back
	cmp	al,bl
	jnz	post_stc1	;:error
	out	iowait,al
	ror	bl,1	;try next bit
	jnb	post_reg2
	clc		;return ok status
post_reg9: ret
	;
	; Test DMA page registers
	;
post_page: mov	dx,fd_page
	mov	cx,15	;81..8F
post_pag2: call	post_reg
	jb	post_reg9	;:error
	inc	dx
	loop	post_pag2
	ret
	;
	; Test timer 2 registers
	;
post_tim:	mov	al,0b0h	;timer 2
	out	timer+3,al
	out	iowait,ax	;this is needed, at least on M6117 !
	out	iowait,ax
ifdef	MEDIAGX
	out	timer+2,al	;dummy write, read
	out	timer+2,al
	in	al,timer+2
	in	al,timer+2
endif
	mov	bx,1
post_tim1: mov	al,bl	;LSB
	out	timer+2,al
	out	iowait,ax
	mov	al,bh	;MSB
	out	timer+2,al
	out	iowait,ax
	in	al,timer+2	;check LSB
	cmp	al,bl
	jnz	post_stc2
	out	iowait,ax
	in	al,timer+2	;check MSB
	out	iowait,ax
	cmp	al,bh
	jnz	post_stc2
	shl	bx,1
	jnb	post_tim1
	clc
	ret
post_stc2: stc
	ret
	;
	; Clear registers, disable DMA, interrupts
	;
post_clr:	mov	si,offset clrtab
	jmp	short post_tdm0
 	;
 	; Initialize timers, DMA
 	;
post_tdma: mov	si, offset tdmatab
post_tdm0: mov	dh,0
post_tdm1:
	cs	lodsw
	cmp	ah,0ffh	;end of table ?
	jz	post_tdm9
	mov	dl,ah	;port address
	out	dx,al	;write data
	out	iowait,al	;I/O wait
	jmp	post_tdm1
post_tdm9: ret
	;
	;
	;
ifdef PROT_MODE
	;
	; global descriptor table (GDT) for unreal mode
	;
	;db	(($+15) and 0fff0h)-$ dup (0ffh)	;even 16
	align 16
gdt:	dw	gdtend-gdt-1	;GDT limit
gdtadr:	dw	gdt,000fh	;linear address of GDT
	dw	0
	dw	0ffffh,0,9300h,008fh	;4G data segment, accessed
ifdef	GX_GDT
	dw	0ffffh,0,9300h,408fh	;GX_BASE segment -> GS:
endif
gdtend:
	;
	; Enter unreal (4GB segment) mode -> change DS,ES selector
	;
	; based on code in DDJ 7/90
	;
getunreal:
	cli		;disable interrupts
	lgdt [fword ptr cs:gdt]	;load GDT (in data module, writeable)
	
	mov	eax,cr0	;mov eax,cr0
	or	al,1	;enable protected mode
	mov	cr0,eax	;mov cr0,eax
	jmp	short getunrl2	;flush queue
getunrl2:	mov	bx,8	;selector
	mov	ds,bx
	mov	es,bx
	and	al,0feh	;exit protected mode
	mov	cr0,eax	;mov cr0,eax
	ret
	;
	; display high memory size EBP (destroyed)
	;
post_dsph: push 	ebp	;save EBP
ifdef	GX_VID
	mov	ax,0e0bh	;display clear to beginning of line
else
	mov	ax,0e0dh	;display CR
endif
	mov	bl,0
	int	10h
	pop 	eax	;EBP -> EAX
	shr 	eax,10	;display high memory size
			;div 1024 -> KB	
	sub 	eax,1024	;sub eax,#1024
			;fall through
	;
	; display number EAX
	;
	; divide / stack based algorithm
	;
post_itoa: xor	dx,dx	;mark first digit on stack
	push	dx
	mov 	ecx,10
post_ito2: xor 	edx,edx
	div 	ecx
	or	dl,"0"	;remainder -> ASCII digit
	push	dx	;push digit
	and 	eax,eax	;done ?
	jnz	post_ito2
	
post_ito3: pop	ax	;get digit
	and	al,al
	jz	post_ito9
	mov	ah,0eh	;TTY output
	mov	bh,0	;page 0
	int	10h
	jmp	post_ito3

post_ito9: ret
	;
	; size low memory -> EBX = top address; 64KB granularity
	; (run in unreal mode)
	;
post_szlo:
	mov 	ebx,0a0000h	;top limit
	xor 	ecx,ecx	;bottom limit
post_szl0:
	mov 	edx,ebx	;save top
	mov 	edi,10000h	;64KB increment
	
	; first, write address to memory, counting down
	
post_szl1:
	sub 	ebx,edi
	mov	[ebx],ebx
	cmp 	ebx,ecx
	jnz	post_szl1
	
	; now, verify going up
	
post_szl2:
	add 	ebx,edi
	cmp	[ebx],ebx
	jnz	post_szl3	;error: done
	cmp 	ebx,edx
	jnz	post_szl2
post_szl3:
	ret		;ebx = top address
	;
	; size high memory
	; (run in unreal mode)
	;
	
	; first, we do binary rough size
	
post_szhi: xor 	esi,esi	;start seed
	mov 	[esi],esi
	mov 	ebx,00100000h	;1MB start
	mov 	ecx,ebx	;start for szlo
post_szh1: mov 	[ebx],ebx
	cmp 	[esi],esi 	;wrote over previous ?
	jnz	post_szh2	;:yes - reached top
	cmp 	[ebx],ebx 	;this location ok ?
	jnz	post_szh2	;:no - reached top
	mov 	esi,ebx	;new seed location
	shl 	ebx,1
	test 	ebx,(TOP_MEM shl 16)	;reached top ?
	jz	post_szh1	;:not yet
post_szh2:
	jmp	post_szl0	;ebx is top limit - use low size
			;algorithm now for 64KB resolution
	;
	; Test 64 KB memory block [EBP]
	; (run in unreal mode)
	;
	; preserve EDX !
	;
post_t64k: mov 	edi,ebp	;starting address (must be at 64K
			;multiple)

	; first, do a 64 bit sliding bit test over first 64 x 64 bits
	
	mov 	eax,1	;test pattern
	xor 	ebx,ebx
post_tk1:	mov 	[edi],eax
	mov 	[edi+4],ebx
	add	di,8
	shl 	eax,1
	rcl 	ebx,1
	jnb	post_tk1	;:another bit
	
	xor	di,di	;return to start
	mov 	eax,1	;test pattern
	xor 	ebx,ebx
post_tk2:	cmp 	[edi],eax
	jnz	post_tk9	;:error
	cmp 	[edi+4],ebx
	jnz	post_tk9	;:error
	add	di,8
	shl 	eax,1
	rcl 	ebx,1
	jnb	post_tk2
	
	; now, write initial test pattern seed
	; 72 bytes long -> always get distance between
	; current cache line and destination

	mov 	eax,00100100100100100100100100100100b	;test pattern
post_tk3:	mov 	edi,ebp	;start location
	mov	di,16	;skip first 16 bytes
	mov 	esi,edi
	
	mov	cx,18
post_tk4:	stosd
	test	al,4	;"round" rotate
	jz	post_tk41	;implicit CLC
	stc
post_tk41: rcr 	eax,1
	dec	cx
	jnz	post_tk4	;:another

	; do block move -> copies pattern all over memory

	mov 	ecx,16362	;word count
	rep movsd
	
	; now verify final pattern
	
post_tk5:	cmp 	eax,[esi]
	jnz	post_tk9	;:error
	test	al,4	;"round" rotate
	jz	post_tk51	;implicit CLC
	stc
post_tk51: rcr 	eax,1
	add	si,4
	jnz	post_tk5
	
	test	al,4	;"round" rotate
	jz	post_tk52	;implicit CLC
	stc
post_tk52: rcr 	eax,1	;try next pattern
	jnb	post_tk3	;:again, total of three passes
	
	mov 	edi,ebp
	xor 	eax,eax
	mov	cx,16384
	rep stosd	;clear memory
	
	mov 	ebp,edi	;new top
	clc
	ret

post_tk9:	stc		;error return
	ret

IFDEF	QUICKMEM
	;
	; Clear 64 KB memory block [EBP]
	; (run in unreal mode)
	;
	; preserve EDX !
	;
post_c64k: mov 	edi,ebp	;starting address (must be at 64K
			;multiple)
	xor 	eax,eax	;zero fill
	mov 	ecx,4000h
	rep stosd	;fill
	mov 	ebp,edi	;mov ebp,edi - new top
	clc
	ret
ENDIF
	;
	; base memory test
	;
post_base: call	getunreal	;enter unreal mode
	call	post_szlo	;size low memory
	mov 	[dword ptr ds:tmp_losz],ebx
	
	mov	[word ptr ds:m_lomem],64	;we have at least 64KB DRAM
	mov 	ebp,10000h	;start address
	
post_bas0:
IFDEF	QUICKMEM
	call	post_c64k	;clear 64K of DRAM
ELSE
	call	post_t64k	;test 64K of DRAM
ENDIF
	jb	post_bas1	;:error
	add	[word ptr ds:m_lomem],64	;we got another 64KB
	cmp 	ebp,[tmp_losz]
	jnz	post_bas0	;:another block
	
post_bas1: xor	ax,ax	;access BIOS segment
	mov	ds,ax
	mov	es,ax
	
ifdef	CM_LEGACY
	mov	ah,cm_meml	;write base memory size to CMOS
	mov	al,[m_lomem]
	call	rtc_write
	mov	al,[m_lomem+1]
	mov	ah,cm_memh	;write low memory size
	call	rtc_write
endif
	ret
	;
	; init interrupt vectors
	;
post_vec:	mov	si,offset inttab	;init interrupt vectors
	xor	di,di	;vec00
	mov	ax,cs	;BIOS segment -> eax bit 31..16
	shl 	eax,16
	mov	cx,1fh
post_vec1:
	cs	lodsw	;copy vectors 00.1e
	stosd		;vector + segment
	loop	post_vec1
	add	di,4	;skip vector 1F
	
	mov	cl,60h-20h
	mov	ax,offset intdummy	;dummy vectors 20..5F
	rep 	stosd
	add	di,8*4	;skip 60..67
	mov	cl,8
	rep 	stosd	;fill 68..6F
	
	mov	cl,8	;copy 8 more vectors
post_vec2:
	cs 	lodsw	;copy vectors 70..77
	stosd
	loop	post_vec2
	ret
	;
	; Extended memory test
	;
post_ext:	call	getunreal	;enter unreal mode again (& cli)

	push 	[dword ptr ds:0]	;save lowest memory - zapped by
			;post_szhi
	call	post_szhi	;size high memory
	pop 	[dword ptr ds:0]
	
	mov 	[dword ptr ds:tmp_hisz],ebx
	
	mov 	ebp,100000h	;start address
	
post_ext0:
IFNDEF	QUICKMEM
	test 	ebp,0fffffh	;reached 1MB boundary ?
	jnz	post_ext1
	pushad		;save all registers
	call	post_dsph	;display current count
	call	getunreal	;get back to unreal mode
	popad		;restore all registers
ENDIF
post_ext1:
IFDEF	QUICKMEM
	call	post_c64k	;clear 64K of DRAM
ELSE
	call	post_t64k	;test 64K of DRAM
ENDIF
	jb	post_ext2	;:error
	cmp 	ebp,[tmp_hisz]
	jnz	post_ext0	;:another block

post_ext2:
	mov 	[dword ptr ds:tmp_hisz],ebp	;save actual memory size
	call	post_dsph	;display current count
	mov	si, offset msg_ext	;display " KB Extended Memory"
	call	v_msg

	xor	ax,ax	;access BIOS segment
	mov	ds,ax
	mov	es,ax

	mov 	ebx,[tmp_hisz]	;store extended memory size in CMOS
	shr 	ebx,10  	;convert to KB
	sub	bx,1024	;minus base memory
	mov	ah,cm_exh	;write high memory size
	mov	al,bh
	call	rtc_write
	mov	al,bl
	mov	ah,cm_exl	;write low memory size
ifdef	CM_LEGACY
	call	rtc_write
	mov	ah,cm_exh2	;write high memory size
	mov	al,bh
	call	rtc_write
	mov	al,bl
	mov	ah,cm_exl2	;write low memory size
endif
	jmp	rtc_write
	;
	;
	;
else ; PROT_MODE

post_base:
	ret
	
post_vec:
	ret
	
post_itoa:
	ret
	
post_ext:
	ret
	
endif ; PROT_MODE
	;
	; scan for option ROMs
	;	
post_scan: mov	ds,bx
	cmp	[word ptr ds:0],0aa55h	;start signature
	jnz	post_scn8	;:no
	mov	cl,[2]	;get length
	mov	ch,0
	mov al, 9
	shl	cx,al	;* 512
	xor	si,si	;start offset
	xor	al,al	;clear sum
post_scn1: add	al,[si]	;calculate checksum
	inc	si
	loop	post_scn1
	mov 	[word ptr es:m_ioofs],3	;offset - call vector
	mov 	[word ptr es:m_ioseg],ds	;segment
	shr	si,1
	shr	si,1
	shr	si,1
	shr	si,1
	add	bx,si	;update segment
	cmp	al,0
	jnz	post_scn9	;:bad checksum
	
	push	bx	;save segment
	push	dx	;save limit
	
	call 	far ptr [es:m_ioofs]	;call ROM
	cld		;just in case they set it...
	pop	dx	;restore limit
	pop	bx	;restore segment
	jmp	short post_scn9
	
post_scn8: add	bx,0080h
post_scn9: cmp	bx,dx	;top limit ?
	jb	post_scan	;:no
	xor	ax,ax	;restore segments
	mov	ds,ax
	mov	es,ax
	ret
	;
	; Interrupt vector table
	;
inttab:	dw	int00	;divide by zero
	dw	int01	;single step
	dw	nmi	;NMI
	dw	int03	;breakpoint
	dw	int04	;overflow
	dw	int05	;print screen
	dw	int06	;invalid opcode
	dw	int07	;coprocessor not available
	dw	irq0	;IRQ0 system timer
	dw	irq1	;IRQ1 keyboard
	dw	inteoi	;reserved - cascade
	dw	inteoi	;IRQ3 reserved
	dw	inteoi	;IRQ4 reserved
	dw	inteoi	;IRQ5 reserved
	dw	irq6	;IRQ6 floppy
	dw	inteoi	;IRQ7 reserved
	dw	int10	;video
	dw	int11	;equipment determination
	dw	int12	;memory size
	dw	int13	;disk
	dw	int14	;serial
	dw	int15	;system services
	dw	int16	;keyboard
	dw	int17	;printer
	dw	int18	;expansion ROM
	dw	int19	;bootstrap
	dw	int1a	;timer / RTC
	dw	int1b	;keyboard break
	dw	int1c	;user timer tick
	dw	v_parm	;video parameters
	dw	fd_ptab	;diskette parameters

	dw	irq8	;IRQ8: RTC
	dw	inteoi2	;IRQ9: cascade
	dw	inteoi2	;IRQ10: spare
	dw	inteoi2	;IRQ11: spare
ifdef	PS2MOUSE
	dw	irq12
else
	dw	inteoi2	;IRQ12: spare
endif
	dw	irq13	;IRQ13: spare
	dw	irq14	;IRQ14: hard disk
	dw	inteoi2	;IRQ15: spare
	;
	; Display POST code AL
	;
	; This routine is called very early, without a stack.
	; If you decide to display POST codes to a serial or parallel
	; port, you will have to initialize the super I/O first.
	;
;ifndef	postcode	;can be overridden by user routine
postcode:	out	post,al
	ret
;endif
	;
	; Display fatal error code AL
	;
	; This routine is called on fatal errors, e.g. bad memory.
	; We just write the POST code, then hang.
	;
;ifndef	fatal		;can be overridden by user routine
fatal:	out	post,al
fatal1:	hlt
	jmp	fatal1
;endif
