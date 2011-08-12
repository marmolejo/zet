	;
	; PCI BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; pd 990525 rewrite 32 bit BIOS to avoid any data accesses
	; 	    (Linux hang)
	;
	; Limitations:
	;
	; - Interrupt probe / reassign functions not implemented.
	;
	; I/O ports
	;
pci_ver	equ	0210h	;PCI version reported
bios3seg	equ	000fh	;$f000 / 4096
	;
	; 32 bit pusha stack frame
	;
_eax	equ	1ch
_ebx	equ	10h
_ecx	equ	18h
_edx	equ	14h
_ebp	equ	08h
_esi	equ	04h
_edi	equ	00h
_efl	equ	24h	;flags
	;
	; PCI INT1A functions
	;
pci_i1a:	pushad		;build stack frame
	mov	bp,sp
	mov	ah,0	;command code -> vector
	cmp	al,0fh	;max command
	ja	pci_badc0	;:bad
	add	ax,ax
	mov	si,ax
	call 	[cs:si+pci_vec]	;dispatch command
pci_i1a2:	jb	pci_i1a4	;:error
	mov	al,0	;ok status
	and	byte ptr [ds:bp._efl],0feh	;clear carry flag
pci_i1a3:	mov	byte ptr [ds:bp._eax+1],al	;return status code -> AH
	popad
	iret
	;
	; bad command
	;
pci_badc:	pop	ax	;pop return address
pci_badc0: mov	al,81h	;bad command
	;
	; return error
	;
pci_i1a4:	or	byte ptr [ds:bp._efl],1	;set carry flag
	jmp	pci_i1a3
	;
	; dispatch table
	;
	even
pci_vec:	dw	pci_badc	;00: bad command
	dw	pci_pres	;01: PCI BIOS present
	dw	pci_find	;02: find PCI device
	dw	pci_class	;03: find PCI class code
	dw	pci_badc	;04: invalid
	dw	pci_badc	;05: invalid
	dw	pci_spec	;06: generate special cycle
	dw	pci_badc	;07: invalid
	dw	pci_readb	;08: read config byte
	dw	pci_readw	;09: read config word
	dw	pci_readd	;0A: read config dword
	dw	pci_writb	;0B: write config byte
	dw	pci_writw	;0C: write config word
	dw	pci_writd	;0D: write config dword
	dw	pci_badc	;0E: get IRQ routing options
			;not implemented
	dw	pci_badc	;0F: set PCI IRQ
			;not implemented
	;
	; 01: PCI BIOS present
	;
pci_pres:	mov	word ptr [ds:bp._ebx],pci_ver	;PCI 2.1 -> BX
	mov 	dword ptr [ds:bp._edx],20494350h	;"PCI " -> DX
	mov	al,byte ptr [cs:d_lastbus]	;number of last PCI bus -> CL
	mov	byte ptr [ds:bp._ecx],al
	mov	byte ptr [ds:bp._eax],11h	;hardware mechanism 1 -> AL
	clc
	ret
	;
	; 08: read config byte
	;
pci_readb: mov	ax,0ff00h	;address mask (forbidden bits)
	call	pci_idx	;set index
	in	al,dx	;read data
	mov	[bp._ecx],al	;return in CL
	ret
	;
	; 09: read config word
	;
pci_readw: mov	ax,0ff01h	;address mask
	call	pci_idx	;set index
	in	ax,dx	;read data
	mov	[bp._ecx],ax	;return in CX
	ret
	;
	; 0A: read config dword
	;
pci_readd: mov	ax,0ff03h	;address mask
	call	pci_idx	;set index
	in 	eax,dx	;read data
	mov 	[bp._ecx],eax	;return in ECX
	ret
	;
	; 0B: write config byte
	;
pci_writb: mov	ax,0ff00h	;address mask
	call	pci_idx	;set index
	out	dx,al	;write data
	ret
	;
	; 0C: write config word
	;
pci_writw: mov	ax,0ff01h	;address mask
	call	pci_idx	;set index
	out	dx,ax	;write data
	ret
	;
	; 06: generate special cycle
	;
