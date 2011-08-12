;
; XCDROM.ASM    Written 8-Feb-2006 by Jack R. Ellis.
;
; XCDROM is free software.  You can redistribute and/or modify it under
; the terms of the GNU General Public License (hereafter called GPL) as
; published by the Free Software Foundation, either version 2 of GPL or
; any later versions at your option.  XCDROM is distributed in the hope
; that it will be useful, but WITHOUT ANY WARRANTY and without even the
; implied warranties of MERCHANTABILITY nor of FITNESS FOR A PARTICULAR
; PURPOSE!   See the GPL for details.   You should have received a copy
; of the GPL with your XCDROM files.  If not write to the Free Software
; Foundation Inc., 59 Temple Place Ste. 330, Boston, MA 02111-1307 USA.
; http://www.gnu.org/licenses/
;
; This is a DOS driver for 1 to 3 CD-ROM drives on PC mainboards having
; a VIA VT8235 or similar chipset.   On loading, XCDROM checks both IDE
; channels for CD-ROM drives and runs all the drives it finds.   It has
; switch options (see below) to indicate a desired "driver name" and to
; override its "IDE order" search and check for specific CD-ROM drives.
; XCDROM accepts requests from a "CD-ROM redirector" (SHCDX33A, MSCDEX,
; etc.) for the CD-ROM drive.   If the XDMA disk driver (V3.1 or later)
; is also present and is using output overlap, XCDROM shall synchronize
; all I-O activity on its drive with XDMA I-O.    This lets XDMA output
; overlap be used even where an UltraDMA hard-disk and the CD-ROM drive
; are sharing the same IDE channel!    Also, if V3.1+ XDMA with overlap
; or any V3.0+ XDMA/XDMAJR driver is present, a CD-ROM drive capable of
; UltraDMA will be enabled for it.   XCDROM can be run with older XDMA/
; UDMA2/UDMA drivers or "stand-alone", in which case it will scan for a
; mainboard UltraDMA controller by itself.    If one is found, a CD-ROM
; drive capable of UltraDMA will also be enabled for it.   Other XCDROM
; features are the same as for any DOS CD-ROM driver.   XCDROM does not
; use interrupts and is only for "legacy" IDE channels at I-O addresses
; 01F0h (primary) and 0170h (secondary).
;
; XCDROM switch options are as follows:
;
;    /AX   Excludes ALL audio functions.   This makes the driver report
;	     on a Device-Status request that it reads DATA tracks only!
;	     /AX reduces the resident driver by 448 bytes.    UltraDMA,
;	     multi-drives, and other driver features are NOT affected!
;
;    /D:   Specifies the desired "device name" which SHCDX33A or MSCDEX
;	     will use during their initialization to address the CD-ROM
;	     drives.   Examples are:  /D:CDROM1  /D:MYCDROM  etc.   The
;	     device name must be from 1 to 8 bytes valid for use in DOS
;	     filenames.   If /D: is omitted, or the "device name" after
;	     a /D: is missing or invalid, "XCDROM" will be the default.
;
;    /L    Limits UltraDMA to "low memory" below 640K.   /L is REQUIRED
;	     to use UMBPCI or a similar driver whose upper-memory areas
;	     cannot do UltraDMA.   If /L is given, the driver must load
;	     in LOW memory so its DMA command-lists can fetch preperly,
;	     or driver loading will ABORT!   /L causes any I-O requests
;	     above 640K to use "PIO mode" input.   Note that /L will be
;	     IGNORED if /UX is also given.
;
;    /Mn   Specifies the MAXIMUM UltraDMA "mode" to be set for a CD-ROM
;	     drive, where  n  is a number between 0 and 6, as follows:
;		 0 = ATA-16, 16 MB/sec.    4 = ATA-66,   66 MB/sec.
;		 1 = ATA-25, 25 MB/sec.    5 = ATA-100, 100 MB/sec.
;		 2 = ATA-33, 33 MB/sec.    6 = ATA-133, 133 MB/sec.
;		 3 = ATA-44, 44 MB/sec.
;	     A CD-ROM drive designed to use "modes" LESS than the given
;	     value will be limited to its own highest "mode".   /M will
;	     be IGNORED for CD-ROM drives which cannot do UltraDMA, and
;	     it will be ignored for ALL drives if /UX is also given.
;
;    /PM   Requests the driver to check the IDE primary-master unit for
;	     a CD-ROM drive during driver init.    If a CD-ROM drive is
;	     NOT found as primary-master, driver loading will ABORT!
;
;    /PS   Same as /PM but tests the primary-slave unit only.
;
;    /SM   Same as /PM but tests the secondary-master unit only.
;
;    /SS   Same as /PM but tests the secondary-slave unit only.
;
;	     --- NOTE ---
;	     Using multiple drives, multiple  /PM /PS /SM /SS  switches
;	     can be given.    The first-specified drive is addressed as
;	     "unit 0", the second as "unit 1", etc.   If fewer switches
;	     than drives are given, the unreferenced drives will NOT be
;	     used.    If NO such switches are given, the driver "scans"
;	     for CD-ROM drives, from primary-master to secondary-slave.
;	     The first drive found will be "unit 0", the second will be
;	     "unit 1", etc.
;
;    /UF   Enables "Fast UltraDMA".   Data input requests that cross an
;	     UltraDMA "64K boundary" are executed using a 2-element DMA
;	     command list, one for data up to the boundary, and one for
;	     data beyond it.   CD-ROM speed is increased significantly.
;	     "PIO mode" input is still needed for user buffers that are
;	     misaligned (not at an even 4-byte address).    /UF will be
;	     IGNORED for CD-ROM drives which cannot do UltraDMA.
;
;	     --- NOTE ---
;	     Despite any UltraDMA specs, NOT ALL chipsets or mainboards
;	     can run multi-element DMA commands properly!   Although it
;	     is valuable, /UF must be TESTED on every system, and "Fast
;	     UltraDMA" should be enabled with CARE!!
;
;    /UX   Disables ALL UltraDMA, even for CD-ROM drives capable of it.
;	     The driver then uses "PIO mode" for all data input.    /UX
;	     should be needed only for tests and diagnostic work.
;
; For each switch, a dash may replace the slash, and lower-case letters
; may be used.
;
;
; Revision History:
; ----------------
;  V2.4x 08-Aug-11  Port to 8086 code, for Zet
;  V2.4  08-Jun-07          Rebuilt pci scan. Now SATA and PATA works together.
;  V2.3  		      GCDROM released.
;  V2.2   8-Feb-06  JRE  Corrected DVD handling and "regular" UltraDMA.
;  V2.1  31-Jan-06  JRE  Deleted init "Set Mode" commands (BIOS will do
;			   them anyway) to avoid conflicts.
;  V2.0  27-Jan-06  JRE  Startup and seek timeouts increased.  Added up
;			   to ATA-133 support.  Minor size reductions.
;  V1.9  20-Jan-06  JRE  Fixed errors in Multi-Session and I-O logic.
;  V1.8  17-Jan-06  JRE  Fixed Multi-Session "TOC input" to support ALL
;			   drives, added a drive "reset" on I-O errors.
;  V1.7  14-Jan-06  JRE  Updated XCDROM to read a "Multi Session" disk.
;  V1.6  10-Jan-06  JRE  XCDROM now has stand-alone UltraDMA capability
;			   and no longer requires XDMA/XDMAJR!   "Audio
;			   Busy" status is now updated on ALL requests.
;  V1.5   5-Jan-06  JRE  Fixed "Audio Status" & /AX device-status flags
;			   and added support for up to 3 CD-ROM drives.
;  V1.4   2-Jan-06  JRE  Initial release, added /AX and dual drives.
;  V1.3  30-Dec-05  JRE  4th "Beta" issue, uses V3.1+ XDMA "OCheck".
;  V1.2  23-Dec-05  JRE  3rd "Beta" issue, new /UF and /UX switches.
;  V1.1  15-Dec-05  JRE  2nd "Beta" issue, improved XDMA linkage.
;  V1.0  14-Dec-05  JRE  Original "Beta" XCDROM issue.
;
cpu 8086
;
; General Program Equations.
;
%define		VER 'V2.4b, 8086 only, 08 Aug 2011'		;Driver version number and date.
BSTACK		equ	330							;"Basic" driver local-stack size.
STACK		equ	332							;Regular driver local-stack size.
XDDMAAD		equ	00008h						;XDMA "DMAAd" offset,  CANNOT CHANGE!
XDFLAGS		equ	00012h						;XDMA "Flags" offset,  CANNOT CHANGE!
XDCHECK		equ	00314h						;XDMA "OCheck" offset, CANNOT CHANGE!
PCHADDR		equ	001F0h						;"Legacy" IDE primary base address.
SCHADDR		equ	00170h						;"Legacy" IDE secondary base address.
MSELECT		equ	0A0h						;"Master" device-select bits.
SSELECT		equ	0B0h						;"Slave"  device-select bits.
RMAXLBAlsb	equ	0DD39h						;Redbook (audio) maximum LBA value.
RMAXLBAmsb	equ	00006h						;Redbook (audio) maximum LBA value.
COOKSL		equ	2048						;CD-ROM "cooked" sector length.
RAWSL		equ	2352						;CD-ROM "raw" sector length.
CMDTO		equ	00Ah						;500-msec minimum command timeout.
SEEKTO		equ	037h						;3-second minimum "seek"  timeout.
STARTTO		equ	07Fh						;7-second minimum startup timeout.
BIOSTMR 	equ	0046Ch						;BIOS "tick" timer address.
HDI_OFS		equ	0048Eh-BIOSTMR				;BIOS hard-disk int. flag "offset".
VDSFLAG 	equ	0047Bh						;BIOS "Virtual DMA" flag address.
IXM			equ	2048						;IOCTL transfer-length multiplier.
CR			equ	00Dh						;ASCII carriage-return.
LF			equ	00Ah						;ASCII line-feed.
TAB			equ	009h						;ASCII "tab".
;
; IDE Controller Register Definitions.
;
CDATA		equ	001F0h						;Data port.
;CDATA		equ	00080h						;Data port.
;;CDATA		equ	9000h						;Data port.
;CSECCT		equ	CDATA+2						;I-O sector count.
;CDSEL		equ	CDATA+6						;Drive-select and upper LBA.
;CCMD		equ	CDATA+7						;Command register.
;CSTAT		equ	CDATA+7						;Primary status register.
;CSTAT2		equ	CDATA+206h					;Alternate status register.
;
; Controller Status and Command Definitions.
;
BSY			equ	080h						;IDE controller is busy.
DRQ			equ	008h						;IDE data request.
ERR			equ	001h						;IDE general error flag.
DMI			equ	004h						;DMA interrupt occured.
DME			equ	002h						;DMA error occurred.
LBABITS 	equ	0E0h						;Fixed LBA command bits.
;
; DOS "Request Packet" Layout.
;
struc	RP
RPHLen		resb	1						;Header byte count.
RPSubU		resb	1						;Subunit number.
RPOp		resb	1						;Command code.
RPStat		resw	1						;Status field.
			resb	8						;(Unused by us).
RPUnit		resb	1						;Number of units found.
RPSize		resd	1						;Resident driver size.
RPCL		resd	1						;Command-line data pointer.
endstruc

RPERR		equ	08003h						;Packet "error" flags.
RPDON		equ	00100h						;Packet "done" flag.
RPBUSY		equ	00200h						;Packet "busy" flag.
;	
; IOCTL "Request Packet" Layout.
;
struc	IOC
			resb	13						;Request "header" (unused by us).
			resb	1						;Media descriptor byte (Unused by us).
IOCAdr		resd	1 						;Data-transfer address.
IOCLen		resw	1						;Data-transfer length.
			resw	1						;Starting sector (unused by us).
			resd	1						;Volume I.D. pointer (unused by us).
endstruc
;
; Read Long "Request Packet" Layout.
;
struc	RL
			resb	13						;Request "header" (unused by us).
RLAM		resb	1						;Addressing mode.
RLAddr		resd	1						;Data-transfer address.
RLSC		resw	1						;Data-transfer sector count.
RLSec		resd	1						;Starting sector number.
RLDM		resb	1						;Data-transfer mode.
RLIntlv		resb	1						;Interleave size.
RLISkip		resb	1						;Interleave skip factor.
endstruc
;
; DOS CD-ROM Driver Device Header.
;
@			dd	0FFFFFFFFh					;Link to next header block.
			dw	0C800h						;Driver "device attributes".
			dw	Strat						;"Strategy" routine offset.
			dw	DevIntJ						;"Device-Interrupt" routine offset.
DvrName		db	'XGCDROM '					;DOS "device name" (XCDROM default).
			dw	0							;(Reserved).
			db	0							;First assigned drive letter.
