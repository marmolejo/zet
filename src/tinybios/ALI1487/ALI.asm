	;
	; System specific code
	;
	; ALI M1487 chipset
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
TOP_MEM	equ	0400h	;memory size limit = 64 MB
	;
	; IDE timing parameters 25 / 30 MHz
	;
CS_IDE8	equ	10	;8 bit command time for 25/30 MHz
			;8 for mode 3
CS_IDE8R	equ	10	;8 bit recovery time
CS_IDE16	equ	6	;16 bit command time for 25/30 MHz
			;3 for mode 3
CS_IDE16R	equ	8	;16 bit recovery time
			;3 for mode 3
	;
	; IDE timing parameters 33 MHz
	;
CS_IDE8b	equ	10	;8 bit command time
CS_IDE8Rb	equ	14	;8 bit recovery time
CS_IDE16b	equ	6	;16 bit command time
			;5 for mode 3
CS_IDE16Rb equ 	10	;16 bit recovery time
	;
	; Equates
	;
idx	equ	22h	;configuration index register
dat	equ	23h	;configuration data register

cxidx	equ	22h	;Cyrix index register
cxdat	equ	23h	;Cyrix data register

idelock	equ	0f4h	;ALI IDE unlock register
ideidx	equ	0f8h	;ALI IDE index register
idedat	equ	0fch	;ALI IDE data register

pci_cfg	equ	0cfbh	;PCI mechanism control register
	;
	; initialize chipset
	;
	; set all registers, detect memory size
	; keep L2 cache disabled at this point
	; set CPU specific registers if required
	;

	; initialize Cyrix CPU
	
cs_init:
;	mov	eax,cr0
;	or 	eax,20000000h	;enable write back
;	mov	cr0,eax
	
;	mov	al,0c1h	;CPU configuration register 1:
;	out	cxidx,al
;	mov	al,00010000xb	;No LOCK#, no SMI, RPL pins
;	out	cxdat,al
	
;	mov	al,0c2h	;CPU configuration register 2:
;	out	cxidx,al
;	mov	al,01011110xb	;disable SUSP, write through 640K-1M,
;	out	cxdat,al	;lock NW, suspend on halt, enable INVAL,
;			;WM_RST, burst write
			
	; get chipset registers from table
	
	mov	si,offset cs_tab
cs_ini1:	cs:	lodsw	;get index / data from table
	cmp	al,0ffh
	jz	cs_ini2	;:end
	out	idx,al
	mov	al,ah
	out	dat,al
	jmp	cs_ini1

cs_ini2:	mov	dx,pci_cfg	;enable PCI configuration mechanism #1
	mov	al,1
	out	dx,al

	; if shadow enabled, don't touch memory / shadow configuration
	
	mov	al,14h	;shadow read enabled ?
	out	idx,al
	in	al,dat
	and	al,10h
	jz	cs_ini3	;:no
	stc		;return, already in shadow
	ret

cs_ini3:	cs:	lodsw	;get index / data from table
	cmp	al,0ffh
	jz	cs_ini4	;:end
	out	idx,al
	mov	al,ah
	out	dat,al
	jmp	cs_ini3

cs_ini4:	clc		;return, full initialization
	ret
	;
	; CPU specific settings
	;
cs_cpu:	pushfd	
	pop 	eax
	or 	eax,00200000h	;bit 21 modifiable -> CPUID supported
	push 	eax
	popfd	
	pushfd
	pop 	eax
	test 	eax,00200000h
	jz	cs_wt	;no CPU ID: stay in write through mode

	; get CPU ID

	xor 	eax,eax
	cpuid
	cmp 	ecx,444d4163h	;"cAMD"
	jnz	cs_notamd
	
	; set correct mode for AMD CPU
	
	cpuid		;get device type
	and	al,0f0h	;mask out stepping
	cmp	al,70h
	jz	cs_wb	;70: DX2 in WB mode
	cmp	al,90h
	jz	cs_wb	;90: DX4 in WB mode
	cmp	al,0f0h
	jz	cs_wb	;F0: DX5 in WB mode
	jmp	short cs_wt	;else write through
	
	; set correct mode for Intel CPU
	
