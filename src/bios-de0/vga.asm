;
;  Zet PC system VGA BIOS helper functions in 8086 assembly
;  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
;   ported to Open Watcom compiler by Donna Polehn <dpolehn@verizon.net>
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

;; $0000 ; Signature
;; $0003 ; Entry Point
;;--------------------------------------------------------------------------

;;--------------------------------------------------------------------------
;; BIOS constant definitions
;;--------------------------------------------------------------------------
BIOSMEM_SEG                     equ     0x40
BIOSMEM_INITIAL_MODE            equ     0x10
BIOSMEM_CURRENT_MODE            equ     0x49
BIOSMEM_NB_COLS                 equ     0x4A
BIOSMEM_PAGE_SIZE               equ     0x4C
BIOSMEM_CURRENT_START           equ     0x4E
BIOSMEM_CURSOR_POS              equ     0x50
BIOSMEM_CURSOR_TYPE             equ     0x60
BIOSMEM_CURRENT_PAGE            equ     0x62
BIOSMEM_CRTC_ADDRESS            equ     0x63
BIOSMEM_CURRENT_MSR             equ     0x65
BIOSMEM_CURRENT_PAL             equ     0x66
BIOSMEM_NB_ROWS                 equ     0x84
BIOSMEM_CHAR_HEIGHT             equ     0x85
BIOSMEM_VIDEO_CTL               equ     0x87
BIOSMEM_SWITCHES                equ     0x88
BIOSMEM_MODESET_CTL             equ     0x89
BIOSMEM_DCC_INDEX               equ     0x8A
BIOSMEM_VS_POINTER              equ     0xA8
BIOSMEM_VBE_FLAG                equ     0xB9
BIOSMEM_VBE_MODE                equ     0xBA

;;--------------------------------------------------------------------------
;; VGA registers
;;--------------------------------------------------------------------------
VGAREG_ACTL_ADDRESS             equ     0x3c0
VGAREG_ACTL_WRITE_DATA          equ     0x3c0
VGAREG_ACTL_READ_DATA           equ     0x3c1
VGAREG_INPUT_STATUS             equ     0x3c2
VGAREG_WRITE_MISC_OUTPUT        equ     0x3c2
VGAREG_VIDEO_ENABLE             equ     0x3c3
VGAREG_SEQU_ADDRESS             equ     0x3c4
VGAREG_SEQU_DATA                equ     0x3c5
VGAREG_PEL_MASK                 equ     0x3c6
VGAREG_DAC_STATE                equ     0x3c7
VGAREG_DAC_READ_ADDRESS         equ     0x3c7
VGAREG_DAC_WRITE_ADDRESS        equ     0x3c8
VGAREG_DAC_DATA                 equ     0x3c9
VGAREG_READ_FEATURE_CTL         equ     0x3ca
VGAREG_READ_MISC_OUTPUT         equ     0x3cc
VGAREG_GRDC_ADDRESS             equ     0x3ce
VGAREG_GRDC_DATA                equ     0x3cf
VGAREG_MDA_CRTC_ADDRESS         equ     0x3b4
VGAREG_MDA_CRTC_DATA            equ     0x3b5
VGAREG_VGA_CRTC_ADDRESS         equ     0x3d4
VGAREG_VGA_CRTC_DATA            equ     0x3d5
VGAREG_MDA_WRITE_FEATURE_CTL    equ     0x3ba
VGAREG_VGA_WRITE_FEATURE_CTL    equ     0x3da
VGAREG_ACTL_RESET               equ     0x3da
VGAREG_MDA_MODECTL              equ     0x3b8
VGAREG_CGA_MODECTL              equ     0x3d8
VGAREG_CGA_PALETTE              equ     0x3d9

;;--------------------------------------------------------------------------
;;  Video memory 
;;--------------------------------------------------------------------------
VGAMEM_GRAPH                    equ     0xA000
VGAMEM_CTEXT                    equ     0xB800
VGAMEM_MTEXT                    equ     0xB000

;;--------------------------------------------------------------------------
;; ROM Utilities Externals
;;--------------------------------------------------------------------------
                EXTRN  _int10_func:proc      ; Contained in C source module
                EXTRN  _printf    :proc      ; Contained in C source module