Units		db	0							;Number of CD-ROM drives (1 or 2).
;
; Main I-O Variables (here to align the VDS and DMA variables below).
;
XFRLn		dw	0							;I-O data transfer length.
XFRAd		dd	0							;I-O data transfer address.
RqPkt		dd	0		;					DOS request-packet address.
;
; VDS and DMA Variables.
;
PRDAd		dd	IOAdr						;PRD 32-bit command addr. (Init set).
VDSLn		dd	ResEnd						;VDS buffer length.
VDSOf		dd	0							;VDS 32-bit offset.
VDSSg		dd	0							;VDS 16-bit segment (hi-order zero).
IOAdr		dd	0							;VDS and DMA 32-bit address.
IOLen		dd	0							;1st DMA byte count.
IOAdr2		dd	0							;2nd DMA 32-bit address & byte count
IOLen2		dd	080000000h					;  for input "across" a 64K boundary!
;
; ATAPI "Packet" Area (always 12 bytes for a CD-ROM).
;
Packet		db	0							;Opcode.
			db	0							;Unused (LUN and reserved).
PktLBA		dd	0							;CD-ROM logical block address.
PktLH		db	0							;"Transfer length" (sector count).
PktLn		dw	0							;Middle- and low-order sector count.
PktRM		db	0							;Read mode ("Raw" Read Long only).
			dw	0							;Unused ATAPI "pad" bytes (required).
;
; Miscellaneous Driver Variables.
;
XOCheck		dw	XDCHECK						;XDMA's "OCheck" subroutine pointer.
XDSeg		dw	0							;XDMA's segment address (set by Init).
EntryP		dw	I_Init						;DOS entry routine ptr. (set by Init).
AudAP		dw	0							;Current audio-start address pointer.
DMAAd		dw	0FFFFh						;Current DMA cmd. addr. (set by Init).
IDEAd		dw	0							;Current IDE data-register address.
IDESl		db	0							;Current device-select command byte.
SyncF		db	0							;Current XDMA synchronization flag.
BusyF		db	0							;"Sync busy" flag (in sync with XDMA).
VLF			db	0							;VDS "lock" flag (001h = buffer lock).
DMAFl		db	0							;DMA input flag (001h if so).
Try			db	0							;I-O retry counter.
			db	0,0							;(Unused alignment "filler").
;
; Audio Function Buffer (16 bytes) for most CD-ROM "audio" requests.
;   The variables below are used only during driver initialization.
;
InBuf		equ	$

ClrStak		dw	ResEnd-STACK-4				;Beginning stack addr. (set by Init).
UTblP		dw	UnitTbl						;Initialization unit table pointer.
PrDMA		dw	0FFFFh						;Primary DMA address   (set by Init).
IEMsg		dw	0							;Init error-message pointer.
UFXSw		db	0F1h						;UltraDMA "F/X" switch (set by Init).
MaxUM		db	0FFh						;UltraDMA "mode" limit (set by Init).
UFlag		db	0							;UltraDMA "mode" flags (set by Init).
UMode		db	0							;UltraDMA "mode" value (set by Init).
			db	0							;(Unused alignment "filler").
SyncX		db	0FFh						;"No XDMA synchronization" flag.
ScanX		dw	ScanP						;Scan table index (0FFFFh = no scan).

ChipN		db	00h							;channel number (set by Init).
			db	00h

;
; Unit Parameter Tables.   If you want a 4th drive, simply add 1 more
;   parameter table -- NO extra code and NO other changes are needed!
;
UnitTbl		dw	0FFFFh						;Unit 0 DMA address   (set by Init).
			dw	0FFFFh						;	IDE address   (set by Init).
			db	0FFh						;	Device-select (set by Init).
			db	0FFh						;	XDMA sync bit (set by Init).
			db	0							;	(Unused alignment "filler").
			db	0FFh						;	Media-change flag.
			dd	0FFFFFFFFh					;	Current audio-start address.
			dd	0FFFFFFFFh					;	Current audio-end   address.
			dd	0FFFFFFFFh					;	Last-session starting LBA.
			dd	0FFFFFFFFh					;Unit 1 Parameters  (same as above).
			dd	0FF00FFFFh
			dd	0FFFFFFFFh
			dd	0FFFFFFFFh
			dd	0FFFFFFFFh
			dd	0FFFFFFFFh					;Unit 2 Parameters  (same as above).
			dd	0FF00FFFFh
			dd	0FFFFFFFFh
			dd	0FFFFFFFFh
			dd	0FFFFFFFFh
			
UTblEnd		equ	$							;(End of all unit tables).
;
; Dispatch Table for DOS CD-ROM request codes 0 through 14.
;
DspTbl1		dw	DspLmt1						;Number of valid request codes.
			dw	Try2ndD						;Invalid-request handler address.
DspTblA		dw	UnSupp						;00 -- Initialization  (special).
			dw	UnSupp						;01 -- Media Check	(unused).
			dw	UnSupp						;02 -- Build BPB	(unused).
			dw	Try3rdD						;03 -- IOCTL Input.
			dw	UnSupp						;04 -- Input		(unused).
			dw	UnSupp						;05 -- Input no-wait	(unused).
			dw	UnSupp						;06 -- Input Status	(unused).
			dw	UnSupp						;07 -- Input flush	(unused).
			dw	UnSupp						;08 -- Output		(unused).
			dw	UnSupp						;09 -- Output & verify	(unused).
			dw	UnSupp						;10 -- Output status	(unused).
			dw	UnSupp						;11 -- Output flush	(unused).
			dw	Try4thD						;12 -- IOCTL Output.
			dw	Ignored						;13 -- Device Open     (ignored).
			dw	Ignored						;14 -- Device Close    (ignored).
DspLmt1		equ	($-DspTblA)/2				;Request-code limit for this table.
;
; Dispatch Table for DOS CD-ROM request codes 128 through 136.
;
DspTbl2		dw	DspLmt2						;Number of valid request codes.
			dw	UnSupp						;Invalid-request handler address.
DspTblB		dw	ReqRL						;128 -- Read Long.
			dw	UnSupp						;129 -- Reserved	(unused).
@RqPref		dw	ReqSeek						;130 -- Read Long Prefetch.
@RqSeek		dw	ReqSeek						;131 -- Seek.
@RqPlay		dw	ReqPlay						;132 -- Play Audio.
@RqStop		dw	ReqStop						;133 -- Stop Audio.
			dw	UnSupp						;134 -- Write Long	(unused).
			dw	UnSupp						;135 -- Wr. Long Verify	(unused).
@RqRsum		dw	ReqRsum						;136 -- Resume Audio.

DspLmt2		equ	($-DspTblB)/2				;Request-code limit for this table.
;
; Dispatch table for IOCTL Input requests.
;
DspTbl3		dw	DspLmt3						;Number of valid request codes.
			dw	UnSupp						;Invalid-request handler address.
DspTblC		dw	ReqDHA +5*IXM				;00 -- Device-header address.
@RqCHL		dw	ReqCHL +6*IXM				;01 -- Current head location.
			dw	UnSupp						;02 -- Reserved		(unused).
			dw	UnSupp						;03 -- Error Statistics	(unused).
			dw	UnSupp						;04 -- Audio chan. info (unused).
			dw	UnSupp						;05 -- Read drive bytes	(unused).
			dw	ReqDS  +5*IXM				;06 -- Device status.
			dw	ReqSS  +4*IXM				;07 -- Sector size.
@RqVS		dw	ReqVS  +5*IXM				;08 -- Volume size.
			dw	ReqMCS +2*IXM				;09 -- Media-change status.
@RqADI		dw	ReqADI +7*IXM				;10 -- Audio disk info.
@RqATI		dw	ReqATI +7*IXM				;11 -- Audio track info.
@RqAQI		dw	ReqAQI +11*IXM				;12 -- Audio Q-channel info.
			dw	UnSupp						;13 -- Subchannel info	(unused).
			dw	UnSupp						;14 -- Read UPC code	(unused).
@RqASI		dw	ReqASI +11*IXM				;15 -- Audio status info.

DspLmt3		equ	($-DspTblC)/2				;Request-code limit for this table.
;
; Dispatch table for IOCTL Output requests.
;
DspTbl4		dw	DspLmt4						;Number of valid request codes.
			dw	UnSupp						;Invalid-request handler address.
DspTblD		dw	ReqEjct +1*IXM				;00 -- Eject Disk.
			dw	ReqDoor +2*IXM				;01 -- Lock/Unlock Door.
			dw	ReqRS   +1*IXM				;02 -- Reset drive.
			dw	UnSupp						;03 -- Audio control	(unused).
			dw	UnSupp						;04 -- Write ctl. bytes	(unused).
			dw	ReqTray +1*IXM				;05 -- Close tray.
			
DspLmt4		equ	($-DspTblD)/2				;Request-code limit for this table.
;
; "Strategy" routine -- At entry, ES:BX points to the DOS init request
;   packet, whose address is saved for processing below.
;
Strat:
	mov	[cs:RqPkt],bx					;Save DOS request-packet address.
	mov	[cs:RqPkt+2],es
	retf								;Exit & await DOS "device interrupt".
	db	0								;(Unused alignment "filler").
;
; Subroutines to do all initialization "external" calls.
;
I_Dsply:
	push	bx							;Message -- save our BX-register.
	mov	ah,009h							;Have DOS display desired message.
	int	021h
	pop	bx								;Reload our BX-register.
	sti									;RESTORE all critical driver settings!
	cld									;(Never-NEVER "trust" external code!).
	push	cs
	pop	ds
	ret									;Exit.
;
; Subroutine to convert a 4-digit hex number to ASCII for messages.
;   At entry, the number is in the AX-reg., and the message pointer
;   is in the SI-reg.   At exit, the SI-reg. is updated and the CX-
;   reg. is zero.
;
I_Hex:
	mov	cx,4							;Set 4-digit count.
I_HexA:
	rol	ax,1							;Get next hex digit in low-order.
	rol	ax,1
	rol	ax,1
	rol	ax,1
	push	ax							;Save remaining digits.
	and	al,00Fh							;Mask off next hex digit.
	cmp	al,009h							;Is digit 0-9?
	jbe	I_HexB							;Yes, convert to ASCII.
	add	al,007h							;Add A-F offset.
I_HexB	add	al,030h						;Convert digit to ASCII.
	mov	[si],al							;Store next digit in message.
	inc	si								;Bump message pointer.
	pop	ax								;Reload remaining digits.
	loop	I_HexA						;If more digits to go, loop back.
	ret									;Exit.
;
Debug_Adr_Msb	db	'xxxx:'
Debug_Adr_Lsb	db	'xxxx',CR,LF,'$'
				db  0,0,0,0,0,0,0,0
;
; "Device-Interrupt" routine -- This routine processes DOS requests.
;
DevInt:
	pushf								;Entry -- save current CPU flags.
	cli									;Disable CPU interrupts.
	mov	[cs:CStack],sp					;Save caller's stack pointer.
@CStak1	equ	$-2
	mov	[cs:CStack+2],ss
@CStak2	equ	$-2
	push	cs							;Switch to this driver's stack.
	pop	ss
	mov	sp,CStack
@Stack	equ	$-2							;(Driver stack pointer, set by Init).
	sti									;Re-enable CPU interrupts.
	cld									;Ensure FORWARD "string" commands!
	push	ax							;Save only the CPU registers we need.
	push	dx							;(Only EAX/EDX are used for 32-bit
	push	bx							;   math, and BP is not used here).
	push	cx
	push	si
	push	di
	push	ds							;Save CPU segment registers.
	push	es
	push	cs							;Set this driver's DS-register.
	pop	ds
	xor	bx,bx							;Zero BX-reg. for relative commands.
	call	ZPacket						;Clear our ATAPI packet area.
	les	si,[bx+RqPkt-@]					;Point to DOS request packet.
	mov	word [es:si+RPStat],RPDON 		;Init status to "done".
	mov	al,[es:si+RPSubU]	   			;Get unit-table offset.
	mov	ah,20
	mul	ah
	mov	di,UnitTbl+8					;Set unit's audio-start address ptr.
	add	di,ax
	mov	[bx+AudAP-@],di
	mov	ax,[di+0-8]						;Set drive DMA and IDE addresses.
	mov	[bx+DMAAd+0-@],ax
	mov	ax,[di+2-8]
	mov	[bx+DMAAd+2-@],ax
	mov	ax,[di-4]						;Set device-select & XDMA "sync" flag.
	mov	[bx+IDESl-@],ax
	mov	al,[es:si+RPOp]					;Get packet request code.	
	mov	di,DspTbl1						;Point to 1st DOS dispatch table.
	call	Dspatch						;Dispatch to desired request handler.
	xor	cx,cx							;Load and reset our "sync busy" flag.
	xchg	cl,[bx+BusyF-@]
	cli									;Disable CPU interrupts.
	jcxz	DevInt1						;Are we synchronized with XDMA?
	mov	es,[bx+XDSeg-@]					;Yes, point to XDMA driver data.
	not	cl								;Reset XDMA channel "busy" flag.
	and	[es:XDFLAGS],cl
DevInt1:
	pop	es								;Reload the CPU registers we used.
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	dx
	pop	ax
	mov	sp,[cs:CStack]  				;Reload caller's stack pointer.
@CStak3	equ	$-2
	mov	ss,[cs:CStack+2]
@CStak4	equ	$-2
	popf								;Reload CPU flags saved on entry.
	retf								;Exit.