cs_notamd: cmp 	ecx,6c65746eh	;"ntel"
	jnz	cs_wt
	
	cpuid		;get device type
	and	al,0f0h	;mask out stepping
	cmp	al,90h
	jz	cs_wb	;90: CPU in WB mode
	jmp	short cs_wt
	
	; set Intel / AMD write back mode

cs_wb:	mov	al,19h	;set Intel / AMD write back mode
	out	idx,al
	in	al,dat
	and	al,3fh
	or	al,40h
	out	dat,al

	mov	al,16h	;enable L1 write back
	out	idx,al
	in	al,dat
	or	al,04
	out	dat,al

	; enable L1 (CPU) cache
	
cs_wt:	invd
	mov	eax,cr0
	and 	eax,9fffffffh
	mov	cr0,eax
	ret
	;
	; Detect memory
	;
	; EAX = scratch
	; BX = DRAM configuration all banks (shifted left)
	; CL = bank number (0..3)
	; DX = scratch / return address
	; SP = return pointer
	; DS = 0
	;
	; Cache must be off !
	;
cs_det:	xor	ax,ax	;set low 64K segment
	mov	ds,ax
	mov	cl,3	;start with bank 3
	
	; test a bank
	
cs_det2:	shl	bx,4	;make space for next bank
	mov	ah,0100xb	;set bank to 16 Mb DRAM
	mov	dx,cs_det3
	jmp	cs_memset
	
	; see whether there is any life in this bank - test first two words
	
cs_det3:	mov 	eax,55aaff00h
	mov 	[0],eax
	not 	eax
	mov 	[4],eax
	not 	eax
	
	cmp 	[0],eax
	jnz	cs_det4	;:fail
	not 	eax
	cmp 	[4],eax
	jz	cs_det5	;:ok
cs_det4:	or 	bl,1111xb	;nothing in this bank
	jmp	cs_det91
	
	; See how large the bank is
	
	; This is done by determining how many row address bits there are.
	; If a bit isn't there, we'll overwrite location 0. See M1487 data
	; book page 109 for memory address mapping. Remember that we are
	; in 16 Mbit mode.
	
cs_det5: 	mov 	[2048],eax
	cmp 	[0],eax
	jnz	cs_det6
	mov	al,0000	;256 Kbit bank
	jmp	short cs_det20
	
cs_det6:	mov 	[4096],eax
	cmp 	[0],eax
	jnz	cs_det7	;overwrite -> 1 or 2 Mbit bank
	
	mov	ah,0101xb	;set 2 Mbit (2Mx8)
	mov	dx,cs_det6a
	jmp	cs_memset
	
	; differentiate between 1Mx16 / 1Mx4 and 2Mx8 memory
	
cs_det6a:	mov 	eax,55aaff00
	mov 	[0],eax
	not 	eax
	mov 	[8192],eax
	cmp 	[0],eax
	mov	al,0001xb	;overwrite -> 1 Mbit (1Mx16)
	jz	cs_det20
	mov	al,0101xb	;2Mx8
	jmp	short cs_det20

cs_det7: 	mov 	[8192],eax
	cmp 	[0],eax
	jnz	cs_det8	;overwrite -> 4 Mbit bank
	mov	al,0011xb	;4 Mbit bank
	jmp	short cs_det20

cs_det8: 	mov	al,0100xb	;16 Mbit bank
	
	; Test whether this bank is EDO
	
cs_det20:	or	bl,al	;store bank size in BX
	mov	ch,1
	shl	ch,cl	;EDO bit
	or	ch,20h	;EDO test mode bit
	mov	al,1ah	;enable EDO mode
	out	idx,al
	in	al,dat
	or	al,ch	;set bank EDO + EDO test mode bit
	out	dat,al
	
	mov 	eax,55aaff00h	;write test pattern
	mov 	[0],eax
	cmp 	[0],eax	;verify
	jnz	cs_det29	;:fast page mode, clear bank EDO bit
	and	ch,0f0h	;EDO - keep bank EDO bit as is.

cs_det29:	mov	al,1ah	;clear EDO (if bad)
	out	idx,al
	in	al,dat
	xor	al,ch
	and	al,1fh	;clear EDO test mode
	out	dat,al
	
	; done with the bank - store result in BX, and disable bank
	
cs_det91: mov	ah,1111xb	;disable this bank
	mov	dx,cs_det92
	jmp	short cs_memset
