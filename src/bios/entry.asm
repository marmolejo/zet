;
;  Zet PC system BIOS helper functions in 8086 assembly
;  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
;  Copyright (C) 2010        Donna Polehn <dpolehn@verizon.net>
;
;  This file is part of the Zet processor. This program is free software;
;  you can redistribute it and/or modify it under the terms of the GNU
;  General Public License as published by the Free Software Foundation;
;  either version 3, or (at your option) any later version.
;
;  Zet is distrubuted in the hope that it will be useful, but WITHOUT
;  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
;  License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with Zet; see the file COPYING. If not, see
;  <http://www.gnu.org/licenses/>.
;

;;--------------------------------------------------------------------------
;; ROM BIOS compatability entry points:
;;--------------------------------------------------------------------------
;; $0000 ; Start of ROM Utilities
;; $e05b ; POST Entry Point
;; $e6f2 ; INT 19h Boot Load Service Entry Point
;; $efc7 ; Diskette parameter table
;; $f045 ; INT 10 Functions 0-Fh Entry Point
;; $f065 ; INT 10h Video Support Service Entry Point
;; $f0a4 ; MDA/CGA Video Parameter Table (INT 1Dh)
;; $f859 ; INT15 services interupt
;; $fef3 ; Vector table
;; $ff23 ; Ignored interupt vector
;; $ff53 ; Dummy interupt 
;; $fff0 ; Power-up Entry Point
;; $fff5 ; ASCII Date ROM was built - 8 characters in MM/DD/YY
;; $fffe ; System Model ID

;;--------------------------------------------------------------------------

;;--------------------------------------------------------------------------
;; ROM Utilities Externals
;;--------------------------------------------------------------------------
EBDA_SEG                equ     09FC0h   ; EBDA is used for PS/2 mouse support, and IDE BIOS, etc.
EBDA_SIZE               equ     1        ; In KiB
BASE_MEM_IN_K           equ     640 - EBDA_SIZE
IPL_SEG                 equ     09ff0h   ; 256 bytes at 0x9ff00 -- 0x9ffff is used for the IPL boot table.
IPL_COUNT_OFFSET        equ     0080h    ; u16: number of valid table entries
IPL_SEQUENCE_OFFSET     equ     0082h    ; u16: next boot device
IPL_BOOTFIRST_OFFSET    equ     0084h    ; u16: user selected device
IPL_TABLE_ENTRIES       equ     8        ; num Table entries
IPL_TYPE_BEV            equ     080h     ;

PICM					equ		020h
PICS					equ		0A0h
NSEOI					equ		020h

IO_POST					equ		080h

;;--------------------------------------------------------------------------
;; ROM Utilities Externals
;;--------------------------------------------------------------------------
                        EXTRN  _print_bios_banner      :proc      ; Print the BIOS Banner message
                        EXTRN  _int13_diskette_function:proc      ; Contained in C source module
                        EXTRN  _MakeRamdisk            :proc      ; Contained in C source module 
                        EXTRN  _int13_harddisk         :proc      ; Contained in C source module
                        EXTRN  _boot_halt              :proc      ; Contained in C source module
                        EXTRN  _int19_function         :proc      ; Contained in C source module
                        EXTRN  _int14_function         :proc      ; Contained in C source module
                        EXTRN  _int15_function         :proc      ; Contained in C source module
                        EXTRN  _int15_function_mouse   :proc      ; Contained in C source module
                        EXTRN  _int1a_function         :proc      ; Time-of-day Service Entry Point
                        EXTRN  _int09_function         :proc      ; BIOS Interupt 09
                        EXTRN  _int16_function         :proc      ; Keyboard Service Entry Point
                        EXTRN  _init_boot_vectors      :proc      ; Initialize Boot Vectors

;;--------------------------------------------------------------------------
;; Set vector macro:
;; This macro is called by the POST sections andsets the interupt vectors in 
;; the BDA (BIOS Data Area) at memory location 0040:0000 to 0040:0100
;; INT 08 - IRQ0  - SYSTEM TIMER; CPU-generated (80286+)
;; INT 09 - IRQ1  - KEYBOARD DATA READY; CPU-generated 
;; INT 0A - IRQ2  - LPT2/EGA,VGA/IRQ9; CPU-generated (80286+)
;; INT 0B - IRQ3  - SERIAL COMMUNICATIONS (COM2); CPU-generated (80286+)
;; INT 0C - IRQ4  - SERIAL COMMUNICATIONS (COM1); CPU-generated (80286+)
;; INT 0D - IRQ5  - FIXED DISK/LPT2/reserved; CPU-generated (80286+)
;; INT 0E - IRQ6  - DISKETTE CONTROLLER; CPU-generated (80386+)
;; INT 0F - IRQ7  - PARALLEL PRINTER
;; INT 70 - IRQ8  - CMOS REAL-TIME CLOCK
;; INT 71 - IRQ9  - REDIRECTED TO INT 0A BY BIOS
;; INT 72 - IRQ10 - RESERVED
;; INT 73 - IRQ11 - RESERVED
;; INT 74 - IRQ12 - POINTING DEVICE (PS)
;; INT 75 - IRQ13 - MATH COPROCESSOR EXCEPTION (AT and up)
;; INT 76 - IRQ14 - HARD DISK CONTROLLER (AT and later)
;; INT 77 - IRQ15 - RESERVED (AT,PS); POWER CONSERVATION (Compaq)
;;--------------------------------------------------------------------------
POSTCODE MACRO parm1
						mov		al, parm1
						out		IO_POST, al
ENDM
;;--------------------------------------------------------------------------
SET_INT_VECTOR MACRO parm1, parm2, parm3
                        mov     ax, parm3
                        mov     ds:[parm1*4], ax
                        mov     ax, parm2
                        mov     ds:[parm1*4+2], ax
ENDM
;;--------------------------------------------------------------------------
PUSHALL MACRO
                        push    ax
                        push    cx
                        push    dx
                        push    bx
                        push    bp
                        push    si
                        push    di
ENDM
;;--------------------------------------------------------------------------
POPALL MACRO
                        pop     di
                        pop     si
                        pop     bp
                        pop     bx
                        pop     dx
                        pop     cx
                        pop     ax
ENDM

;;--------------------------------------------------------------------------
;; This value is subtracted from all the values that have to be placed to an
;; absolute location. The reason is so we can assemble a module that the linker
;; will start linking at F000:E000 offset. If we do not, then the linker will
;; fill F000:0000 to F000:DFFF with zeros and we will not be able to linke the
;; C module in. This trick makes the assembler thing we are starting at F000:0000 
;; then we set the linker script in the make file with an ofset of E000 in this
;; _BIOSSEG segment only. If you followed that then congratulations.
;;--------------------------------------------------------------------------
startofrom              equ     0e000h

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        .Model  Tiny    ;; this forces it to nears on code and data
                        .8086           ;; this forces it to use 80186 and lower
_BIOSSEG                SEGMENT 'CODE'
                        assume  cs:_BIOSSEG
