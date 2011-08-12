	;
	; Hard Disk BIOS
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;
	; Limitations:
	;
	; - HDD must support command EC (identify device).
	; - Read Long, Write Long (hardware-specific number of ECC bytes,
	;   rarely used) not supported
	; - Format not supported (not available on IDE drives)
	; - Only one drive supported
	; - Only AMI / Intel style of CHS translation supported.
	;   (simple bit shift would be simpler, but messes up sequential
	;   transfer rate)
	; - Extended disk address mode only works with drives that support
	;   LBA.
	;
	; Notes:
	;
	; - Storage of disk parameters requires read/write shadow during POST
	;   (can be write protected later). This code will break if shadow
	;   is write protected during drive configuration.
	;
	; pd 001019 - add option HD_EDD -> packet interface
	; pd 001019 - add functions 41 and 48 to support large drives.
	; pd 001017 - fix power saving HLT to avoid race conditions.
	; pd 001017 - don't limit cylinder number to 1023 in hd_lba
	;             (ensure correct result for function 15), do limit in
	;             function 08.
	; pd 000211 - recognize new SanDisk ID
	; pd 991020 - add hd_top variable, needed to support M-Systems
	; 	      DiskOnChip.
	; pd 990501 - add CDBOOT hook
	; pd 990427 - add ATAPI identify
	; pd 990214 - add hook for IDE speed initialization (cs_ide)
	; pd 990210 - add LBA mode support
	; pd 981010 - fix read handshake
	; pd 980710 - fix function 15: return 0 if drive not present

ifdef	DEBUG
HD_DEBUG:			;& comment out for production code
endif
	;
	; drive parameter structure (stored in data module)
	;
dpt_cyl	equ	0	;number of cylinders
dpt_head	equ	2	;number of heads
dpt_sig	equ	3	;signature, $A0
dpt_psec	equ	4	;physical sectors per track
dpt_mul	equ	5	;(precompensation) -> multiple count
dpt_shl	equ	7	;reserved -> shift count
dpt_ctl	equ	8	;drive control byte
dpt_pcyl	equ	9	;physical cylinders
dpt_phd	equ	11	;physical heads
dpt_lz	equ	12	;(landing zone)
dpt_sec	equ	14	;logical sectors per track
dpt_res	equ	15	;reserved
dpt_len	equ	16	;length of structure
	;
	; disk address packet for extended read/write/verify/seek
	;
ifdef	HD_EDD
drq_len	equ	0	;packet size in bytes
drq_res	equ	1	;reserved, must be 0
drq_blk	equ	2	;number of blocks, max. 127
drq_res2	equ	3	;reserved, must be 0
drq_ofs	equ	4	;transfer buffer offset
drq_seg	equ	6	;transfer buffer segment
drq_lba	equ	8	;block number (8 bytes)
endif
	
ifdef	FLASHDISK
int40:	dec	dl	;correct floppy drive number
	int	40h	;execute floppy interrupt
	inc	dl	;restore drive number
	retf	2	;return, don't change status
intfld:	jmp	fldisk
	;
	; INT 13 entry
	;
int13hd:	sti
	and	dl,dl	;flash disk ?
	jz	intfld
	jns	int40	;:floppy
	and	ah,ah	;reset drive ?
	jnz	int13hd1	;:no
	cmp	dl,81h	;above valid HDD ?
	ja	int40	;-> floppy only
	int	40h	;reset floppy
	mov	ah,0
else
ifdef	CDBOOT

	; redirect to floppy or CD emulation as needed

int40:	test 	byte [cs:d_cdflag],1	;emulation enabled ?
	jz	int40a	;:no
	test	dl,dl	;drive 0 ?
	jnz	int40b	;:no
	jmp	cddisk

int40a:	int	40h	;execute floppy interrupt
	retf	2	;return, don't change status
	
int40b:	dec	dl	;correct floppy drive number
	int	40h	;execute floppy interrupt
	inc	dl	;restore drive number
	retf	2	;return, don't change status
else
	; execute floppy interrupt

int40:	int	40h	;execute floppy interrupt
	retf	2	;return, don't change status
endif
	;
	; INT 13 entry
	;
int13hd:	sti
	and	dl,dl	;HDD ?
	jns	int40	;:floppy
	cmp	dl,byte ptr cs:[hd_top]	;compare with max drive number
	jae	int40	;:floppy or DiskOnChip
	and	ah,ah	;reset drive ?
	jnz	int13hd1	;:no
	cmp	dl,81h	;above valid HDD ?
	ja	int40	;-> floppy only
	int	40h	;reset floppy
	mov	ah,0
endif
	;
	; dispatch disk commands
	;
int13hd1:	push	ds	;save registers
	push	es
	PUSH_A
	mov	bp,sp	;access to stack frame
	xor	di,di	;access BIOS segment
	mov	ds,di
ifdef	HD_DEBUG
;	test	byte [m_kbf],kb_fscrs	;scroll lock ?
;	jnz	int13dmp1	;yes: don't display
	call	v_dump	;& dump registers
int13dmp1:
endif
	mov	di,ax	;command -> index
	push cx
	mov cl,8
	shr	di,cl
	pop cx
	add	di,di
	and	byte ptr ds:[bp+18h],0feh	;clear return carry
	cmp	di,hd_vec99-hd_vectab	;limit command vector
	jae	hd_badcmd	;:too high
	jmp	[cs:di.hd_vectab]	;jump to command	
	;
	; Illegal command
	;
hd_badcmd: mov	byte ptr ds:[m_hdstat],1	;illegal command
	;
	; AH=01: get status
	;
hd_status: mov	al,byte ptr ds:[m_hdstat]	;get old status
	mov	byte ptr ds:[bp._al],al	;return in AL
	;
	; return status
	;
hd_exit0:	mov	byte ptr ds:[m_hdstat],al	;set error code
	mov	byte ptr ds:[bp._ah],al	;return in AH
