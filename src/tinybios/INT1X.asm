	;
	; Miscellaneous interrupts
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - INT15 support is very limited.
	;
	; pd 991127 add PS/2 mouse hook

	;
	; Dummy interrupts -> IRET
	;
intdummy:
int00:	;divide by zero
int01:	;single step
int03:	;breakpoint
int04:	;overflow
int06:	;invalid opcode
int07:	;coprocessor not available
int1b:	;keyboard break
int1c:	;user timer tick

	iret

	;
	; NMI
	;
nmi:	push	ax
	in	al,port61	;check type of NMI
ifndef	NO_NMI
	shl	al,1
	jb	nmi1	;$80 set: parity error
	shl	al,1
	jb	nmi2	;$40 set: I/O check
else
	mov	al,33h	;display POST code on NMI
	out	post,al
endif
	mov	al,0dh	;read CMOS register -> clear NMI
	out	cm_idx,al
	out	iowait,al
	in	al,cm_dat
	pop	ax
	iret		

ifndef	NO_NMI
	
	; display error message
		
nmi1:	mov	si,offset msg_parit
	jmp	short nmi3
	
nmi2:	mov	si,offset msg_iochk

nmi3:	mov	ax,7	;set video mode
	int	10h
	call	v_msg	;display message
	mov	si,offset msg_halt
	call	v_msg	;"system halted"
	cli		;hang system
	hlt
endif
	;
	; end of interrupt, primary controller
	;
inteoi:	push	ax
	mov	al,eoi
	out	pic0,al
	pop	ax
	iret
	;
	; end of interrupt, secondary controller
	;
inteoi2:	push	ax
	mov	al,eoi
	out	pic1,al
	out	pic0,al
	pop	ax
	iret
	;
	; INT 5: print screen
	;
int05:	push	ax
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	byte ptr [ds:m_prtsc],0ffh	;error
	pop	ds
	pop	ax
	iret
	;
	; INT 11 entry: equipment flag
	;
int11:	push	ds
	xor	ax,ax
	mov	ds,ax
          mov	ax,[m_devflg]
	pop	ds
	iret
	;
	; INT12 entry: memory size
	;
int12:	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,[m_lomem]
	pop	ds
	iret
	;
	; INT15 function 86: wait
	;
int1586:	
	PUSH_A
	mov	bx,dx	;microseconds / 1024 -> BX
	push dx
	mov dl,10
	shr	bx,dl
	mov dl, 6
	shl	cx,dl
	pop dx
	or	bx,cx
	call	cs_waitbx	;do the delay
	POP_A
	clc		;return ok status
	retf	2
	;
	; INT15 entry: multiplex interrupt
	;
int15:	sti

;&	push	ax	;display command code
;&	mov	al,ah
;&	call	diaghex
;&	pop	ax
ifdef INT15BLOCKMOVE
	cmp	ah,87h	;block move ?
	jz	int1587
endif
ifdef	PS2MOUSE
	cmp	ah,0c2h	;PS/2 mouse ?
	jnz	int15nc2
	jmp	int15c2
int15nc2:
endif
	cmp	ah,88h	;memory size determine ?
	jz	int1588
	cmp	ah,0c0h	;configuration table ?
	jz	int15c0
	cmp	ah,86h	;wait ?
	jz	int1586
	mov	ah,86h	;bad command
	stc
	retf	2	;return
          ;
          ; AH=88: determine extended memory size
          ;
int1588:	push	bx
	mov	ah,cm_exh	;read high memory size
	call	rtc_read
	mov	bh,al
	mov	ah,cm_exl	;read low memory size
	call	rtc_read
	mov	ah,bh
	pop	bx
	iret
	;
	; AH=C0: configuration table
	;
int15c0:	mov	bx,offset conf_tab	;ES:BX = @configuration table
	push	cs
	pop	es
	mov	ah,0
	clc
	retf	2
	;
ifdef INT15BLOCKMOVE
	;
	; AH=87: block move
	;
	; This assumes that A20 gate is always open (preferably using
	; port 92), and uses "unreal mode". Interrupts are disabled during
	; block move, which can add considerably to interrupt latency.
	;
	; Note we don't close the A20 gate on return.
	;
