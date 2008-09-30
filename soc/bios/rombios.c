// ROM BIOS compatability entry points:
// ===================================
// $e05b ; POST Entry Point
// $e6f2 ; INT 19h Boot Load Service Entry Point
// $f045 ; INT 10 Functions 0-Fh Entry Point
// $f065 ; INT 10h Video Support Service Entry Point
// $f0a4 ; MDA/CGA Video Parameter Table (INT 1Dh)
// $fff0 ; Power-up Entry Point
// $fff5 ; ASCII Date ROM was built - 8 characters in MM/DD/YY
// $fffe ; System Model ID

   /* model byte 0xFC = AT */
#define SYS_MODEL_ID     0xFC

#ifndef BIOS_BUILD_DATE
#  define BIOS_BUILD_DATE "06/23/99"
#endif

  // 1K of base memory used for Extended Bios Data Area (EBDA)
  // EBDA is used for PS/2 mouse support, and IDE BIOS, etc.
#define EBDA_SEG           0x9FC0
#define EBDA_SIZE          1              // In KiB
#define BASE_MEM_IN_K   (640 - EBDA_SIZE)

// This is for compiling with gcc2 and gcc3
#define ASM_START #asm
#define ASM_END #endasm

ASM_START
.rom

.org 0x0000

use16 8086

static void           int19_function();

static char bios_svn_version_string[] = "$Revision$ $Date$";

//--------------------------------------------------------------------------
// print_bios_banner
//   displays a the bios version
//--------------------------------------------------------------------------
void
print_bios_banner()
{
  printf("Zet BIOS - build: %s\n%s\n",
    BIOS_BUILD_DATE, bios_svn_version_string);
}

;----------
;- INT18h -
;----------
int18_handler: ;; Boot Failure recovery: try the next device.

  ;; Reset SP and SS
  mov  ax, #0xfffe
  mov  sp, ax
  xor  ax, ax
  mov  ss, ax

  ;; Get the boot sequence number out of the IPL memory
  mov  bx, #IPL_SEG
  mov  ds, bx                     ;; Set segment
  mov  bx, IPL_SEQUENCE_OFFSET    ;; BX is now the sequence number
  inc  bx                         ;; ++
  mov  IPL_SEQUENCE_OFFSET, bx    ;; Write it back
  mov  ds, ax                     ;; and reset the segment to zero.

  ;; Carry on in the INT 19h handler, using the new sequence number
  push bx

  jmp  int19_next_boot

;----------
;- INT19h -
;----------
int19_relocated: ;; Boot function, relocated

  ;; int19 was beginning to be really complex, so now it
  ;; just calls a C function that does the work

  push bp
  mov  bp, sp

  ;; Reset SS and SP
  mov  ax, #0xfffe
  mov  sp, ax
  xor  ax, ax
  mov  ss, ax

  ;; Start from the first boot device (0, in AX)
  mov  bx, #IPL_SEG
  mov  ds, bx                     ;; Set segment to write to the IPL memory
  mov  IPL_SEQUENCE_OFFSET, ax    ;; Save the sequence number
  mov  ds, ax                     ;; and reset the segment.

  push ax

int19_next_boot:

  ;; Call the C code for the next boot device
  call _int19_function

  ;; Boot failed: invoke the boot recovery function
  int  #0x18

;--------------------
;- POST: EBDA segment
;--------------------
; relocated here because the primary POST area isnt big enough.
ebda_post:
#if BX_USE_EBDA
  mov ax, #EBDA_SEG
  mov ds, ax
  mov byte ptr [0x0], #EBDA_SIZE
#endif
  xor ax, ax            ; mov EBDA seg into 40E
  mov ds, ax
  mov word ptr [0x40E], #EBDA_SEG
  ret;;

rom_checksum:
  push ax
  push bx
  push cx
  xor  ax, ax
  xor  bx, bx
  xor  cx, cx
  mov  ch, [2]
  shl  cx, #1
checksum_loop:
  add  al, [bx]
  inc  bx
  loop checksum_loop
  and  al, #0xff
  pop  cx
  pop  bx
  pop  ax
  ret