hd_exit1:	and	al,al	;error ?
	jz	hd_exit2	;:no
	or	byte ptr ds:[bp+18h],1	;yes: set carry
ifdef	HD_DEBUG
	stc
hd_exit2:	pushf
	test	byte ptr ds:[m_kbf],kb_fscrs	;scroll lock ?
	jnz	int13dmp2	;yes: don't display
	call	v_dump2	;& dump registers
int13dmp2:	popf
else
hd_exit2:
endif
	POP_A		;restore registers
	pop	es
	pop	ds
	iret		;return from interrupt
	;
	; IDE vector table
	;
	even
hd_vectab: dw	hd_rst	;AH=00: recalibrate drive
	dw	hd_status	;AH=01: get status
	dw	hd_read	;AH=02: read
	dw	hd_write	;AH=03: write
	dw	hd_verify	;AH=04: verify
          dw	hd_badcmd	;AH=05: format track -> not supported
	dw	hd_badcmd	;AH=06: bad
	dw	hd_badcmd	;AH=07: bad
	dw	hd_getprm	;AH=08: read drive parameters
	dw	hd_setprm	;AH=09: set drive parameters
	dw	hd_badcmd	;AH=0A: read long -> not supported
	dw	hd_badcmd	;AH=0B: write long -> not supported
	dw	hd_seek	;AH=0C: seek
	dw	hd_rst2	;AH=0D: alternate disk reset (HD only)
	dw	hd_badcmd	;AH=0E: bad
	dw	hd_badcmd	;AH=0F: bad
	dw	hd_trdy	;AH=10: test drive ready
	dw	hd_recal	;AH=11: recalibrate
	dw	hd_badcmd	;AH=12: bad
	dw	hd_badcmd	;AH=13: bad
	dw	hd_diag	;AH=14: controller diagnostics
	dw	hd_gettyp	;AH=15: get drive type
	dw	hd_badcmd	;AH=16: bad
	dw	hd_badcmd	;AH=17: bad
	dw	hd_badcmd	;AH=18: bad
	dw	hd_badcmd	;AH=19: bad
	dw	hd_badcmd	;AH=1A: bad
	dw	hd_badcmd	;AH=1B: bad
	dw	hd_badcmd	;AH=1C: bad
	dw	hd_badcmd	;AH=1D: bad
	dw	hd_badcmd	;AH=1E: bad
	dw	hd_badcmd	;AH=1F: bad
	dw	hd_badcmd	;AH=20: bad
	dw	hd_badcmd	;AH=21: bad
	dw	hd_badcmd	;AH=22: bad
ifdef	HD_TIME
	dw	hd_timer	;AH=23: set standby timer NON-STANDARD
else
	dw	hd_badcmd
endif
	dw	hd_setmul	;AH=24: set multiple mode
	dw	hd_id	;AH=25: identify drive
ifdef	HD_EDD
	dw	hd_badcmd	;AH=26: bad
	dw	hd_badcmd	;AH=27: bad
	dw	hd_badcmd	;AH=28: bad
	dw	hd_badcmd	;AH=29: bad
	dw	hd_badcmd	;AH=2A: bad
	dw	hd_badcmd	;AH=2B: bad
	dw	hd_badcmd	;AH=2C: bad
	dw	hd_badcmd	;AH=2D: bad
	dw	hd_badcmd	;AH=2E: bad
	dw	hd_badcmd	;AH=2F: bad
	dw	hd_badcmd	;AH=30: bad
	dw	hd_badcmd	;AH=31: bad
	dw	hd_badcmd	;AH=32: bad
	dw	hd_badcmd	;AH=33: bad
	dw	hd_badcmd	;AH=34: bad
	dw	hd_badcmd	;AH=35: bad
	dw	hd_badcmd	;AH=36: bad
	dw	hd_badcmd	;AH=37: bad
	dw	hd_badcmd	;AH=38: bad
	dw	hd_badcmd	;AH=39: bad
	dw	hd_badcmd	;AH=3a: bad
	dw	hd_badcmd	;AH=3b: bad
	dw	hd_badcmd	;AH=3c: bad
	dw	hd_badcmd	;AH=3d: bad
	dw	hd_badcmd	;AH=3e: bad
	dw	hd_badcmd	;AH=3f: bad
	dw	hd_badcmd	;AH=40: bad
	dw	hd_edd41	;AH=41: detect extended interface
	dw	hd_xrd	;AH=42: extended read
	dw	hd_xwr	;AH=43: extended write
	dw	hd_xver	;AH=44: extended verify
	dw	hd_badcmd	;AH=45: bad (lock / unlock drive)
	dw	hd_badcmd	;AH=46: bad (eject removable media)
	dw	hd_xsk	;AH=47: extended seek
	dw	hd_edd48	;AH=48: get extended parameters
