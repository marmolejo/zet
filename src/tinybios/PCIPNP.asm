	;
	; PCI plug & play
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;

	; pd 000830 add PCI_NORST2 option -> don't touch base register
	;           for second motherboard device (e.g. USB)
	; pd 991115 fix PCI I/O allocation: some devices (e.g. ESS Tech)
	;           have 16 bit base registers.
	; pd 990329 fix PCI I/O allocation: 4 byte -> 64 bit registers...
	; pd 990216 rewrite I/O allocation	
	; pd 980728 change to call postcode routine
	; pd 980728 fix PCI_NORST option -> skip entire device, not just
	;           function

	;
	; To make this BIOS more suitable for future hot plug PCI support,
	; the PCI bus address space allocation has been designed to use
	; minimum granularity and fixed size allocation for bridges, rather
	; than packing things as tightly as possible. This also simplifies
	; the code quite a bit.
	;
	; Limitations:
	;
	; - PCI bridge code not yet tested.
	; - Fixed size allocation for bridges (better to support future
	;   hot plug, simpler). As implemented, this does not work for
	;   more than 2 levels of bridges.
	; - VGA through bridge is not supported (bad idea for performance).
	; - Except for VGA BIOS, expansion ROMs are not supported.
	;   Assume first image, 32 KB size.
	; - Memory allocation below 1MB does not handle memory holes.
	;
	; PCI inherent limitations:
	;
	; - Devices behind bridges don't support memory that must be
	;   allocated below 1MB.
	;
	; PCI configuration space structure
	;
p_id	equ	0	;vendor, device ID
p_cmd	equ	4	;command register
p_stat	equ	6	;status register
p_class	equ	8	;class code, revision ID
p_linesz	equ	12	;cache line size
p_lat	equ	13	;latency timer
p_hedt	equ	14	;header type
p_bist	equ	15	;built-in self test
p_base	equ	10h	;base address registers
pb_bus	equ	18h	;bridge: primary bus number
pb_bus2	equ	19h	;bridge: secondary bus number
pb_bus3	equ	1ah	;bridge: subordinate bus number
pb_lat2	equ	1bh	;bridge: secondary latency timer
pb_io	equ	1ch	;bridge: I/O limit
pb_stat	equ	1eh	;bridge: secondary status
pb_mem	equ	20h	;bridge: memory base low
pb_memp	equ	24h	;bridge: prefetchable memory base
p_cis	equ	28h	;end of base address registers
pb_mem2	equ	28h	;bridge: memory base high
pb_memp2	equ	2ch	;bridge: prefetchable memory base high
p_rom	equ	30h	;expansion rom base
pb_io2	equ	34h	;bridge: I/O base high
pb_rom	equ	38h	;bridge: ROM
p_line	equ	3ch	;IRQ assigned to function
p_pin	equ	3dh	;0 = not used, 1=A, 2=B, 3=C, 4=D
p_mingnt	equ	3eh	;minimum grant time
pb_ctl	equ	3eh	;bridge: control
p_maxlat	equ	3fh	;maximum latency
	;
	; working variables for PNP
	;
	;+ must directly follow previous variable !
	;
;tmp_pci	struct
	p_int		dw	?,?	;PCI interrupt lines, LSB = INTA,
						;MSB = INTD
	p_irqpt		dw	?	;pointer to IRQ table entry
	p_mem		dw	?	;regular memory (64K steps)
	p_memlim	dw	?	;+ memory limit
	p_memp		dw	?	;prefetchable memory (64K steps)
	p_memplim 	dw	?	;+ prefetchable memory limit
		p_io	dw	?	;I/O address	(16 byte steps)
	p_iolim		dw	?	;+ I/O limit
	p_memr		dw	?	;memory below 1MB (segment value)
	p_memrlim 	dw	?	;+ limit
	p_capa		dw	?	;low: 0 if back to back mode supported
						;high: 0 for fast, 2 for medium, 4/6
						;slow devsel
	p_bus		db	?	;current bus
	p_lastbus 	db	?	;+ last bus number
;tmp_pci	ends
	;
	; get byte [EBX] -> AL
	;