bootrom:                org     0000h           ;; start of ROM, get placed at 0E000h
bios_name_string:       db      "zetbios 1.1"   ;; version string, not used by code
                        db      0,0,0,0         ;; padding

;;---------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; POST -  POST Entry Point:
;; After power on reset, the cpu starts at linear 0xfff00 and there is a jmp
;; there (see below) which comes here (jmp far post). This section doe the 
;; following tasks in this order:
;; - initializes our SDRAM first so we can use memory
;; - Sets the interupt vectors in BDA
;; - Sets keyboard variables in BDA
;; - Scans for the vga bios rom and links to it
;; - prints the opening banner message
;; - Calls the HD POST to set up the hard drive
;; - calls int19 which boots up the OS
;;---------------------------------------------------------------------------
;;---------------------------------------------------------------------------
                        org     (0e05bh - startofrom)

post:                   POSTCODE 010h								; PostCode = 10
						xor     ax, ax          					; clear ax register
                        mov     es, ax          					; zero out BIOS data area (40:00..40:ff)
                        mov     cx, 0080h       					; 128 words
                        mov     di, 0400h       					; Point index register to bda area
                        cld
                        rep     stosw           					; repeat cx times
                        xor     bx, bx          					; set all interrupts to default handleroffset index
                        mov     cx, 0100h                  			;; counter (256 interrupts)
                        mov     ax, dummy_iret_handler      		;; handle ignored vectors
                        mov     dx, 0F000h                  		;; load the Bios Data Segment

post_default_ints:      mov     [bx], ax             				; Store dummy return handler offset
                        add      bx,  2              				; Go to next word
                        mov     [bx], dx            				; Store Bios Segment word
                        add      bx,  2              				; Go to next word
                        loop    post_default_ints    				; do cx times
						
						POSTCODE 011h								; PostCode = 11

                        SET_INT_VECTOR 079h, 0, 0     				;; set vector 0x79 to zero this is used by 'gardian angel' protection system
                        mov     ax, BASE_MEM_IN_K     				;; base memory in K 40:13 (word)
                        mov     ds:00413h, ax

                        SET_INT_VECTOR 018h, 0F000h, int18_handler    ;; Bootstrap failure vector
                        SET_INT_VECTOR 019h, 0F000h, int19_handler    ;; Bootstrap Loader vector
                        SET_INT_VECTOR 01ch, 0F000h, int1c_handler    ;; User Timer Tick vector
                        SET_INT_VECTOR 011h, 0F000h, int11_handler    ;; Equipment Configuration Check vector
                        SET_INT_VECTOR 012h, 0F000h, int12_handler    ;; Memory Size Check vector

ebda_post:              POSTCODE 012h								; PostCode = 12
						mov     ax, EBDA_SEG                          ;; EBDA Segment
                        mov     ds, ax                                ;; Set data segment to it
                        mov     byte ptr ds:0x0000, EBDA_SIZE         ;; Load the size in to 1st byte
                        mov     byte ptr ds:0x0027, 0x00              ;; Clear flags
                        xor     ax, ax                                ;; BDA Segment
                        mov     ds, ax                                ;; Set data segment to it
                        mov     word ptr ds:0x040E, EBDA_SEG          ;; Save the EBDA seg in BDA 

                        SET_INT_VECTOR 008h, 0F000h, int08_handler    ;; IRQ0 - PIT setup - int 1C already points at dummy_iret_handler (above)
                        SET_INT_VECTOR 009h, 0F000h, int09_handler    ;; IRQ1 -  Keyboard Hardware Service Entry Point
                        SET_INT_VECTOR 016h, 0F000h, int16_handler    ;; Keyboard Service Entry Point

                        SET_INT_VECTOR 015h, 0F000h, int15_handler    ;; Mouse interface 
                        
                        SET_INT_VECTOR 074h, 0F000h, int74_handler    ;; Mouse hardware interupt vector
                        ;;SET_INT_VECTOR 00Bh, 0F000h, int0B_handler    ;; IRQ3 - COM2/Mouse hardware interupt vector 

                        xor     ax, ax
                        mov     ds, ax
                        mov     BYTE PTR ds:00417h, al      ; keyboard shift flags, set 1
                        mov     BYTE PTR ds:00418h, al      ; keyboard shift flags, set 2
                        mov     BYTE PTR ds:00419h, al      ; keyboard alt-numpad work area
                        mov     BYTE PTR ds:00471h, al      ; keyboard ctrl-break flag
                        mov     BYTE PTR ds:00497h, al      ; keyboard status flags 4
                        mov     al, 010h
                        mov     BYTE PTR ds:00496h, al      ; keyboard status flags 3
                        mov     bx, 001Eh                   ; keyboard head of buffer pointer
                        mov     WORD PTR ds:0041Ah, bx
                        mov     WORD PTR ds:0041Ch, bx      ; keyboard end of buffer pointer
                        mov     bx, 001Eh                   ; keyboard pointer to start of buffer
                        mov     WORD PTR ds:00480h, bx
                        mov     bx, 003Eh                   ; keyboard pointer to end of buffer
                        mov     WORD PTR ds:00482h, bx

                        mov     bx, 03F8h                   ; COM1 Adapter
                        mov     WORD PTR ds:0400h, bx       ; Serial port Setup, hard coded rather
                        mov     bx, 02F8h                   ; COM2 Adapter
                        mov     WORD PTR ds:0402h, bx       ; than detecting them,
                        
                        ; Equipment list set up, This is the the only place
                        ;           1111110000000000
                        ;           5432109876543210
                    ;;  mov     ax, 0000010001000001B    ; where we setup the equipment list, see INT11 
                        mov     ax, 0000001000100101B    ; where we setup the equipment list, see INT11 
                        mov     WORD PTR ds:0410h, ax    ; Equipment word bits 9..11 determing # serial ports

                        SET_INT_VECTOR 01Ah, 0F000h, int1a_handler    ;; CMOS RTC
                        SET_INT_VECTOR 010h, 0F000h, int10_handler    ;; int10_handler - Video Support Service Entry Point

						; Initialize Pic Master
						POSTCODE 013h								; PostCode = 13
						mov		al, 011h
						out		PICM, al				;; Send ICW1
						mov		al, 008h				;; Vector start = 0x08
						out		PICM+1, al				;; Send ICW2
						mov		al, 004h				;; Slave at IRQ2
						out		PICM+1, al				;; Send ICW3
						mov		al, 001h				;; Mode = 8086
						out		PICM+1, al				;; Send ICW4
						;
						mov		al, 0E8h				;; Enable IRQ 0 (Timer), 1 (Keyboard), 2 (Slave), 4 (Serial)
						out		PICM+1, al				;; OCW1

						; Initialize Pic Slave
						mov		al, 011h
						out		PICS, al				;; Send ICW1
						mov		al, 070h				;; Vector start = 0x70
						out		PICS+1, al				;; Send ICW2
						mov		al, 002h				;; Slave Id = 2 (This is ignored) 
						out		PICS+1, al				;; Send ICW3
						mov		al, 001h				;; Mode = 8086
						out		PICS+1, al				;; Send ICW4
						;
						mov		al, 0EFh				;; Enable IRQ 12 (Mouse)
						out		PICS+1, al				;; OCW1

						POSTCODE 020h								; PostCode = 20
                        mov     cx, 0c000h             ;; init vga bios
                        mov     ax, 0c780h
                        call    rom_scan               ;; Scan ROM  
						POSTCODE 021h								; PostCode = 21
                        call    _print_bios_banner     ;; Print the openning banner

						POSTCODE 030h								; PostCode = 30
                        call    _MakeRamdisk           ;; Ram Drive setup
						POSTCODE 040h								; PostCode = 40
                        call    hard_drive_post        ;; Hard Drive setup
						POSTCODE 050h								; PostCode = 50
                        call    _init_boot_vectors     ;; Initialize the boot vectors

						POSTCODE 060h								; PostCode = 60
                        mov     cx, 0c800h             ;; Initialize option roms
                        mov     ax, 0e000h             ;; Initialize option roms
                        call    rom_scan               ;; Call the rom scan again

						POSTCODE 0FFh								; PostCode = FF
                        sti                            ;; enable interrupts
                        int     019h                   ;; Now load dos boot sector and jump to it