;;--------------------------------------------------------------------------
;; Set vector macro
;;--------------------------------------------------------------------------
SET_INT_VECTOR MACRO parm1, parm2, parm3
                        push    ds
                        xor     ax, ax
                        mov     ds, ax
                        mov     ax, parm3
                        mov     ds:[parm1*4], ax
                        mov     ax, parm2
                        mov     ds:[parm1*4+2], ax
                        pop     ds
ENDM

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Start of ROM
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        .Model  Tiny    ;; this forces it to nears on code and data
                        .8086           ;; this forces it to use 8086 and lower
_VGASEG                 SEGMENT 'CODE'
                        assume  cs:_VGASEG
;;--------------------------------------------------------------------------
vgarom:                 org     0x0000         ;; start of ROM, get placed at 00000h
                        db      0x55, 0xaa     ;; BIOS signature, required for BIOS extensions 
                        db      0x40           ;; BIOS extension length in units of 512 bytes 
vgabios_entry_point:    jmp     vgabios_init_func
;;--------------------------------------------------------------------------
vgabios_name:           db      "Zet VGA bios "
                        db      0x00
                        org     0x001e
                        db      "IBM"
                        db      0x00
vgabios_version:        db      "Special Build "
vgabios_date:           db      "May 20, 2010"
                        db      0x0a,0x0d, 0x00
vgabios_copyright:      db      "(C) 2003 the LGPL VGABios developers Team"
                        db      0x0a,0x0d,0x00
vgabios_license:        db      "This VGA/VBE Bios is released under the GNU LGPL"
                        db      0x0a,0x0d,0x0a,0x0d,0x00
vgabios_website:        db      "Please visit :",0x0a,0x0d
                        db      "  http://zet.aluzina.org"
                        db      0x0a,0x0d
                        db      "  http://bochs.sourceforge.net"
                        db      0x0a,0x0d
                        db      "  http://www.nongnu.org/vgabios"
                        db      0x0a,0x0d,0x0a,0x0d,0x00
                        
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Init Entry point
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
vgabios_init_func:      
                        call    init_vga_card               ;; init vga card
                        call    init_bios_area              ;; init basic bios vars

           SET_INT_VECTOR 0x10, 0xC000, vgabios_int10_handler ;; set int10 vect
           
                        mov     ax,0x0003                   ;; init video mode and clear the screen
                        int     0x10
                        call    display_info                ;; show info
                        retf

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;;  int10 handled here
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
vgabios_int10_handler:  pushf
                        cmp     ah, 0x0f
                        jne     int10_test_1A
                        call    biosfn_get_video_mode
                        jmp     int10_end
int10_test_1A:          cmp     ah, 0x1a
                        jne     int10_test_1103
                        call    biosfn_group_1A
                        jmp     int10_end
int10_test_1103:        cmp     ax, 0x1103
                        jne     int10_test_101B
                        call    biosfn_set_text_block_specifier
                        jmp     int10_end
int10_test_101B:        cmp     ax, 0x101b
                        je      int10_normal
                        cmp     ah, 0x10
                        jne     int10_normal
                        call    biosfn_group_10
                        jmp     int10_end
int10_normal:           push    es
                        push    ds
                        push    ax          ;; these equivalent of pusha
                        push    cx
                        push    dx
                        push    bx
                        push    sp
                        mov     bx, sp
                        add     word ptr ss:[bx], 10
                        mov     bx, word ptr ss:[bx+2]
                        push    bp
                        push    si
                        push    di

                        mov     bx, 0xc000   ;; We have to set ds to access the right data segment
                        mov     ds, bx

                        call    _int10_func

                        pop     di           ;; These pop's equivalent of popa
                        pop     si
                        pop     bp
                        add     sp, 2
                        pop     bx
                        pop     dx
                        pop     cx
                        pop     ax
            
                        pop     ds
                        pop     es