endif
hd_vec99:			;end of table
	;
	; AH=00: reset hard disk drives
	; AH=0D: alternate reset (doesn't reset floppy)
	;
hd_rst:	
hd_rst2:	cli
	in	al,pic1+1	;enable HD interrupt
	and	al,0bfh
	out	iowait,ax
	out	pic1+1,al
	
	in	al,pic0+1	;enable cascade interrupt
	and	al,0fbh
	out	iowait,ax
	out	pic0+1,al
	sti

	mov	dx,hdc_ctrl
	mov	al,4	;soft reset
	out	dx,al
	out	iowait,ax	;wait a bit
	out	iowait,ax
	out	iowait,ax
	out	iowait,ax
	out	iowait,ax
	mov	al,0	;end of reset, interrupt enable
	out	dx,al	;hdc_ctrl
	call	hd_busy18	;wait while busy
	jb	hd_rst8	;:error
	mov	dx,hdc_err	;check error status
	in	al,dx
	and	al,7fh
	sub	al,1
	jnz	hd_rst8	;:bad status
	mov	al,0	;ok status
	jmp	hd_exit0	;return
	
hd_rst8:	mov	al,5	;reset failed
hd_rst9:	jmp	hd_exit0
	;
	; AH=02: read sectors
	;
hd_read:	call	hd_sel	;select drive
	jb	hd_read9
	call	hd_chs	;translate CHS
	jb	hd_read9
	mov	bl,[bp._al]	;get sector count
	cld		;forward mode
	mov	di,[bp._bx]	;get destination address
	mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag
	mov	al,20h	;issue read command
	mov	dx,hdc_cmd
	out	dx,al
	
hd_read1:	call	hd_int	;wait for interrupt
	jb	hd_read9
	;mov	dl, low(hdc_stat)	;read status
	mov	dx, hdc_stat	;read status
	in	al,dx
	mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag for next
	test	al,1	;ERR ?
	jnz	hd_read8
	test	al,8	;DRQ ?
	jz	hd_read8	;:no
	mov	dx,hdc_dat	;read 512 bytes from drive
	mov	cx,256
	;rep	insw
	REP_INSW
	dec	bl	;another sector ?
	jnz	hd_read1	;:yes
hd_read8:	sub	byte ptr ds:[bp._al],bl	;adjust sector count to reality
	call	hd_stat	;get status
hd_read9:	jmp	hd_exit0

			;
			; AH=03: write sectors
			;
hd_write:	mov	si,bx	;source address
			call	hd_sel	;select drive
			jb	hd_writ9
			call	hd_chs	;translate CHS
			jb	hd_writ9
			mov	bl,[bp._al]	;get sector count
			cld		;forward mode
			mov	al,30h	;issue write command
			mov	dx,hdc_cmd
			out	dx,al
	
hd_writ1:
			mov	dx,hdc_stat	;read status
			xor	cx,cx
			mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag for next
hd_writ2:	in	al,dx
			test	al,8	;DRQ ?
			jnz	hd_writ3	;:yes
			test	al,21h	;error ?
			jnz	hd_writ8
			loop	hd_writ2
			mov	al,80h	;time-out
			jmp	short hd_writ9
	
hd_writ3:	mov	dx,hdc_dat	;write 512 bytes from drive
			mov	cx,256
			;es	rep	outsw
			ES_REP_OUTSW
			call	hd_int	;wait for interrupt
			jb	hd_writ9
			dec	bl	;another sector ?
			jnz	hd_writ1	;:yes
		
hd_writ8:	call	hd_stat	;get status
hd_writ9:	jmp	hd_exit0
	;
	; AH=04: verify sectors
	;
hd_verify:
	call	hd_sel	;select drive
	jb	hd_ver9
	call	hd_chs	;translate CHS
	mov	al,40h
	call	hd_cmd	;read verify command	
	jb	hd_ver9
	call	hd_stat	;get status
hd_ver9:	jmp	hd_exit0
	;
	; AH=08: get drive parameters
	;
hd_getprm:
	cmp	byte ptr ds:[m_hdcnt],0	;no drives ?
	jnz	hd_getp1
	jmp	hd_badcmd	;:bad command
	
hd_getp1:	call	hd_parm	;get ^parameters
	mov	al,7	;invalid drive number
	mov	cx,0	;return 0 size
	mov	dx,0
	jb	hd_getp9	;:not present

	mov	dh,cs:[di.dpt_head]	;DH = max head number
	dec	dh
	mov	dl, byte ptr ds:[m_hdcnt]	;DL = number of drives
	mov	cx,[cs:di.dpt_cyl]	;CX = max cylinders (swapped)
	dec	cx	;-2 for diag, max cyl
	dec	cx
	cmp	cx,1023	;limit cylinder to 1023
	jbe	hd_getp2
	mov	cx,1023
hd_getp2:	xchg	cl,ch
	push dx
	mov dl,6
	shl	cl,dl	;CL high 6 bits = cylinders high
	pop dx
	or	cl,[cs:di.dpt_sec]	;CL = number of sectors
	mov	al,0	;clear status

hd_getp9:	mov	[bp._cx],cx	;cylinder count
	mov	[bp._dx],dx	;number drives, heads
	jmp	hd_exit0
	;
	; AH=09: set drive parameters
	;
hd_setprm: call	hd_sel	;select drive
	jb	hd_setp9
	mov	ah,[cs:di.dpt_phd]	;number heads (physical)
	dec	ah
	mov	dx,hdc_drv	;set maximum heads
	in	al,dx
	or	al,ah
	out	dx,al
	mov	al,[cs:di.dpt_psec]	;(physical)
	mov	dx,hdc_cnt	;sector count
	out	dx,al
	mov	al,91h	;set drive parameters
	call	hd_cmd
	jb	hd_setp9	;:error
	call	hd_stat	;check status		
hd_setp9:	jmp	hd_exit0
	;
	; AH=0C: seek
	;
hd_seek:	call	hd_sel	;select drive
	jb	hd_seek9	
	call	hd_chs	;set CHS value
	mov	al,70h
	call	hd_cmd	;seek command
	jb	hd_seek9
	call	hd_stat	;check status
hd_seek9:	cmp	al,40h	;seek error ?
	jnz	hd_seek91
	mov	al,0	;don't show it... (Core test will fail
hd_seek91: jmp	hd_exit0	;otherwise)
	;
	; AH=10: test drive ready
	;
hd_trdy:	mov	cx,0ffffh	;no time-out
	call	hd_sel0	;select drive, test ready
	jb	hd_trdy9
	mov	dx, hdc_stat	;check status
	in	al,dx
	mov	byte ptr ds:[m_hdst],al
	mov	ah,0aah	;not ready
	test	al,40h
	jz	hd_trdy8
	mov	ah,40h	;seek error
	test	al,10h
	jz	hd_trdy8
	mov	ah,0cch	;write fault
	test	al,20h
	jnz	hd_trdy8
	mov	ah,0	;ok status	