;;--------------------------------------------------------------------------
;; Padding - This can be removed if space becomes tight, it is here right
;; now just to delineate between the POST section and the other routines
;;--------------------------------------------------------------------------
                        db      0,0,0,0,0,0,0,0
                        
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;;- INT18h - ;; Boot Failure recovery: try the next device.
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
int18_handler:          mov     ax, 0fffeh       
                        mov     sp, ax              ;; Reset SP and SS
                        xor     ax, ax              ;; Clear ax regiater
                        mov     ss, ax              ;; Clears SS
                        mov     bx, IPL_SEG         ;; Get the boot sequence number out of the IPL memory
                        mov     ds, bx                                  ;; Set segment
                        mov     bx, WORD PTR ds:IPL_SEQUENCE_OFFSET   ;; BX is now the sequence number
                        inc     bx                                      ;; Increment BX register
                        mov     ax, WORD PTR ds:IPL_COUNT_OFFSET      ;; get offset
                        cmp     ax, bx                                  
                        jg      i18_next
                        call    _boot_halt                              ;; Call the halt message
                        hlt                                             ;; Halt the processor
i18_next:               xor     ax, ax
                        mov     WORD PTR ds:IPL_SEQUENCE_OFFSET, bx    ;; Write it back
                        mov     ds, ax                                   ;; and reset the segment to zero.
                        push    bx                              ;; Carry on in the INT 19h handler, 
                        jmp     int19_next_boot                 ;; using the new sequence number

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; - POST: HARD DRIVE 
;; - IRQ 14 = INT 76h, INT 76h calls INT 15h function ax=9100 
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
hard_drive_post:        xor     ax, ax           ; Clear ax
                        mov     ds, ax           ; Data segment = 0, control table location
                        mov     ds:0474h, al     ; hard disk status of last operation
                        mov     ds:0477h, al     ; hard disk port offset (XT only ???)
                        mov     ds:048ch, al     ; hard disk status register
                        mov     ds:048dh, al     ; hard disk error register
                        mov     ds:048eh, al     ; hard disk task complete flag
                        mov     al, 01h          ; Drive #1
                        mov     ds:0475h, al     ; hard disk number attached
                        mov     al, 0c0h         ; Control byte
                        mov     ds:0476h, al     ; hard disk control byte

                        SET_INT_VECTOR 013h, 0F000h, int13_handler
                        SET_INT_VECTOR 076h, 0F000h, int76_handler

                        mov     al, 0ffh         ; Initialize the SD card controller
                        mov     dx, 0100h        ; Location of SD controller 
                        mov     cx, 10           ; Number of times to repeat
  
hd_post_init80:         out     dx, al           ; 80 cycles of initialization
                        loop    hd_post_init80   ; Looop 80 times
                        mov     ax, 040h         ; CS = 0, CMD0: reset the SD card
                        out     dx, ax           ; Reset the card 
                        xor     al, al           ; Clear al
                        out     dx, al           ; 32-bit zero value
                        out     dx, al
                        out     dx, al
                        out     dx, al
                        mov     al, 095h         ; Fixed value
                        out     dx, al           ; load it
                        mov     al, 0ffh         
                        out     dx, al           ; wait
                        in      al, dx           ; status
                        mov     cl, al
                        mov     ax, 0ffffh
                        out     dx, ax           ; CS = 1
                        cmp     cl, 1
                        je      hd_post_cmd1
                        mov     al, 1            ; error 1
                        mov     ds:0048dh, al
                        ret

hd_post_cmd1:           mov     ax, 041h        ; CS = 0, CMD1: activate the init sequence
                        out     dx, ax
                        xor     al, al
                        out     dx, al          ; 32-bit zero value
                        out     dx, al
                        out     dx, al
                        out     dx, al
                        mov     al, 0ffh
                        out     dx, al          ; CRC (not used)
                        out     dx, al          ; wait
                        in      al, dx          ; status
                        mov     cl, al
                        mov     ax, 0ffffh
                        out     dx, ax          ; CS = 1
                        test    cl, 0ffh
                        jnz     hd_post_cmd1
                        
                        mov     ax, 050h        ; CS = 0, CMD16: set block length
                        out     dx, ax
                        xor     al, al
                        out     dx, al          ; 32-bit value
                        out     dx, al
                        mov     al, 2           ; 512 bytes
                        out     dx, al
                        xor     al, al
                        out     dx, al
                        mov     al, 0ffh
                        out     dx, al          ; CRC (not used)
                        out     dx, al          ; wait
                        in      al, dx          ; status
                        mov     cl, al
                        mov     ax, 0ffffh
                        out     dx, ax          ; CS = 1
                        test    cl, 0ffh
                        jz      hd_post_success
                        mov     al, 2           ; error 2
                        mov     ds:0048dh, al
                        ret
hd_post_success:        ret

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; record completion in BIOS task complete flag
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
int76_handler:          push    ax
                        push    ds
                        mov     ax, 0040h
                        mov     ds, ax
                        mov     BYTE PTR ds:008Eh, 0ffh
                                            ;; 
                     ;; call  eoi_both_pics ;; commented out because we do not
                                            ;; have a PIC in this computer
                        pop     ds
                        pop     ax
                        iret  

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;;  ROM Checksum calculation
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
rom_checksum:           push    ax                      ;; Save registers
                        push    bx                      ;; Save registers
                        push    cx                      ;; Save registers
                        xor     ax, ax                  ;; Clear ax
                        xor     bx, bx                  ;; Clear bx
                        xor     cx, cx                  ;; Clear cx
                        mov     ch, BYTE PTR ds:[2]     ;; get 2nd byte pointerd to
                        shl     cx, 1                   ;; Shift left (mult by 2)
checksum_loop:          add     al, BYTE PTR ds:[bx]    ;; Add
                        inc     bx                      ;; increment bx++
                        loop    checksum_loop           ;; loop until done
                        and     al, 0ffh                ;; 
                        pop     cx
                        pop     bx
                        pop     ax
                        ret                             ;; return to caller