cs_det92:	dec	cl	;another bank ?
	js	cs_det99	;:no
	jmp	cs_det2
	
	; now set all banks according to BX
	
cs_det99:	mov	al,10h
	out	idx,al
	mov	al,bl
	out	dat,al
	mov	al,11h
	out	idx,al
	mov	al,bh
	out	dat,al
	ret
	;
	; set memory bank [CL] -> value in AH; return to [DX]
	;
cs_memset: mov	al,10h	;bank -> 10h or 11h
	test	cl,2
	jz	cs_memst1
	inc	ax
cs_memst1: out	idx,al
	in	al,dat
	test	cl,1	;low or high nibble ?
	jnz	cs_memst2	;:high
	and	al,0f0h	;set low nibble
	jmp	short cs_memst3

cs_memst2: shl	ah,4
	and	al,0fh

cs_memst3: or	al,ah
	out	dat,al
	jmp	dx	;return
	;
	; Copy BIOS to shadow RAM (skip if already enabled)
	;
	; Note: For fastest startup, this happens before DRAM test and
	; BIOS checksum test. If DRAM or BIOS is bad, we might crash.
	;
cs_shad:	mov	al,03h	;unlock configuration registers
	out	idx,al
	mov	al,0c5h
	out	dat,al
	
	mov	al,14h	;shadow read enabled ?
	out	idx,al
	in	al,dat
	test	al,10h
	jnz	cs_shad9	;yes: don't do again (implicit clear C)

	mov	al,14h	;enable shadow write for F000..FFFF
	out	idx,al
	mov	al,00101100xb
	out	dat,al
	
	mov	ax,cs	;copy BIOS to shadow RAM
	mov	ds,ax
	mov	es,ax
	xor	si,si
	xor	di,di
	mov	cx,4000h
	rep 	movsd

	mov	al,14h	;enable shadow read / write F000..FFFF
	out	idx,al
	mov	al,00011100xb
	out	dat,al

	stc		;set C = new shadow
cs_shad9:	jmp	rstshad2
	ret
	;
	; Copy video BIOS to shadow RAM
	;
cs_vshad:	push	ds
	push	es
	mov	al,13h	;video shadow enabled ?
	out	idx,al
	in	al,dat
	test	al,00000011xb
	jnz	cs_vshad1	;yes: don't touch
	
	mov	al,13h	;enable C000 shadow
	out	idx,al
	mov	al,00000011xb
	out	dat,al
	
	mov	al,14h	;set write only shadow
	out	idx,al
	mov	al,00101100xb	;F000..FFFF write shadow
	out	dat,al
	
	mov	ax,0c000h	;copy video BIOS from ROM to shadow
	mov	ds,ax
	mov	es,ax
	xor	si,si
	xor	di,di
	mov	cx,8000h/4
	rep 	movsd
	
	mov	al,14h	;read only shadow
	out	idx,al
	mov	al,00011100xb
	out	dat,al
	
cs_vshad1: pop	es	;restore segment
	pop	ds
	ret
	;
	; Copy video BIOS from PCI ROM to shadow RAM
	; DS:ESI = unreal mode pointer to BIOS
	; ES     = destroyed
	;
cs_vshad2: mov	al,13h	;video shadow enabled ?
	out	idx,al
	in	al,dat
	test	al,00000011xb
	jnz	cs_vshad9	;yes: don't touch
	
	mov	al,13h	;enable C000 shadow
	out	idx,al
	mov	al,00000011xb
	out	dat,al
	
	mov	al,14h	;set write only shadow
	out	idx,al
	mov	al,00101100xb	;F000..FFFF write shadow
	out	dat,al
	
	mov	ax,0c000h	;copy video BIOS from PCI ROM
	mov	es,ax	;to shadow
	xor	edi,edi
	mov	ecx,8000h/4
	a4 	rep movsd
	
	mov	al,14h	;read only shadow
	out	idx,al
	mov	al,00011100xb
	out	dat,al
cs_vshad9: ret
	;
	; set speed-sensitive chipset registers
	;
cs_spd:	mov	si,cs_spd1	;determine CPU bus speed
	jmp	short cs_bus
cs_spd1:	
	mov	si,offset cs_tab25	;25 MHz table
	cmp	bx,3630	;~31 MHz threshold
	jb	cs_spd2
	mov	si,offset cs_tab33
	
	; modify chipset parameters according to speed
	