hd_trdy8:	mov	al,ah
hd_trdy9:	jmp	hd_exit0
	;
	; AH=11: recalibrate
	;
hd_recal:	call	hd_sel	;select drive
	mov	al,10h
	call	hd_cmd	;recalibrate command
	jb	hd_rec9
	call	hd_stat	;get status
hd_rec9:	jmp	hd_exit0
	;
	; AH=14: controller diagnostics
	;
hd_diag:	call	hd_busy18	;wait for not busy
	mov	al,20h	;bad controller
	jb	hd_diag9	;:bad
	mov	al,90h	;diagnostic command
	mov	dx,hdc_cmd
	out	dx,al
	out	iowait,al
	mov	cx,18*6	;max. 6 seconds (!!!)
	call	hd_busy	;wait for not busy
	mov	al,80h	;time-out
	jb	hd_diag9
	mov	dx,hdc_err	;check error register
	in	al,dx
	and	al,7fh
	sub	al,1
	jz	hd_diag9	;:ok
	mov	al,20h	;bad controller
hd_diag9:	jmp	hd_exit0	
	;
	; AH=15: read DASD type
	;
hd_gettyp: call	hd_parm	;get pointer to parameter block
	jb	hd_gett8	;:not present
	mov	al,[cs:di.dpt_head]	;number heads
	mul 	byte ptr cs:[di.dpt_sec]	;number sectors
	mov	dx,[cs:di.dpt_cyl]	;number cylinders
	dec	dx	;minus one for diagnostics
	mul	dx
	mov	cl,3	;drive present
	jmp	short hd_gett9
		
hd_gett8:	xor	ax,ax	;0 = drive not present
	xor	cx,cx
	xor	dx,dx
hd_gett9:
	mov	byte ptr ds:[bp._ah],cl	;0 = not present, 3 = present
	mov	[bp._cx],dx	;CX = MSB sector count
	mov	[bp._dx],ax	;DX = LSB sector count
	mov	al,0	;ok status
	mov	byte ptr ds:[m_hdstat],al
	jmp	hd_exit1
	;
	; AH = 24: set multiple mode
	;
hd_setmul: call	hd_sel	;select drive
	mov	dx, hdc_cnt
	mov	al,[bp._al]	;number of sectors
	out	dx,al
	mov	al,0c6h
	call	hd_cmd	;set multiple mode command
	jb	hd_setm9
	call	hd_stat	;get status
hd_setm9:	jmp	hd_exit0
	;
	; AH=25: identify drive
	;
hd_id:	call	hd_selb	;select drive
			;ignore time-out here, if drive not ready
			;(ATAPI drive doesn't report ready
			;until spoken to)
	mov	al,0ech	;identify drive
	call	hd_cmd	;issue command
	jb	hd_id9	;:bad drive
	in	al,dx	;hdc_stat
	test	al,1	;error ?
	jz	hd_id1	;:no

hd_id0:	mov	al,0a1h	;ATAPI identify drive
	call	hd_cmd	;issue command
	jb	hd_id9	;:time-out

hd_id1:	xor	cx,cx
hd_id2:	in	al,dx	;hdc_stat
	test	al,8	;DRQ ?
	jnz	hd_id3	;:yes
	loop	hd_id2
	mov	al,80h	;time-out
	jmp	short hd_id9

hd_id3:	cld		;forward direction
	mov	dx,hdc_dat
	mov	cx,256	;512 bytes
	mov	di,bx	;destination
	;rep	insw	;read data
	REP_INSW
	call	hd_stat	;get status
hd_id9:	jmp	hd_exit0	;exit

ifdef	HD_EDD
	;
	; AH=41: detect EDD support
	;
hd_edd41:	cmp	bx,55aah	;magic cookie ?
	jnz	hd_edd419	;no: bad
	mov	word ptr ds:[bp._bx],0aa55h	;return cookie
	mov	word ptr ds:[bp._cx],1	;support packet commands; no lock /
			;eject
	mov	byte ptr ds:[bp._ah],1	;major version
	mov	byte ptr ds:[m_hdstat],0
	jmp	hd_exit2	;return carry clear

hd_edd419: jmp	hd_badcmd	;return error
	;
	; AH=42: extended read
	;
hd_xrd:	call	hd_sel	;select drive
	jb	hd_xrd9
	call	hd_xadr	;handle address
	jb	hd_xrd9
	mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag
	mov	al,20h	;issue read command
	mov	dx,hdc_cmd
	out	dx,al
	
hd_xrd1:	call	hd_int	;wait for interrupt
	jb	hd_xrd9
	mov	dx,hdc_stat	;read status
	in	al,dx
	mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag for next
	test	al,1	;ERR ?
	jnz	hd_xrd8
	test	al,8	;DRQ ?
	jz	hd_xrd8	;:no
	mov	dx,hdc_dat	;read 512 bytes from drive
	mov	cx,256
	;rep	insw
	REP_INSW
	dec	bl	;another sector ?
	jnz	hd_xrd1	;:yes
hd_xrd8:	mov	es,[bp._ds]	;access address packet
	sub 	byte ptr es:[si+drq_blk],bl	;adjust sector count to reality
	call	hd_stat	;get status
hd_xrd9:	jmp	hd_exit0
	;
	; AH=43: extended write
	;
hd_xwr:	call	hd_sel	;select drive
	jb	hd_xwr9
	call	hd_xadr	;handle address
	jb	hd_xwr9
	mov	si,di	;buffer ^
	mov	al,30h	;issue write command
	mov	dx,hdc_cmd
	out	dx,al
	
hd_xwr1:	mov	dx,hdc_stat	;read status
	xor	cx,cx
	mov	byte ptr ds:[m_hdflag],0	;clear interrupt flag for next
hd_xwr2:	in	al,dx
	test	al,8	;DRQ ?
	jnz	hd_xwr3	;:yes
	test	al,21h	;error ?
	jnz	hd_xwr8
	loop	hd_xwr2
	mov	al,80h	;time-out
	jmp	short hd_xwr9
	