int10_end:              popf
                        iret

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; Boot time harware inits
;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
init_vga_card:          mov     dx, 0x03C2  ;; switch to color mode and enable CPU access 480 lines
                        mov     al, 0xC3
                        out     dx, al
                        mov     dx, 0x03C4  ;; more than 64k 3C4/04
                        mov     al, 0x04
                        out     dx, al
                        mov     dx, 0x03C5
                        mov     al, 0x02
                        out     dx, al
if USE_BX_INFO
                        mov     bx, msg_vga_init
                        push    bx
                        call    _printf
endif
                        ret
;;--------------------------------------------------------------------------
msg_vga_init:           db      "VGABios $Id: vgabios.c,v 1.66 2006/07/10 07:47:51 vruppert Exp $"
                        db      0x0d, 0x0a,0x00
;;--------------------------------------------------------------------------

;;--------------------------------------------------------------------------
;;  Boot time bios area inits
;;--------------------------------------------------------------------------
init_bios_area:         push    ds
                        mov     ax, BIOSMEM_SEG
                        mov     ds, ax

                        mov     bx, BIOSMEM_INITIAL_MODE    ;; init detected hardware BIOS Area
                        mov     ax, [bx]
                        and     ax, 0xffcf

                        or      ax, 0x0020    ;; set 80x25 color (not clear from RBIL but usual)
                        mov     [bx], ax

                        mov     bx, BIOSMEM_CHAR_HEIGHT ;; Just for the first int10 find its children
                        mov     al, 0x10                ;; the default char height
                        mov     [bx], al

                        mov     bx, BIOSMEM_VIDEO_CTL   ;; Clear the screen
                        mov     al, 0x60
                        mov     [bx], al

                        mov     bx, BIOSMEM_SWITCHES    ;; Set the basic screen we have
                        mov     al, 0xf9
                        mov     [bx], al

                        mov     bx, BIOSMEM_MODESET_CTL ;; Set the basic modeset options
                        mov     al, 0x51
                        mov     [bx], al

                        mov     bx, BIOSMEM_CURRENT_MSR ;; Set the  default MSR
                        mov     al, 0x09
                        mov     [bx], al

                        pop     ds
                        ret

;;--------------------------------------------------------------------------
;;  Tell who we are
;;--------------------------------------------------------------------------
display_info:           mov     ax, 0xC000
                        mov     ds, ax
                        mov     si, near ptr vgabios_name 
                        call    display_string
                        mov     si, near ptr vgabios_version
                        call    display_string
                        mov     si, near ptr vgabios_license
                        call    display_string
                        mov     si, near ptr vgabios_website
                        call    display_string
                        ret

;;--------------------------------------------------------------------------
;; Display a string
;;--------------------------------------------------------------------------
display_string:         mov     ax, ds
                        mov     es, ax          ;; and to the extra segment
                        mov     di, si          ;; store the string index to data index
                        xor     cx, cx          ;; Clear the cx register
                        not     cx              ;; then make it all 1's
                        xor     al, al          ;; Clear al register
                        cld                     ;;
                        repne   scasb           ;;
                        not     cx
                        dec     cx

                        push    cx
                        mov     ax, 0x0300
                        mov     bx, 0x0000
                        int     0x10
                        pop     cx

                        mov     ax, 0x1301
                        mov     bx, 0x000b
                        mov     bp, si
                        int     0x10
                        ret

;;--------------------------------------------------------------------------
biosfn_get_video_mode:  push  ds
                        mov   ax, BIOSMEM_SEG
                        mov   ds, ax
                        push  bx
                        mov   bx, BIOSMEM_CURRENT_PAGE
                        mov   al, [bx]
                        pop   bx
                        mov   bh, al
                        push  bx
                        mov   bx, BIOSMEM_VIDEO_CTL
                        mov   ah, [bx]
                        and   ah, 0x80
                        mov   bx, BIOSMEM_CURRENT_MODE
                        mov   al, [bx]
                        or    al, ah
                        mov   bx, BIOSMEM_NB_COLS
                        mov   ah, [bx]
                        pop   bx
                        pop   ds
                        ret

;;--------------------------------------------------------------------------
biosfn_set_text_block_specifier:
                        push    ax
                        push    dx
                        mov     dx, VGAREG_SEQU_ADDRESS
                        mov     ah, bl
                        mov     al, 0x03
                        out     dx, ax
                        pop     dx
                        pop     ax
                        ret

