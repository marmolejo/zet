	;
	; POST power on self-test
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; pd 991021 add option for M-Systems DiskOnChip
	
ifndef	ROM_BEG
ROM_BEG	equ	0c800h	;start of ROM scan
endif

ifndef	ROM_END
ROM_END	equ	0f800h	;end of ROM scan
endif

ifndef	VGA_BEG
VGA_BEG	equ	0c000h	;start of VGA BIOS scan
endif

ifndef	VGA_END
VGA_END	equ	0c800h	;end of VGA BIOS scan
endif
	;
	; Reset entry
	;
	; Note: Processor shutdown is NOT supported. There are easier and
	; faster ways to get out of protected mode.
	;
reset:
	cli
	cld
	xor ax,ax
	mov ds,ax
	mov	ax,cs	;SS = CS (to support fake stack)
	mov	ss,ax
	mov	al,01h	;POST code: reset entry
	ret_sp	postcode
	
	ret_sp	cs_clr	;clear chipset registers to allow
			;access to DMA, IRQ controller
	ret_sp	post_clr	;clear registers
	;
	; Initialize chipset
	;
resetcs:	mov	al,02h	;POST code: chipset initialization
	ret_sp	postcode
	;ret_sp	cs_init	;initialize chipset
rstini:	jb	rstvid	;:shadow already enabled
	;
	; Detect base memory size
	;
	mov	al,03h	;POST code: detect base memory size
	ret_sp	postcode
	;ret_sp	cs_det	;detect memory
rstdet:			;may return by RET or JMP
	;
	; Init shadow RAM - if DRAM is bad, we'll die here
	; (running out of shadow makes for a more effective
	; memory test, and accelerates startup).
	;
	mov	al,04h	;POST code: initialize shadow RAM
	ret_sp	postcode
	;ret_sp	cs_shad	;init shadow
rstshad2:
	;
	; Init Hercules video card (blind init, we don't care if it's there)
	;
rstvid:	mov	al,05h	;POST code: init mono video
	ret_sp	postcode
ifndef	NO_VIDINIT
	ret_sp	vid_init	;let there be light ...
endif
	;
	; disable all PCI adapters on primary bus -> get bus masters
	; to shut up...
	;
ifdef	PCI
rstpci:	mov	al,06h	;POST code: disable PCI devices
	ret_sp	postcode
	ret_sp	pci_rst
endif
	;
	; Check low 64KB of DRAM
	;
	mov	al,07h	;POST code: test low 64KB of DRAM
	ret_sp	postcode
;	ret_sp	getunreal	;enter unreal mode
;	xor 	ebp,ebp	;start address
	mov	dx,ds:[m_rstflg]	;save reset flag
;	ret_sp	post_t64k	;test first 64K of DRAM
	jnb	rstmem5	;:ok
	mov	al,0f7h	;POST code: low 64KB failure
	jmp	fatal	;handle fatal error

rstmem5:
	;mov	ax,dx				;restore reset flag
	mov	ds:[m_rstflg], dx		;restore reset flag
	;
	; initialize stack
	;
	mov	al,08h	;POST code: initialize stack
	ret_sp	postcode
	mov	sp,tmp_stack	;set stack
	xor	ax,ax
	mov	ss,ax
	;
	; Set CPU specific parameters, enable L1 cache
	;
	; call	cs_cpu
	;
	; Check BIOS checksum
	;
	mov	al,09h	;POST code: BIOS checksum
	call	postcode
	call	cs_shadrw	;set read/write shadow
	call	d_dosum	;update data checksum
	call	cs_shadro	;set read only shadow
ifndef	NO_ROMSUM
	call	post_sum	;verify BIOS checksum
	call	post_err	;hang if error
endif
	;
	; Configure super I/O
	;
	mov	al,0ah	;POST code: super I/O initialization
	call	postcode
	call	sio_init
	;
	; Clear RTC interrupts, test shutdown byte, set operating mode
	;
	mov	al,0bh	;POST code: RTC test
	call	postcode
ifndef	RTC_SKIP
	call	rtc_test
ifndef	IGNORE_RTC
	call	post_err