;;--------------------------------------------------------------------------
;;  We need a copy of this string, but we are not actually a PnP BIOS,
;;  so make sure it is *not* aligned, so OSes will not see it if they scan.
;;--------------------------------------------------------------------------
                        align 16
                        db      0
pnp_string:             DB      "$PnP"

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Scan for existence of valid expansion ROMS.
;;   Video ROM:   from 0xC0000..0xC7FFF in 2k increments
;;   General ROM: from 0xC8000..0xDFFFF in 2k increments
;;   System  ROM: only 0xE0000
;;
;; Header:
;;   Offset    Value
;;   0         055h
;;   1         0AAh
;;   2         ROM length in 512-byte blocks
;;   3         ROM initialization entry point (FAR CALL)
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
rom_scan:
rom_scan_loop:          push    ax                      ;; Save AX
                        mov     ds, cx
                        mov     ax, 0004h               ;; start with increment of 4 (512-byte) blocks = 2k
                        cmp     WORD PTR ds:[0], 0AA55h ;; look for signature
                        jne     rom_scan_increment
                        call    rom_checksum
                        jnz     rom_scan_increment
                        mov     al, BYTE PTR ds:[2]     ;; change increment to ROM length in 512-byte blocks
                        test    al, 003h                ;; We want our increment in 512-byte quantities, rounded to
                        jz      block_count_rounded     ;; the nearest 2k quantity, since we only scan at 2k intervals.
                        and     al, 0fch                ;; needs rounding up
                        add     al, 004h

block_count_rounded:    xor     bx, bx                  ;; Restore DS back to 0000:
                        mov     ds, bx
                        push    ax                      ;; Save AX
                        push    di                      ;; Save DI  Push addr of ROM entry point
                        push    cx                      ;; Push seg
                        mov     ax, 00003h              ;; Offset
                        push    ax                      ;; Put offset on stack            
                        mov     ax, 0F000h              ;; Point ES:DI at "$PnP", which tells the ROM that we are a PnP BIOS.
                        mov     es, ax                  ;; That should stop it grabbing INT 19h; we will use its BEV instead.
                        lea     di, pnp_string+startofrom
                        mov     bp, sp                          ;; Call ROM init routine using seg:off on stack
                        call    DWORD PTR ss:[bp]           ;; should assemble to 0ff05eh 0 (and it does under tasm)
                        cli                                 ;; In case expansion ROM BIOS turns IF on
                        add     sp, 2                       ;; Pop offset value
                        pop     cx                          ;; Pop seg value (restore CX)
                                                            ;; Look at the ROM's PnP Expansion header.  Properly, we're supposed
                                                            ;; to init all the ROMs and then go back and build an IPL table of
                                                            ;; all the bootable devices, but we can get away with one pass.
                        mov     ds, cx                      ;; ROM base
                        mov     bx, WORD PTR ds:01ah      ;; 0x1A is the offset into ROM header that contains...
                        mov     ax, [bx]                    ;; the offset of PnP expansion header, where...
                        cmp     ax, 05024h                  ;; we look for signature "$PnP"
                        jne     no_bev
                        mov     ax, 2[bx]
                        cmp     ax, 0506eh
                        jne     no_bev
                        mov     ax, 01ah[bx]                ;; 0x1A is also the offset into the expansion header of...
                        cmp     ax, 00000h                  ;; the Bootstrap Entry Vector, or zero if there is none.
                        je      no_bev                      ;; Found a device that thinks it can boot the system.
                                                            ;; Record its BEV and product name string.
                        mov     di, 010h[bx]                ;; Pointer to the product name string or zero if none
                        mov     bx, IPL_SEG                 ;; Go to the segment where the IPL table lives
                        mov     ds, bx
                        mov     bx, WORD PTR ds:IPL_COUNT_OFFSET  ;; Read the number of entries so far
                        cmp     bx, IPL_TABLE_ENTRIES
                        je      no_bev                              ;; Get out if the table is full
                        push    cx
                        mov     cx, 04h                             ;; Zet: Needed to be compatible with 8086
                        shl     bx, cl                              ;; Turn count into offset (entries are 16 bytes)
                        pop     cx
                        mov     WORD PTR 0[bx], IPL_TYPE_BEV        ;; This entry is a BEV device
                        mov     WORD PTR 6[bx], cx                  ;; Build a far pointer from the segment...
                        mov     WORD PTR 4[bx], ax                  ;; and the offset
                        cmp     di, 00000h
                        je      no_prod_str
                        mov     0Ah[bx], cx                     ;; Build a far pointer from the segment...
                        mov     8[bx], di                       ;; and the offset
no_prod_str:            push    cx
                        mov     cx, 04h
                        shr     bx, cl                          ;; Turn the offset back into a count
                        pop     cx
                        inc     bx                               ;; We have one more entry now
                        mov     WORD PTR ds:IPL_COUNT_OFFSET, bx ;; Remember that.
no_bev:                 pop     di                               ;; Restore DI
                        pop     ax                               ;; Restore AX
rom_scan_increment:     push    cx
                        mov     cx, 5                       ;; convert 512-bytes blocks to 16-byte increments
                        shl     ax, cl                      ;; because the segment selector is shifted left 4 bits.
                        pop     cx
                        add     cx, ax
                        pop     ax                          ;; Restore AX
                        cmp     cx, ax
                        jbe     rom_scan_loop               ;; This is a far jump
                        xor     ax, ax                      ;; Restore DS back to 0000:
                        mov     ds, ax
                        ret
      
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;;- INT 13h Fixed Disk Services Entry Point -
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Absolute location 0xe3fe needed to be bios correct
;; This function has been re-written to:
;;   - Push all registers onto the stack for the C call and set the data segment
;;   - detects which function to call HD or diskette
;;   - Pop everything back off the stack that the C program may have changed
;;   - because the iret will pop the flags, we copy the needed flags to the 
;;     flags reg on the stack then return from interupt
;;--------------------------------------------------------------------------
                        org     (0e3feh - startofrom)   ;; INT 13h Fixed Disk Services Entry Point
int13_handler:          push    ax                      ;; This will save them all and pass them to
                        push    cx                  ;; the C program
                        push    dx                  ;;
                        push    bx                  ;;
                        push    bp                  ;;
                        push    si                  ;;
                        push    di                  ;;
                        push    es                  ;; The order of parms in C program 
                        push    ds                  ;; DS, ES, DI, SI, BP, BX, DX, CX, AX, rIP, rCS, FLAGS

                        push    ss                  ;; Push the stack segment
                        pop     ds                  ;; Pop it to the Data segment, now we have DS set for our C call
                        
                        test    dl,80h                      ;; Test to see if current drive is HD
                        jnz     int13_HardDisk              ;; If so, do that, otherwise do floppy

                        call    _int13_diskette_function    ;; Call the diskette function
                        jmp     int13_out                   ;; Jump to exit code