pci_spec:	cmp 	bh,byte ptr [cs:d_lastbus]	;bus number ok ?
	ja	pci_badc	;:bad
	mov	bl,0ffh	;device number = FF
	mov 	ecx,edx	;special cycle data -> ECX
	xor	di,di	;register number 0
			;fall through
	;
	; 0D: write config dword
	;
pci_writd: mov	ax,0ff03h	;address mask
	call	pci_idx	;set index
	out 	dx,eax	;write data
	ret
	;
	; set PCI configuration index
	;
pci_idx:	test	di,ax	;any "forbidden" bits set ?
	jnz	pci_idx1
	mov	dx,pci_ad
	mov	ah,80h	;configuration enable
	mov	al,bh	;bus number
	shl 	eax,16	;-> high word
	mov	ax,di	;register number
	and	al,0fch	;clear lower bits
	mov	ah,bl	;device number / function number
	out 	dx,eax	;set index
	mov	dx,pci_dat
	and	di,3	;low bits of register
	add	dx,di	;update register pointer (implicit clc)
	mov 	eax,ecx	;write data -> EAX
	ret
	
pci_idx1:	pop	ax	;return address
	mov	al,87h	;bad register number
	stc
	ret		;return to dispatcher
	;
	; 02: find PCI device
	;
pci_find:	inc	dx	;vendor ID FFFF ?
	jnz	pci_find2	;:ok
	mov	al,83h	;bad vendor ID
	stc
	ret

pci_find2: dec	dx	;restore vendor ID
	mov 	ebx,80000000h	;bus address
	shl 	ecx,16	;device ID -> bits 31..16
	mov	cx,dx	;vendor ID -> bits 15..00
	mov 	esi,0ffffffffh	;mask
	jmp	short pci_find3
	;
	; 03: find PCI class code
	;
pci_class: shl 	ecx,8	;class code is bits 31..08
	mov 	esi, 0ffffff00h	;mask
;	mov 	ebx,(080000000h + p_class)	;bus address
	mov 	ebx,080000008h	;bus address
	
pci_find3: mov	di,[bp._esi]	;restore device index
          ;
          ; search all buses / devices
          ;
pci_find4: mov	dx,pci_ad
	mov 	eax,ebx	;device address
	mov	al,p_id	;vendor / device ID
	out 	dx,eax
	mov	dx,pci_dat
	in 	eax,dx	;read device / vendor ID
	cmp	ax,0ffffh	;not present ?
	jz	pci_find7	;:skip entire device
	cmp	bl,0	;looking for class code ?
	jz	pci_find5	;:no
	mov	dx,pci_ad
	mov 	eax,ebx	;restore register offset
	out 	dx,eax
	mov	dx,pci_dat
	in 	eax,dx	;read class code
pci_find5: and 	eax,esi	;mask relevant bits
	cmp 	eax,ecx	;same ?
	jnz	pci_find6	;:no
	dec	di	;device count
	js	pci_found	;:this is the one
	
	; try next function
	
pci_find6: test	bh,7	;function 0 ?
	jnz	pci_find8	;:no
	mov	dx,pci_ad
	mov 	eax,ebx	;index
	mov	al, p_hedt
	and al, 0fch	;header type
	out 	dx,eax
	mov	dx,pci_dat + 2
	in 	al,dx	;read header type
	test	al,80h	;multifunction device ?
	jnz	pci_find8	;:yes
pci_find7: or	bh,7	;skip the rest of this device
	
	; try next device / function
	
pci_find8: inc	bh	;next device / function
	jnz	pci_find4	;:ok
	
	; try next bus
	
	ror 	ebx,16
	inc	bx	;next bus
	cmp	bl,byte ptr [cs:d_lastbus]
	ja	pci_find9	;:not found
	ror 	ebx,16	;restore
	jmp	pci_find4

	; didn't find it
	
pci_find9: mov	al,86h	;device not found
	stc
	ret
	
	; found device
	
pci_found: shr 	ebx,8	;return bus, device number in BX
	mov	[bp._ebx],bx
	clc		;ok return
	ret
	
ifndef	NO_PCI32
	;
	; 32 bit PCI BIOS entry point
	;
	;use32
	
pci_32:	pushad		;build stack frame
	mov	ebp,esp

	cmp	al,0ah	;0A: read config dword
	jnz	pci_3a
	call 	pci3readd
	jmp	short pci_3z
	