;
; Function-Code "Dispatch" Routines.
;
Try2ndD:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 1Fh
	out dx, al
	pop ax
	pop dx
	;
	sub	al,080h							;Not request code 0-15:  subtract 128.
	mov	di,DspTbl2						;Point to 2nd DOS dispatch table.
	jmp	short Dspatch					;Go try request-dispatch again.
Try3rdD:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 13h
	out dx, al
	pop ax
	pop dx
	;
	mov	di,DspTbl3						;Point to IOCTL Input dispatch table.
	jmp	short TryIOC
Try4thD:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 1Ch
	out dx, al
	pop ax
	pop dx
	;
	mov	di,DspTbl4						;Point to IOCTL Output dispatch table.
TryIOC:
	les	si,[es:si+IOCAdr]  				;Get actual IOCTL request code.
	mov	al,[es:si]
	les	si,[bx+RqPkt-@]					;Reload DOS request-packet address.
Dspatch:
	cmp	al,[di]							;Is request code out-of-bounds?
	inc	di								;(Skip past table-limit value).
	inc	di
	jae	Dsptch1							;Yes?  Dispatch to error handler!
	inc	di								;Skip past error-handler address.
	inc	di
	xor	ah,ah							;Point to request-handler address.
	shl	ax,1
	add	di,ax
Dsptch1:
	mov	dx,[di]							;Get handler address from table.
	mov	di,007FFh
	and	di,dx
	xor	dx,di							;IOCTL request (xfr length > 0)?
	jz	Dsptch2							;No, see if request needs XDMA sync.
	mov cl,11
	shr	dx,cl		   					;Ensure correct IOCTL transfer
	mov	[es:si+IOCLen],dx  				;  length is set in DOS packet.
	les	si,[es:si+IOCAdr]  				;Get IOCTL data-transfer address.
Dsptch2:
	cmp	di,SyncReq	   					;Does request require XDMA sync?
	jb	DspGo		   					;No, dispatch to desired handler.
	cmp	[bx+SyncF-@],bl					;Are we synchronizing with XDMA?
	jz	DspGo							;No, dispatch to desired handler.
	push	ax							;Save AX- and ES-registers.
	push	es
	mov	es,[bx+XDSeg-@]					;Point to XDMA driver in memory.
	mov	al,[bx+SyncF-@]					;Get our XDMA "busy" flags.
	mov	ah,al							;Get XDMA flags for our IDE channel.
	cli									;Disable CPU interrupts.
	and	ah,[es:XDFLAGS]					;Another driver using our channel?
	jz	Dsptch4							;No, post our channel "busy" flag.
	test	ah,060h						;Is our channel busy doing overlap?
	jz	Dsptch3							;Yes, have XDMA await overlap end.
	sti									;Sync ERROR!  Re-enable interrupts.
	pop	es								;Reload ES- and AX-registers.
	pop	ax
GenFail:
	mov	al,12							;General failure!  Get error code.
	jmp	short ReqErr					;Go post packet error code & exit.
Dsptch3:
	call	far [bx+XOCheck-@]  		;Have XDMA await overlap end.
Dsptch4:
	and	al,060h							;Post "busy" flag for our channel.
	or	[es:XDFLAGS],al
	sti									;Re-enable CPU interrupts.
	mov	[bx+BusyF-@],al					;Post "sync busy" flag for exit above.
	pop	es								;Reload ES- and AX-registers.
	pop	ax
DspGo:
	push	di							;Dispatch to desired request handler.
	ret
	;
UnSupp:
	mov	al,3							;Unsupported request!  Get error code.
	jmp	short ReqErr					;Go post packet error code & exit.
SectNF:
	mov	al,8							;Sector not found!  Get error code.
ReqErr:
	les	si,[bx+RqPkt-@]					;Reload DOS request-packet address.
	mov	ah,081h							;Post error flags & code in packet.
	mov	[es:si+RPStat],ax
Ignored	ret								;Exit ("ignored" request handler).
;
; IOCTL Input "Device Header Address" handler, placed here to AVOID
;   the need for XDMA I-O synchronization in our "dispatch" logic.
;
ReqDHA:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 30h
	out dx, al
	pop ax
	pop dx
	;
	push	cs							;Return our base driver address.
	push	bx
	pop	word [es:si+1]
	pop	word [es:si+3]
	ret			;Exit.
;
; IOCTL Input "Sector Size" handler, placed here to AVOID the need
;   for XDMA I-O synchronization in our "dispatch" logic.
;
ReqSS:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 37h
	out dx, al
	pop ax
	pop dx
	;
	cmp	byte [es:si+1],1  				;Is read mode "cooked" or "raw"
	ja	GenFail							;No?  Post "general failure" & exit.
	mov	ax,RAWSL						;Get "raw" sector length.
	je	RqSS1							;If "raw" mode, set sector length.
	mov	ax,COOKSL						;Get "cooked" sector length.
RqSS1	mov	[es:si+2],ax				;Post sector length in IOCTL packet.
RqSSX	ret								;Exit.
SyncReq	equ	$							;Handlers beyond here need I-O sync!
;
; DOS "Read Long" handler.
;
ReqRL:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 20h
	out dx, al
	pop ax
	pop dx
	;
	call	ValSN						;Validate starting sector number.
	call	MultiS						;Handle Multi-Session disk if needed.
	jc	ReqErr							;If error, post return code & exit.
	mov	cx,[es:si+RLSC]					;Get request sector count.
	jcxz	RqSSX						;If zero, simply exit.
	xchg	cl,ch						;Save swapped sector count.
	mov	[bx+PktLn-@],cx
	cmp	byte [es:si+RLDM],1 			;"Cooked" or "raw" read mode?
	ja	SectNF		    				;No?  Return "sector not found"!
	mov	dl,028h		    				;Get "cooked" input values.
	mov	ax,COOKSL
	jb	RqRL1		    				;If "cooked" input, set values.
	mov	dl,0BEh		    				;Get "raw" input values.
	mov	ax,RAWSL
	mov	byte [bx+PktRM-@],0F8h 			;Set "raw" input flags.
RqRL1:
	mov	[byte bx+Packet-@],dl  			;Set "packet" opcode.
	mul	word [es:si+RLSC]   			;Get desired input byte count.
	test	dx,dx		    			;More than 64K bytes desired?
	jnz	SectNF		    				;Yes?  Return sector not found!
	mov	[bx+VDSLn-@],ax	    			;Set VDS and DMA byte counts.
	mov	[bx+IOLen-@],ax
	mov	ax,[es:si+RLAddr]   			;Set user input-buffer address.
	mov	[bx+VDSOf-@],ax
	mov	ax,[es:si+RLAddr+2] 			;Set user input-buffer segment.
	mov	[bx+VDSSg-@],ax
	mov	[bx+XFRAd+2-@],ax
	;
	test	byte [bx+DMAAd-@],007h		;Is drive using UltraDMA?
	jnz	RqRL5			   				;No, do "PIO mode" input.
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 0E8h
	out dx, al
	pop ax
	pop dx
	;
RqRL1lock:
	jmp RqRL1lock
	;
	or	word [bx+IOAdr+0-@],byte -1		;Invalidate VDS address.
	or	word [bx+IOAdr+2-@],byte -1
	mov	ax,08103h		   				;VDS "lock" user buffer.
	mov	dx,0000Ch
	call	RqRL8
	jc	RqRL5			   				;Error -- use PIO input.
	mov	ax,[bx+IOAdr-@]		   			;Get lower VDS address.
	cmp	word [bx+IOAdr+0-@],byte -1 	;Is VDS address valid?
	jne RqRL1a
	cmp	word [bx+IOAdr+2-@],byte -1
	je	RqRL2			  				;Yes, set VDS "lock" flag.
RqRL1a:	
	mov	ax,16		    				;No VDS -- get 20-bit segment.
	mul	word [bx+VDSSg-@]
	add	ax,[bx+VDSOf-@]	   	 			;Add in buffer offset value.
	adc	dx,bx
	mov	[bx+IOAdr-@],ax	    			;Set 20-bit user buffer address.
	mov	[bx+IOAdr+2-@],dx	
RqRL2:
	adc	[bx+VLF-@],bl	    			;Set VDS "lock" flag from carry.
	test	al,003h		    			;Is user buffer 32-bit aligned?
	jnz	RqRL4		    				;No, "unlock" buffer and use PIO.
	cmp	word [bx+IOAdr+2-@],byte -1 	;Is DMA beyond our limit?
@DMALmt	equ	$-1			     			;(009h for a 640K limit).
	ja	RqRL4			     			;Yes, "unlock" & use PIO.
	mov	byte [bx+IOLen+3-@],080h     	;Set DMA list "end" flag.
	mov	cx,[bx+IOLen-@]	    			;Get lower ending DMA address.
	dec	cx		    					;(IOLen - 1 + IOAdr).
	add	ax,cx		    				;Would input cross a 64K boundary?
	jnc	RqRL3		    				;No, set DMA flag & do transfer.
@NoFast:
	inc	ax		    					;Get bytes above 64K boundary.
	cmp	ax,64		    				;Is this at least 64 bytes?
	jb	RqRL4		    				;No, "unlock" buffer and use PIO.
	inc	cx		    					;Get bytes below 64K boundary.
	sub	cx,ax
	cmp	cx,64		    				;Is this at least 64 bytes?
	jb	RqRL4		    				;No, "unlock" buffer and use PIO.
	mov	[bx+IOLen2-@],ax    			;Set 2nd command-list byte count.
	mov	ax,cx		    				;Set 1st command-list byte count.
	push dx
	xor dx,dx
	mov	[bx+IOLen+0-@],ax
	mov	[bx+IOLen+2-@],dx
	add	ax,[bx+IOAdr+0-@]    			;Set 2nd command-list address.
	adc dx,[bx+IOAdr+2-@]
	mov	[bx+IOAdr2+0-@],ax
	mov	[bx+IOAdr2+2-@],dx
	pop dx
RqRL3	inc	byte [bx+DMAFl-@]   		;Set UltraDMA input flag.
	jmp	short RqRL5	    				;Go execute read request.
	;
RqRL4	call	RqRL7					;No UltraDMA -- "unlock" user buffer.
	;
RqRL5:
	call	DoIO						;Execute desired read request.
	jnc	RqRL6							;If no errors, go exit below.
	call	ReqErr						;Post desired error code.
RqRL6:
	mov	[bx+DMAFl-@],bl					;Reset UltraDMA input flag.
RqRL7:
	shr	byte [bx+VLF-@],1  				;Is user buffer "locked" by VDS?
	jnc	RqRLX							;No, just exit below.
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 0E8h
	out dx, al
	pop ax
	pop dx
	;
RqRL7lock:
	jmp RqRL7lock
	;
	mov	ax,08104h						;Get VDS "unlock" parameters.
	xor	dx,dx
RqRL8	push	bx						;Save all our "global" registers.
	push	si
	push	di
	push	es
	mov	di,VDSLn						;Point to VDS parameter block.
	push	cs
	pop	es
	int	04Bh							;Execute VDS "lock" or "unlock".
	sti									;RESTORE all critical driver settings!
	cld									;(Never-NEVER "trust" external code!).
	push	cs
	pop	ds
	pop	es								;Reload all our "global" registers.
	pop	di
	pop	si
	pop	bx
RqRLX	ret								;Exit.
;
; DOS "Seek" handler.
;
DOSSeek:
	call	ValSN						;Validate desired seek address.
	call	MultiS						;Handle Multi-Session disk if needed.
	jc	DOSSkE							;If error, post return code & exit.
	mov	byte [bx+Packet-@],02Bh  		;Set "seek" command code.
DOSSk1:
	call	DoIOCmd						;Issue desired command to drive.
DOSSkE:
	jc	ReqErr							;If error, post return code & exit.
	ret									;Exit.
;
; IOCTL Input "Device Status" handler.
;
ReqDS:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 36h
	out dx, al
	pop ax
	pop dx
	;
	mov	word [bx+Packet+0-@],0005Ah  	;Set up mode-sense.
	mov	word [bx+Packet+2-@],0002Ah
	mov	al,16							;Use input byte count of 16.
	call	DoBufIO						;Issue mode-sense for hardware data.
	jc	DOSSkE							;If error, post return code & exit.
	xor ax,ax							; clear msb part in status flag
	mov	[es:si+3],ax
	mov	ax,00214h						;Get our basic driver status flags.
@Status	equ	$-2		 					;(Set by Init to 00204h for /AX).
	cmp	byte [di+2],071h  				;"Unknown CD", i.e. door open?
	jne	ReqDS1		 					;No, check "locked" status.
	or	al,001h		  					;Post "door open" status flag.
ReqDS1:
	test	byte [di+14],002h	 		;Drive pushbutton "locked out"?
	jnz	ReqDS2		 					;No, set flags in IOCTL.
	or	al,002h							;Set "door locked" status flag.
ReqDS2:
	mov	[es:si+1],ax					;Set status flags in IOCTL buffer.
	xor ax,ax
	mov [es:si+3],ax					;Set status flags in IOCTL buffer.
@RqDSX	jmp	ReadAST						;Go post "busy" status and exit.
;
; IOCTL Input "Media-Change Status" handler.
;
ReqMCS:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 39h
	out dx, al
	pop ax
	pop dx
	;
	call	DoIOCmd						;Issue "Test Unit Ready" command.
	mov	di,[bx+AudAP-@]					;Get media-change flag from table.
	mov	al,[di-1]
	mov	[es:si+1],al					;Return media-change flag to user.
	ret									;Exit.