cs_spd2:	cs:	lodsb	;get index
	cmp	al,0ffh	;end of table ?
	jz	cs_spd4
	out	idx,al	;out index
	mov	ah,al
	in	al,dat
	and 	al,[cs:si]	;AND, OR data
	inc	si
	or 	al,[cs:si]
	inc	si
	xchg	al,ah
	out	idx,al
	mov	al,ah
	out	dat,al		;out data
	jmp	cs_spd2
cs_spd4:
	;
	; initialize ALI local bus IDE, using speed dependent table
	; located after cs_tabxx
	;
	mov	al,30h	;unlock registers
	out	idelock,al
	in	al,idelock
cs_ide:	cs:	lodsb	
	cmp	al,0ffh	;end of table ?
	jz	cs_ide9
	out	ideidx,al
	cs:	lodsb	
	out	idedat,al
	jmp	cs_ide
cs_ide9:	mov	al,0ffh	;lock registers
	out	idelock,al
	ret
	;
	; Determine CPU bus frequency
	;
	; We need to know the CPU bus frequency to ensure correct setting of
	; DRAM timing, IDE timing, ISA timing etc. The easiest way to do this
	; is to enable refresh (which runs off the timer, independent of CPU
	; frequency), and count the number of I/O cycles we can do per refresh
	; loop. The duration of I/O cycles depends on CPU bus frequency, and
	; is sufficiently slow compared to the CPU overhead.
	;
	; This test must run out of shadow RAM, with index 1B = 4E.
	; Other registers will also influence these results, so if in
	; doubt, recheck.
	;
	; The result is returned in BX, and is approximately 119 * CPU bus
	; speed, fairly consistent across DX2 and DX4 CPUs.
	;
cs_bus:	mov	cx,256
  	mov	dx,port61	;refresh toggle register
	xor	bx,bx	;cycle counter
cs_bus1:	inc	bx	;count loops
	in	al,dx
	test	al,16	;wait until refresh toggle is 0
	jnz	cs_bus1
cs_bus2:	inc	bx	;count loops
	in	al,dx
	test	al,16	;wait until refresh toggle is 1
	jz	cs_bus2
	loop 	cs_bus1	;repeat cycle for better accuracy
	jmp	si	;return to caller, result in BX
	;
	; Set read/write shadow
	;
	; The BIOS is written to for HDD parameters.
	;
cs_shadrw: mov	al,14h
	out	idx,al
	in	al,dat
	mov	ah,al
	mov	al,14h
	out	idx,al
	mov	al,ah
	or	al,30h	;read / write shadow
	out	dat,al
	ret
	;
	; set read only shadow
	;
cs_shadro: wbinvd		;flush write back cache
	mov	al,14h
	out	idx,al
	in	al,dat
	mov	ah,al
	mov	al,14h
	out	idx,al
	mov	al,ah
	and	al,0dfh	;clear write shadow
	out	dat,al
	ret
	;
	; enable A20 gate
	;
cs_a20on:	mov	al,26h	;enable A20 gate
	out	port92,al
	ret
	;
	; Wait BX milliseconds - depends on refresh rate !!!
	;
	; This is used for floppy delays and INT15 function 86.
	;
cs_waitbx: inc	bx
	jmp	short cs_wbx8
	
cs_wbx1:	mov	cx,62	;62 refresh cycles per millisecond
cs_wbx2:	in	al,port61
	and	al,10h
	mov	ah,al
cs_wbx3:	in	al,port61	;wait for refresh bit to change state
	and	al,10h
	cmp	al,ah
	jz	cs_wbx3
          loop	cs_wbx2	;:another iteration
cs_wbx8:	dec	bx	;another millisecond ?
	jnz	cs_wbx1
cs_wbx9:	ret
	;
	; Test and enable numeric coprocessor
	;
cs_npx:	fninit		;initialize x87
	fstcw	[tmp_npx]	;FSTCW tmp_npx -> store status
	cmp	word [tmp_npx],037fh	;present
	jnz	cs_npx7	;:no
	
	in	al,pic1+1	;enable interrupt
	and	al,11011111xb
	out	pic1+1,al
	or	byte [m_devflg],2	;set device flag
	
	mov	eax,cr0
	and	al,11011011xb	;clear EM, NE bits
	or	al,00000010xb	;set MP bit
	mov	cr0,eax
	ret
	