pci_3a:	cmp	al,09	;09: read config word
	jnz	pci_3b
	call 	pci3readw
	jmp	short pci_3z

pci_3b:	cmp	al,08	;08: read config byte
	jnz	pci_3c
	call 	pci3readb
	jmp	short pci_3z

pci_3c:	cmp	al,0dh	;0D: write config dword
	jnz	pci_3d
	call 	pci3writd
	jmp	short pci_3z

pci_3d:	cmp	al,0ch	;0C: write config word
	jnz	pci_3e
	call 	pci3writw
	jmp	short pci_3z
	
pci_3e:	cmp	al,0bh	;0B: write config byte
	jnz	pci_3f
	call 	pci3writb
	jmp	short pci_3z

pci_3f:	cmp	al,01	;01: PCI BIOS present
	jnz	pci_3g
	call 	pci3pres
	jmp	short pci_3z

pci_3g:	cmp	al,02	;02: find PCI device
	jnz	pci_3h
	call 	pci3find
	jmp	short pci_3z
	
pci_3h:	cmp	al,03	;03: find PCI class code
	jnz	pci_3j
	call 	pci3find
	jmp	short pci_3z
	
pci_3j:	cmp	al,06	;06: generate special cycle
	jnz	pci_3k
	call 	pci3spec
	jmp	short pci_3z

pci_3k:	call 	pci3badc	;others: bad commands
	
pci_3z:	jb	pci_32b	;:error
	mov	al,0	;return ok status
pci_32b:	mov	[ebp._eax+1],al	;status code -> AH
	popad		;restore registers
	retf
	;
	; bad command
	;
pci3badc:	mov	al,81h	;return error code
	stc
	ret
	;
	; 01: PCI BIOS present
	;
pci3pres:
	mov	word ptr [ds:ebp._ebx],pci_ver	;PCI 2.1 -> BX
	mov 	dword ptr [ds:ebp._edx],20494350h	;"PCI " -> EDX
	call	getlbus	;get number of last PCI bus -> AL
	mov	[ebp._ecx],al	;-> return in CL
	mov	byte ptr [ds:ebp._eax],11h	;hardware mechanism 1 -> AL
	clc
	ret
	;
	; 08: read config byte
	;
pci3readb: mov	al,0	;address mask (forbidden bits)
	call	pci3idx	;set index
	in	al,dx	;read data
	mov	[ebp._ecx],al	;return in CL
	ret
	;
	; 09: read config word
	;
pci3readw: mov	al,1	;address mask
	call	pci3idx	;set index
	in	ax,dx	;read data
	mov	[ebp._ecx],ax	;return in CX
	ret
	;
	; 0A: read config dword
	;
pci3readd: mov	al,03	;address mask
	call	pci3idx	;set index
	in 	eax,dx	;read data
	mov 	[ebp._ecx],eax	;return in ECX
	ret
	;
	; 0B: write config byte
	;
pci3writb: mov	al,00	;address mask
	call	pci3idx	;set index
	out	dx,al	;write data
	ret
	;
	; 0C: write config word
	;
pci3writw: mov	al,01	;address mask
	call	pci3idx	;set index
	out	dx,ax	;write data
	ret
	;
	; 06: generate special cycle
	;
pci3spec:	call	getlbus	;bus number ok ?
	cmp	bh,al
	ja	pci3badc	;:bad
	mov	bl,0ffh	;device number = FF
	mov 	ecx,edx	;special cycle data -> ECX
	xor	edi,edi	;register number 0
			;fall through
	;
	; 0D: write config dword
	;
pci3writd: mov	al,03	;address mask
	call	pci3idx	;set index
	out 	dx,eax	;write data
	ret
	;
	; set PCI configuration index
	;
pci3idx:	ror	ebx,8
	mov	bh,80h
	rol	ebx,16
	mov	dx,[ebp._edi]	;get index
	test	dl,al	;forbidden bits set ?
	jnz	pci3idx1	;:yes
	and	dh,dh	;high byte ?
	jnz	pci3idx1	;:yes
	mov	bl,dl	;set index
	mov	dx,pci_ad	;set port address
	mov	eax,ebx	;get index -> eax
	and	al,0fch	;mask low bits
	out 	dx,eax	;set index
	mov	dl,bl	;get low address
	or	dx,pci_dat	;assume pci_dat $fc (implicit clc)
	mov 	eax,ecx	;write data -> EAX
	ret
	