;
; IOCTL Output "Eject Disk" handler.
;
ReqEjct:
	mov	word [bx+Packet-@],0011Bh		;Set "eject" commands.
	mov	byte [bx+PktLBA+2-@],002h  		;Set "eject" function.
	jmp	short DOSSk1		   			;Go do "eject" & exit.
;
; IOCTL Output "Lock/Unlock Door" handler.
;
ReqDoor:
	mov	al,[es:si+1]					;Get "lock" or "unlock" function.
	cmp	al,001h							;Is function byte too big?
	ja	RqRS1							;Yes, post "General Failure" & exit.
	mov	cx,0001Eh						;Get "lock" & "unlock" commands.
RqDoor1:
	mov	[bx+Packet-@],cx   				;Set "packet" command bytes.
	mov	[bx+PktLBA+2-@],al  			;Set "packet" function byte.
	call	DoIOCmd						;Issue desired command to drive.
	jc	DOSSkE							;If error, post return code & exit.
	jmp	short @RqDSX					;Go post "busy" status and exit.
;
; IOCTL Output "Reset Drive" handler.
;
ReqRS:
	call	StopDMA						;Stop previous DMA & select drive.
	inc	dx								;Point to IDE command register.
	mov	al,008h							;Do an ATAPI "soft reset" command.
	out	dx,al
	call	TestTO						;Await controller-ready.
RqRS1:
	jc	GenFail							;Timeout!  Return "General Failure".
	ret									;Exit.
;
; IOCTL Output "Close Tray" handler.
;
ReqTray:
	mov	al,003h							;Get "close tray" function byte.
	mov	cx,0011Bh						;Get "eject" & "close" commands.
	jmp	short RqDoor1					;Go do "close tray" command above.
;
; Subroutine to handle a Multi-Session disk for DOS reads and seeks.
;   Multi-Session disks require (A) saving the last-session starting
;   LBA for a new disk after any media-change and (B) "offsetting" a
;   read of the VTOC or initial directory block, sector 16 or 17, to
;   access the VTOC/directory of the disk's last session.
;
MultiS:
	mov	di,[bx+AudAP-@]					;Point to drive variables.
	cmp	byte [di+11],0FFh				;Is last-session LBA valid?
	jne	MultiS1							;Yes, proceed with request.
	mov	byte [bx+Packet-@],043h			;Set "Read TOC" command.
	inc	byte [bx+PktLBA-@]				;Set "format 1" request.
	call	DoTOCIO						;Read first & last session.
	jc	MultiSX							;If any error, exit below.
	mov	[bx+PktLBA-@],bl				;Reset "format 1" request.
	mov	al,[di+3]						;Get last-session number.
	call	DoTOCSN						;Read disk info for last session.
	jc	MultiSX							;If error, exit with carry set.
	call	SwapLBA						;"Swap" & save last-session LBA addr.
	mov	di,[bx+AudAP-@]
	mov	[di+8],ax
	mov	[di+10],dx
	call	ZPacket		   				;Reset our ATAPI packet area.
MultiS1:
	mov	ax,[es:si+RLSec+0] 				;Get starting sector number.
	mov	dx,[es:si+RLSec+2]
	cmp dx, byte 0
	jne MultiS2
	cmp ax, byte 16						;Sector 16 (VTOC)
	jne MultiS2
	cmp	ax, byte 17						;Sector 17 (directory)?
	jne	MultiS2							;No, set sector in packet.
	add	ax,[di+8]						;Offset sector to last-session start.
	adc dx,[di+10]
MultiS2:
	call	Swap32						;"Swap" sector into packet as LBA.
	mov	[bx+PktLBA+0-@],ax
	mov	[bx+PktLBA+2-@],dx
	clc									;Clear carry flag (no errors).
MultiSX:
	ret									;Exit.
;
; Ye Olde I-O Subroutine.   ALL of our CD-ROM I-O is executed here!
;
DoTOCSN:
	mov	[bx+PktLH-@],al					;"TOC" -- set session no. in packet.
DoTOCIO:
	mov	al,12							;Use 12-byte "TOC" allocation count.
DoBufIO:
	mov	[bx+PktLn+1-@],al  				;Buffered -- set packet count.
DoBufIn:
	xor	ah,ah		   					;Save data-transfer length.
	mov	[bx+VDSLn-@],ax
	mov	word [bx+VDSOf-@],InBuf  		;Use our buffer for I-O.
	mov	[bx+XFRAd+2-@],cs
	jmp	short DoIO						;Go start I-O below.
DoIOCmd:
	mov	[bx+VDSLn-@],bx					;Command only -- reset xfr length.
DoIO:
	push	si							;Save SI- and ES-registers.
	push	es
	mov	byte [bx+Try-@],4  				;Set request retry count of 4.
DoIO1:
	;
	call	StopDMA						;Stop previous DMA & select drive.
	call	TestTO						;Await controller-ready.
	jc	DoIO3							;Timeout!  Handle as a "hard error".
	mov	ax,[bx+VDSOf-@]					;Reset data-transfer buffer address.
	mov	[bx+XFRAd-@],ax
	mov	ax,[bx+VDSLn-@]					;Reset data-transfer byte count.
	mov	[bx+XFRLn-@],ax
	cmp	[bx+DMAFl-@],bl					;UltraDMA input request?
	je	DoIO2							;No, output our ATAPI "packet".
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 0E4h
	out dx, al
	pop ax
	pop dx
	;
DoIO1lock:
	jmp DoIO1lock
	;
	mov	dx,[bx+DMAAd-@]					;Point to DMA command register.
	mov	al,008h							;Reset DMA commands & set read mode.
	out	dx,al
	inc	dx								;Point to DMA status register.
	inc	dx
	in	al,dx							;Reset DMA status register.
	or	al,006h							;(Done this way so we do NOT alter
	out	dx,al							;  the "DMA capable" status flags!).
	inc	dx								;Set PRD pointer to our DMA address.
	inc	dx
	mov	si,PRDAd
	;outsd								;																80386
	mov ax, [ds:si]
	out dx, ax
	inc si
	inc si
	mov ax, [ds:si]
	out dx, ax
	inc si
	inc si
DoIO2:
	mov	dx,[bx+IDEAd-@]					;Point to IDE "features" register.
	inc	dx
	mov	al,[bx+DMAFl-@]					;If UltraDMA input, set "DMA" flag.
	out	dx,al
	add	dx,byte 3						;Point to byte count registers.
	mov	ax,[bx+XFRLn-@]					;Output data-transfer length.
	out	dx,al
	inc	dx
	mov	al,ah
	out	dx,al
	inc	dx								;Point to command register.
	inc	dx
	mov	al,0A0h							;Issue "Packet" command.
	out	dx,al
	mov	cl,DRQ							;Await controller- and data-ready.
	call	TestTO1
DoIO3:
	jc	DoIO6							;Timeout!  Handle as a "hard error".
	xchg	ax,si						;Save BIOS timer address.
	mov	dx,[bx+IDEAd-@]					;Point to IDE data register.
	mov	cx,6							;Output all 12 "Packet" bytes.
	mov	si,Packet
	; rep	outsw						;																80386
	push ax
DoIO3L:	
	mov ax, [ds:si]
	out dx, ax
	inc si
	inc si
	loop DoIO3L
	pop ax
	;
	xchg	ax,si						;Reload BIOS timer address.
	mov	ah,STARTTO						;Allow 7 seconds for drive startup.
	cmp	[bx+DMAFl-@],bl					;UltraDMA input request?
	je	DoIO8							;No, do "PIO mode" transfer below.
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 0E5h
	out dx, al
	pop ax
	pop dx
	;
DoIO3lock:
	jmp DoIO3lock
	;
	mov	[bx+XFRLn-@],bx					;Reset transfer length (DMA does it).
	add	ah,[es:si]						;Set 4-second timeout in AH-reg.
	mov	[es:si+HDI_OFS],bl  			;Reset BIOS disk-interrupt flag.
	mov	dx,[bx+DMAAd-@]					;Point to DMA command register.
	in	al,dx							;Set DMA Start/Stop bit (starts DMA).
	or	al,1
	out	dx,al
DoIO4:
	inc	dx								;Point to DMA status register.
	inc	dx
	in	al,dx							;Read DMA controller status.
	dec	dx								;Point back to DMA command register.
	dec	dx
	and	al,DMI+DME						;DMA interrupt or DMA error?
	jnz	DoIO5							;Yes, halt DMA and check results.
	cmp	ah,[es:si]						;Has our DMA transfer timed out?
	jz	DoIO5
	cmp	[es:si+HDI_OFS],bl  			;Did BIOS get a disk interrupt?
	je	DoIO4							;No, loop back and check again.
	mov	al,DMI
DoIO5:
	xchg	ax,si						;Save ending DMA status.
	in	al,dx							;Reset DMA Start/Stop bit.
	and	al,0FEh
	out	dx,al
	xchg	ax,si						;Reload ending DMA status.
	cmp	al,DMI							;Did DMA end with only an interrupt?
	jne	DoIO13							;No?  Handle as a "hard error"!
	inc	dx								;Reread DMA controller status.
	inc	dx
	in	al,dx
	test	al,DME						;Any "late" DMA error after DMA end?
	jnz	DoIO13							;Yes?  Handle as a "hard error"!
	call	TestTO						;Await final controller-ready.
DoIO6:
	jc	DoIO13							;Timeout!  Handle as a "hard error"!
	jmp	short DoIO12					;Go check for other input errors.
	;
DoIO7:
	mov	ah,SEEKTO						;"PIO mode" -- get "seek" timeout.
DoIO8:
	xor	cl,cl							;Await controller-ready.
	call	TestTO2
	jc	DoIO13							;Timeout!  Handle as a "hard error".
	test	al,DRQ						;Did we also get a data-request?
	jz	DoIO12							;No, go check for any input errors.
	dec	dx								;Get controller-buffer byte count.
	dec	dx
	in	al,dx
	mov	ah,al
	dec	dx
	in	al,dx
	mov	dx,[bx+IDEAd-@]					;Point to IDE data register.
	mov	si,[bx+XFRLn-@]					;Get our data-transfer length.
	or	si,si							;Any remaining bytes to input?
	jz	DoIO10							;No, "eat" all residual data.
	cmp	si,ax							;Remaining bytes > buffer count?
	jbe	DoIO9							;No, input all remaining bytes.
	mov	si,ax							;Use buffer count as input count.
DoIO9:
	les	di,[bx+XFRAd-@]					;Get input data-transfer address.
	mov	cx,si							;Input all 16-bit data words.
	shr	cx,1
	;rep	insw
	push ax
DoIO9L:	
	in ax,dx
	mov [es:di],ax
	inc di
	inc di
	loop DoIO9L
	pop ax
	;
	add	[bx+XFRAd-@],si					;Increment data-transfer address.
	sub	[bx+XFRLn-@],si					;Decrement data-transfer length.
	sub	ax,si							;Any data left in controller buffer?
	jz	DoIO7							;No, await next controller-ready.
DoIO10:
	xchg	ax,cx						;"Eat" all residual input data.
	shr	cx,1							;(Should be NO residual data as we
DoIO11:
	in	ax,dx							;  always set an exact byte count.
	loop	DoIO11						;  This logic is only to be SAFE!).
	jmp	short DoIO7						;Go await next controller-ready.
DoIO12:
	mov	si,[bx+AudAP-@]					;Get drive media-change flag pointer.
	dec	si
	and	ax,00001h						;Did controller detect any errors?
	jz	DoIO15							;No, see if all data was transferred.
	sub	dx,byte 6						;Get controller's sense key value.
	in	al,dx
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	cmp	al,006h							;Is sense key "Unit Attention"?
	je	DoIO16							;Yes, check for prior media-change.
	mov	ah,0FFh							;Get 0FFh M.C. flag for "Not Ready".
	cmp	al,002h							;Is sense key "Drive Not Ready"?
	je	DoIO17							;Yes, go set our media-change flag.
DoIO13:
	mov	dx,[bx+IDEAd-@]					;Hard error!  Point to command reg.
	add	dx,byte 7
	mov	al,008h							;Issue ATAPI "soft reset" to drive.
	out	dx,al
	mov	al,11							;Get "hard error" return code.
DoIO14:
	dec	byte [bx+Try-@]					;Do we have more I-O retries left?
	jz	DoIO18							;No, set carry & return error code.
	jmp	DoIO1							;Try re-executing this I-O request.
DoIO15:
	cmp	[bx+XFRLn-@],bx					;Was all desired data input?
	jne	DoIO13							;No?  Handle as a hard error.
	mov	byte [si],001h					;Set "no media change" flag.
	clc									;Reset carry flag (no error).
	jmp	short DoIO19					;Go reload regs. and exit below.
DoIO16:
	mov	al,002h							;"Attention":  Get "Not Ready" code.
	cmp	[si],bl							;Is media-change flag already set?
	jle	DoIO14							;Yes, retry & see if it goes away!