pci_getb:	mov 	eax,ebx	;set index
	mov	dx,pci_ad
	and	al,0fch	;mask low bits
	out 	dx,eax
	mov	dl,bl	;I/O port index
	or	dl,0fch	;pci_dat assume $fc + bit mask
	in	al,dx
	ret
	;
	; get word [EBX] -> AX
	;
pci_getw:	mov 	eax,ebx	;set index
	mov	dx,pci_ad
	and	al,0fch	;mask low bits
	out 	dx,eax
	mov	dl,bl	;I/O port index
	or	dl,0fch	;pci_dat assume $fc + bit mask
	in	ax,dx
	ret
	;
	; get double word [EBX] -> EAX
	;
pci_getd:	mov 	eax,ebx	;set index
	mov	dx,pci_ad
	out 	dx,eax
	mov	dx,pci_dat
	in 	eax,dx
	ret
	;
	; assign interrupts to device [EBX]
	;
pci_airq:	mov	bl,p_pin	;which interrupt pin does device use ?
	call	pci_getb
	mov	ah,0
	sub	al,1	;0 -> FF
	mov	si,ax
	jb	pci_airq3	;0 -> FF = no interrupt
	cmp	al,3
	mov	al,0ffh
	ja	pci_airq3	;out of range -> FF = no interrupt
	mov	al,byte ptr [ds:si+p_int]	;get interrupt connected to this line
pci_airq3: mov	bl,p_line	;store interrupt number
	;V fall through
	;
	; set byte AL -> [EBX]
	;
pci_setb:	push	ax
	mov 	eax,ebx	;set index
	mov	dx,pci_ad
	and	al,0fch	;mask low bits
	out 	dx,eax
	pop	ax
	mov	dl,bl	;I/O port index
	or	dl,0fch	;assume pci_dat $fc + bit mask
	out	dx,al
	ret
	;
	; set word AX -> [EBX]
	;
pci_setw:	push	ax
	mov 	eax,ebx	;set index
	mov	dx,pci_ad
	and	al,0fch	;mask low bits
	out 	dx,eax
	pop	ax
	mov	dl,bl	;I/O port index
	or	dl,0fch	;assume pci_dat $fc + bit mask
	out	dx,ax
	ret
	;
	; set double word EAX -> [EBX]
	;
pci_setd:	xchg 	eax,ebx
	mov	dx,pci_ad
	out 	dx,eax
	xchg 	eax,ebx
	mov	dx,pci_dat
	out 	dx,eax
	ret
	;
	; allocate space for a device, CL = ending index
	; (different for normal device / bridge)
	;
pci_dev:	mov	bl,p_base
pci_dev1:	mov 	eax,0ffffffffh	;find out how many valid bits
          call	pci_setd	;write
          call	pci_getd	;and read back
         	mov	ch,al	;save register type
	test	al,1	;I/O ?
	jz	pci_dev1a	;:no
	and	ax,ax	;high bit set ? (D15)
	jns	pci_dev9	;no: this register doesn't work
	jmp	pci_io	;allocate I/O device
	
pci_dev1a: and 	eax,eax	;high bit set ? (D31)
	jns	pci_dev9	;no: this register doesn't work !
	test	al,2	;below 1 MB ?
	jnz	pci_memr
	mov	si,p_memp
	test	al,8	;prefetchable ?
	jnz	pci_dev2	;:yes
	mov	si,p_mem
	
	; allocate memory (normal or prefetchable)
	;
	; we allocate with a minimum of 64KB granularity
	
pci_dev2:	shr 	eax,16	;/ 64KB
	not 	ax	;get requested block size
	cmp	ax,P_MEMINC-1	;round up to minimum increment
	ja	pci_dev3
	mov	ax,P_MEMINC-1
pci_dev3:	test	[si],ax	;do we need to round up base ?
	jz	pci_dev4	;:no
	or	[si],ax	;round up base
	inc	word ptr [ds:si]
	jz	pci_err2	;:overflow
pci_dev4:	inc	ax	;size + 1
	add	ax,[si]	;update base
	jb	pci_err2	;overflow: error
	cmp	ax,[si+2]	;exceed limit ?
	ja	pci_err2	;:yes
	xchg	ax,[si]	;set new base, get starting base
	shl 	eax,16	;-> high word, low base is 0