endif
endif
	;
	; Test refresh (and indirectly, 8254 timer)
	;
	mov	al,0ch	;POST code: refresh / 8254 test
	call	postcode
	call	post_ref
	call	post_err
	;
	; Set speed-dependent chipset registers
	; (done after post_ref)
	;
	mov	al,0dh 	;POST code: speed-dependent chipset regs
	call	postcode
	call	cs_spd
	;
	; Test 8237 DMA registers
	;
	mov	al,0eh 	;POST code: test 8237 DMA
	call	postcode
ifndef	DMA_SKIP
	call	post_dma
	call	post_err
endif
	;
	; Test DMA page registers
	;
	mov	al,0fh	;POST code: test DMA page registers
	call	postcode
	call	post_page
	call	post_err
	;
	; Test 8254 registers
	;
	mov	al,10h	;POST code: test 8254 registers
	call	postcode
	call	post_tim
	call	post_err
	;
	; Test keyboard controller (don't care whether we have a keyboard)
	;
	mov	al,11h	;POST code: test keyboard controller
	call	postcode
	call	kb_ini
ifndef	NO_KBC
	call	post_err
endif
	;
	; Initialize Timer, DMA, interrupt registers, port 92
	;
	mov	al,12h	;POST code: init timer, DMA, 8259...
	call	postcode
	call	post_tdma
	;
	; Test 8259 interrupt mask registers
	;
	mov	al,13h	;POST code: test 8259 mask registers
	call	postcode
	call	post_irq
	call	post_err
	;
	; Size and test low 640 KB
	;
	mov	al,14h	;POST code: test low 640KB
	call	postcode
	call	post_base	;base memory test						To Do!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;
	; Initialize memory locations, interrupt vectors, etc.
	;
	mov	al,15h	;POST code: init vectors
	call	postcode
	call	post_vec	;init interrupt vectors					To Do!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	call	vid_vars	;initialize Hercules video BIOS vars
	;mov	byte ds:[m_devflg], 00110000b	;no floppy present, monochrome
	mov	byte ptr ds:[m_devflg], 030h	;no floppy present, monochrome
	
ifdef	GX_VID
	call	gx_video	;initialize GX video
endif
ifdef	GX_INT10
	call	gxv_init	;initialize GX int 10
endif
ifdef	VID_CGA
	call	cs_cga	;enable CGA redirect
endif
	;
	; run PCI plug & play
	;
ifdef	PCI
	mov	al,16h	;POST code: PCI plug & play
	call	postcode
	call	cs_shadrw	;enable read / write shadow

ifndef	SKIP_PNP
	call	pci_pnp
	
	mov 	eax,(INTD shl 24)+(INTC shl 16)+(INTB shl 8)+INTA
	call	cs_pciint	;set interrupt channels
endif
endif
	;
	; shadow video BIOS (unless PCI already did it)
	;
	mov	al,17h	;POST code: shadow video BIOS
	call	postcode
	call	cs_vshad
	;
	; Look for VGA video BIOS at C000
	;
	mov	al,18h	;POST code: look for VGA BIOS
	call	postcode
	mov	bx,VGA_BEG	;starting address
	mov	dx,VGA_END	;ending address
	call	post_scan
	mov	ax,cs
	cmp	ds:[vec10+2],ax	;did VGA initialize ?
	jz	rstmda	;:no, still same interrupt
	mov	byte ptr ds:[m_devflg],0	;VGA
rstmda:
	;
	; Display signon prompt, base memory size
	;
	mov	al,19h	;POST code: sign-on prompt
	call	postcode
ifdef	CONSOLE
	call	con_init	;initialize serial console
endif
	mov	si, offset copyrt
	call	v_msg

;	xor 	eax,eax
	xor 	ax,ax
	mov	ax,[m_lomem]	;memory size
	call	post_itoa	;display number						To Do!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	mov	si, offset msg_base	;display " KB Base Memory"
	call	v_msg
	;
	; keyboard test #2
	;
	mov	al,1ah	;POST code: second keyboard test
	call	postcode
	call	kb_inb
	;
	; Size and test extended memory
	;
	mov	al,1bh	;POST code: extended memory test
	call	postcode
ifndef	SKIP_EXTEST
	call	cs_a20on	;enable A20 gate
	call	post_ext	;test extended memory				To Do!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
endif
	;
	; keyboard test, enable timer tick, enable interrupts
	;
	mov	al,1ch	;POST code: enable interrupts
	call	postcode
	call	kb_inc	;continue keyboard initialization
	call	tim_init	;initialize timer tick, unmask ints
	sti		;enable interrupts
	call	kb_ind	;set keyboard LEDs
	;
	; test & init RTC
	;
	mov	al,1dh	;POST code: test / init RTC
	call	postcode
	call	rtc_ini
	;
	; Initialize floppy disk: detect, spin up, recalibrate
	;
	mov	al,1eh	;POST code: init floppy disk
	call	postcode
	call	fd_init
	;
	; ROM scan
	;
ifndef	DISKONCHIP
	mov	al,1fh	;POST code: option ROM scan
	call	postcode
ifndef	NO_ROMSCAN
	mov	bx,ROM_BEG	;starting address
	mov	dx,ROM_END	;ending address
	call	post_scan
endif
endif
	;
	; Test & init parallel ports
	;
	mov	al,20h	;POST code: test parallel ports
	call	postcode
	call	lp_test
	;
	; Test & init serial ports
	;
	mov	al,21h	;POST code: test serial ports
	call	postcode
	call	rs_test
	;
	; enable numeric coprocessor
	;
	mov	al,22h	;POST code: enable coprocessor
	call	postcode
	call	cs_npx
	;
	; secondary floppy init
	;
	mov	al,23h	;POST code: floppy init
	call	postcode
	call	fd_inb
	;
	; IDE initialization
	;	
	mov	al,24h	;POST code: hard disk init
	call	postcode
	call	cs_shadrw	;set read/write shadow
	call	hd_init	;init disk drives
	call	d_dosum	;update data checksum
	call	cs_shadro	;set read only shadow
	;
	; Flash disk initialization
	;
ifdef	FLASHDISK
	call	fld_init	;initialize flash disk
endif
	;
	; ROM scan (alternate location for M-Systems DiskOnChip)
	;
	; Caution: their firmware version 3.3.5 will HANG if no HDD
	; present. Connect a HDD, and update their boot image to
	; DOC121.EXB or later.
	;
ifdef	DISKONCHIP
	mov	al,1fh	;POST code: option ROM scan
	call	postcode
ifndef	NO_ROMSCAN
	mov	bx,ROM_BEG	;starting address
	mov	dx,ROM_END	;ending address
	call	post_scan
endif
endif
	;
	; detect PS/2 mouse
	;
ifndef	PS2MOUSE
	mov	al,25h 	;POST code: PS/2 mouse detect
	call	postcode
	mov	ax,0c201h	;reset pointing device
	int	15h
	jb	msdet2
	cmp	bx,00aah	;mouse ?
	jnz	msdet2
	or	byte ptr ds:[m_devflg],4	;set PS/2 mouse flag
msdet2:	

endif
	;
	; Timer / RTC update check
	;
	; Note: This test can take up to one second (normally overlapped
	; with floppy / IDE init), skip if not required.
	;
	mov	al,26h 	;POST code: timer/RTC check
	call	postcode
ifndef	NO_RTCFAIL
	call	tim_test
	cmp	byte ptr ds:[tmp_tim],0
rsttim:
	jnz	rsttim	;hang if failure
endif
	;
	; enable L2 cache if present
	;
ifdef	cs_cache
	mov	al,27h
	call	postcode
	call	cs_cache
endif
	;
	; OEM decision: verify diagnostic flags to decide
	; whether to boot or display error messages
	;
	mov	al,28h	;POST code: OEM boot decision point
	call	postcode
	call	decide
	;
	; clean up before boot
	;
	mov	word ptr ds:[m_rstflg],0	;clear reset flag
	mov	di,0500h	;clear temporary data area: 0500..11FF
	mov	cx,(1200h-0500h) / 2
	xor	ax,ax
	rep	stosw	;this also overwrites stack !
	;
	; Boot operating system
	;
	mov	al,00h	;POST code: boot
	call	postcode
ifdef	BOOTBEEP
	call	beep	;let there be noise
endif
	int	19h	;boot
	mov	al,0dfh	;we shouldn't get here
	call	postcode
	cli
	hlt		;hang