int1587:	push	ax
	push	bx
	push	si
	push	di
	push	ds
	push	es
	call	cs_a20on	;enable A20 gate
	cld
	and 	ecx,0000ffffh
	mov 	edi,[es:si+1ah]	;24 bit destination address
	and 	edi,00ffffffh	;mask high bits
	mov 	esi,[es:si+12h]	;24 bit destination address
	and 	esi,00ffffffh	;mask high bits
		
	; enter unreal mode
	
	cli		;disable interrupts
	;lgdt [cs:gdt]	;load GDT
	mov	eax,cr0
	or	al,1	;enable protected mode
	mov	cr0,eax
	jmp	short int15872	;flush queue
int15872:	mov	bx,8	;selector
	mov	ds,bx
	mov	es,bx
	and	al,0feh	;exit protected mode
	mov	cr0,eax
	
	shr	cx,1	;convert to 32 bit words
	rep movsd	;do the block move
	jnb	int15873
	movsw	;move a 16 bit "orphan"
int15873:	pop	es
	pop	ds
	sti		;now interrupts are ok again
	pop	di
	pop	si
	pop	bx
	pop	ax
	mov	ah,0	;ok return
	clc	
	retf	2
endif
	;
	; configuration table
	;
conf_tab:	dw	8	;length
	db	0fch	;model byte
	db	01	;sub model
	db	00	;BIOS level
	db	70h	;cascaded interrupt 2, RTC, keyboard
			;scan hook 1A
	db	0,0,0,0	;reserved

	;
	; INT18 entry: expansion ROM
	;	
;ifndef	int18		;if not defined by user code
int18:	mov	si, offset msg_noboot	;display message "No boot device..."
	call	v_msg
	mov	ah,0	;get a keystroke
	int	16h
	iret
;endif
	;
	; INT19 entry: boot operating system
	;
int19:	mov	byte ptr [ds:m_fdcnt],36	;spin down drive A: after 2 seconds

ifdef	BOOT_AC
	mov	dl,0	;drive A:
	mov	cx,1	;retry count
	call	bootdrv	;try to boot
	test	ah,80h	;time out ?
	jnz	int19_1	;yes: probably no disk
	mov	dl,0	;drive A:
	mov	cx,2	;retry count
	call	bootdrv	;try to boot
int19_1:	mov	dl,80h	;drive C:
	mov	cx,3	;retry count
	call	bootdrv	;try to boot
else
	mov	dl,80h	;drive C:
	mov	cx,3	;retry count
	call	bootdrv	;try to boot
	mov	dl,0	;drive A:
	mov	cx,3	;retry count
	call	bootdrv	;try to boot
endif
	int	18h	;display message / expansion ROM
	jmp	int19
	;
	; Try to boot operating system from drive DL, CX retries
	;
bootdrv:	push	cx
	xor	ax,ax	;$0000:$7c00 = destination address
	mov	es,ax
	mov	bx,7c00h
	mov	ax,0201h	;read, 1 sector
	mov	cx,0001	;cylinder 0, sector 1
	mov	dh,0	;head 0
	int	13h	;try to read boot sector
	pop	cx
	jnb	bootdrv2	;:ok
	push	ax
	mov	ah,0	;reset disk system
	int	13h
	pop	ax	;restore status
	loop	bootdrv	;try 3 times
bootdrv9:	ret		;return, didn't work	
	
	; check boot sector signature
	
bootdrv2:	cmp	word ptr [es:7dfeh],0aa55h
	jnz	bootdrv9	;:no
	;jmp	far 0:7c00h	;jump to boot sector
	DB	0EAH			; HARD CODE FAR JUMP TO SET
	DW	07c00h			;  OFFSET
	DW	00000H			;  SEGMENT
	;
	; IRQ13: coprocessor error
	;
irq13:	push	ax
	mov	al,0	;clear error
	out	0f0h,al
	mov	al,eoi	;end of interrupt
	out	pic1,al
	out	pic0,al
	pop	ax
	int	2	;NMI -> further handling
	iret	