pci_dev7:	call	pci_setd	;set base register
pci_dev8:	test	ch,4	;64 bit base register ?
	jz	pci_dev9	;:32 bit
	add	bl,4
	xor 	eax,eax	;clear high register
pci_dev8a: call	pci_setd
pci_dev9:	add	bl,4
	cmp	bl,cl	;end of registers ?
	jb	pci_dev1	;:try another
	ret
	
pci_err2:	mov	al,0c2h	;& error code
	jmp	pci_err9
	
pci_err3:	mov	al,0c3h	;& error code
	jmp	pci_err9
	
pci_err4:	mov	al,0c4h	;& error code
	jmp	pci_err9
	;
	; Allocate <1MB memory space
	;
pci_memr:	test	al,4	;reserved type ?
	jnz	pci_err4	;:yes
	not 	eax	;find out requested block size
	shr 	eax,4	;/16
	test 	eax,0ffff0000h	;error if device wants more than 1MB !
	jnz	pci_err3
	cmp	ax,P_MEMRINC-1	;round up to minimum increment
	ja	pci_memr2
	mov	ax,P_MEMRINC-1

	;&&& need to add base rounding

pci_memr2: add	ax,[p_memr]	;update base
	jb	pci_err2	;overflow: error
	cmp	ax,[p_memrlim]	;exceed limit ?
	ja	pci_err2	;:yes
	xchg	[p_memr],ax	;get old base, set new
	shl 	eax,4	;-> get back into place
			;(high EAX is 0 from 1MB test)
	jmp	short pci_dev7	;set base register, continue
	;
	; Allocate I/O space
	;
	; Note that I/O is allocated in 256 byte blocks starting at
	; $1000, $1400, etc. (aliases of chipset registers 0000..00FF)
	;
	; Space in x100 .. x3FF is reserved for ISA bus. Space in 0000..00FF
	; and 0480..04FF is reserved for chipset peripherals. 0CF8..0CFF is
	; the PCI config address. So we usually start at 1000.
	;
pci_io:	not	ax	;find out requested block size
	test	ax,0ff00h	;> 256 bytes ?
	jnz	pci_err5	;:error
	or	ax,P_IOINC-1	;minimum allocation
	
	test	[p_io],ax	;do we need to round up ?
	jz	pci_ior2	;:no
	or	[p_io],ax	;base must be multiple of block size
	inc	word ptr [ds:p_io]
	test	word ptr [ds:p_io],0300h	;block overrun ?
	jz	pci_ior2	;:no
	or	word ptr [ds:p_io],03ffh	;next 1024 byte block
	inc	word ptr [ds:p_io]
	jz	pci_err5	;:overflow
pci_ior2:
	inc	ax	;mask -> count
	add	ax, word ptr [ds:p_io]	;base + block size -> future base
	test	ax,0300h	;block overrun ?
	jz	pci_ior3	;:no
	or	ax,03ffh	;next 1024 byte block
	inc	ax
	jz	pci_err5	;:overflow
pci_ior3:	cmp	ax,[p_iolim]	;exceeded limit ?
	ja	pci_err5	;:overflow

	xchg	[p_io],ax	;get old base, set new
	and 	eax,0ffffh	;clear high half of EAX
	jmp	pci_dev8a	;set base register, continue
	
pci_err5:	mov	al,0c5h	;& error code
	jmp	pci_err9
	;
	; round up [SI], mask CL, set limit using DX if primary bus,
	; DI if secondary bus
	;
pci_rnd:	mov	ax,[si]
	test	al,cl
	jz	pci_rnd1
	or	al,cl
	inc	ax
	jz	pci_err1
	mov	[si],ax
pci_rnd1:	cmp	byte ptr [ds:p_bus],0	;primary bus ?
	jnz	pci_rnd2
	add	ax,dx	;primary bus limit
	jmp	short pci_rnd3
	
pci_rnd2:	add	ax,di	;secondary bus limit
pci_rnd3:	jb	pci_err1	;:too much
	mov	[si+2],ax	;set limit
	ret

pci_err1:	jmp	pci_bus9	;allocation error
	;
	; allocate space for a bridge
	;