cs_npx7:	mov	eax,cr0
	or	al,00100100xb	;set EM, NE bits
	and	al,11111101xb	;clear MP bit
	mov	cr0,eax
	ret
	;
	; configure PCI interrupts [eax]
	; 0..7 = INTA, 8..15 = INTB, 16..23 = INTC, 24..31 = INTD
	;
cs_pciint: mov	bx,offset cs_intab
	xor	di,di	;clear interrupt bitmap
	call	cs_pcii	;translate register numbers
	call	cs_pcii
	push	ax
	mov	al,42h	;set first register
	out	idx,al
	mov	al,cl
	out	dat,al
	pop	ax
	call	cs_pcii	;translate register numbers
	call	cs_pcii
	mov	al,43h	;set second register
	out	idx,al
	mov	al,cl
	out	dat,al
	mov	dx,picedge0	;set edge/level mode
	mov	ax,di
	and	al,0feh	;clear bit 0
	out	dx,ax	;also sets picedge1
	ret
	
	; AL -> setting
	
cs_pcii:	cmp	al,15	;limit to interrupt 15
	jbe	cs_pcii2
	mov	al,0	;otherwise disable
cs_pcii2:	push	cx
	mov	cl,al	;set level mode for corresponding IRQ
	mov	si,1
	shl	si,cl
	or	di,si
	pop	cx
	cs:	xlat	;AL -> setting
	shr	cl,4	;move to CL bits 7..4
	or	cl,al
	shr 	eax,8	;proceed to next interrupt
	ret
	;
	; interrupt number -> chipset setting
	;
cs_intab:	db	0	;0 = disable
	db	0	;1 = invalid
	db	0	;2 = invalid
	db	20h	;IRQ3
	db	40h	;IRQ4
	db	50h	;IRQ5
	db	70h	;IRQ6
	db	60h	;IRQ7
	db	0	;8 = invalid
	db	10h	;IRQ9
	db	30h	;IRQ10
	db	90h	;IRQ11
	db	0b0h	;IRQ12
	db	0	;13 = invalid
	db	0d0h	;IRQ14
	db	0f0h	;IRQ15
	;
	; M1487 initialization table
	;
	; Avoid changing timing parameters here, this will mess up bus
	; speed detection.
	;
cs_tab:	db	003,0c5	;unlock registers
#if def	C000_ROM
	db 	012,086	;Enable hidden refresh, Cxxx = ROM
#else
	db	012,080	;enable hidden refresh, C000 = ISA
#endif
	db 	015,040	;Check point select
	db 	016,0E1	;E5	;Enable L1 cache
 	db 	017,0c4	;L2 cache, enable shadow cache
 	db 	019,004	;Intel WT CPU, disable SMM
 	db 	01B,04e	;DRAM timing = fast, CBR refresh, no parity
 	db 	01C,080	;Memory on CPU bus
 	db 	020,02D	;CPU to PCI buffer
 	db 	021,032	;DEVSEL check point
 	db 	022,01D	;PCI read buffer
 	db 	025,080	;GP/MEM address
 	db 	026,000	;GP/MEM address
 	db 	027,000	;GP/MEM address
	db 	028,024	;PCI arbiter control
	db 	029,032	;System clock: AT = CPU/4, port 92 enable, ONE ISA wait
 	db 	02A,004	;I/O recovery disable, normal system refresh
 	db 	02B,0D3	;Turbo mode, ignore hw turbo, isa master prefetch enable
 	db 	030,000	;disable PMU
 	db 	031,000	;disable monitoring events
 	db 	032,000	;disable monitoring events
 	db 	033,000	;disable SMI events
 	db 	034,000	;disable SMI events
 	db 	035,000	;040	Cyrix;select Intel SMI mode
 	db 	036,000	;disable IRQ events
 	db 	037,000	;disable IRQ events
 	db 	038,000	;disable DRQ events
 	db 	039,000	;disable mode timer
 	db 	03A,000	;disable input device timer
 	db 	03B,000	;disable GP/MEM timer
 	db 	03C,000	;disable LED flash
 	db 	03D,001	;ISA address fully decoded
 	db 	040,02B	;clock control
 	db 	041,0FF	;power control output
 	db 	042,000	;PCI interrupt mapping disable
 	db 	043,000	;PCIVGA interrupt mapping disable
 	db 	044,00F	;CPU normal priority
 	db 	045,080	;IORDY synchronized for ISA bus masters
 	db 	0ff,0ff	;end of table
	;
	; secondary table - only set if cold reset (shadow not enabled)
	; directly after cs_tab
	;