pci3idx1:	pop	eax	;return address
	mov	al,87h	;bad register number
	stc
	ret		;return to dispatcher
	;
	; 02: find PCI device
	;
pci3find:	inc	dx	;vendor ID FFFF ?
	jnz	pci3find2	;:ok
	mov	al,83h	;bad vendor ID
	stc
	ret

pci3find2: dec	dx	;restore vendor ID
	mov 	ebx,80000000h	;bus address
	shl 	ecx,16	;device ID -> bits 31..16
	mov	cx,dx	;vendor ID -> bits 15..00
	mov 	edi,0ffffffffh	;mask
	jmp	short pci3find4
	;
	; 03: find PCI class code
	;
pci3class: shl 	ecx,8	;class code is bits 31..08
	mov 	edi,0ffffff00h	;mask
;	mov 	ebx,080000000h+p_class	;bus address
	mov 	ebx,080000008h	;bus address
          ;
          ; search all buses / devices
          ;
pci3find4: mov	dx,pci_ad
	mov 	eax,ebx	;device address
	mov	al,p_id	;vendor / device ID
	out 	dx,eax
	mov	dx,pci_dat
	in 	eax,dx	;read device / vendor ID
	cmp	ax,0ffffh	;not present ?
	jz	pci3find7	;:skip entire device
	cmp	bl,0	;looking for class code ?
	jz	pci3find5	;:no
	mov	dx,pci_ad
	mov 	eax,ebx	;restore register offset
	out 	dx,eax
	mov	dx,pci_dat
	in 	eax,dx	;read class code
pci3find5: and 	eax,edi	;mask relevant bits
	cmp 	eax,ecx	;same ?
	jnz	pci3find6	;:no
	dec	si	;device count
	js	pci3found	;:this is the one
	
	; try next function
	
pci3find6: test	bh,7	;function 0 ?
	jnz	pci3find8	;:no
	mov	dx,pci_ad
	mov 	eax,ebx	;index
	mov	al,p_hedt	;header type
	and al, 0fch
	out 	dx,eax
	mov	dx,pci_dat + 2
	in 	al,dx	;read header type
	test	al,80h	;multifunction device ?
	jnz	pci3find8	;:yes
pci3find7: or	bh,7	;skip the rest of this device
	
	; try next device / function
	
pci3find8: inc	bh	;next device / function
	jnz	pci3find4	;:ok
	
	; try next bus
	
	ror 	ebx,16
	inc	bl	;next bus
	call	getlbus
	cmp	bl,al
	ja	pci3find9	;:not found
	ror 	ebx,16	;restore
	jmp	short pci3find4

	; didn't find it
	
pci3find9: mov	al,86h	;device not found
	stc
	ret
	
	; found device
	
pci3found: shr 	ebx,8	;return bus, device number in BX
	mov	[ebp._ebx],bx
	clc		;ok return
	ret
	;
	; 32 bit BIOS entry point
	;
bios_32:	and	ebx,ebx	;valid function code ?	
	jz	bios_32a	;:ok
	mov	al,81h	;unimplemented function
	retf
bios_32a:	cmp	eax,49435024h	;$PCI
	jz	bios_32b	;:ok
	mov	al,80h	;service is not present
	retf
bios_32b:	mov	al,0	;ok status
	mov	ebx,bios3seg shl 16	;BIOS segment base = $000f 0000
	mov	ecx,10000h	;length of BIOS service = 64K
	mov	edx,pci_32	;offset from ebx base
	retf
	;use16
	;
	; 32 bit BIOS header
	;
	align 16
bios_32hd	db	"_32_"
	dw	bios_32	;entry point
	dw	bios3seg	;BIOS segment
	db	0	;revision level 0
	db	1	;length (16 byte units)
	db	0	;checksum (bios_32hd) - filled in
			;by BIOSSUM.EXE.
	db	0,0,0,0,0	;reserved
endif