pci_bri:	inc 	byte ptr [ds:p_lastbus]	;get a new bus number
	mov	ax,word ptr [ds:p_bus]	;+ lastbus
	mov	bl,pb_bus	;set primary, secondary bus number
	call	pci_setw
	mov	ax,P_SECLAT * 256 + 0ffh	;subordinate = 255 for config
	mov	bl,pb_bus3	;+ pb_lat2
	call	pci_setw

	; save variables for recursion	

	mov	al,[p_lastbus]	;save old bus number, set new
	xchg	al,[p_bus]
	push	ax
	push	[p_memlim]
	push	[p_memplim]
	push	[p_iolim]
	
	;bridges don't have fine granularity - start at 1MB / 4K boundaries
	
	mov	si,p_mem	;memory: 1MB boundaries
	mov	dx,P_MEMINC1	;primary bus
	mov	di,P_MEMINC2	;secondary bus
	mov	cl,0fh
	call	pci_rnd
	
	mov	si,p_memp	;prefetch memory: 1MB boundaries
	;mov	dx,P_MEMINC1	;primary bus
	;mov	di,P_MEMINC2	;secondary bus
	;mov	cl,0fh
	call	pci_rnd
	
	mov	si,p_io	;I/O: 4K boundaries
	mov	cl,0ffh
	mov	dx,P_IOINC1	;primary bus
	mov	di,P_IOINC2	;secondary bus
	call	pci_rnd
	
	;set bridge base and limit registers
	
	mov	bl,pb_mem	;memory base / limit
	mov 	eax, dword ptr [ds:p_mem]	;+ p_memlim
	sub 	eax,10000h	;-> inclusive limit
	call	pci_setd
	mov	bl,pb_memp	;prefetchable base / limit
	mov 	eax, dword ptr [ds:p_memp]	;+ p_memplim
	sub 	eax,10000h	;-> inclusive limit
	call	pci_setd
	mov	bl,pb_io	;I/O base / limit
	mov	al, byte ptr [ds:p_io+1]
	mov	ah, byte ptr [ds:p_iolim+1]
	dec	ah	;-> inclusive limit
	call	pci_setw
	
	;clear high registers
	
	xor 	eax,eax	;clear high memory base
	mov	bl,pb_mem2
	call	pci_setd
	mov	bl,pb_memp2	;clear high prefetchable base
	call	pci_setd
	mov	bl,pb_io2	;clear high I/O base
	call	pci_setd
		
	; save variables for recursion
	
	push	word ptr [ds:p_capa]
	push 	dword ptr [ds:p_int]
	
	mov	word ptr [ds:p_capa],80h	;bus capabilities
	mov	bl,pb_stat	;read secondary status
	call	pci_getw
	and	byte ptr [ds:p_capa],al	;clear fast back to back if not supportd
	or	byte ptr [ds:p_capa+1],ah	;set devsel timing
	
	mov	bl,p_cmd	;command register: enable bus master
	call	pci_getw
	or	al,04
	mov	bl,p_cmd
	call	pci_setw

	push 	ebx	;save current EBX
	rol 	dword ptr [ds:p_int],8	;precompensate for interrupt rotation
	
	call	pci_bus	;enumerate this bus
	call	pci_capa	;set capability flags
	
	; limit -> new allocation pointer

	mov	ax,[p_memlim]	;memory
	mov	[p_mem],ax
	
	mov	ax,[p_memplim]	;prefetchable memory
	mov	[p_memp],ax
	
	mov	ax,[p_iolim]	;I/O
	mov	[p_io],ax
	
	; restore variables

	pop ebx	;restore after recursion
	pop 	dword ptr [ds:p_int]
	pop	word ptr [ds:p_capa]
	pop	word ptr [ds:p_iolim]
	pop	word ptr [ds:p_memplim]
	pop	word ptr [ds:p_memlim]
	pop	ax
	mov	word ptr [ds:p_bus],ax
	
	mov	al,[p_lastbus]	;set correct subordinate bus number
	mov	bl,pb_bus3
	call	pci_setb

	mov	bl,pb_ctl	;set bridge control register
	mov	ax,P_BRIDGE
	and	byte ptr [ds:p_capa],80h	;isolate fast back to back bit
	or	al,byte ptr [ds:p_capa]	;copy to control register
	call	pci_setw
	ret
	;
	; get next interrupt assignment
	;
