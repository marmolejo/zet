	;
	; System specific code
	;
	; Zet Fpga PC
	;
	; Equates
	;
idx	equ	22h	;configuration index register
dat	equ	23h	;configuration data register

TOP_MEM	equ	0100	;memory size limit = 16 MB
	
	;
	; clear chipset registers before initializing DMA, IRQ
	;
cs_clr:	ret
	;
	; initialize chipset
	;
	; set all registers, detect memory size
	; keep L2 cache disabled at this point
	; set CPU specific registers if required
	;
cs_init: ret		;no carry = full initialization
	;
	; CPU specific settings
	;
cs_cpu:	ret
	;
	; Detect memory
	;
cs_det:	ret
	;
	; Copy BIOS to shadow RAM (skip if already enabled)
	;
	; Note: For fastest startup, this happens before DRAM test and
	; BIOS checksum test. If DRAM or BIOS is bad, we might crash.
	;
cs_shad: ret
	;
	; Copy video BIOS to shadow RAM
	;
cs_vshad: ret
	;
	; set speed-sensitive chipset registers
	;
cs_spd:	ret
	;
	; Set read/write shadow
	;
	; The BIOS is written to for HDD parameters.
	;
cs_shadrw: 
	jmp	short cs_set
	;
	; set read only shadow
	;
cs_shadro: 
	jmp	short cs_set
	;
	; Wait BX milliseconds - depends on refresh rate !!!
	;
	; This is used for floppy delays and INT15 function 86.
	;
cs_waitbx: ret
	;
	; Test and enable numeric coprocessor - not supported
	;
cs_npx:	ret
	;
	; get register [AH]->AL	(BX clobbered)
	;
cs_get: ret
	;
	; enable A20 gate
	;
cs_a20on:
	mov	ah,31h
	call	cs_get
	or	al,1	;enable A20 gate
	;call cs_set
	;ret
	;
	; set register AL->[AH]	(BX clobbered)
	;
cs_set: ret