int13_HardDisk:         call    _int13_harddisk             ;; Otherwise call the hardisk function
int13_out:                                                  ;; diskette jumps to here when done
                        pop     ds                  ;; Restore all registers
                        pop     es                  ;; Back in the reverse order pushed from above
                        pop     di                  ;;
                        pop     si                  ;;
                        pop     bp                  ;;
                        pop     bx                  ;;
                        pop     dx                  ;;
                        pop     cx                  ;;
                        pop     ax                  ;;
                        iret                                    ;; return from interupt

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; - INT19h - INT 19h Boot Load Service Entry Point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0e6e0h - startofrom) 
int19_relocated:        push    bp                  ;; int19 was beginning to be really complex, so now it
                        mov     bp, sp              ;; just calls a C function that does the work

                        mov     ax, 0fffeh          ;; Reset SS and SP
                        mov     sp, ax              ;; Set Stack pointer to top o ram
                        xor     ax, ax              ;; Clear AX register
                        mov     ss, ax              ;; Reset Stack Segment
int19_next_boot:        call    _int19_function     ;; Call the C code for the next boot device
                        int     018h                ;; Boot failed: invoke the boot recovery function

                        org     (0e6f2h - startofrom) 
int19_handler:          jmp     int19_relocated                        

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; System BIOS Configuration Data Table
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
SYS_MODEL_ID            equ     0xFC
SYS_SUBMODEL_ID         equ     0x00
BIOS_REVISION           equ     1
;--------------------------------------------------------------------------
                        org     (0e6f5h - startofrom) 
                        db      0x08                  ; Table size (bytes) -Lo
                        db      0x00                  ; Table size (bytes) -Hi
                        db      SYS_MODEL_ID
                        db      SYS_SUBMODEL_ID
                        db      BIOS_REVISION
;--------------------------------------------------------------------------
; Feature byte 1
; b7: 1=DMA channel 3 used by hard disk
; b6: 1=2 interrupt controllers present
; b5: 1=RTC present
; b4: 1=BIOS calls int 15h/4Fh every key
; b3: 1=wait for extern event supported (Int 15h/41h)
; b2: 1=extended BIOS data area used
; b1: 0=AT or ESDI bus, 1=MicroChannel
; b0: 1=Dual bus (MicroChannel + ISA)
;--------------------------------------------------------------------------
; db (0 << 7)|(1 << 6)|(1 << 5)|(BX_CALL_INT15_4F << 4)|(0 << 3)|(BX_USE_EBDA << 2)|(0 << 1)|(0 << 0)
;                               76543210
                       db       00000100b
   
;--------------------------------------------------------------------------
; Feature byte 2
; b7: 1=32-bit DMA supported
; b6: 1=int16h, function 9 supported
; b5: 1=int15h/C6h (get POS data) supported
; b4: 1=int15h/C7h (get mem map info) supported
; b3: 1=int15h/C8h (en/dis CPU) supported
; b2: 1=non-8042 kb controller
; b1: 1=data streaming supported
; b0: reserved
;--------------------------------------------------------------------------
; db (0 << 7)|(1 << 6)|(0 << 5)|(0 << 4)|(0 << 3)|(0 << 2)|(0 << 1)|(0 << 0)

                        db      01000000b
;--------------------------------------------------------------------------
; Feature byte 3
; b7: not used
; b6: reserved
; b5: reserved
; b4: POST supports ROM-to-RAM enable/disable
; b3: SCSI on system board
; b2: info panel installed
; b1: Initial Machine Load (IML) system - BIOS on disk
; b0: SCSI supported in IML
;--------------------------------------------------------------------------
                        db 0x00
;--------------------------------------------------------------------------
; Feature byte 4
; b7: IBM private
; b6: EEPROM present
; b5-3: ABIOS presence (011 = not supported)
; b2: private
; b1: memory split above 16Mb supported
; b0: POSTEXT directly supported by POST
;--------------------------------------------------------------------------
                        db 0x00
;--------------------------------------------------------------------------
; Feature byte 5 (IBM)
; b1: enhanced mouse
; b0: flash EPROM
;--------------------------------------------------------------------------
                        db 0x00

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT14h - IBM entry point for Serial com. RS232 services
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0e729h - startofrom) 
int14_handler:        sti                         ; Serial com. RS232 services
                        push    ds                  ; save on stack
                        push    ax                  ; place ax on stack
                        push    dx                  ; place ax on stack
                        xor     ax, ax              ; Clear ax
                        mov     ds, ax              ; make data segment 0
                        call    _int14_function
                        pop     dx
                        pop     ax
                        pop     ds
                        cli                         ; enale interrupts
                        iret                        ; Baud Rate Generator Table
baud_rates:             dw      0417h               ;  110 baud clock divisor
                        dw      0300h               ;  150 baud clock divisor
                        dw      0180h               ;  300 baud clock divisor
                        dw      00C0h               ;  600 baud clock divisor
                        dw      0060h               ; 1200 baud clock divisor
                        dw      0030h               ; 2400 baud clock divisor
                        dw      0018h               ; 4800 baud clock divisor
                        dw      000Ch               ; 9600 baud clock divisor

;int14_handler:         sti                         ; Serial com. RS232 services
;                       cli                         ; enale interrupts
;                       iret                        ; Baud Rate Generator Table

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT16 Keyboard Service Entry Point -
;; This interupt service routine checks the AH register to see if the user
;; wants to check for a key or wait for a key. If AH==0, then the user is 
;; checking (equivalent of C kbhit) if AH=10h then they want to wait. In either
;; case, the C helper function int16_function() is called to get the keyboard
;; input.
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0e82eh - startofrom)
int16_handler:          sti                             ;; Enable interupts
                        push    ds                      ;; Save all registers that
                        push    dx                      ;; are not supposed to change
                        push    bx                      ;; on return
                        push    bp                      ;;
                        push    si                      ;;
                        push    di                      ;;
                        cmp     ah, 00h                 ;; Check to see what command
                        je      int16_F00               ;; was issued with the call
                        cmp     ah, 010h                ;; If either 0x00 or 0x10
                        je      int16_F00               ;; then it is a wait for key loop command
                        mov     bx, 0f000h              ;; Otherwise, just check for a key
                        mov     ds, bx                  ;; First set the data seg to the bios
                        pushf                           ;; Push the parms on the stack
                        push    cx                      ;; for the C program to receive
                        push    ax                      ;; Pass the user command
                        call    _int16_function         ;; Now call the function
                        pop     ax                      ;; Now restor the stack
                        pop     cx                      ;;
                        popf                            ;; Flags should have ZF set correctly
                        pop     di                      ;; Now restore all the saved
                        pop     si                      ;; registers from above
                        pop     bp                      ;; 
                        pop     bx                      ;;
                        pop     dx                      ;;
                        pop     ds                      ;;
                        
                        jz      int16_zero_set          ;; Check the ZF flag set
int16_zero_clear:       push    bp                              ;; This section of code
                        mov     bp, sp                          ;; Sets the ZF flag
                        and     BYTE PTR ss:[bp + 06h], 0bfh    ;; while it is sitting on the stack
                        pop     bp                              ;; The iret will popf 
                        iret                                    ;; return from interupt