pci_nint:	test	bh,7	;function 0 ?
	jnz	pci_nint4	;no: same interrupts
	cmp	byte ptr [ds:p_bus],0	;primary bus ?
	jnz	pci_nint5	;:no
	cmp	word ptr [ds:p_irqpt], offset pci_tab9	;end of IRQ table ?
	jz	pci_nint4	;yes: don't change
	mov	si, word ptr [ds:p_irqpt]	;get next table entry
	cs 	lodsd
	mov	word ptr [ds:p_irqpt],si
	mov dword ptr [ds:p_int],eax	;save interrupt setting
pci_nint4: ret
	
pci_nint5: ror 	dword ptr [ds:p_int],8	;rotate interrupts
	ret
	;
	; enumerate a bus - called recursively
	;
pci_bus:	mov	bh,80h	;enable config access
	mov	bl,byte ptr [ds:p_bus]	;bus number
	shl 	ebx,16	;device, function = 0

	; check vendor ID, 0 or FFFF = nothing there, skip device

pci_bus0:	call	pci_nint	;get next interrupt assignment
	mov	bl,p_id	;get vendor / device ID
	call	pci_getd
	inc	ax	;FFFF = not present
	jz	pci_bus4	;:skip device
	dec	ax	;0000 = no more functions
	jz	pci_bus4	;:skip device
	
	call	pci_airq	;assign interrupts

	call	pci_vga	;handle PCI VGA
	
	; check header type, different handling if bridge

	mov	bl,p_hedt	;get header type
	call	pci_getb
	
	and	al,7fh
	cmp	al,1	;bridge
	jz	pci_bus1
ifdef	PCI_NORST
	cmp	bh,PCI_NORST	;don't touch base registers on this
	jz	pci_bus3	;device (pd 980728: was jz pci_bus2)
endif
ifdef	PCI_NORST2
	cmp	bh,PCI_NORST2
	jz	pci_bus3
endif
	mov	cl,p_cis	;end index for normal device
	call	pci_dev	;allocate resources
	jmp	short pci_bus2

pci_bus1:	mov	cl,pb_bus	;end index for bridge
	call	pci_dev	;allocate resources
	call	pci_bri	;enumerate secondary buses

	; try next function

pci_bus2:	test	bh,7	;function 0 ?
	jnz	pci_bus4	;:no, try next subfunction
	
	; function 0 - is this a multifunction device
	
	mov	bl,p_hedt	;get header type
	call	pci_getb
	
	and	al,80h
	jnz	pci_bus4	;:yes, multifunction device
pci_bus3:	or	bh,7	;step to next device
pci_bus4:	inc	bh
	jnz	pci_bus0
	mov	ax,[p_mem]	;check allocation limits
	cmp	ax,[p_memlim]
	ja	pci_bus9	;:error
	mov	ax,[p_memp]
	cmp	ax,[p_memplim]
	ja	pci_bus9	;:error
	mov	ax,[p_io]
	cmp	ax,[p_iolim]
	ja	pci_bus9
	ret
	
pci_bus9:	mov	al,0e5h	;error !
pci_err9:	call	postcode 	;pd 980728: don't do direct I/O
pci_err99: jmp	pci_err99
	;
	; handle PCI VGA
	;
pci_vga:	mov	bl,p_class	;read class ID
	call	pci_getd
	shr	eax,16	;check high 16 bits
	cmp	ax,0300h	;VGA ?
	jnz	pci_vga9	;:no
	
	mov	bl,p_cmd	;enable memory access
	call	pci_getw
	push	ax
	or	al,2
	call	pci_setw
	
	mov	bl,p_rom	;enable ROM - at P_ROM0
	mov	esi,P_ROM0 shl 16
	mov 	eax,esi
	inc	ax	;low bit = 1 -> enable
	call	pci_setd
	push 	ebx	;save ebx context
	
	call	getunreal	;enter unreal mode
	
	mov	ax,[esi]
	cmp	ax,0aa55h	;ROM header ?
	jnz	pci_vga2	;:no
	call	cs_vshad2	;copy video BIOS to shadow RAM
			;(chipset specific)
	