;;--------------------------------------------------------------------------
biosfn_group_10:        cmp   al, 0x00
                        jne   int10_test_1001
                        jmp   biosfn_set_single_palette_reg
int10_test_1001:        cmp   al, 0x01
                        jne   int10_test_1002
                        jmp   biosfn_set_overscan_border_color
int10_test_1002:        cmp   al, 0x02
                        jne   int10_test_1003
                        jmp   biosfn_set_all_palette_reg
int10_test_1003:        cmp   al, 0x03
                        jne   int10_test_1007
                        jmp   biosfn_toggle_intensity
int10_test_1007:        cmp   al, 0x07
                        jne   int10_test_1008
                        jmp   biosfn_get_single_palette_reg
int10_test_1008:        cmp   al, 0x08
                        jne   int10_test_1009
                        jmp   biosfn_read_overscan_border_color
int10_test_1009:        cmp   al, 0x09
                        jne   int10_test_1010
                        jmp   biosfn_get_all_palette_reg
int10_test_1010:        cmp   al, 0x10
                        jne   int10_test_1012
                        jmp   biosfn_set_single_dac_reg
int10_test_1012:        cmp   al, 0x12
                        jne   int10_test_1013
                        jmp   biosfn_set_all_dac_reg
int10_test_1013:        cmp   al, 0x13
                        jne   int10_test_1015
                        jmp   biosfn_select_video_dac_color_page
int10_test_1015:        cmp   al, 0x15
                        jne   int10_test_1017
                        jmp   biosfn_read_single_dac_reg
int10_test_1017:        cmp   al, 0x17
                        jne   int10_test_1018
                        jmp   biosfn_read_all_dac_reg
int10_test_1018:        cmp   al, 0x18
                        jne   int10_test_1019
                        jmp   biosfn_set_pel_mask
int10_test_1019:        cmp   al, 0x19
                        jne   int10_test_101A
                        jmp   biosfn_read_pel_mask
int10_test_101A:        cmp   al, 0x1a
                        jne   int10_group_10_unknown
                        jmp   biosfn_read_video_dac_state
int10_group_10_unknown: ret

;;--------------------------------------------------------------------------
biosfn_set_single_palette_reg:
                        cmp     bl, 0x14
                        ja      no_actl_reg1
                        push    ax
                        push    dx
                        mov     dx, VGAREG_ACTL_RESET
                        in      al, dx
                        mov     dx, VGAREG_ACTL_ADDRESS
                        mov     al, bl
                        out     dx, al
                        mov     al, bh
                        out     dx, al
                        mov     al, 0x20
                        out     dx, al
                        pop     dx
                        pop     ax
no_actl_reg1:           ret

;;--------------------------------------------------------------------------
biosfn_set_overscan_border_color:
                        push    bx
                        mov     bl, 0x11
                        call    biosfn_set_single_palette_reg
                        pop     bx
                        ret

;;--------------------------------------------------------------------------
biosfn_set_all_palette_reg:
                        push    ax
                        push    bx
                        push    cx
                        push    dx
                        mov     bx, dx
                        mov     dx, VGAREG_ACTL_RESET
                        in      al, dx
                        mov     cl, 0x00
                        mov     dx, VGAREG_ACTL_ADDRESS
set_palette_loop:       mov     al, cl
                        out     dx, al
                        mov     al, es:[bx]
                        out     dx, al
                        inc     bx
                        inc     cl
                        cmp     cl, 0x10
                        jne     set_palette_loop
                        mov     al, 0x11
                        out     dx, al
                        mov     al, es:[bx]
                        out     dx, al
                        mov     al, 0x20
                        out     dx, al
                        pop     dx
                        pop     cx
                        pop     bx
                        pop     ax
                        ret