hd_xwr3:	mov	dx,hdc_dat	;write 512 bytes from drive
	mov	cx,256
	;es rep	outsw
	ES_REP_OUTSW
	call	hd_int	;wait for interrupt
	jb	hd_xwr9
	dec	bl	;another sector ?
	jnz	hd_xwr1	;:yes
		
hd_xwr8:	call	hd_stat	;get status
hd_xwr9:	mov	es,[bp._ds]	;access address packet
	mov	si,[bp._si]
	sub 	byte ptr es:[si+drq_blk],bl	;adjust sector count to reality
	jmp	hd_exit0
	;
	; AH=44: extended verify
	;
hd_xver:	call	hd_sel	;select drive
	jb	hd_xver9
	call	hd_xadr	;handle address
	jb	hd_xver9
	mov	al,40h
	call	hd_cmd	;read verify command	
	jb	hd_xver9
	call	hd_stat	;get status
hd_xver9:	jmp	hd_exit0
	;
	; AH=47: extended seek
	;
hd_xsk:	call	hd_sel	;select drive
	jb	hd_xsk9	
	call	hd_xadr	;handle address
	jb	hd_xsk9
	mov	al,70h
	call	hd_cmd	;seek command
	jb	hd_xsk9
	call	hd_stat	;check status
hd_xsk9:	jmp	hd_exit0
	;
	; AH=48: return drive parameters
	;
	; Note: Phoenix spec says we should return PHYSICAL geometry, but
	; Award BIOS returns LOGICAL... Users of this function are most
	; interested in the max sector count anyway.
	;
hd_edd48:	call	hd_parm	;get ^parameter block -> DI
	jb	hd_edd489
	mov	si,di	;^parameter block
	cld		;forward direction
	mov	es,[bp._ds]	;buffer segment
	mov	di,[bp._si]	;buffer offset
	mov	al,1	;(error code)
	cmp 	word ptr es:[di],26	;buffer at least 26 bytes long
	jb	hd_edd489	;less -> error
	mov	ax,26	;buffer length
	stosw
	mov	ax,2	;flags: valid geometry
	stosw
	;xor 	eax,eax
	mov	ax,[cs:si.dpt_cyl]	;number of cylinders
	;
	stosw
	xor ax,ax
	stosw
	;
	mov 	al,[cs:si.dpt_head]	;number of heads
	mov	ah,0
	;
	stosw
	xor ax,ax
	stosw
	;
	mov	al,[cs:si.dpt_sec]	;number of sectors
	mov	ah,0
	;
	stosw
	xor ax,ax
	stosw
	;
	mov	al,[cs:si.dpt_head]	;number heads
	mul	byte ptr [cs:si.dpt_sec]	;number sectors
	mov	dx,[cs:si.dpt_cyl]	;number cylinders
	mul	dx
	stosw		;-> physical sector count
	xchg	ax,dx
	stosw
	xor 	ax,ax
	stosw
	stosw
	mov	ax,512	;bytes per sector
	stosw
	mov	al,0	;ok status
hd_edd489: jmp	hd_exit0
	;
	; write LBA address to command file
	;
	; returns sector count in BL, transfer address in ES:DI
	;
	; this will break on old drives that don't support LBA
	;
hd_xadr:	mov	es,[bp._ds]	;restore segment, SI still OK
	cmp 	byte ptr [es:si+drq_len],16	;at least 16 bytes
	jb	hd_xadr9	;:error
	mov	dx,hdc_cnt	;sector count
	mov	al,[es:si+drq_blk]
	mov	bl,al	;return in BL
	out	dx,al
	inc	dx
	mov 	ax,[es:si+drq_lba]	;LBA sector number
	out	dx,al	;hdc_sec sector = LBA 7..0
	inc	dx
	mov cl,8
	shr	ax,cl
	out	dx,al	;hdc_cyl cylinder low = LBA 15..8
	inc	dx
	mov 	ax,[es:si+drq_lba+2]	;LBA sector number
	out	dx,al	;hdc_cyh cylinder high = LBA 23..16
	inc	dx
	in	al,dx	;hdc_drv get drive
	and	al,0b0h	;keep reserved, drive select bits
	or	al,40h	;set LBA mode
	or	al,ah
	out	dx,al	;hdc_drv heads = LBA27..24
	mov 	di,[es:si+drq_ofs]	;get ^transfer buffer
	mov 	es,[es:si+drq_seg]
	cld		;forward mode
	clc		;ok
	ret
	
hd_xadr9:	mov	al,1	;return error
	stc
	ret
endif
	;
	; wait for not busy, check status
	;
hd_stat0:	call	hd_busy18	;wait until not busy
	jb	hd_stat9
	
	; Enter here for faster service (assuming normally not busy)
	; This is arranged to get fastest response when no error.
	
hd_stat:	mov	dx,hdc_stat	;test whether busy
	in	al,dx
	test	al,80h
	jnz	hd_stat0	;:busy
	mov	byte ptr [ds:m_hdst],al
	mov	ah,al	;save status
	test	al,24h	;write fault / ECC ?
	jnz	hd_stat1
	and	al,50h	;not ready, or seek error ?
	cmp	al,50h
	jnz	hd_stat2
	test	ah,1	;other error ?
	jnz	hd_stat3
	mov	al,0	;return ok status
	ret
	
hd_stat1:	mov	al,11h	;ECC corrected data
	test	ah,4
	jnz	hd_stat9
	mov	al,0cch	;no - must be write fault
hd_stat9:	stc
	ret
	
hd_stat2:	mov	al,0aah	;not ready
	test	ah,40h
	jz	hd_stat9
	mov	al,40h	;no - must be seek error
	stc
	ret
	
hd_stat3:	mov	dx,hdc_err	;read error register
	in	al,dx
	mov	byte ptr [ds:m_hderr],al
	mov	si, offset hd_errtab
	cmp	al,0	;nothing set -> undefined error
	jz	hd_stat5