pci_vga2:	pop 	ebx	;restore ebx
	xor 	eax,eax	;disable ROM
	call	pci_setd

	pop	ax	;restore command register
	mov	bl,p_cmd
	call	pci_setw

	xor	ax,ax	;restore segment (from unreal mode)
	mov	ds,ax
	mov	es,ax
pci_vga9:	ret
	;
	; set capability bits & enable devices
	;
pci_capa:	xor	bx,bx	;start with device / function 0
	mov	cx,P_COMMAND	;standard command value
	cmp	byte ptr [ds:p_capa],80h	;all devices back-to-back capable ?
	jnz	pci_capa1	;:no
	or	ch,02	;enable fast back-to-back mode
pci_capa1: mov	bl,p_id	;get vendor / device ID
	call	pci_getw
	inc	ax	;FFFF = not present
	jz	pci_capa4	;:skip device
	dec	ax	;0000 = no more functions
	jz	pci_capa4	;:skip device

	mov	bl,p_cmd	;read command register
	call	pci_getw
	and	ax,0ff5fh	;clear stepping, palette snoop bits
	or	ax,cx	;enable according to P_COMMAND
	call	pci_setw	;set command register

ifdef	P_LINSIZE
	mov	bl,p_linesz
	mov	al,P_LINSIZE
	call	pci_setb
endif

	; try next function

	test	bh,7	;function 0 ?
	jnz	pci_capa4	;:no, try next subfunction
	
	; function 0 - is this a multifunction device
	
	mov	bl,p_hedt	;get header type
	call	pci_getb
	
;	mov 	eax,ebx	;device address
;	mov	al,p_hedt and 0fch	;header type
;	mov	dx,pci_ad
;	out 	dx,eax
;	mov	dl,low(pci_dat) + 2
;	in 	al,dx
	and	al,80h
	jnz	pci_capa4	;:yes, multifunction device
	or	bh,7	;step to next device
pci_capa4: inc	bh
	jnz	pci_capa1
	ret
	;
	; PCI plug & play configuration
	;
	; EAX = scratch
	; EBX = 80 / bus / device / function / index
	; CX  = scratch
	; DX  = port address
	; SI  = scratch
	; DI  = scratch
	; BP  = scratch
	;
pci_pnp:
	mov	word ptr [ds:p_mem],P_MEM0	;set starting addresses
	mov	word ptr [ds:p_memp],P_MEMP0
	mov	word ptr [ds:p_memr],P_MEMR0
	mov	word ptr [ds:p_io],P_IO0
	mov	word ptr [ds:p_memlim],P_MEM9	;set allocation limits
	mov	word ptr [ds:p_memplim],P_MEMP9
	mov	word ptr [ds:p_memrlim],P_MEMR9
	mov	word ptr [ds:p_iolim],P_IO9
	;mov	byte [p_bus],0
	;mov	byte [p_lastbus],0
	mov	word ptr [ds:p_irqpt],offset pci_tab
	
	call	pci_bus	;enumerate bus
	call	pci_capa	;set capability flags

	mov	al,[p_lastbus]	;set number of last PCI bus
	mov 	byte ptr [cs:d_lastbus],al
	ret
	;
	; Disable all devices on primary bus
	;
	; NOTE: Called without stack ! On a chipset with PCI reset
	; function, PCI reset is the easier way...
	;
pci_rst:

ifdef	PCI_NOCLR
	ret
else

ifdef	PCI_NORST
	mov 	eax,p_cmd+80000800h	;start with device 1 (don't cut off
			;chipset)
else
	mov 	eax,p_cmd+80000000h	;access bus 0, device 0, function 0
endif

pci_rst1:

ifdef	PCI_NORST
	cmp	ah,PCI_NORST	;don't reset this device
	jnz	pci_rst2
	add	ah,8
pci_rst2:
endif
	mov	dx,pci_ad
	out 	dx,eax	;write index
	xchg	ax,bx
	mov	dx,pci_dat
	in	ax,dx	;read command register
	and	ax,0fff8h	;disable bus master, I/O, memory access
	xchg	ax,bx
	mov	dx,pci_ad
	out 	dx,eax	;write index
	xchg	ax,bx
	mov	dx,pci_dat
	out	dx,ax	;write command register
	xchg	ax,bx
	inc	ah	;next device / function
	jnz	pci_rst1
	ret
endif