;;--------------------------------------------------------------------------
biosfn_toggle_intensity:
                        push    ax
                        push    bx
                        push    dx
                        push    cx
                        mov     dx, VGAREG_ACTL_RESET
                        in      al, dx
                        mov     dx, VGAREG_ACTL_ADDRESS
                        mov     al, 0x10
                        out     dx, al
                        mov     dx, VGAREG_ACTL_READ_DATA
                        in      al, dx
                        and     al, 0xf7
                        and     bl, 0x01
                        mov     cl, 3
                        shl     bl, cl
                        or      al, bl
                        mov     dx, VGAREG_ACTL_ADDRESS
                        out     dx, al
                        mov     al, 0x20
                        out     dx, al
                        pop     cx
                        pop     dx
                        pop     bx
                        pop     ax
                        ret

;;--------------------------------------------------------------------------
biosfn_get_single_palette_reg:
                        cmp   bl, 0x14
                        ja    no_actl_reg2
                        push  ax
                        push  dx
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, bl
                        out   dx, al
                        mov   dx, VGAREG_ACTL_READ_DATA
                        in    al, dx
                        mov   bh, al
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, 0x20
                        out   dx, al
                        pop   dx
                        pop   ax
no_actl_reg2:           ret

;;--------------------------------------------------------------------------
biosfn_read_overscan_border_color:
                        push  ax
                        push  bx
                        mov   bl, 0x11
                        call  biosfn_get_single_palette_reg
                        mov   al, bh
                        pop   bx
                        mov   bh, al
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_get_all_palette_reg:
                        push  ax
                        push  bx
                        push  cx
                        push  dx
                        mov   bx, dx
                        mov   cl, 0x00
get_palette_loop:       mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, cl
                        out   dx, al
                        mov   dx, VGAREG_ACTL_READ_DATA
                        in    al, dx
                        mov   es:[bx], al
                        inc   bx
                        inc   cl
                        cmp   cl, 0x10
                        jne   get_palette_loop
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, 0x11
                        out   dx, al
                        mov   dx, VGAREG_ACTL_READ_DATA
                        in    al, dx
                        mov   es:[bx], al
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, 0x20
                        out   dx, al
                        pop   dx
                        pop   cx
                        pop   bx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_set_single_dac_reg:
                        push    ax
                        push    dx
                        mov     dx, VGAREG_DAC_WRITE_ADDRESS
                        mov     al, bl
                        out     dx, al
                        mov     dx, VGAREG_DAC_DATA
                        pop     ax
                        push    ax
                        mov     al, ah
                        out     dx, al
                        mov     al, ch
                        out     dx, al
                        mov     al, cl
                        out     dx, al
                        pop     dx
                        pop     ax
                        ret

;;--------------------------------------------------------------------------
biosfn_set_all_dac_reg:
                        push  ax
                        push  bx
                        push  cx
                        push  dx
                        mov   dx, VGAREG_DAC_WRITE_ADDRESS
                        mov   al, bl
                        out   dx, al
                        pop   dx
                        push  dx
                        mov   bx, dx
                        mov   dx, VGAREG_DAC_DATA
set_dac_loop:           mov   al, es:[bx]
                        out   dx, al
                        inc   bx
                        mov   al, es:[bx]
                        out   dx, al
                        inc   bx
                        mov   al, es:[bx]
                        out   dx, al
                        inc   bx
                        dec   cx
                        jnz   set_dac_loop
                        pop   dx
                        pop   cx
                        pop   bx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_select_video_dac_color_page:
                        push  ax
                        push  bx
                        push  dx
                        push  cx
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, 0x10
                        out   dx, al
                        mov   dx, VGAREG_ACTL_READ_DATA
                        in    al, dx
                        and   bl, 0x01
                        jnz   set_dac_page
                        and   al, 0x7f
                        mov   cl, 7
                        shl   bh, cl
                        or    al, bh
                        mov   dx, VGAREG_ACTL_ADDRESS
                        out   dx, al
                        jmp   set_actl_normal
set_dac_page:           push  ax
                        mov   dx, VGAREG_ACTL_RESET
                        in    al, dx
                        mov   dx, VGAREG_ACTL_ADDRESS
                        mov   al, 0x14
                        out   dx, al
                        pop   ax
                        and   al, 0x80
                        jnz   set_dac_16_page
                        mov   cl, 2
                        shl   bh, cl
set_dac_16_page:        and   bh, 0x0f
                        mov   al, bh
                        out   dx, al