int16_zero_set:         push    bp                              ;; Save the base pointer
                        mov     bp, sp                          ;; load it with the stack pointer
                        or      BYTE PTR ss:[bp + 06h], 040h    ;; locate the flags register on the stack
                        pop     bp                              ;; Restore the BP register
                        iret                                    ;; return from interupt

int16_F00:              mov     bx, 0040h               ;; Point to the correct data seg
                        mov     ds, bx                  ;; Set up the DS
int16_wait_for_key:     cli                             ;; Loop and Wait for the key
                        mov     bx, ds:001ah            ;; The head and tail of the buffer
                        cmp     bx, ds:001ch            ;; If they are not equal a key was put on the buffer
                        jne     int16_key_found         ;; Found the key, lets go process it
                        sti                             ;; Enable interupts agains
                        nop                             ;; No operation
                        jmp     int16_wait_for_key      ;; Continue looping until key is received
                        
int16_key_found:        mov     bx, 0f000h              ;; Otherwise, just check for a key
                        mov     ds, bx                  ;; First set the data seg to the bios
                        pushf                           ;; Push the parms on the stack
                        push    cx                      ;; for the C program to receive
                        push    ax                      ;; Pass the user command
                        call    _int16_function         ;; Now call the function
                        pop     ax                      ;; Now restor the stack
                        pop     cx                      ;;
                        popf                            ;; Flags should have ZF set correctly

                        pop     di                      ;; Now restore all the saved
                        pop     si                      ;; registers from above
                        pop     bp                      ;; 
                        pop     bx                      ;;
                        pop     dx                      ;;
                        pop     ds                      ;;
                        iret                            ;; return from interupt


;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT74h : PS/2 mouse hardware interrupt -
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
MOUSE_PORT              equ     0x0060                  ;; Bus Mouse port

;;--------------------------------------------------------------------------
int0B_handler:          int 0x74                        ;; Vector to official mouse interrupt
                        iret

;;--------------------------------------------------------------------------
int74_handler:          PUSHALL                         ;; same as push ax cx dx bx bp si di (or pusha on 286)
                        push    ds                      ;; save DS
                        xor     ax, ax                  ;; Get BDA Segment (0x0000)
                        mov     ds, ax                  ;; Set data segment to BDA
                        mov     ax, word ptr ds:0x040E  ;; Get the EBDA segment
                        mov     ds, ax                  ;; Set data segment to EBDA
                                                        ;; ds = ebda seg now, so now we can do mouse stuff
                        mov     dx, MOUSE_PORT          ;; load address of mouse port
                        in      al, dx                  ;; Get input byte
                        mov     bl, byte ptr ds:0x26    ;; Get current packet counter (and other flags)
                        mov     dl, bl                  ;; Save it as is with other flags in dl
                        and     bx, 0x07                ;; mask off upper bits in bx so we can use it as an index
                        mov     byte ptr ds:[0x28+bx],al ; Save the input byte into circular buffer
                        inc     dl                      ;; Increment packet counter by 1 (preserving other junk)
                        mov     byte ptr ds:0x26,dl     ;; Save new packet count in it's little place
                        inc     bl                      ;; Add 1 for the compare coming up
                        mov     cl, byte ptr ds:0x27    ;; Get packet size for this mousey (it is almost always 3)
                        and     cl, 0x07                ;; Mask off upper bits so we can do a comparison
                        cmp     cl, bl                  ;; Compare the numbers cl>bl (cl - bl) = !ZF
                        jg      int74_done              ;; If cl > bl, then we are done for now  
                        xor     bl, bl                  ;; Otherwise we have a complete packet so, Clear the count
                        mov     byte ptr ds:0x26, bl    ;; Save new packet count which is now 0
                                                        ;; -Make far call to driver
                        mov     cl, byte ptr ds:0x27    ;; Check to see if driver is loaded
                        and     cl, 0x80                ;; Ss the flag set ? (driver sets this)
                        jz      int74_done              ;; If set, then get ready to do the far call, otherwise exit
                        xor     ax,ax                   ;; Clear upper byte (this is probably not necessary)
                        mov     al, byte ptr ds:0x28    ;; Status  argument (button presses)
                        push    ax                      ;; Push argument onto stack 
                        mov     al, byte ptr ds:0x29    ;; X argument
                        push    ax                      ;; Push argument onto stack 
                        mov     al, byte ptr ds:0x2A    ;; Y argument
                        push    ax                      ;; Push argument onto stack 
                        xor     ax,ax                   ;; Z = 0, this is a dummy argument, no idea what is for
                        push    ax                      ;; Push argument onto stack 
                        call    far ptr ds:[0022h]      ;; call far routine (call_Ep DS:0022 :opcodes 0xff, 0x1e, 0x22, 0x00)
                        add     sp, 8                   ;; pop status, x, y, z
                                                        ;; -End of far call
int74_done:             cli
						mov		al, NSEOI				;; Load Non Specific End Of Interrupt
						out		PICS, al				;; Slave Pic EOI
						out		PICM, al				;; Master Pic EOI
						;
						pop     ds                      ;; restore DS
                        POPALL                          ;; same as popa on 286
                        iret                            ;; Return from interrupt
  
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT09h : Keyboard Hardware Service Entry Point -
;; This is a hardware interupt service routine. This is called whenever
;; a key stroke is registered, the cpu calls this and we place the key stroke
;; in a small circular buffer down in the BDA. All the work is done using the 
;; C helper function int09_function()
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0e987h - startofrom)
int09_handler:          cli                         ;; Clear interupt enable flag
                        push    ax                  ;; Save the AX register      
                        in      al, 060h            ;; read key from keyboard controller
                        sti                         ;; Enable interupts again
                        push    ds                  ;; next pushes 6 equivalent of pusha
                        push    cx                  ;; Save all register contents
                        push    dx                  ;; Onto the stack
                        push    bx                  ;;
                        push    bp                  ;;
                        push    si                  ;;
                        push    di                  ;;
                        
                        cmp     al, 0e0h            ;; check for extended key
                        jne     int09_check_pause   ;; check if the pause key pressed
                        xor     ax, ax                      ;; Clear the ax register
                        mov     ds, ax                      ;; Load the data segment reg with 0
                        mov     al, BYTE PTR ds:[0496h]     ;; mf2_state |= 0x02
                        or      al, 002h                    ;; set bit 2
                        mov     BYTE PTR ds:[0496h], al     ;; Store in correct key buf location
                        jmp     int09_done                  ;; Leave this routine

int09_check_pause:      cmp     al, 0e1h                    ;; check for pause key
                        jne     int09_process_key           ;; Pause was not pressed
                        xor     ax, ax                      ;; Pause was pressed
                        mov     ds, ax                      ;; Load the data segment reg with 0
                        mov     al, BYTE PTR ds:[0496h]     ;; mf2_state |= 0x01
                        or      al, 001h                    ;; Set bit 1
                        mov     BYTE PTR ds:[0496h], al     ;; Store in correct key buf location
                        jmp     int09_done                  ;; Leave this routine

int09_process_key:      mov     bx, 0f000h                  ;; Load the Data seg register with
                        mov     ds, bx                      ;; The bios segment location
                        push    ax                          ;; Push AX onto stack to pass that parameter 
                        call    _int09_function             ;; To the C program on the stack
                        pop     ax                          ;; Restore the stack
                            