DoIO17:
	xchg	ah,[si]						;Load & set our media-change flag.
	mov	byte [si+12],0FFh  				;Make last-session LBA invalid.
	dec	ah								;Is media-change flag already set?
	jnz	DoIO18							;Yes, set carry flag and exit.
	mov	al,15							;Return "Invalid Media Change".
DoIO18:
	stc									;Set carry flag (error!).
DoIO19:
	pop	es								;Reload ES- and SI-registers.
	pop	si
	mov	di,InBuf						;For audio, point to our buffer.
	ret									;Exit.
;
; Subroutine to convert "RedBook" MSF values to an LBA sector number.
;
ConvLBA:
	cmp	dx,byte 99						;Is "minute" value too large?
	ja	CnvLBAE							;Yes, return -1 error value.
	cmp	ah,60							;Is "second" value too large?
	ja	CnvLBAE							;Yes, return -1 error value.
	cmp	al,75							;Is "frame" value too large?
	ja	CnvLBAE							;Yes, return -1 error value.
	;
	mov  cx, ax							; Backup Seconds and Frames
	mov  ax, dx     					; Get minutes
	;
	; ax =   MM
	; cx = SSFF
	;
	mov  dx, 60
	mul  dx								; Multiply by 60	
	;
	; ax = (60*MM)
	; cx = SSFF
	;
	xor dx, dx
	mov dl, ch							; get seconds
	add ax, dx							; add seconds
	;
	; ax = ((60*MM) + SS)
	; cx = SSFF
	;
	mov dx, 75
	mul dx								; Multiply by 75
	;
	; ax = (((60*MM) + SS)*75)
	; cx = SSFF
	;
	xor ch, ch
	add ax, cx
	adc dx, byte 0						; add frames
	;
	; dx:ax = (((60*MM) + SS)*75) + FF
	; cx = 00FF
	;
	mov cl, byte 150
	sub ax, cx
	sbb dx, byte 0
	;
	; dx:ax = (((60*MM) + SS)*75) + FF - 150
	;
	;
	ret									;Exit.
CnvLBAE:
	or	ax,byte -1						;Too large!  Set -1 error value.
	or	dx,byte -1
	ret									;Exit.
;
; Subroutine to clear our ATAPI "packet" area.
;
ZPacket:
	mov	[bx+Packet+0-@],bx   			;Zero 1st 10 ATAPI packet bytes.
	mov	[bx+Packet+2-@],bx 				;(Last 2 are unused "pad" bytes).
	mov	[bx+Packet+4-@],bx
	mov	[bx+Packet+6-@],bx
	mov	[bx+Packet+8-@],bx
	ret			   						;Exit.
;
; Subroutine to validate the starting RedBook disk sector number.
;
ValSN:
	mov	ax,[es:si+RLSec+0] 				;Get starting sector number.
	mov	dx,[es:si+RLSec+2]
ValSN1:
	mov	cl,[es:si+RLAM]					;Get desired addressing mode.
	cmp	cl,001h							;HSG or RedBook addressing?
	ja	ValSNE							;No?  Return "sector not found".
	je	ValSN3							;RedBook -- get starting sector.
ValSN2:
	ret									;HSG -- exit (accept any DVD value).
	;
ValSN3:
	call	ConvLBA						;RedBook -- get starting sector.
	cmp dx, RMAXLBAmsb
	jb ValSN2
	ja ValSNE
	cmp	ax, RMAXLBAlsb					;					Is starting sector too big?
	jbe	ValSN2							;No, all is well -- go exit above.
ValSNE:
	pop	ax								;Error!  Discard our exit address.
	jmp	SectNF							;Post "sector not found" and exit.
;
; Subroutine to test for I-O timeouts.   At entry, the CL-reg. is
;   008h to test for a data-request, also.   At exit, the DX-reg.
;   points to the IDE primary-status register.   The AH-, SI- and
;   ES-regs. will be lost.
;
TestTO:
	xor	cl,cl							;Check for only controller-ready.
TestTO1:
	mov	ah,CMDTO						;Use 500-msec command timeout.
TestTO2:
	mov	es,bx							;Point to low-memory BIOS timer.
	mov	si,BIOSTMR
	add	ah,[es:si]						;Set timeout limit in AH-reg.
TestTO3:
	cmp	ah,[es:si]						;Has our I-O timed out?
	stc									;(If so, set carry flag).
	je	TestTOX							;Yes?  Exit with carry flag on.
	mov	dx,[bx+IDEAd-@]					;Read IDE primary status.
	add	dx,byte 7
	in	al,dx
	test	al,BSY						;Is our controller still busy?
	jnz	TestTO3							;Yes, loop back and test again.
	or	cl,cl							;Are we also awaiting I-O data?
	jz	TestTOX							;No, just exit.
	test	al,cl						;Is data-request (DRQ) also set?
	jz	TestTO3							;No, loop back and test again.
TestTOX:
	ret									;Exit -- carry indicates timeout.
;
; Detect Atapi Drives
;
DetAtapi:
	mov dx, [bx+IDEAd+0-@]				; Get Ide Base Address
	mov ah, [bx+IDEAd+2-@]				; Get Select
	;
	add dx, byte 7
	in al, dx							; Get Status register
	;
	dec dx
	in al, dx							; Get Drive Select Register
	;
	cmp ah, al							; Check if drive is selected
	jne DetAtapiX						; No just skip...
	;
	dec dx
	in al, dx							; Get Reg 5
	;
	dec dx
	in al, dx							; Get Reg 4
	;
	add dx, byte 3
	in al, dx							; Read Status again
DetAtapiX:
	ret
;
; Subroutine to ensure UltraDMA is stopped and then select our CD-ROM
;   drive.   For some older chipsets, if UltraDMA is running, reading
;   an IDE register causes the chipset to "HANG"!!
;
StopDMA:
	mov	dx,[bx+DMAAd-@]					;Get drive UltraDMA command address.
	test	dl,006h						;Is any UltraDMA controller present?
	jnz	StopDM1							;No, select "master" or "slave" unit.
	and	dl,0FEh							;Mask out "DMA disabled" flag.
	in	al,dx							;Ensure any previous DMA is stopped!
	and	al,0FEh
	out	dx,al
StopDM1:
	mov	dx,[bx+IDEAd-@]					;Point to IDE device-select register.
	add	dx,byte 6
	mov	al,[bx+IDESl-@]					;Select IDE "master" or "slave" unit.
	out	dx,al
	ret									;Exit.
;
; Device-Interrupt "Entry" Jump.   "EntryP" causes a jump to our init
;   routines on the first driver entry, after which "EntryP" causes a
;   jump to the Device Interrupt routine above.   To avoid trouble on
;   new CPUs with a big "code cache", this jump must appear AFTER any
;   instructions that are MODIFIED at run-time!
;
DevIntJ	jmp	[cs:EntryP]	;On first entry, initialize driver.
;
; Subroutine to "swap" the 4 bytes of a a 32-bit value.
;
SwapLBA:
	mov	ax,[di+8]						;Get audio-end or buffer LBA value (Swap).
	mov	dx,[di+10]
Swap32:
	xchg	al,ah						;"Swap" original low-order bytes.
	xchg	ax,dx
	xchg	al,ah						;"Swap" ending low-order bytes.
Swap32X:
	ret			;Exit.
BaseEnd	equ	$+BSTACK+4	;End of resident "basic" driver.
;
; DOS "Audio Seek" handler.   All DOS and IOCTL routines beyond this
;   point are DISMISSED by driver-init when the /AX switch is given.
;
ReqSeek:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 22h
	out dx, al
	pop ax
	pop dx
	;
	call	RdAST1						;Read current "audio" status.
	call	ZPacket						;Reset our ATAPI packet area.
	jc	RqSK1							;If status error, do DOS seek.
	mov	al,[di+1]						;Get "audio" status flag.
	cmp	al,011h							;Is drive in "play audio" mode?
	je	RqSK2							;Yes, validate seek address.
	cmp	al,012h							;Is drive in "pause" mode?
	je	RqSK2							;Yes, validate seek address.
RqSK1:
	jmp	DOSSeek							;Use DOS seek routine above.
RqSK2:
	call	ValSN						;Validate desired seek address.
	mov	di,[bx+AudAP-@]					;Point to audio-start address.
	cmp	dx,[di+6]						;Is address past "play" area?
	ja	RqSK1							;Yes, do DOS seek above.
	jb  RqSK2a
	cmp	ax,[di+4]						;Is address past "play" area?
	ja	RqSK1							;Yes, do DOS seek above.
RqSK2a:
	mov	[di+0],ax						;Update audio-start address.
	mov	[di+2],dx						;Update audio-start address.
	call	PlayAud						;Issue "Play Audio" command.
	jc	RqPLE							;If error, post code & exit.
	cmp	byte [di+1],011h  				;Were we playing audio before?
	je	RqPLX							;Yes, post "busy" status and exit.
	call	ZPacket						;Reset our ATAPI packet area.
	jmp	short ReqStop					;Go put drive back in "pause" mode.
;
; DOS "Play Audio" handler.
;
ReqPlay:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 24h
	out dx, al
	pop ax
	pop dx
	;
	cmp	word [es:si+RLSC+0],byte 0  	;Is sector count zero?
	jne	ReqPlayA
	cmp	word [es:si+RLSC+2],byte 0 		;Is sector count zero?
	je	Swap32X			  				;Yes, just exit above.
ReqPlayA:	
	mov	ax,[es:si+RLAddr+0]  			;Validate audio-start address.
	mov dx,[es:si+RLAddr+2]
	call	ValSN1
	mov	di,[bx+AudAP-@]					;Save drive's audio-start address.
	mov	[di+0],ax
	mov	[di+2],dx
	add	ax,[es:si+18]					;Calculate audio-end address.
	adc	dx,[es:si+20]
	cmp dx, RMAXLBAmsb
	jb ReqPL2
	ja ReqPL1							;If "end" WAY too big, use max.
	cmp	ax, RMAXLBAlsb					
	jbe	ReqPL2							;No, use "end" address as-is.
ReqPL1:
	mov	ax, RMAXLBAlsb					;Set "end" address to maximum.
	mov dx, RMAXLBAmsb
ReqPL2:
	mov	[di+4],ax						;Save drive's audio-end address.
	mov	[di+6],dx
	call	PlayAud						;Issue "Play Audio" command.
RqPLE:
	jc	ReqErr							;Error!  Post return code & exit.
RqPLX:
	jmp	RdAST4							;Go post "busy" status and exit.
;
; DOS "Stop Audio" handler.
;
ReqStop:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 25h
	out dx, al
	pop ax
	pop dx
	;
	mov	byte [bx+Packet-@],04Bh  ;Set "Pause/Resume" cmd.
	jmp	DoIOCmd		;Go pause "audio", then exit.
;
; DOS "Resume Audio" handler.
;
ReqRsum:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 28h
	out dx, al
	pop ax
	pop dx
	;
	inc	byte [bx+PktLn+1-@]  ;Set "Resume" flag for above.
	call	ReqStop		;Issue "Pause/Resume" command.
	jmp	short RqPLE	;Go exit through "ReqPlay" above.
;
; IOCTL Input "Current Head Location" handler.
;
ReqCHL:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 31h
	out dx, al
	pop ax
	pop dx
	;
	mov	word [bx+Packet+0-@],00042h   ;Set command bytes.
	mov	word [bx+Packet+2-@],00140h   ;Set command bytes.
	mov	al,16		;Set input byte count of 16.
	call	RdAST3		;Issue "Read Subchannel" request.
	jc	RqPLE		;If error, post return code & exit.
	mov	[es:si+1],bl	;Return "HSG" addressing mode.
	call	SwapLBA		;Return "swapped" head location.
	mov	[es:si+2],ax
	mov	[es:si+4],dx
	jmp	short RqATIX	;Go post "busy" status and exit.
;
; IOCTL Input "Volume Size" handler.
;
ReqVS:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 38h
	out dx, al
	pop ax
	pop dx
	;
	mov	byte [bx+Packet-@],025h  		;Set "Read Capacity" code.
	mov	al,008h							;Get 8 byte data-transfer length.
	call	DoBufIn						;Issue "Read Capacity" command.
	jc	RqPLE							;If error, post return code & exit.
	mov	ax,[di+0]						;Set "swapped" size in IOCTL packet.
	mov	dx,[di+2]
	call	Swap32
	mov	[es:si+1],ax
	mov	[es:si+3],dx
	jmp	short RqATIX					;Go post "busy" status and exit.
;
; IOCTL Input "Audio Disk Info" handler.
;
ReqADI:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 39h
	out dx, al
	pop ax
	pop dx
	;
	mov	al,0AAh							;Specify "lead-out" session number.
	call	ReadTOC						;Read disk table-of-contents (TOC).
	jc	RqASIE							;If error, post return code & exit.
	mov	[es:si+3],ax					;Set "lead out" LBA addr. in IOCTL.
	mov	[es:si+5],dx					;Set "lead out" LBA addr. in IOCTL.
	mov	ax,[di+2]						;Set first & last tracks in IOCTL.
	mov	[es:si+1],ax
	jmp	short RqATIX					;Go post "busy" status and exit.