cs_tab2:	db 	010,0ff	;0f1	;DRAM bank 0,1 = 4MB -> 8 MB total
	db 	011,0ff	;DRAM bank 2,3 = none
	db	013,000	;Shadow C000 - DFFF disable
	db 	014,02f	;Shadow E000 - FFFF write mode
 	db 	01A,000	;DRAM bank 0,1 = FPM, normal refresh rate, normal EDO write
	db	0ff	;end of table
	;
	; chipset, IDE timings for 25 MHz
	;
cs_tab25:	db	01a,0ff,010	;2-1-1-1 EDO write
	db	01b,0,04f	;fast DRAM timing
	db	029,0f8,001	;ATCLK = CPUCLK/3
	db	0ff	;end of table, IDE table follows

	;IDE initialization table - 25 MHz

	db 	001,003	;enable IDE
 	db 	002,CS_IDE8	;data byte active count	IDE1
 	db 	003,CS_IDE16	;read command time	IDE1 disk 0
 	db 	004,CS_IDE16	;write command time	IDE1 disk 0
 	db 	005,CS_IDE16	;read command time	IDE1 disk 1
 	db 	006,CS_IDE16	;write command time	IDE1 disk 1
 	db 	007,01F	;buffer mode: enabled
 	db 	009,041	;3F6 decode enable
 	db 	00A,001	;enable IDE1 disk 0 buffer
 	db 	00B,000	;low sector byte count	IDE1 disk 0
 	db 	00C,002	;high sector byte count	IDE1 disk 0
 	db 	00D,000	;low sector byte count	IDE1 disk 1
 	db 	00E,002	;high sector byte count	IDE1 disk 1
 	db 	00F,000	;low sector byte count	IDE2 disk 0
 	db 	010,002	;high sector byte count	IDE2 disk 0
 	db 	011,000	;low sector byte count	IDE2 disk 1
 	db 	012,002	;high sector byte count	IDE2 disk 1

 	db 	025,CS_IDE8R	;command recovery	IDE1
 	db 	026,CS_IDE16R	;read recovery		IDE1 disk 0
 	db 	027,CS_IDE16R	;write recovery		IDE1 disk 0
 	db 	028,CS_IDE16R	;read recovery 		IDE1 disk 1
 	db 	029,CS_IDE16R	;write recovery		IDE1 disk 1
 	db 	02A,CS_IDE8	;command active		IDE2
 	db 	02B,CS_IDE16	;read active		IDE2 disk 0
 	db 	02C,CS_IDE16	;write active		IDE2 disk 0
 	db 	02D,CS_IDE16	;read active		IDE2 disk 1
 	db 	02E,CS_IDE16	;write active 		IDE2 disk 1
 	db 	02F,CS_IDE8R	;command recovery	IDE2
 	db 	030,CS_IDE16R	;read recovery		IDE2 disk 0
 	db 	031,CS_IDE16R	;write recovery		IDE2 disk 0
 	db 	032,CS_IDE16R	;read recovery		IDE2 disk 1
 	db 	033,CS_IDE16R	;write recovery		IDE2 disk 1
 	db 	035,001	;port enable: no RAID.
 	db 	0ff	;end of table
	;
	; chipset, IDE timings for 33 MHz
	;