int09_done:             cli                         ;; Clear interupt enable flag
						mov		al, NSEOI				;; Load Non Specific End Of Interrupt
						out		PICM, al				;; Master Pic EOI
						;
						pop     di                  ;; Retore all the saved registers
                        pop     si                  ;; That were saved on entry
                        pop     bp                  ;;
                        pop     bx                  ;;
                        pop     dx                  ;;
                        pop     cx                  ;;
                        pop     ds                  ;;
                        pop     ax                  ;;  
                        iret                        ;; Return from interupt

;;---------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Diskette parameter table adding 3 parameters from IBM Since no
;; provisions are made for multiple drive types, most values in this
;; table are ignored. set parameters for 1.44M floppy here. This table is 
;; located here for compatibility purposes but is only accessed by the C
;; helper function int13_diskette_function() which returns this location to 
;; the int13 caller if AH=08.
;;---------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0efc7h - startofrom)  ; IBM entry for disk param
int1E_table:            db      0xAF                   ; Disk parameter table
                        db      0x02       ;; head load time 0000001, DMA used 
                        db      0x25
                        db      0x02
                        db        18
                        db      0x1B
                        db      0xFF
                        db      0x6C
                        db      0xF6
                        db      0x0F
                        db      0x08
                        db        79       ;; maximum track      
                        db         0       ;; data transfer rate 
                        db         4       ;; drive type in cmos                         
                        
                                               
;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; INT10h - Video Support Service Entry Point
;; This is here for stub puposes. The VGA bios will set this vector and
;; handle screen. In the original xt-bios, this would have had a character
;; based rudimentary screen function. 
;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------
                        org     (0f065h - startofrom)    