set_actl_normal:        mov   al, 0x20
                        out   dx, al
                        pop   cx
                        pop   dx
                        pop   bx
                        pop   ax
                        ret
                         
;;--------------------------------------------------------------------------
biosfn_read_single_dac_reg:
                        push  ax
                        push  dx
                        mov   dx, VGAREG_DAC_READ_ADDRESS
                        mov   al, bl
                        out   dx, al
                        pop   ax
                        mov   ah, al
                        mov   dx, VGAREG_DAC_DATA
                        in    al, dx
                        xchg  al, ah
                        push  ax
                        in    al, dx
                        mov   ch, al
                        in    al, dx
                        mov   cl, al
                        pop   dx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_read_all_dac_reg:
                        push  ax
                        push  bx
                        push  cx
                        push  dx
                        mov   dx, VGAREG_DAC_READ_ADDRESS
                        mov   al, bl
                        out   dx, al
                        pop   dx
                        push  dx
                        mov   bx, dx
                        mov   dx, VGAREG_DAC_DATA
read_dac_loop:          in    al, dx
                        mov   es:[bx], al
                        inc   bx
                        in    al, dx
                        mov   es:[bx], al
                        inc   bx
                        in    al, dx
                        mov   es:[bx], al
                        inc   bx
                        dec   cx
                        jnz   read_dac_loop
                        pop   dx
                        pop   cx
                        pop   bx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_set_pel_mask:
                        push  ax
                        push  dx
                        mov   dx, VGAREG_PEL_MASK
                        mov   al, bl
                        out   dx, al
                        pop   dx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_read_pel_mask:
                        push  ax
                        push  dx
                        mov   dx, VGAREG_PEL_MASK
                        in    al, dx
                        mov   bl, al
                        pop   dx
                        pop   ax
                        ret

;;--------------------------------------------------------------------------
biosfn_read_video_dac_state:
                        push    ax
                        push    dx
                        push   cx
                        mov    dx, VGAREG_ACTL_RESET
                        in     al, dx
                        mov    dx, VGAREG_ACTL_ADDRESS
                        mov    al, 0x10
                        out    dx, al
                        mov    dx, VGAREG_ACTL_READ_DATA
                        in     al, dx
                        mov    bl, al
                        mov    cl, 7
                        shr    bl, cl
                        mov    dx, VGAREG_ACTL_RESET
                        in     al, dx
                        mov    dx, VGAREG_ACTL_ADDRESS
                        mov    al, 0x14
                        out    dx, al
                        mov    dx, VGAREG_ACTL_READ_DATA
                        in     al, dx
                        mov    bh, al
                        and    bh, 0x0f
                        test   bl, 0x01
                        jnz    get_dac_16_page
                        mov    cl, 2
                        shr    bh, cl
get_dac_16_page:        mov    dx, VGAREG_ACTL_RESET
                        in     al, dx
                        mov    dx, VGAREG_ACTL_ADDRESS
                        mov    al, 0x20
                        out    dx, al
                        pop    cx
                        pop    dx
                        pop    ax
                        ret
                        
;;--------------------------------------------------------------------------
biosfn_group_1A:
                        cmp     al, 0x00
                        je      biosfn_read_display_code
                        cmp     al, 0x01
                        je      biosfn_set_display_code
                        ret
biosfn_read_display_code:
                        push    ds
                        push    ax
                        mov     ax, BIOSMEM_SEG
                        mov     ds, ax
                        mov     bx, BIOSMEM_DCC_INDEX
                        mov     al, [bx]
                        mov     bl, al
                        xor     bh, bh
                        pop     ax
                        mov     al, ah
                        pop     ds
                        ret
biosfn_set_display_code:
                        push    ds
                        push    ax
                        push    bx
                        mov     ax, BIOSMEM_SEG
                        mov     ds, ax
                        mov     ax, bx
                        mov     bx, BIOSMEM_DCC_INDEX
                        mov     [bx], al
                        pop     bx
                        pop     ax
                        mov     al, ah
                        pop     ds
                        ret

;;--------------------------------------------------------------------------
_VGASEG                 ends
                        end             vgarom
;;---------------------------------------------------------------------------