;
; IOCTL Input "Audio Track Info" handler.
;
ReqATI:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 3Ah
	out dx, al
	pop ax
	pop dx
	;
	mov	al,[es:si+1]					;Specify desired session (track) no.
	call	ReadTOC						;Read disk table-of-contents (TOC).
	jc	RqASIE							;If error, post return code & exit.
	mov	[es:si+2],ax					;Set track LBA address in IOCTL.
	mov	[es:si+4],dx
	mov	al,[di+5]
	shl	al,1
	shl	al,1
	shl	al,1
	shl	al,1
	mov	[es:si+6],al
RqATIX	jmp	ReadAST						;Go post "busy" status and exit.
;
; IOCTL Input "Audio Q-Channel Info" handler.
;
ReqAQI:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 3Bh
	out dx, al
	pop ax
	pop dx
	;
	mov	ax,04010h						;Set "data in", use 16-byte count.
	call	RdAST2						;Read current "audio" status.
	jc	RqASIE							;If error, post return code & exit.
	;
	mov	ax,[di+5]						;Set ctrl/track/index in IOCTL.
	mov	dx,[di+7]
	mov	[es:si+1],ax
	mov	[es:si+3],dx
	;
	mov	ax,[di+13]						;Set time-on-track in IOCTL.
	mov	dx,[di+15]
	mov	[es:si+4],ax
	mov	[es:si+6],dx
	;
	mov	ax,[di+4]						;Get current audio "end" address.
	mov dx,[di+11]
	;shl	edx,8						;  order time-on-track in IOCTL.
	mov dh,dl
	mov dl,ah
	mov ah,al
	xor al,al
	mov	[es:si+7],ax					;Set audio "end" address in IOCTL.
	mov	[es:si+9],dx
	ret									;Exit.
;
; IOCTL Input "Audio Status Info" handler.
;
ReqASI:
	;
	push dx
	push ax
	mov dx, 00080h
	mov al, 3Fh
	out dx, al
	pop ax
	pop dx
	;
	mov	ax,04010h						;Set "data in", use 16-byte count.
	call	RdAST2						;Read current "audio" status.
RqASIE:
	jc	ReqErr							;If error, post return code & exit.
	mov	[es:si+1],bx					;Reset audio "paused" flag.
	xor	dx,dx		  					;Reset ending audio address.
	xor	ax,ax							;Reset starting audio address.
	mov	[es:si+3],ax					
	mov	[es:si+5],dx					
	mov	[es:si+7],ax					
	mov	[es:si+9],dx					
	cmp	byte [di+1],011h  				;Is drive now "playing" audio?
	jne	RqASI1		  					;No, check for audio "pause".
	mov	di,[bx+AudAP-@]	  				;Point to drive's audio data.
	mov	ax,[di+0]	  					;Get current audio "start" addr.
	mov	dx,[di+2]
	jmp	short RqASI2	  				;Go get current audio "end" addr.
RqASI1	cmp	byte [di+1],012h  			;Is drive now in audio "pause"?
	jne	RqASI3		  					;No, return "null" addresses.
	inc	byte [es:si+1]					;Set audio "paused" flag.
	call	SwapLBA						;Convert time-on-disk to LBA addr.
	call	ConvLBA
	mov	di,[bx+AudAP-@]					;Point to drive's audio data.
RqASI2:
	mov	[es:si+3],ax					;Set audio "start" addr. in IOCTL.
	mov	[es:si+5],dx
	mov	ax,[di+4]						;Get current audio "end" address.
	mov	dx,[di+6]
	mov	[es:si+7],ax					;Set audio "end" address in IOCTL.
	mov	[es:si+9],dx
RqASI3:
	ret			;Exit.
;
; Subroutine to issue a "Play Audio" command.   At entry, the
;   DI-reg. points to the audio-start address for this drive.
;
PlayAud:
	mov	ax,[di+0]						;Set "packet" audio-start address.
	mov	dx,[di+2]
	call	ConvMSF
	mov	[bx+PktLBA+1-@],ax
	mov	[bx+PktLBA+3-@],dx
	mov	ax,[di+4]						;Set "packet" audio-end address.
	mov	dx,[di+6]
	call	ConvMSF
	mov	[bx+PktLH+0-@],ax
	mov	[bx+PktLH+2-@],dx
	mov	byte [bx+Packet-@],047h			;Set "Play Audio" command.
	jmp	DoIOCmd							;Start drive playing audio & exit.
;
; Subroutine to read the current "audio" status and disk address.
;
ReadAST:
	call	ZPacket		  				;Status only -- reset ATAPI packet.
RdAST1:
	mov	ax,00004h	  					;Clear "data in", use 4-byte count.
RdAST2:
	mov	word [bx+Packet+0-@],00242h		;Set command bytes.
	mov	word [bx+Packet+2-@],00100h
	mov	[bx+PktLBA-@],ah 				;Set "data in" flag (RdAST2 only).
RdAST3:
	call	DoBufIO		  				;Issue "Read Subchannel" command.
	jc	RdASTX		  					;If error, exit immediately.
	cmp	byte [di+1],011h  				;Is a "play audio" in progress?
	jne	RdTOC1		  					;No, clear carry flag and exit.
RdAST4:
	push	si		  					;Save SI- and ES-regs.
	push	es
	les	si,[bx+RqPkt-@]	  				;Reload DOS request-packet addr.
	or	word [es:si+RPStat],RPBUSY  	;Set "busy" status bit.
	pop	es		  						;Reload ES- and SI-regs.
	pop	si
RdASTX:
	ret			  						;Exit.
;
; Subroutine to read disk "Table of Contents" (TOC) values.
;
ReadTOC:
	mov	word [bx+Packet-@],00243h		;Set TOC and MSF bytes.
	call	DoTOCSN						;Issue "Read Table of Contents" cmd.
	jc	RdTOCX							;If error, exit immediately.
	call	SwapLBA						;Return "swapped" starting address.
RdTOC1:
	clc									;Clear carry flag (no error).
RdTOCX:
	ret									;Exit.
;
;cpu 386
;
; Subroutine to convert an LBA sector number to "RedBook" MSF format.
;
ConvMSF:
	; dx:ax = LBA Sector number
	add ax, 150							; Add Offset of 150
	adc dx, 0
	;
	; dx:ax = number of frames
	;
	;
	mov cx, 75
	div cx								; devide by 75 frames/second
	;
	; dx = remainder frames
	; ax = number of seconds
	;
	mov cl, 60
	div cl								; devide by 60 seconds/minute
	;
	; dx = remainder frames
	; ah = remainder seconds
	; al = number of minutes
	;
	; ---------------------------------------------------
	;
	;add	eax,150							;Add in offset.
	;push	eax							;Get address in DX:AX-regs.
	;pop	ax
	;pop	dx
	;
	; dx:ax = number of frames
	;
	;mov	cx,75							;Divide by 75 "frames"/second.
	;div	cx
	;
	; dx = remainder frames
	; ax = number of seconds
	;
	;shl	eax,16							;Set "frames" remainder in upper EAX.
	;mov	al,dl
	;
	; eax = ssss00ff
	;
	;ror	eax,16
	;
	; eax = 00ffssss
	;
	;mov	cl,60							;Divide quotient by 60 seconds/min.
	;div	cl
	;
	; eax = 00ffssmm
	;
	;
	ret									;Exit -- DX:AX-reg. contains 00MMSSFF value.
	db	0								;(Unused alignment "filler").
CStack	equ	$+STACK		;Caller's saved stack pointer.
ResEnd	equ	CStack+4	;End of resident driver.
;
;cpu	8086
;
; Driver Initialization Routine.   Note that this routine runs on
;   the DOS stack.   All logic past this point becomes our local-
;   stack or is DISMISSED, after initialization is completed.
;
I_Init:
	pushf								;Entry -- save CPU flags.
	push	ds							;Save CPU segment registers.
	push	es
	push	ax							;Save needed 16-bit CPU registers.
	push	bx
	push	dx
	;
	push	cs							;Set our DS-register.
	pop	ds
	xor	bx,bx							;Zero BX-reg. for relative commands.
	cld									;Ensure FORWARD "string" commands!
	mov	ax,DevInt						;Prevent entry to this logic again!
	mov	[bx+EntryP-@],ax
	les	si,[bx+RqPkt-@]					;Point to DOS request packet.
	cmp	byte [es:si+RPOp],0 			;Is this an "Init" packet?
	je	I_386							;Yes, lets get installed
	jmp	I_BadP							;Go post errors and exit quick!
	;
I_386:
	push ax
	push cx
	push dx
	push bx
	push sp
	push bp
	push si
	push di
	;
	mov	dx,XCMsg						;Display driver "title" message.
	call	I_Dsply
	;
	les	si,[bx+RqPkt-@]					;Reload DOS request-packet pointer.
	les	si,[es:si+RPCL]					;Point to command line that loaded us.
I_NxtC:
	mov	al,[es:si]						;Get next command-line byte.
	inc	si								;Bump pointer past this byte.
	cmp	al,0							;Is byte the command-line terminator?
	je	I_TermJ							;Yes, go test for UltraDMA controller.
	cmp	al,LF							;Is byte an ASCII line-feed?
	je	I_TermJ							;Yes, go test for UltraDMA controller.
	cmp	al,CR							;Is byte an ASCII carriage-return?
I_TermJ:
	je	I_Term							;Yes, go test for UltraDMA controller.
	;
	; Check start of option
	;
	cmp	al,'-'							;Is byte a dash?
	je	I_NxtS							;Yes, see what next "switch" byte is.
	cmp	al,'/'							;Is byte a slash?
	jne	I_NxtC							;No, check next command-line byte.
	;
	; Check UX or UF option
	;
I_NxtS:
	mov	ax,[es:si]						;Get next 2 command-line bytes.
	and	al,0DFh							;Mask out 1st lower-case bit (020h).
	cmp	al,'U'							;Is switch byte a "U" or "u"?
	jne	I_ChkA							;No, go see if byte is "A" or "a".
	inc	si								;Bump pointer past "UltraDMA" switch.
	and	ah,0DFh							;Mask out 2nd lower-case bit (020h).
	mov	cl,0F0h							;Get "UX" switch value.
	cmp	ah,'X'							;Is following byte an "X" or "x"?
	je	I_SetUX							;Yes, update "UFX" switch.
	mov	cl,0F2h							;Get "UF" switch value.
	cmp	ah,'F'							;Is following byte an "F" or "f"?
	jne	I_NxtC							;No, see if byte is a terminator.
I_SetUX:
	mov	[bx+UFXSw-@],cl					;Update "UFX" switch for below.
	inc	si								;Bump pointer past "F" or "X".
	;
	; Check AX option
	;
I_ChkA:
	cmp	al,'A'							;Is switch byte an "A" or "a"?
	jne	I_ChkL							;No, go see if byte is "L" or "l".
	inc	si								;Bump pointer past "Audio" switch.
	and	ah,0DFh							;Mask out 2nd lower-case bit (020h).
	cmp	ah,'X'							;Is following byte an "X" or "x"?
	jne	I_NxtC							;No, see if byte is a terminator.
	;
	mov	ax,BaseEnd						;Reduce size of this driver.
	mov	[bx+VDSLn-@],ax
	dec	ax								;Adjust all "CStack" pointers.
	dec	ax
	mov	[@CStak2],ax
	mov [@CStak4],ax
	dec	ax
	dec	ax
	mov	[@CStak1],ax
	mov	[@CStak3],ax
	mov	[@Stack],ax						;Adjust driver stack pointers.
	mov	ax,(BaseEnd-BSTACK-4)
	mov	[ClrStak],ax
	mov	ax,UnSupp						;Disable all unwanted dispatches.
	mov	[@RqPlay],ax
	mov	[@RqStop],ax
	mov	[@RqRsum],ax
	mov	[@RqCHL],ax
	mov	[@RqADI],ax
	mov	[@RqATI],ax
	mov	[@RqAQI],ax
	mov	[@RqASI],ax
	mov	ax,DOSSeek						;Do only LBA-address DOS seeks.
	mov	[@RqPref],ax
	mov	[@RqSeek],ax
	mov	al,004h							; Have "Device Status" declare
	mov	[@Status],al					; we handle DATA reads only,
	;db	0B0h							; and have it NOT update the
	;ret								; IOCTL "busy" flag & return
	mov al, 0c3h						; Ret instruction
	mov	[@RqDSX],al						; Replace Jump to "ReadAST" with Ret instruction
	inc	si								;Bump pointer past "X" or "x".
	;
	; Check L option, 640K DMA Limit
	;
I_ChkL:
	cmp	al,'L'							;Is switch byte an "L" or "l"?
	jne	I_ChkM							;No, go see if byte is "M" or "m".
	mov	byte [@DMALmt],009h  			;Set 640K "DMA limit" above.
	inc	si								;Bump pointer past "limit" switch.
	;
	; Check M option, Max Dma mode 