cs_tab33:	db	01a,0ef,0	;slow down EDO write
	db	01b,0,04e	;DRAM timing
	db	029,0f8,002	;ATCLK = CPUCLK/4
	db	0ff	;end of table

	;IDE initialization table - 33 MHz

	db	001,3	;enable IDE
	db	002,CS_IDE8b	;data byte active count	IDE1
	db	003,CS_IDE16b	;read command time	IDE1 disk 0
	db	004,CS_IDE16b	;write command time	IDE1 disk 0
	db	005,CS_IDE16b	;read command time	IDE1 disk 1
	db	006,CS_IDE16b	;write command time	IDE1 disk 1
	db	007,01F	;buffer mode: enabled
	db	009,041	;3F6 decode enable
	db	00A,001	;enable IDE1 disk 0 buffer
	db	00B,0	;low sector byte count	IDE1 disk 0
	db	00C,2	;high sector byte count	IDE1 disk 0
	db	00D,0	;low sector byte count	IDE1 disk 1
	db	00E,2	;high sector byte count	IDE1 disk 1
	db	00F,0	;low sector byte count	IDE2 disk 0
	db	010,2	;high sector byte count	IDE2 disk 0
	db	011,0	;low sector byte count	IDE2 disk 1
	db	012,2	;high sector byte count	IDE2 disk 1

	db	025,CS_IDE8Rb	;command recovery	IDE1
	db	026,CS_IDE16Rb	;read recovery		IDE1 disk 0
	db	027,CS_IDE16Rb	;write recovery		IDE1 disk 0
	db	028,CS_IDE16Rb	;read recovery 		IDE1 disk 1
	db	029,CS_IDE16Rb	;write recovery		IDE1 disk 1
	db	02A,CS_IDE8b	;command active		IDE2
	db	02B,CS_IDE16b	;read active		IDE2 disk 0
	db	02C,CS_IDE16b	;write active		IDE2 disk 0
	db	02D,CS_IDE16b	;read active		IDE2 disk 1
	db	02E,CS_IDE16b	;write active 		IDE2 disk 1
	db	02F,CS_IDE8Rb	;command recovery	IDE2
	db	030,CS_IDE16Rb	;read recovery		IDE2 disk 0
	db	031,CS_IDE16Rb	;write recovery		IDE2 disk 0
	db	032,CS_IDE16Rb	;read recovery		IDE2 disk 1
	db	033,CS_IDE16Rb	;write recovery		IDE2 disk 1
	db	035,1	;port enable: no RAID.
	db	0ff	;end of table
	;
	; clear chipset registers before initializing DMA, IRQ
	;
cs_clr:	shl 	edx,16	;save DX = CPU type
	ret
	
PCI:			;Undefine if not PCI based

P_MEM0	equ	08000	;start address, PCI memory space
P_MEM9	equ	08400	;end address, PCI memory space
P_ROM0	equ	0000C	;temporary address for PCI ROM
P_MEMP0	equ	08400	;start address, PCI prefetchable space
P_MEMP9	equ	08800	;end address, PCI prefetchable space
P_MEMINC	equ	00004	;minimum allocation
P_MEMINC1	equ	00100	;mem allocation, primary bridge
P_MEMINC2	equ	00040	;mem allocation, secondary bridge

			;real mode: 16 byte multiples
P_MEMR0	equ	0c800	;real mode memory start
P_MEMR9	equ	0e000	;real mode memory limit
P_MEMRINC	equ	00400	;real mode minimum allocation

			;I/O: 16 byte multiples
P_IO0	equ	01000	;start address, PCI I/O
P_IOINC	equ	00040	;minimum allocation for I/O devices
P_IOINC1	equ	04000	;I/O allocation, primary bridge
P_IOINC2	equ	01000	;I/O allocation, secondary bridge
P_IO9	equ	0FFFF	;I/O limit = 64k

P_PRILAT	equ	020	;primary latency timer
P_SECLAT	equ	020	;bridge secondary latency timer

P_BRIDGE	equ	00000111xb	;PCI bridge control register
			;bit 0 = 1: enable parity check
			;bit 1 = 1: forward serr# to primary
			;bit 2 = 1: ISA mode for I/O registers
			;bit 3 = 1: VGA enable
			;bit 5 = 1: master abort mode
			;bit 6 = 1: secondary bus reset
			;bit 7 = 1: fast back to back enable
			;           (set automatically)

P_COMMAND	equ	0000000111xb	;PCI device command register
			;bit 0 = 1: enable I/O access
			;bit 1 = 1: enable memory access
			;bit 2 = 1: enable bus master access
			;bit 3 = 1: enable special cycles
			;bit 4 = 1: enable mem write / inval
			;bit 5 = 1: enable VGA palette snoop
			;bit 6 = 1: enable parity checking
			;bit 7 = 1: enable AD stepping
			;bit 8 = 1: enable SERR# driver
			;bit 9 = 1: enable fast back to back