hd_stat4:	inc	si
	shl	al,1
	jnb	hd_stat4
hd_stat5:	mov 	al,[cs:si]	;get error code
	stc
	ret
	;
	; error register -> error code translation
	;
hd_errtab: db	0e0h	;nothing set - status error
	db	0ah	;80 - bad sector flag detected
	db	10h	;40 - bad ECC
	db	0bbh	;20 - undefined error
	db	04h	;10 - record not found
	db	01h	;08 - abort -> bad command
	db	0bbh	;04 - undefined error
	db	40h	;02 - seek error
	db	02h	;01 - address mark not found
	;
	; get pointer to parameter block
	;
	; entry: DL = drive
	; exit:  CS:DI = parameter block
	;
hd_parm:	and	dl,7fh
	cmp	dl, byte ptr [ds:m_hdcnt]	;legal drive number ?
	jae	hd_parm9	;:bad
	mov	di, offset hd_prm1
	test	dl,1	;(clc)
	jnz	hd_parm2
	mov	di, offset hd_prm0
hd_parm2:	ret

hd_parm9:	mov	al,1	;error code
	stc
	ret
	;
	; wait while HD busy, CX ticks
	;
hd_busy18: mov	cx,18	;18 ticks = 1 second
hd_busy:	add	cx,[m_timer]	;start time + max number of ticks
	mov	dx,hdc_stat
hd_busy1:	in	al,dx
	test	al,80h	;busy ?
	jz	hd_busy9	;:no, carry clear
	cmp	cx,[m_timer]
	jns	hd_busy1	;keep waiting
hd_busy8:	stc		;time-out
	mov	al,80h	;status code
hd_busy9:	ret
	;
	; select drive, wait for drive ready
	;
	; -> CS:DI = ^parameter block
	;
	
	; special entry: no drive number check
	
hd_selb:	mov	cx,18	;1 s time-out
	and	dl,7fh	;mask drive number
	jmp	short hd_sel0a

	; normal entry
	
hd_sel:	mov	cx,18	;1 s time-out for ready wait
hd_sel0:	and	dl,7fh	;legal drive number ?
	cmp	dl, byte ptr [ds:m_hdcnt]
	jae	hd_parm9	;:bad
hd_sel0a:	mov	di, offset hd_prm1
	test	dl,1	;(clc)
	jnz	hd_sel1
	mov	di, offset hd_prm0
hd_sel1:	mov	byte ptr [ds:m_hdflag],0	;clear interrupt flag
	mov	al,dl	;drive
	push cx
	mov cl,4
	shl	al,cl
	pop cx
	or	al,0a0h	;reserved bits
	mov	dx,hdc_drv
	out	dx,al	;set drive
	;
	; wait until HD ready, CX ticks
	;
hd_rdy:	add	cx,[m_timer]	;start time + max number of ticks
	mov	dx,hdc_stat
hd_rdy1:	in	al,dx
	test	al,80h
	jnz	hd_rdy2	;:busy
	test	al,40h
	jnz	hd_busy9	;:ready, carry clear
hd_rdy2:	cmp	cx,[m_timer]
	jns	hd_rdy1	;keep waiting
	jmp	hd_busy8
	;
	; issue command AL, wait for interrupt
	;
hd_cmd:	mov	byte ptr [ds:m_hdflag],0	;clear interrupt flag
	mov	dx,hdc_cmd
	out	dx,al
	
	; wait for HD interrupt
	
hd_int:	mov	cx,18*4	;4 seconds
	add	cx,[m_timer]	;start time + max number of ticks
hd_int1:	cli		;test in critical section as some
			;modern drives are "too fast" for
			;slower embedded boards.
	test	byte ptr [ds:m_hdflag],0ffh	;interrupt ?
	jnz	hd_int9	;:yes, return NC
	cmp	cx,[m_timer]	;time-out ?
	js	hd_int8	;:yes, return CY
	sti		;end critical section, HLT follows
	hlt		;power-saving wait for next interrupt
	jmp	hd_int1
	
hd_int8:	stc		;time-out
	mov	al,80h	;status code
hd_int9:	sti		;re-enable interrupts !
	ret
	;
	; IRQ14 entry
	;
irq14:	push	ax
	push	ds
	xor	ax,ax	;BIOS segment
	mov	ds,ax
	mov	byte ptr [ds:m_hdflag],0ffh	;set interrupt flag
	mov	al,eoi
	out	pic1,al
	out	pic0,al
	pop	ds
	pop	ax
	iret
	;
	; set hard disk time-out
	;
ifdef	HD_TIME
hd_timer:
	call	hd_sel	;select drive, wait for not busy
	jb	hd_tim9
	mov	dx,hdc_cnt
	mov	al,HD_TIME
	out	dx,al
	mov	al,0e3h
	call	hd_cmd	;issue command
	jb	hd_tim9
	mov	dl,low(hdc_err)
	in	al,dx
	and	al,7fh
	jz	hd_tim9
	sub	al,1	;ok ?
	jz	hd_tim9
	mov	al,20h
	stc
hd_tim9:	jmp	hd_exit0
endif
	;
	; write CHS parameters to command file, including CHS translation
	;
hd_chs:	mov	dx,hdc_cnt	;sector count
	mov	al,[bp._al]
	out	dx,al
	inc	dx
	mov 	cl,[cs:di.dpt_shl]	;get shift count
ifdef	HDD_LBA
	cmp	cl,0ffh	;LBA mode ?
	jz	hd_chs2