int10_handler:                                          ; dont do anything, since 
                        iret                            ; the VGA BIOS handles int10h requests

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT12h - ; INT 12h Memory Size Service Entry Point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0f841h - startofrom)   ; ??? different for Pentium (machine check)?
int12_handler:          push    ds
                        mov     ax, 0040h               ;; BDA segment address
                        mov     ds, ax                  ;; set data segment register
                        mov     ax, WORD PTR ds:[0013h] ;; get the memory block count
                        pop     ds
                        iret                            ;; return from interupt

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; INT11h -  INT 11h Equipment List Service Entry Point, 2 bytes Equipment Word 
;;           40:10  2 bytes  Equipment list flags (see INT 11)
;;
;;                |7|6|5|4|3|2|1|0| 40:10 (value in INT 11 register AL)
;;                 | | | | | | | `- IPL diskette installed
;;                 | | | | | | `-- math coprocessor
;;                 | | | | |-+--- old PC system board RAM < 256K
;;                 | | | | | `-- pointing device installed (PS/2)
;;                 | | | | `--- not used on PS/2
;;                 | | `------ initial video mode
;;                 `--------- # of diskette drives, less 1
;;
;;                |7|6|5|4|3|2|1|0| 40:11  (value in INT 11 register AH)
;;                 | | | | | | | `- 0 if DMA installed
;;                 | | | | `------ number of serial ports
;;                 | | | `------- game adapter
;;                 | | `-------- not used, internal modem (PS/2)
;;                 `----------- number of printer ports
;;
;; we should return 0000_0010 0100_0101 = 0205h
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0f84dh - startofrom)
int11_handler:          push    ds                      ;; save data segment register
                        mov     ax, 0040h               ;; BDA segment address
                        mov     ds, ax
                        mov     ax, WORD PTR ds:[0010h] ;; get equipment list pointer
                        pop     ds
                        iret

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;;  INT15h - System Services Entry Point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0f859h - startofrom)
int15_handler:          sti                             ;; Disable interrupts
                        push    ds                      ;; Save data segment
                        push    es                      ;; Save Extra segment
                        cmp     ah, 0x86                ;; Compare to 0x86
                        je      int15_handler32_ret     ;; We got no support for that
                        cmp     ah, 0xE8                ;; Compare to 0xE8 command
                        je      int15_handler32_ret     ;; We got no support for that
                        PUSHALL                         ;; Same as push ax cx dx bx bp si di
                        cmp     ah, 0xC2                ;; PS2 Mouse commands
                        je      int15_handle_mouse      ;; Handle mouse events
                        call    _int15_function         ;; Some other INT15 command 
                        jmp     int15_return            ;; All done
int15_handle_mouse:     call    _int15_function_mouse   ;; USE PS2 MOUSE
int15_return:           POPALL                          ;; Same as pop di si bp bx dx cx ax
int15_handler32_ret:    pop     es                      ;; Restore
                        pop     ds                      ;; Restore
                        cli                             ;; Enale interrupts
                        iret                            ;; Return from Interrupt

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; - INT1Ah - INT 1Ah Time-of-day Service Entry Point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0fe6eh - startofrom)    
int1a_handler:          push    ds                      ;; Save all registers that
                        push    bx                      ;; on return
                        push    bp                      ;; Save Base Pointer
                        push    si                      ;; Save segment index
                        push    di                      ;; Save data index
                        push    dx                      ;; for the C program to receive
                        push    cx                      ;; for the C program to receive
                        push    ax                      ;; Pass the user command
                        call    _int1a_function         ;; Now call the function
                        pop     ax                      ;; Now restor the stack
                        pop     cx                      ;; 
                        pop     dx                      ;;
                        pop     di                      ;; Now restore all the saved
                        pop     si                      ;; registers from above
                        pop     bp                      ;; The next section insures that this
                        pop     bx                      ;; routines returns with the Zero Flag
                        pop     ds                      ;; Set correctly
                        iret            ;; IRET Instruction for Dummy Interrupt Handler

;;--------------------------------------------------------------------------
;; INT 1C Dummy Handler routing
;;--------------------------------------------------------------------------
int1c_handler:                          ;; re-vectored by users later 
                        iret            ;; IRET Instruction for Dummy Interrupt Handler

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; - INT08 -  System Timer ISR Entry Point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        org     (0fea5h - startofrom)     
int08_handler:          sti
                        push    ax
                        push    bx
                        push    ds
                        xor     ax, ax
                        mov     ds, ax
                        mov     ax, WORD PTR ds:046ch    ;; get ticks dword
                        mov     bx, WORD PTR ds:046eh    ;; get ticks dword
                        inc     ax
                        jne     i08_linc_done
                        inc     bx            ;; inc high word
i08_linc_done:          push    bx 
                        sub     bx, 0018h ;; compare eax to one days worth of timer ticks at 18.2 hz
                        jne     i08_lcmp_done
                        cmp     ax, 00B0h
                        jb      i08_lcmp_b_and_lt
                        jge     i08_lcmp_done
                        inc     bx
                        jmp     i08_lcmp_done
i08_lcmp_b_and_lt:      dec     bx
i08_lcmp_done:          pop     bx
                        jb      int08_store_ticks    ;; there has been a midnight rollover at this point
                        xor     ax, ax               ;; zero out counter
                        xor     bx, bx
                        inc     BYTE PTR ds:0470h     ;; increment rollover flag
int08_store_ticks:      mov     WORD PTR ds:046ch, ax           ;; store new ticks dword
                        mov     WORD PTR ds:046eh, bx
                        int     01ch
						;
                        cli
						mov		al, NSEOI				;; Load Non Specific End Of Interrupt
						out		PICM, al				;; Master Pic EOI
						;
                        pop     ds        ;; call eoi_master_pic
                        pop     bx
                        pop     ax
                        iret

;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;;
;; S H A D O W      B O O T      S E C T I O N:
;;
;; This is the only section of the bios that will reside in the ROM. The rest
;; of the BIOS is loaded into DRAM by this section of code prior to POST.
;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------

;; BIOS Strings: These strings are not actually used for anything, they are
;; placed in the file so that the binary file can be identified later.
                        org     (0ff00h - startofrom)

BIOS_COPYRIGHT_STRING equ     "Zet Bios 1.1 (C) 2010 Zeus Gomez Marmolejo, Donna Polehn"
MSG1:                   db      BIOS_COPYRIGHT_STRING
                        db      0

;; IRET Instruction for Dummy Interrupt Handler -
;; Also INT1C - User Timer Tick and INT1B
                        org     (0ff53h - startofrom)
dummy_iret_handler:     iret            ;; IRET Instruction for Dummy Interrupt Handler
                        db      0

;;--------------------------------------------------------------------------
;; First we have to prepare DRAM for use:
;;--------------------------------------------------------------------------
SDRAM_POST:             xor     ax, ax          ; Clear AX register
                        cli                     ; Disable interupt for startup
						
						POSTCODE 000h			; PostCode = 00
						
                        mov     dx, 0f200h      ; CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_BYPASS|HPDMC_SYSTEM_RESET|HPDMC_SYSTEM_CKE;
                        mov     ax, 7           ; Bring CKE high
                        out     dx, ax          ; Initialize the SDRAM controller
                        mov     dx, 0f202h      ; Precharge All
                        mov     ax, 0400bh      ; CSR_HPDMC_BYPASS = 0x400B;
                        out     dx, ax          ; Output the word of data to the SDRAM Controller
                        mov     ax, 0000dh      ; CSR_HPDMC_BYPASS = 0xD;
                        out     dx, ax          ; Auto refresh
                        mov     ax, 0000dh      ; CSR_HPDMC_BYPASS = 0xD;
                        out     dx, ax          ; Auto refresh
                        mov     ax, 023fh       ; CSR_HPDMC_BYPASS = 0x23F;
                        out     dx, ax          ; Load Mode Register, Enable DLL
                        mov     cx, 50          ; Wait about 200 cycles
a_delay:                loop    a_delay         ; Loop until 50 goes to zero
                        mov     dx, 0f200h      ; CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_CKE;
                        mov     ax, 4           ; Leave Bypass mode and bring up hardware controller
                        out     dx, ax          ; Output the word of data to the SDRAM Controller

                        mov     ax, 0fffeh      ; We are done with the controller, we can use the memory now
                        mov     sp, ax          ; set the stack pointer to fffe (top)
                        xor     ax, ax          ; clear ax register
                        mov     ds, ax          ; set data segment to 0
                        mov     ss, ax          ; set stack segment to 0

;;--------------------------------------------------------------------------
;; Copy Shadow BIOS from Flash into SDRAM after SDRAM has been initialized
;;---------------------------------------------------------------------------
FLASH_PORT              equ     0x0238                  ;; Flash RAM port
VGABIOSSEGMENT          equ     0xC000                  ;; VGA BIOS Segment
VGABIOSLENGTH           equ     0x4000                  ;; Length of VGA Bios in Words
ROMBIOSSEGMENT          equ     0xF000                  ;; ROM BIOS Segment
ROMBIOSLENGTH           equ     0x7F80                  ;; Copy up to this ROM in Words

;;--------------------------------------------------------------------------
shadowcopy:				POSTCODE 001h					; PostCode = 01
						mov     ax, VGABIOSSEGMENT      ;; Load with the segment of the vga bios rom area
                        mov     es, ax                  ;; BIOS area segment
                        xor     bp, bp                  ;; Bios starts at offset address 0
                        mov     cx, VGABIOSLENGTH       ;; VGA Bios is <32K long
                        mov     dx, FLASH_PORT+2        ;; Set DX reg to FLASH IO port
                        mov     ax, 0x0000              ;; Load MSB address
                        out     dx, ax                  ;; Save MSB address word
                        mov     bx, 0x0000              ;; Bios starts at offset address 0
                        call    biosloop                ;; Call bios IO loop

;;--------------------------------------------------------------------------
						POSTCODE 002h					; PostCode = 02
                        mov     ax, ROMBIOSSEGMENT      ;; Load with the segment of the extra bios rom area
                        mov     es, ax                  ;; BIOS area segment
                        xor     bp, bp                  ;; Bios starts at offset address 0
                        mov     cx, ROMBIOSLENGTH       ;; Bios is 64K long - Showdow rom len
                        mov     dx, FLASH_PORT+2        ;; Set DX reg to FLASH IO port
                        mov     ax, 0x0000              ;; Load start address
                        out     dx, ax                  ;; Save MSB address word
                        mov     bx, 0x8000              ;; Bios starts at offset address 0x8000
                        call    biosloop                ;; Call bios IO loop

						POSTCODE 003h					; PostCode = 03
                        jmp     far ptr post            ;; Continue with regular POST

;;--------------------------------------------------------------------------
biosloop:               mov     ax, bx                  ;; Put bx into ax
                        mov     dx, FLASH_PORT          ;; Set DX reg to FLASH IO port
                        out     dx, ax                  ;; Save LSB address word
                        mov     dx, FLASH_PORT          ;; Set DX reg to FLASH IO port
                        in      ax, dx                  ;; Get input word into ax register
                        mov     word ptr es:[bp], ax    ;; Save that word to next place in RAM
                        inc     bp                      ;; Increment to next address location
                        inc     bp                      ;; Increment to next address location
                        inc     bx                      ;; Increment to next flash address location
                        loop    biosloop                ;; Loop until bios is loaded up
                        ret                             ;; Return
;;--------------------------------------------------------------------------

;;---------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; MAIN BIOS Entry Point:  
;; on Reset - Processor starts at this location. This is the first instruction
;; that gets executed on start up. So we just immediately jump to the entry
;; Point for the Bios which is the POST (which stands for Power On Self Test).
                        org     (0fff0h - startofrom)   ;; Power-up Entry Point
                        jmp     far ptr SDRAM_POST      ;; Boot up bios

                        org     (0fff5h - startofrom)   ;; ASCII Date ROM was built - 8 characters in MM/DD/YY
BIOS_BUILD_DATE         equ     "09/09/10\n"
MSG2:                   db      BIOS_BUILD_DATE

                        org     (0fffeh -startofrom)    ;; Put the SYS_MODEL_ID
                        db      SYS_MODEL_ID            ;; here
                        db      0

_BIOSSEG                ends                    ;; End of code segment
                        end             bootrom ;; End of this program
