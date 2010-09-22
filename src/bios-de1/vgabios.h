/*
 *  Zet PC system VGA BIOS header file
 *  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *   ported to Open Watcom compiler by Donna Polehn <dpolehn@verizon.net>
 *
 *  This file is part of the Zet processor. This program is free software;
 *  you can redistribute it and/or modify it under the terms of the GNU 
 *  General Public License as published by the Free Software Foundation;
 *  either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

#ifndef vgabios_h_included
#define vgabios_h_included

//---------------------------------------------------------------------------
// Type definitions
//---------------------------------------------------------------------------
typedef unsigned char  Bit8u;
typedef unsigned short Bit16u;
typedef unsigned long  Bit32u;
typedef unsigned short Boolean;

//---------------------------------------------------------------------------
// Macro Definitions
//---------------------------------------------------------------------------
#define SET_BYTL(parm, data) __asm { mov al, data} __asm { mov ss:parm, ax }
#define SET_AL(val8) SET_BYTL(rAX , val8)

#define GET_AL() ( rAX & 0x00ff )
#define GET_BL() ( rBX & 0x00ff )
#define GET_CL() ( rCX & 0x00ff )
#define GET_DL() ( rDX & 0x00ff )
#define GET_AH() ( rAX >> 8 )
#define GET_BH() ( rBX >> 8 )
#define GET_CH() ( rCX >> 8 )
#define GET_DH() ( rDX >> 8 )

#define SCROLL_DOWN     0
#define SCROLL_UP       1
#define NO_ATTR         2
#define WITH_ATTR       3

#define SCREEN_SIZE(x,y)        (((x*y*2)|0x00ff)+1)
#define SCREEN_MEM_START(x,y,p) ((((x*y*2)|0x00ff)+1)*p)
#define SCREEN_IO_START(x,y,p)  ((((x*y)|0x00ff)+1)*p)

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Function prototypes:
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
static void     biosfn_set_video_mode(Bit8u mode);
static void     biosfn_set_cursor_shape(Bit8u CH, Bit8u CL);
static void     biosfn_set_cursor_pos(Bit8u page, Bit16u cursor);
static void     biosfn_get_cursor_pos(Bit8u page, Bit16u *shape, Bit16u *pos);
static void     biosfn_set_active_page(Bit8u page);
static void     biosfn_scroll(Bit8u, Bit8u, Bit8u, Bit8u, Bit8u, Bit8u, Bit8u, Bit8u);
static void     biosfn_read_char_attr(Bit8u page, Bit16u *car);
static void     biosfn_write_char_attr(Bit8u car, Bit8u page, Bit8u attr, Bit16u count);
static void     biosfn_write_char_only(Bit8u car, Bit8u page, Bit8u attr, Bit16u count);
static void     biosfn_write_teletype(Bit8u car, Bit8u page, Bit8u attr, Bit8u flag);
static void     set_scan_lines(Bit8u lines);
static void     get_font_access();
static void     release_font_access();
static void     biosfn_load_text_8_16_pat(Bit8u AL, Bit8u BL);
static void     biosfn_write_string(Bit8u, Bit8u, Bit8u, Bit16u, Bit8u, Bit8u, Bit16u, Bit16u);
static Bit8u    find_vga_entry(Bit8u mode);


//---------------------------------------------------------------------------
// Prototypes for Utility Functions
//---------------------------------------------------------------------------
static Bit8u    inb(Bit16u port);
static Bit16u   inw(Bit16u port);
static void     outb(Bit16u port, Bit8u  val);
static void     outw(Bit16u port, Bit16u  val);
static Bit8u    read_byte(Bit16u s_segment, Bit16u s_offset);
static Bit16u   read_word(Bit16u s_segment, Bit16u s_offset);
static void     write_byte(Bit16u s_segment, Bit16u s_offset, Bit8u data);
static void     write_word(Bit16u s_segment, Bit16u s_offset, Bit16u data);
static Bit16u   get_SS();
static void     memsetb(Bit16u s_segment, Bit16u s_offset, Bit8u value, Bit16u count);
static void     memsetw(Bit16u s_segment, Bit16u s_offset, Bit16u value, Bit16u count);
static void     memcpyb(Bit16u d_segment, Bit16u d_offset, Bit16u s_segment, Bit16u s_offset, Bit16u count);
static void     memcpyw(Bit16u d_segment, Bit16u d_offset, Bit16u s_segment, Bit16u s_offset, Bit16u count);

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Exported Function prototypes:
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
void int10_func(Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);
void printf(Bit8u *s);     


//---------------------------------------------------------------------------
#endif
//---------------------------------------------------------------------------