endif
	mov	bx,[bp._cx]	;sector number, cylinder
	mov	al,bl	;sector number
	and	ax,3fh	;(need AH = 0 for divide)
	out	dx,al	;hdc_sec
	mov	al,[bp._dh]	;head number
	div 	byte ptr [cs:di.dpt_phd]	;divide by physical heads
			;-> AL = heads, AH = cylinders
	inc	dx
	xchg	bl,bh	;swap cylinder
	mov ch,6
	shr	bh,ch	;bit 7..6 become bits 9..8
	shl	bx,cl	;shift cylinder for CHS translation
	or	al,bl	;head
	out	dx,al	;hdc_cyl - cylinder low
	inc	dx
	mov	al,bh	;cylinder high
	out	dx,al	;hdc_cyh
	inc	dx
	in	al,dx	;hdc_drv
	or	al,ah	;heads
	out	dx,al
	ret
	;
	; LBA translation
	;
ifdef	HDD_LBA
hd_chs2:
	push 	ax								;save eax, ebx
	push 	bx
	push	cx
	push	dx
	;
	mov		ax,[bp._cx]						; sector number, cylinder
	xchg	al,ah							; swap cylinder high, low
	mov		cl,6
	shr		ah,cl							; ax = cyclinder
	;
	mov		dx, 255
	mul		dx								; dx:ax = cyclinder*255
	;
	mov		bx, ax
	mov		cx, dx							; cx:bx = cylinder*255
	;
	xor 	ax,ax
	mov		al,[bp._dh]						; head number
	mov		dx, 63
	mul		dx								; dx:ax = head*63
	;
	add		ax,bx
	adc		cx,dx							; cx:ax = cylinder*255 + head*63
	;
	xor		bx,bx
	mov		bl,[bp._cl]						; sector number
	and		bl,63
	dec		bx								; bx = sector - 1
	;
	add		ax,bx
	xor		bx,bx
	adc		bx,cx							; bx:ax = cylinder*255 + head*63 + sector - 1
	;										; bx:ax = LBA27..00
	pop		dx
	pop		cx								
	;
	out		dx,al							; hdc_sec sector = LBA 7..0
	;
	inc		dx
	mov		al,ah
	out		dx,al							; hdc_cyl cylinder low = LBA 15..8
	;
	inc		dx
	mov		ax, bx
	out		dx,al							; hdc_cyh cylinder high = LBA 23..16
	
	inc		dx
	in		al,dx							; hdc_drv get drive
	and		al,0b0h							; keep reserved, drive select bits
	or		al,040h							; set LBA mode
	or		al,ah
	out		dx,al							; hdc_drv heads = LBA27..24
	;
	pop 	bx
	pop 	ax
	ret
endif
	;
	; HD detect / init
	;
hd_init:

ifdef	HD_WAIT
	;
	; Some drives take a long time to become responsive to commands,
	; because they only store very minimal firmware, and fetch the
	; actual code from disk. Some of them are allergic to being touched
	; before they are ready.
	;
ifndef	HD_WAITA
	cmp	word ptr [ds:m_rstflg],1234h	;Ctrl-Alt-Del ?
	jz	hd_wait9	;:skip wait
endif
	xor	bx,bx	;clear second counter
	mov	si, offset msg_wait
	call	v_msg
	cmp	bx,HD_ENA	;0 delay ?
	jz	hd_wait3	;yes: bypass
	
hd_wait1:	mov	ax,18	;about 1 second
	add	ax,[m_timer]	;start time + max number of ticks
hd_wait2:	hlt		;low power wait, we'll be here for a
			;while
	cmp	ax,[m_timer]	;time-out ?
	jns	hd_wait2	;no: keep waiting
	
	cmp	bx,HD_ENA	;can we touch the drive now ?
	jb	hd_wait8	;:no
hd_wait3:	mov	al,0ffh	;place FF on the IDE bus (or loopback)
	mov	dx,hdc_dat
	out	dx,al
	mov	dx,hdc_stat	;does the status register read non-FF ?
	in	al,dx
	cmp	al,0ffh
	jz	hd_wait8a	;FF: no drive attached, bail
	test	al,80h	;busy ?
	jnz	hd_wait8	;:don't touch
	mov	al,0a0h	;access master drive
	mov	dx,hdc_drv
	out	dx,al
	out	iowait,ax
	mov	dx,hdc_stat	;read status
	in	al,dx
	test	al,80h	;busy ?
	jnz	hd_wait8
	test	al,40h	;drive ready ?
	jnz	hd_wait8a	;:terminate the wait

hd_wait8:	mov	si, offset msg_dot	;display a dot each second
	call	v_msg
	inc	bx	;second counter
	cmp	bx,HD_WAIT
	jb	hd_wait1
	
hd_wait8a: mov	si, offset msg_crlf	;go to next line
	call	v_msg
hd_wait9:
endif

	cli
	mov	ax,int13hd	;set interrupt vector
	xchg	word ptr [ds:vec13],ax
	mov	word ptr [ds:vec40],ax
	mov	ax,cs	;old INT13 becomes INT40
	xchg	word ptr [ds:vec13+2],ax
	mov	word ptr [ds:vec40+2],ax

	mov	word ptr [ds:vec41], offset hd_prm0	;set vectors to disk parameters
	mov	word ptr [ds:vec41+2],cs
	mov	word ptr [ds:vec46], offset hd_prm1
	mov	word ptr [ds:vec46+2],cs

	in	al,pic1+1	;enable HD interrupt
	and	al,0bfh
	out	iowait,ax
	out	pic1+1,al
	
	in	al,pic0+1	;enable cascade interrupt
	and	al,0fbh
	out	iowait,ax
	out	pic0+1,al
	sti

	mov	byte ptr [ds:m_hdcnt],2	;2 drives to start
	mov	byte ptr [ds:m_hdstat],0	;clear status
	
	mov	di, offset hd_prm0	;setup first drive
	mov	dl,80h
	mov	al,0a0h
ifndef	HDD_PRES
	call	hd_pres	;check presence
	jb	hd_init1