I_ChkM:
	cmp	al,'M'							;Is this byte an "M" or "m"?
	jne	I_ChkC							;No, go see if byte is "C" or "c".
	inc	si								;Bump pointer past "mode" switch.
	cmp	ah,'6'							;Is following byte above a six?
	ja	I_NxtCJ							;Yes, see if byte is a terminator.
	sub	ah,'0'							;Is following byte below a zero?
	jb	I_NxtCJ							;Yes, see if byte is a terminator.
	mov	[bx+MaxUM-@],ah					;Set maximum UltraDMA "mode" above.
	inc	si								;Bump pointer past "mode" value.
	;
	; Check C option, Chip Ordinal
	;
I_ChkC:
	cmp	al,'C'							;Is this byte an "C" or "c"?
	jne	I_ChkP							;No, go see if byte is "P" or "p".
	inc	si								;Bump pointer past "mode" switch.
	cmp	ah,'9'							;Is following byte above a nine?
	ja	I_NxtCJ							;Yes, see if byte is a terminator.
	sub	ah,'0'							;Is following byte below a zero?
	jb	I_NxtCJ							;Yes, see if byte is a terminator.
	mov	[bx+ChipN-@],ah					;Set Chip ordinal.
	inc	si								;Bump pointer past "mode" value.
	;
	; Check P(M/S) or S(M/S) option, Primary/Secondairy Channel, Master/Slave Device
	;
I_ChkP:
	cmp	al,'P'							;Is switch byte a "P" or "p"?
	jne	I_ChkS							;No, go see if byte is "S" or "s".
	mov	di,ScanP						;Point to primary-channel values.
	jmp	short I_ChkMS					;Go check for "M" or "S" next.
I_ChkS:
	cmp	al,'S'							;Is switch byte an "S" or "s"?
	jne	I_ChkD							;No, check for "D" or "d".
	mov	di,ScanS						;Point to secondary-channel values.
I_ChkMS:
	inc	si								;Bump pointer past "channel" switch.
	and	ah,0DFh							;Mask out 2nd lower-case bit (020h).
	cmp	ah,'M'							;Is following byte an "M" or "m"?
	je	I_SetHW							;Yes, set desired hardware values.
	cmp	ah,'S'							;Is following byte an "S" or "s"?
	jne	I_NxtCJ							;No, see if byte is a terminator.
	add	di,byte 4						;Point to channel "slave" values.
I_SetHW:
	inc	si								;Bump pointer past master/slave byte.
	or	word [bx+ScanX-@],byte -1  		;Set "no scan" flag.
	xor ax, ax
	xor dx, dx
	xchg ax, [di+0]
	xchg dx, [di+2]
	or ax, ax
	jnz I_SetHW2
	or dx, dx
	jz I_NxtCJ
I_SetHW2:	
	mov	di,[bx+UTblP-@]					;Get current unit-table pointer.
	cmp	di,UTblEnd						;Have we already set up all units?
	je	I_NxtCJ							;Yes, IGNORE any more switches!
	mov	[di+2],ax						;Set parameters in unit table.
	mov	[di+4],dx						;Set parameters in unit table.
	add	word [bx+UTblP-@],byte 20 		;Bump to next unit table.
I_NxtCJ:
	jmp	I_NxtC							;Go check next command byte.

index   	db	00h	
LastBusNo	db	0
class		db	0
subclass	db	0
	;
	; Check Driver Name
	;
I_ChkD:
	cmp	al,'D'							;Is switch byte a "D" or "d"?
	jne	I_NxtCJ							;No, see if byte is a terminator.
	inc	si								;Bump pointer past "device" switch.
	cmp	ah,':'							;Is following byte a colon?
	jne	I_NxtCJ							;No, see if byte is a terminator.
	inc	si								;Bump pointer past colon.
	mov	di,DvrName						;Blank out device name.
	mov	ax,"  "
	mov	[di+0],ax
	mov	[di+2],ax
	mov	[di+4],ax
	mov	[di+6],ax
I_NameB:
	mov	al,[es:si]						;Get next device-name byte.
	cmp	al,TAB							;Is byte a "tab"?
	je	I_NxtCJ							;Yes, handle above, "name" has ended!
	cmp	al,' '							;Is byte a space?
	je	I_NxtCJ							;Yes, handle above, "name" has ended!
	cmp	al,'/'							;Is byte a slash?
	je	I_NxtCJ							;Yes, handle above, "name" has ended!
	cmp	al,0							;Is byte the command-line terminator?
	je	I_Term							;Yes, go test for UltraDMA controller.
	cmp	al,LF							;Is byte an ASCII line-feed?
	je	I_Term							;Yes, go test for UltraDMA controller.
	cmp	al,CR							;Is byte an ASCII carriage-return?
	je	I_Term							;Yes, go test for UltraDMA controller.
	cmp	al,'a'							;Ensure letters are upper-case.
	jc	I_Name2
	cmp	al,'z'
	ja	I_Name2
	and	al,0DFh
I_Name2:
	cmp	al,'!'							;Is this byte an exclamation point?
	jz	I_Name3							;Yes, store it in device name.
	cmp	al,'#'							;Is byte below a pound-sign?
	jb	I_Name4							;Yes, Invalid!  Blank first byte.
	cmp	al,')'							;Is byte a right-parenthesis or less?
	jbe	I_Name3							;Yes, store it in device name.
	cmp	al,'-'							;Is byte a dash?
	jz	I_Name3							;Yes, store it in device name.
	cmp	al,'0'							;Is byte below a zero?
	jb	I_Name4							;Yes, invalid!  Blank first byte.
	cmp	al,'9'							;Is byte a nine or less?
	jbe	I_Name3							;Yes, store it in device name.
	cmp	al,'@'							;Is byte below an "at sign"?
	jb	I_Name4							;Yes, invalid!  Blank first byte.
	cmp	al,'Z'							;Is byte a "Z" or less?
	jbe	I_Name3							;Yes, store it in device name.
	cmp	al,'^'							;Is byte below a carat?
	jb	I_Name4							;Yes, invalid!  Blank first byte.
	cmp	al,'~'							;Is byte above a tilde?
	ja	I_Name4							;Yes, invalid!  Blank first byte.
	cmp	al,'|'							;Is byte an "or" symbol?
	je	I_Name4							;Yes, invalid!  Blank first byte.
I_Name3:
	mov	[di],al							;Store next byte in device name.
	inc	si								;Bump command-line pointer.
	inc	di								;Bump device-name pointer.
	cmp	di,DvrName+8					;Have we stored 8 device-name bytes?
	jb	I_NameB							;No, go get next byte.
	jmp	short I_Name5					;Go get next byte & check terminator.
I_Name4:
	mov	al,' '							;Invalid!  Blank first "name" byte,
	mov	byte [bx+DvrName-@],' '			;Invalid!  Blank first byte.
I_Name5:
	jmp	I_NxtC							;Go get next command byte.
	;
I_Term:
	xor	bx,bx							;Zero BX-reg. for relative commands.
	cmp	byte [bx+DvrName-@],' '			;Is driver "name" valid?
	jne	I_SetNm							;Yes, display driver name.
	mov	word [bx+DvrName+0-@],"XG"  	;Set our default "name".
	mov	word [bx+DvrName+2-@],"CD"  	;Set our default "name".
	mov	word [bx+DvrName+4-@],"RO"
	mov	word [bx+DvrName+6-@],"M "
I_SetNm:
	mov	si,DvrMsg1+8					;Set driver "name" in message below.
	mov	ax,[bx+DvrName+0-@]
	mov	[si-8],ax
	mov	ax,[bx+DvrName+2-@]
	mov	[si-6],ax
	mov	ax,[bx+DvrName+4-@]
	mov	[si-4],ax
	mov	ax,[bx+DvrName+6-@]
	mov	[si-2],ax
I_ScanN:
	mov	word [si],'"$'					;Set "name" terminators in msg.
	dec	si								;Decrement driver "name" pointer.
	cmp	byte [si],' '					;Is this "name" byte a space?
	je	I_ScanN							;Yes, keep scanning for a non-space.
	mov	dx,DvrMsg						;Display our driver "name".
	call	I_Dsply
	cmp	byte [bx+UFXSw-@],0F2h			;Did user enable "fast DMA"?
	je	I_VDSCh							;Yes, see if we need a VDS "lock".
	;
	;db	0B8h							;Disable 2-element DMA command lists.
	;jmp	$+RqRL4-@NoFast
	;
	mov al, 0EBh						; create jmp instruction B8 EB 24
	mov ah, (RqRL4-@NoFast-2)
	mov	[@NoFast],ax
I_VDSCh:
	xor	ax,ax							;Zero EAX-reg. for 20-bit addressing.
	mov	es,ax							;Point ES-reg. to low memory.
	mov	ax,cs							;Set our code segment in VDS block.
	mov	[bx+VDSSg-@],ax
    mov dx,ax
	mov cl,4
	shl	ax,cl							;Set 20-bit driver virtual address.
	mov cl,12
	shr dx,cl
	mov	[bx+IOAdr+0-@],ax
	mov	[bx+IOAdr+2-@],dx
	add	[bx+PRDAd+0-@],ax 			  	;Set relocated 32-bit PRD address.
	adc	[bx+PRDAd+2-@],dx
	cmp	byte [bx+UFXSw-@],0F0h  		;Did user disable UltraDMA?
	je	I_LinkX		   					;Yes, go try "linking" with XDMA.
	cmp	byte [@DMALmt],-1  				;Is UltraDMA limited to < 640K?
	je	I_LinkX		   					;No, go try "linking" with XDMA.
	mov	dx,LEMsg	   					;Point to "/L Invalid" message.
	cmp	word [bx+IOAdr+2-@],byte 009h	;Are we loaded high?
	ja	I_InitE	   						;Yes?  Display message and exit!
I_LinkX:	
	xor	ax,ax		   					;Point ES:DI-regs. to low memory.
	mov	es,ax
	mov	di,ax
	mov	es,[es:di+04Eh]					;Get Int 13h vector segment.
	cmp	word [es:di+10],"XD"			;Is an XDMA driver present?
	jne I_OurUC							;No, test for UltraDMA ctlr.
	cmp	word [es:di+12],"MA"			;Is an XDMA driver present?
	jne	I_OurUC							;No, test for UltraDMA ctlr.
	cmp	word [es:di+14],"1$"			;Is it a V3.1+ overlap XDMA?
	jne	I_OurUC							;No, test for UltraDMA ctlr.
	mov	ax,[es:di+XDDMAAD]				;Get XDMA primary DMA addr.
	and	al,0F0h
	cmp	ax,[bx+PrDMA-@]					;Did XDMA find our same controller?
	jne	I_OurUC							;No??  Go see if WE found anything!
	mov	[bx+XDSeg-@],es					;Save XDMA driver segment address.
	mov	[bx+SyncX-@],bl					;Reset "No synchronization" flag.
I_Sync1:
	cli									;Disable CPU interrupts.
	mov	al,[es:XDFLAGS]					;Get XDMA "busy" and "overlap" flags.
	test	al,078h						;Any current IDE channel activity?
	jz	I_Sync2							;No, "grab" both IDE channels now!
	sti									;Re-enable CPU interrupts.
	push	ax							;"Delay" for 3 CPU cycles, so XDMA's
	pop	ax								;  overlap timer logic can be called.
	test	al,060h						;Is either IDE channel "busy"?
	jz	I_Sync1							;No, must be "overlap" -- await end.
	mov	dx,SyEMsg						;Sync ERROR!  Very BAAAD NEWS!
	jmp	I_InitE							;Go display error message and exit!
I_Sync2:
	mov	al,060h							;Set both XDMA channel "busy" flags.
	or	[es:XDFLAGS],al					;(We may need to check both below!).
	sti									;Re-enable CPU interrupts.
	mov	dx,ComMsg						;Display a comma after driver "name".
	call	I_Dsply
	mov	dx,SyMsg						;Display "Synchronizing" message.
	call	I_Dsply
I_OurUC:
	mov	dx,CRMsg						;Display ending CR/LF message.
	call	I_Dsply
I_Spcfy:
	mov	ax,UnitTbl						;Reset our unit-table pointer.
	mov	[bx+UTblP-@],ax
I_ScanU:
	mov	ax,[bx+PrDMA-@]					;Set current UltraDMA command addr.
	mov	[bx+DMAAd-@],ax
	mov	si,[bx+UTblP-@]					;Get current unit-table pointer.
	mov	di,[bx+ScanX-@]					;Get current parameters index.
	cmp	di,byte -1						;Are we "scanning" for drives?
	je	I_GetPV							;No, get unit-table parameters.
	cmp	di,ScanE						;Any more IDE units to check?
	je	I_ChkCD							;No, check for any drives to use.
	lea	si,[di-2]						;Point to IDE unit parameters.
	add	di,byte 4						;Update parameter-table index.
	mov	[bx+ScanX-@],di
I_GetPV:
	mov	ax,[si+2]						;Get unit's IDE address, etc.
	mov	dx,[si+4]
	cmp	ax,byte -1						;Not scanning & unit table "empty"?
I_ChkCD:
	je	I_AnyCD							;Yes, check for any drives to use.
	mov	[bx+IDEAd+0-@],ax  				;Set this unit's parameters.
	mov	[bx+IDEAd+2-@],dx
	call	I_ValDV						;Validate device as an ATAPI CD-ROM.
	jnc	I_AnySy							;If no error, we can USE this drive!
	cmp	word [bx+ScanX-@],byte -1  		;"Scanning" for drives?
	jne	I_ScanU							;Yes, ignore error & test next unit.