;; We need a copy of this string, but we are not actually a PnP BIOS,
;; so make sure it is *not* aligned, so OSes will not see it if they scan.
.align 16
  db 0
pnp_string:
  .ascii "$PnP"


rom_scan:
  ;; Scan for existence of valid expansion ROMS.
  ;;   Video ROM:   from 0xC0000..0xC7FFF in 2k increments
  ;;   General ROM: from 0xC8000..0xDFFFF in 2k increments
  ;;   System  ROM: only 0xE0000
  ;;
  ;; Header:
  ;;   Offset    Value
  ;;   0         0x55
  ;;   1         0xAA
  ;;   2         ROM length in 512-byte blocks
  ;;   3         ROM initialization entry point (FAR CALL)

rom_scan_loop:
  push ax       ;; Save AX
  mov  ds, cx
  mov  ax, #0x0004 ;; start with increment of 4 (512-byte) blocks = 2k
  cmp [0], #0xAA55 ;; look for signature
  jne  rom_scan_increment
  call rom_checksum
  jnz  rom_scan_increment
  mov  al, [2]  ;; change increment to ROM length in 512-byte blocks

  ;; We want our increment in 512-byte quantities, rounded to
  ;; the nearest 2k quantity, since we only scan at 2k intervals.
  test al, #0x03
  jz   block_count_rounded
  and  al, #0xfc ;; needs rounding up
  add  al, #0x04
block_count_rounded:

  xor  bx, bx   ;; Restore DS back to 0000:
  mov  ds, bx
  push ax       ;; Save AX
  push di       ;; Save DI
  ;; Push addr of ROM entry point
  push cx       ;; Push seg
  push #0x0003  ;; Push offset

  ;; Point ES:DI at "$PnP", which tells the ROM that we are a PnP BIOS.
  ;; That should stop it grabbing INT 19h; we will use its BEV instead.
  mov  ax, #0xf000
  mov  es, ax
  lea  di, pnp_string

  mov  bp, sp   ;; Call ROM init routine using seg:off on stack
  db   0xff     ;; call_far ss:[bp+0]
  db   0x5e
  db   0
  cli           ;; In case expansion ROM BIOS turns IF on
  add  sp, #2   ;; Pop offset value
  pop  cx       ;; Pop seg value (restore CX)

  ;; Look at the ROM's PnP Expansion header.  Properly, we're supposed
  ;; to init all the ROMs and then go back and build an IPL table of
  ;; all the bootable devices, but we can get away with one pass.
  mov  ds, cx       ;; ROM base
  mov  bx, 0x001a   ;; 0x1A is the offset into ROM header that contains...
  mov  ax, [bx]     ;; the offset of PnP expansion header, where...
  cmp  ax, #0x5024  ;; we look for signature "$PnP"
  jne  no_bev
  mov  ax, 2[bx]
  cmp  ax, #0x506e
  jne  no_bev
  mov  ax, 0x1a[bx] ;; 0x1A is also the offset into the expansion header of...
  cmp  ax, #0x0000  ;; the Bootstrap Entry Vector, or zero if there is none.
  je   no_bev

  ;; Found a device that thinks it can boot the system.  Record its BEV and product name string.
  mov  di, 0x10[bx]            ;; Pointer to the product name string or zero if none
  mov  bx, #IPL_SEG            ;; Go to the segment where the IPL table lives
  mov  ds, bx
  mov  bx, IPL_COUNT_OFFSET    ;; Read the number of entries so far
  cmp  bx, #IPL_TABLE_ENTRIES
  je   no_bev                  ;; Get out if the table is full
  shl  bx, #0x4                ;; Turn count into offset (entries are 16 bytes)
  mov  0[bx], #IPL_TYPE_BEV    ;; This entry is a BEV device
  mov  6[bx], cx               ;; Build a far pointer from the segment...
  mov  4[bx], ax               ;; and the offset
  cmp  di, #0x0000
  je   no_prod_str
  mov  0xA[bx], cx             ;; Build a far pointer from the segment...
  mov  8[bx], di               ;; and the offset
no_prod_str:
  shr  bx, #0x4                ;; Turn the offset back into a count
  inc  bx                      ;; We have one more entry now
  mov  IPL_COUNT_OFFSET, bx    ;; Remember that.