endif
	call	hd_set	;set parameters
	jb	hd_init1
	
	; Unfortunately, it is not that easy to detect the slave drive,
	; as the master drive will often drive the slave registers to
	; "safe" values when the slave is not present.
	;
	; It is supposed to be possible to detect number of drives with
	; the execute drive diagnostic command, but I don't see how.
	;
	; In the end, if the detection was incorrect, we will time out
	; (about a second) when trying to identify the drive.

	mov	dl,81h	;setup second drive
ifndef	HDD_NOSLAVE
	mov	di,hd_prm1
	mov	al,0b0h
	call	hd_pres	;check presence
	jb	hd_init1
	call	hd_set	;set parameters
	jb	hd_init1	;:error
	inc	dx	;increment drive count if no error
endif

hd_init1:
	mov 	byte ptr [cs:hd_top],dl	;store top hard disk number
	and	dl,7fh	;done - store number drives
	mov	byte ptr [ds:m_hdcnt],dl
	ret
	;
	; check drive presence, AL = A0 or B0
	;
hd_pres:	push	dx
	mov	dx,hdc_drv
	out	dx,al
	out	iowait,ax
	out	iowait,ax
	out	iowait,ax
	
	mov	dx,hdc_cnt	;write test pattern
	mov	al,55h
	out	dx,al
	mov	dx,hdc_cyl	;write negative pattern
	mov	al,0aah
	out	dx,al
	mov	dx,hdc_cnt	;read test pattern
	in	al,dx
	xor	al,55h
	jz	hd_pres9	;:ok
hd_pres8:	stc
hd_pres9:	pop	dx
	ret
	;
	; set up drive DL
	;
hd_set:	mov	ah,25h	;get drive ID
	mov	bx,tmp_buf
	int	13h
	jb	hd_set9
	
ifdef	cs_ide
	push	di	;save ^drive parameters
	mov	di,tmp_buf	;DS:DI points to identify buffer
	push	dx	;DL: drive
	call	cs_ide	;set drive timing parameters
	pop	dx
	pop	di
endif
	cmp	word ptr [ds:tmp_buf+0],848ah	;CompactFlash ?
	jz	hd_set0	;:yes
	cmp	word ptr [ds:tmp_buf+0],844ah	;CompactFlash ? (new SanDisk)
	jz	hd_set0	;:yes
	test	byte ptr [ds:tmp_buf+1],80h	;ATAPI ?
	jz	hd_set0	;:no

	; note I/O base and drive ID of ATAPI CD-ROM
	; this is assumed to be the first ATAPI device found

ifdef	CDBOOT
	cmp	byte [cs:d_cdbase],0	;is this the first ATAPI drive ?
	jnz	hd_set9	;:no
	mov	word [cs:d_cdbase],01f0h	;set address
	test	dl,1	;master ?
	jnz	hd_set9	;:slave, default
	mov 	byte [cs:d_cddrv],0a0h	;master drive
endif
	
hd_set9:	stc		;error return
	ret	
	
hd_set0:	mov 	al,byte ptr [ds:tmp_buf+12]	;sectors
	mov 	[cs:di.dpt_sec],al
	mov 	[cs:di.dpt_psec],al
	mov 	al,[ds:tmp_buf+94]	;multiple block size
	mov 	[cs:di.dpt_mul],al
	mov 	ax,[ds:tmp_buf+2]	;cylinders
	mov 	[cs:di.dpt_pcyl],ax
	mov 	bl,[ds:tmp_buf+6]	;heads
	mov 	[cs:di.dpt_phd],bl
	
	; CHS translation: shift cylinders right / heads left until
	; cylinders < 1024
	
	mov	bh,0	;shift count
ifdef	FORCE_LBA
	cmp	ax,8191	;force LBA for high cylinder count
	ja	hd_lba
endif

hd_set1:	cmp	ax,1024
	jb	hd_set2
	shr	ax,1	;cylinders / 2
	shl	bl,1	;heads * 2
ifdef	HDD_LBA
	jb	hd_lba	;:overflow - use LBA mode for this drive
else
	jb	hd_set9	;:overflow - cannot translate drive
endif
	inc	bh	;count the shifts
	jmp	hd_set1

hd_set2:	mov 	[cs:di.dpt_cyl],ax
	mov 	[cs:di.dpt_head],bl
	mov 	[cs:di.dpt_shl],bh
	
	mov 	byte ptr [cs:di.dpt_sig],0a0h	;signature

	mov	ah,9	;set drive parameters
	int	13h
	jb	hd_set9
	
	mov	ah,0dh	;reset drive
	int	13h
	
hd_set2b:
	push	dx
	mov	ah,8	;get max CHS
	int	13h
	mov	al,dh	;heads
	pop	dx
	jb	hd_set9
	
	mov	ah,4	;verify sectors
	mov	dh,al	;max head
	mov	al,cl	;max sector -> sector count
	and	al,3fh
	and	cl,0c0h	;start sector = 1
	or	cl,1
	sub	ch,1	;cylinder - 1
	jnb	hd_set3
	sub	cl,40h
hd_set3:	int	13h
	jb	hd_set9

ifdef	HD_TIME
	mov	ah,23h	;set drive time-out
	mov	al,HD_TIME
	int	13h
endif
	ret		;normal return

ifdef	HDD_LBA
	;
	; determine LBA parameters (always 255 heads / 63 sectors)
	;
hd_lba:	test 	byte ptr [ds:tmp_buf+99],2	;LBA mode supported ?
	jz	hd_set9	;:no	

	push	dx	
	mov	ax,[tmp_buf+120]	;number of LBA sectors (low)
	mov	dx,[tmp_buf+122]	;(high)
	mov	bx,255*63	; / heads / sectors
	div	bx
	pop	dx

	; set drive parameters
	
	mov 	[cs:di.dpt_cyl],ax
	mov 	byte ptr [cs:di.dpt_head],255	;255 heads
	mov	byte ptr [cs:di.dpt_shl],0ffh	;special shift -> LBA mode
	mov	byte ptr [cs:di.dpt_sec],63	;63 sectors
	jmp	hd_set2b	;note we don't set LBA parameters
endif