I_AnySy:
	cmp	[bx+SyncX-@],bl					;Synchronizing with XDMA?
	je	I_NoDMA							;Yes, see if user disabled all DMA.
	mov	[bx+SyncF-@],bl					;Disable run-time "sync" flags.
I_NoDMA:
	cmp	byte [bx+UFXSw-@],0F0h			;Was the /UX switch given?
	jne	I_DspDr							;No, display all drive data.
	or	byte [bx+DMAAd-@],001h			;Post drive "DMA disabled".
I_DspDr:
	mov	dx,UnitMsg						;Display "Unit n:" message.
	call	I_Dsply
	mov	dx,PriMsg						;Point to "Primary" message.
	cmp	word [bx+IDEAd-@],CDATA			;Primary-channel drive?
	je	I_PSMsg							;Yes, display "Primary" message.
	mov	dx,SecMsg						;Point to "Secondary" message.
	or	byte [bx+DMAAd-@],008h  		;Use secondary DMA channel.
I_PSMsg:
	call	I_Dsply						;Display our CD-ROM's IDE channel.
	mov	dx,MstMsg						;Point to "Master" message.
	cmp	byte [bx+IDESl-@],SSELECT  		;Is our drive a "slave"?
	jnz	I_MSMsg							;No, display "Master".
	mov	dx,SlvMsg						;Point to "Slave" message.
I_MSMsg:
	call	I_Dsply						;Display "Master" or "Slave".
	cmp	[bx+IEMsg-@],bx					;Did any validation ERROR occur?
	jz	I_ScnVN							;No, scan "vendor name" for data.
	call	I_EndSy						;End XDMA "synchronization" if needed.
	mov	dx,[bx+IEMsg-@]					;Get init error-message pointer.
	jmp	short I_InitE					;Go display error message and exit.
I_ScnVN:
	mov	di,XCMsg+40						;Point to CD-ROM "vendor name" end.
I_ScnV1:
	mov	byte [di],'$'					;Set message terminator after name.
	dec	di								;Point to previous name byte.
	cmp	byte [di],' '					;Is this byte a space?
	je	I_ScnV1							;Yes, keep scanning for a non-space.
	cmp	byte [bx+XCMsg-@],'$'  			;Is CD-ROM "name" all spaces?
	je	I_ModeM							;Yes, no need to display it!
	mov	dx,ComMsg						;Display comma/space before name.
	call	I_Dsply
	mov	dx,XCMsg						;Display manufacturer CD-ROM "name".
	call	I_Dsply
I_ModeM:
	mov	dx,PIOMsg						;Point to "PIO mode" message.
	test	byte [bx+DMAAd-@],007h  	;Will drive be using UltraDMA?
	jnz	I_MsEnd							;No, display "PIO mode" message.
	mov	dx,UDMsg						;Point to "ATA-xxx" message.
I_MsEnd:
	call	I_Dsply						;Display drive's operating "mode".
	mov	dx,CRMsg						;Display terminating CR/LF/$.
	call	I_Dsply
	mov	si,[bx+UTblP-@]	   				;Update all unit-table parameters.
	mov	ax,[bx+DMAAd+0-@]   			;(If "scanning", table parameters
	mov	dx,[bx+DMAAd+2-@]
	mov	[si+0],ax	   					;  are NOT set from our switches!).
	mov	[si+2],dx
	mov	ax,[bx+IDESl-@]
	mov	[si+4],ax
	add	si,byte 20	   					;Update unit-table pointer.
	mov	[bx+UTblP-@],si
	inc	byte [bx+Units-@]  				;Bump number of active units.
	inc	byte [UMsgNo]	   				;Bump display unit number.
	cmp	si,UTblEnd	   					;Can we install another drive?
	jb	I_ScanU	   						;Yes, loop back & check for more.
I_AnyCD:
	call	I_EndSy						;End XDMA "synchronization" if needed.
	cmp	[bx+Units-@],bl					;Do we have any CD-ROM drives to use?
	ja	I_ClrSt							;Yes, success -- go zero local-stack.
	mov	dx,NDMsg						;NOT GOOD!  Point to "No CD-ROM" msg.
I_InitE:
	call	I_Dsply						;Display desired error message.
	pop di
	pop si
	pop bp
	pop sp
	pop bx
	pop dx
	pop cx
	pop ax
	;
	mov	dx,Suffix						;Display error message suffix.
I_Quit:
	call	I_Dsply
I_BadP:
	xor	ax,ax							;Get "null" length & error flags.
	mov	dx,RPDON+RPERR
	jmp	short I_Exit					;Go set "init" packet values & exit.
I_ClrSt:
	push	cs							;Success!  "Zero" our local-stack.
	pop	es								;(Helps debug if unused stack = 0).
	mov	cx,STACK+4
	mov	di,[ClrStak]
	xor	ax,ax
	rep	stosb
	pop di
	pop si
	pop bp
	pop sp
	pop bx
	pop dx
	pop cx
	pop ax
	;
	xor	ax,ax							;Load & reset driver length.
	xchg	ax,[VDSLn]
	mov	dx,RPDON						;Get initialization "success" code.
I_Exit:
	lds	bx,[RqPkt]						;Set result values in "init" packet.
	mov	[bx+RPSize],ax
	mov	[bx+RPSize+2],cs
	mov	[bx+RPStat],dx
	xor	ax,ax							;Reset returned "units found".
	mov	[bx+RPUnit],al
	pop	dx								;Reload 16-bit CPU registers we used.
	pop	bx
	pop	ax
	pop	es								;Reload CPU segment registers.
	pop	ds
	popf								;Reload CPU flags and exit.
	retf
;
; Subroutine to "validate" an IDE unit as an ATAPI CD-ROM drive.
;
I_ValDV:
	mov	[bx+IEMsg-@],bx					;Reset our error-message pointer.
	call	StopDMA						;Stop previous DMA & select drive.
	;call 	DetAtapi
	call	TestTO						;Await controller-ready.
	mov	cx,TOMsg						;Get "select timeout" message ptr.
	jc	I_Val7							;If timeout, go post pointer & exit.
	mov	al,0A1h							;Issue "Identify Packet Device" cmd.
	out	dx,al
	call	TestTO						;Await controller-ready.
	mov	cx,IDMsg						;Get "Identify" message pointer.
	jc	I_Val7							;If timeout, go post pointer & exit.
	test	al,DRQ						;Did we also get a data-request?
	jz	I_Val6							;No, post "not ATAPI" ptr. & exit.
	sub	dx,byte 7						;Point back to IDE data register.
	in	ax,dx							;Read I.D. word 0, main device flags.
	and	ax,0DF03h						;Mask off flags for an ATAPI CD-ROM.
	xchg	ax,si						;Save main device flags in SI-reg.
	mov	cx,26							;Skip I.D. words 1-26 (unimportant).
I_Val1:
	in	ax,dx
	loop	I_Val1
	mov	di,XCMsg						;Point to drive "name" input buffer.
	push	cs
	pop	es
	mov	cl,20							;Read & swap words 27-46 into buffer.
I_Val2:
	in	ax,dx							;(Manufacturer "name" of this drive).
	xchg	ah,al
	stosw
	loop	I_Val2
	mov	cl,7							;Skip I.D. words 47-52 (unimportant)
I_Val3:
	in	ax,dx							;  and read I.D. word 53 into AX-reg.
	loop	I_Val3
	mov	[bx+UFlag-@],al					;Save UltraDMA "valid" flags.
	mov	cl,35							;Skip I.D. words 54-87 (unimportant)
I_Val4:
	in	ax,dx							;  and read I.D. word 88 into AX-reg.
	loop	I_Val4
	mov	[bx+UMode-@],ah					;Save posted UltraDMA "mode" value.
	mov	cl,167							;Skip all remaining I.D. data.
I_Val5:
	in	ax,dx
	loop	I_Val5
	cmp	si,08500h						;Do device flags say "ATAPI CD-ROM"?
	je	I_Val9							;Yes, see about UltraDMA use.
I_Val6:
	mov	cx,NCMsg						;Get "not an ATAPI CD-ROM" msg. ptr.
I_Val7:
	mov	[bx+IEMsg-@],cx					;Post desired error-message pointer.
	stc									;Set carry flag on (error!).
I_Val8:
	ret									;Exit.
I_Val9:
	test	byte [bx+DMAAd-@],007h		;Will we be using UltraDMA?
	jnz	I_Val8							;No, go exit above.
	test	byte [bx+UFlag-@],004h		;Valid UltraDMA "mode" bits?
	jz	I_Val10							;No, reset UltraDMA address.
	mov	ch,[bx+UMode-@]					;Get UltraDMA "mode" bits.
	or	ch,ch							;Can drive do mode 0 minimum?
	jnz	I_Val11							;Yes, do maximum "mode" scan.
I_Val10:
	or	byte [bx+DMAAd-@],001h  		;Post drive "DMA disabled".
	ret									;Exit -- must use "PIO mode"!
I_Val11:
	push	si							;Save SI-register.
	mov	cl,0FFh							;Initialize UltraDMA "mode" scan.
	mov	si,ModeTbl
	push dx
I_Val12:
	inc	cl								;Advance to next UltraDMA "mode".
	mov ax, [ds:si]
	add si,2
	mov dx, [ds:si]
	add si,2
	cmp	cl,[bx+MaxUM-@] 				;Are we limited to this "mode"?
	je	I_Val13							;Yes, set UltraDMA "mode" now.
	shr	ch,1							;Will drive do next "mode"?
	jnz	I_Val12							;Yes, keep scanning for maximum.
I_Val13:
	mov	[UDMode+0],ax					;Set UltraDMA "mode" in message.
	mov	[UDMode+2],dx					;Set UltraDMA "mode" in message.
	pop dx
	pop	si								;Reload SI-register.
	xor	ax,ax							;Clear return code & carry flag.
	ret									;Exit.
;
; Subroutine to end XDMA "synchronization".
;
I_EndSy:
	cmp	[bx+SyncX-@],bl					;Are we synchronizing with XDMA?
    jne	I_EndSX							;No, just exit below.
	mov	es,[bx+XDSeg-@]					;Point to XDMA driver in memory.
	mov	al,09Fh							;Reset XDMA channel "busy" flags.
	cli
	and	[es:XDFLAGS],al
	sti
I_EndSX	ret								;Exit.
;
; Initialization UltraDMA "Mode" Message Values.
;
ModeTbl		db	'16$ '		;"Mode 0", ATA-16.
			db	'25$ '		;"Mode 1", ATA-25.
			db	'33$ '		;"Mode 2", ATA-33.
			db	'44$ '		;"Mode 3", ATA-44  (rarely used).
			db	'66$ '		;"Mode 4", ATA-66.
			db	'100$'		;"Mode 5", ATA-100.
			db	'133$'		;"Mode 6", ATA-133.
			db	'150$'		;"Mode 7", ATA-166, or SATA-150 ?.
			db	'300$'		;"Mode 8", ATA-300 (?, SATA-2).
;
; Initialization IDE Parameter-Value Table.
;

ScanP		dw	CDATA	;Primary-master   drive parameters.
			db	0A0h,028h
			dw	CDATA	;Primary-slave    drive parameters.
			db	0B0h,028h
ScanS		dw	CDATA-080h	;Secondary-master drive parameters.
			db	0A0h,050h
			dw	CDATA-080h	;Secondary-slave  drive parameters.
			db	0B0h,050h
ScanE		equ	$		;(End of IDE parameter table).

XCMsg		db	CR,LF,'XGCDROM '
			db	VER		;XCDROM.ASM provides version and date!
			db	CR,LF,'$'
DvrMsg		db	'Driver name is "'
DvrMsg1		db	'        "$'
CtlrMsg		db	'PCI ATA controller found, Chip Ven_'
CtlrID		db	'xxxxh&Dev_'
CtlrID0		db	'xxxxh.',CR,LF,'Primary port - '
CtlrAdr0 	db	'xxxxh, Secondary port - '
CtlrAdr		db	'xxxxh'
			db	CR,LF,'$'
VEMsg		db	'.',CR,LF,'VDS init error$'
LEMsg		db	'.',CR,LF,'/L Invalid$'
SyEMsg		db	'.',CR,LF,'ERROR '
SyMsg		db	'Synchronizing I-O with XDMA driver$'
PRMsg		db	'No 80386+ CPU'
Suffix		db	'; XGCDROM not loaded!',CR,LF,'$'
UnitMsg		db	'Unit '
UMsgNo		db	'0:  $'
TOMsg		db	' device select timeout$'
IDMsg		db	' Identify Device error$'
NCMsg		db	' is not an ATAPI CD/DVD-ROM$'
NDMsg		db	'No CD/DVD-ROM drive to use$'
PriMsg		db	'Primary-$'
SecMsg		db	'Secondary-$'
MstMsg		db	'master$'
SlvMsg		db	'slave$'
ComMsg		db	', $'
UDMsg		db	', ATA-'
UDMode		db	'   $'
PIOMsg		db	', PIO mode$'
CRMsg		db	'.',CR,LF,'$'