no_bev:
  pop  di       ;; Restore DI
  pop  ax       ;; Restore AX
rom_scan_increment:
  shl  ax, #5   ;; convert 512-bytes blocks to 16-byte increments
                ;; because the segment selector is shifted left 4 bits.
  add  cx, ax
  pop  ax       ;; Restore AX
  cmp  cx, ax
  jbe  rom_scan_loop

  xor  ax, ax   ;; Restore DS back to 0000:
  mov  ds, ax
  ret

;; for 'C' strings and other data, insert them here with
;; a the following hack:
;; DATA_SEG_DEFS_HERE


;; the following area can be used to write dynamically generated tables
  .align 16
bios_table_area_start:
  dd 0xaafb4442
  dd bios_table_area_end - bios_table_area_start - 8;

;--------
;- POST -
;--------
.org 0xe05b ; POST Entry Point
post:

  xor ax, ax

normal_post:
  ; case 0: normal startup

  cli
  mov  ax, #0xfffe
  mov  sp, ax
  xor  ax, ax
  mov  ds, ax
  mov  ss, ax

  ;; zero out BIOS data area (40:00..40:ff)
  mov  es, ax
  mov  cx, #0x0080 ;; 128 words
  mov  di, #0x0400
  cld
  rep
    stosw

  ;; set all interrupts to default handler
  xor  bx, bx         ;; offset index
  mov  cx, #0x0100    ;; counter (256 interrupts)
  mov  ax, #dummy_iret_handler
  mov  dx, #0xF000

post_default_ints:
  mov  [bx], ax
  add  bx, #2
  mov  [bx], dx
  add  bx, #2
  loop post_default_ints

  ;; set vector 0x79 to zero
  ;; this is used by 'gardian angel' protection system
  SET_INT_VECTOR(0x79, #0, #0)

  ;; base memory in K 40:13 (word)
  mov  ax, #BASE_MEM_IN_K
  mov  0x0413, ax


  ;; Manufacturing Test 40:12
  ;;   zerod out above

  ;; Warm Boot Flag 0040:0072
  ;;   value of 1234h = skip memory checks
  ;;   zerod out above

  ;; Bootstrap failure vector
  SET_INT_VECTOR(0x18, #0xF000, #int18_handler)

  ;; Bootstrap Loader vector
  SET_INT_VECTOR(0x19, #0xF000, #int19_handler)

  ;; EBDA setup
  call ebda_post

  ;; Video setup
  SET_INT_VECTOR(0x10, #0xF000, #int10_handler)

  mov  cx, #0xc000  ;; init vga bios
  mov  ax, #0xc780
  call rom_scan

  call _print_bios_banner

  call _init_boot_vectors

  mov  cx, #0xc800  ;; init option roms
  mov  ax, #0xe000
  call rom_scan

  sti        ;; enable interrupts
  int  #0x19

;----------
;- INT19h -
;----------
.org 0xe6f2 ; INT 19h Boot Load Service Entry Point
int19_handler:

  jmp int19_relocated

.org 0xf045 ; INT 10 Functions 0-Fh Entry Point
  ;; HALT(__LINE__)
  iret

;----------
;- INT10h -
;----------
.org 0xf065 ; INT 10h Video Support Service Entry Point
int10_handler:
  ;; dont do anything, since the VGA BIOS handles int10h requests
  iret

.org 0xf0a4 ; MDA/CGA Video Parameter Table (INT 1Dh)

;------------------------------------------------
;- IRET Instruction for Dummy Interrupt Handler -
;------------------------------------------------
.org 0xff53 ; IRET Instruction for Dummy Interrupt Handler
dummy_iret_handler:
  iret

.org 0xfff0 ; Power-up Entry Point
  jmp 0xf000:post

.org 0xfff5 ; ASCII Date ROM was built - 8 characters in MM/DD/YY
.ascii BIOS_BUILD_DATE

.org 0xfffe ; System Model ID
db SYS_MODEL_ID
db 0x00   ; filler

ASM_START
.org 0xcc00
bios_table_area_end:
// bcc-generated data will be placed here
ASM_END
