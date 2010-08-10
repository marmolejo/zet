/*
 *  Zet PC system BIOS header file
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

//---------------------------------------------------------------------------
// Zet Bios Header file
//---------------------------------------------------------------------------
#ifndef zetbios1H
#define zetbios1H
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
#define SHOW_INFO_MSGS          0
#define SHOW_INT15_DEBUG_MSGS   0
//---------------------------------------------------------------------------
#define BIOS_PRINTF_HALT     1
#define BIOS_PRINTF_SCREEN   2

#if     SHOW_INFO_MSGS 
        #define BIOS_PRINTF_INFO     BIOS_PRINTF_SCREEN
#else
        #define BIOS_PRINTF_INFO     4
#endif

#if     SHOW_INT15_DEBUG_MSGS 
        #define BIOS_INT15_DEBUG    BIOS_PRINTF_SCREEN
#else
        #define BIOS_INT15_DEBUG    8
#endif

#define BIOS_PRINTF_ALL      (BIOS_PRINTF_SCREEN | BIOS_PRINTF_INFO)
#define BIOS_PRINTF_DEBHALT  (BIOS_PRINTF_SCREEN | BIOS_PRINTF_INFO | BIOS_PRINTF_HALT)

#define printf(format,  ...)  bios_printf(BIOS_PRINTF_SCREEN, format, ## __VA_ARGS__)
#define BX_INFO(format,  ...)   bios_printf(BIOS_PRINTF_INFO, format, ## __VA_ARGS__)
#define BX_PANIC(format,  ...)  bios_printf(BIOS_PRINTF_DEBHALT, format, ## __VA_ARGS__)

#define BX_INT15_DEBUG_PRINTF(format,  ...)  bios_printf(BIOS_INT15_DEBUG, format, ## __VA_ARGS__)

#define FLASH_PAGE_REG       0xE000
#define EMS_PAGE1_REG        0x0208
#define EMS_PAGE2_REG        0x0209
#define EMS_PAGE3_REG        0x020A
#define EMS_PAGE4_REG        0x020B

#define EMS_ENABLE_REG       0x020C
#define EMS_ENABLE_VAL       0x8B       // The B Corresonds to the B in the EMS_SECTOR_OFFSET 
#define EMS_SECTOR_OFFSET    0xB000     // Value of the offset register for the base of EMS 

#define SECTOR_SIZE          512
#define SECTOR_COUNT         2880
#define RAM_DISK_BASE        68         // Must be a multiple of 4. This means start the RAM Disk at 0x110000
                                        // i.e one byte beyond the A20 addressing range of the 8086 
#define DRIVE_A              0x00
#define DRIVE_B              0x01
#define DRIVE_C              0x80
#define DRIVE_D              0x81

#define HD_CYLINDERS         8322        // For a 4 Gb SD card 
#define HD_HEADS             16
#define HD_SECTORS           63

#define UNSUPPORTED_FUNCTION 0x86
#define none                 0
#define MAX_SCAN_CODE        0x58


//---------------------------------------------------------------------------
// 1K of base memory used for Extended Bios Data Area (EBDA)
// EBDA is used for PS/2 mouse support, and IDE BIOS, etc.
//---------------------------------------------------------------------------
#define EBDA_SEG         0x9FC0
#define EBDA_SIZE        1              // In KB
#define BASE_MEM_IN_K   (640 - EBDA_SIZE)

//---------------------------------------------------------------------------
// Compatibility type definitions
//---------------------------------------------------------------------------
typedef unsigned char  Bit8u;
typedef unsigned short Bit16u;
typedef unsigned short bx_bool;
typedef unsigned long  Bit32u;
typedef           int  BOOL;

//---------------------------------------------------------------------------
//  256 bytes at 0x9ff00 -- 0x9ffff is used for the IPL boot table.
//---------------------------------------------------------------------------
#define IPL_SEG              0x9ff0
#define IPL_TABLE_OFFSET     0x0000
#define IPL_TABLE_ENTRIES    8
#define IPL_COUNT_OFFSET     0x0080  // u16: number of valid table entries
#define IPL_SEQUENCE_OFFSET  0x0082  // u16: next boot device
#define IPL_BOOTFIRST_OFFSET 0x0084  // u16: user selected device 
#define IPL_SIZE             0xff
#define IPL_TYPE_FLOPPY      0x01
#define IPL_TYPE_HARDDISK    0x02
#define IPL_TYPE_CDROM       0x03
#define IPL_TYPE_BEV         0x80

//---------------------------------------------------------------------------
//  Macro definitions
//---------------------------------------------------------------------------
#define SET_WORD(parm, data) __asm { mov ax, data} __asm { mov ss:parm, ax }
#define SET_BYTL(parm, data) __asm { mov al, data} __asm { mov ss:parm, ax }
#define SET_BYTH(parm, data) __asm { mov ah, data} __asm { mov ss:parm, ax } 

#define SET_IF()    __asm{ or  ss:rFLAGS, 0x0200 }; 
#define SET_ZF()    __asm{ or  ss:rFLAGS, 0x0040 }; 
#define CLEAR_ZF()  __asm{ and ss:rFLAGS, 0xffbf };
#define SET_CF()    __asm{ or  ss:rFLAGS, 0x0001 };
#define CLEAR_CF()  __asm{ and ss:rFLAGS, 0xfffe };

#define SET_AX(val)  SET_WORD(rAX , val)
#define SET_BX(val)  SET_WORD(rBX , val)
#define SET_CX(val)  SET_WORD(rCX , val)
#define SET_DX(val)  SET_WORD(rDX , val)

#define SET_AL(val8) SET_BYTL(rAX , val8)
#define SET_BL(val8) SET_BYTL(rBX , val8)
#define SET_CL(val8) SET_BYTL(rCX , val8)
#define SET_DL(val8) SET_BYTL(rDX , val8)
#define SET_AH(val8) SET_BYTH(rAX , val8)
#define SET_BH(val8) SET_BYTH(rBX , val8)
#define SET_CH(val8) SET_BYTH(rCX , val8)
#define SET_DH(val8) SET_BYTH(rDX , val8)

#define GET_AL()   ( rAX & 0x00ff )
#define GET_BL()   ( rBX & 0x00ff )
#define GET_CL()   ( rCX & 0x00ff )
#define GET_DL()   ( rDX & 0x00ff )
#define GET_AH()   ( rAX >> 8 )
#define GET_BH()   ( rBX >> 8 )
#define GET_CH()   ( rCX >> 8 )
#define GET_DH()   ( rDX >> 8 )
#define GET_CF()   ( rFLAGS & 0x0001 )
#define GET_ZF()   ( rFLAGS & 0x0040 )

//---------------------------------------------------------------------------
// INT15 / INT74 PS2 Mouse support function
// PS2_COMPLIANT    Set this to 1 if the HW is fully PS2 compliant
//                  Set it to 0 if using Donna's hack
//---------------------------------------------------------------------------
#define MOUSE_PORT      0x0060      // Bus Mouse port, use this instead of 0x60
#define MOUSE_CNTL      0x0064      // Bus Mouse control port, use this instead of 0x64
#define MOUSE_INTR      12          // The correct Intetrupt for PS2

//---------------------------------------------------------------------------
// INT15 - AH=C0, configuration table; model byte 0xFC = AT 
//---------------------------------------------------------------------------
#define BIOS_CONFIG_TABLE   0xe6f5

//---------------------------------------------------------------------------
// IPL Structure for INT19 support function
//---------------------------------------------------------------------------
typedef struct {
        Bit16u type;
        Bit16u flags;
        Bit32u vector;
        Bit32u description;
        Bit32u reserved;
} ipl_entry_t;


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Character generator table
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
static struct {
  Bit16u normal;
  Bit16u shift;
  Bit16u control;
  Bit16u alt;
  Bit8u lock_flags;
  }

  scan_to_scanascii[MAX_SCAN_CODE + 1] = {
      {   none,   none,   none,   none, none },
      { 0x011b, 0x011b, 0x011b, 0x0100, none }, /* escape */
      { 0x0231, 0x0221,   none, 0x7800, none }, /* 1! */
      { 0x0332, 0x0340, 0x0300, 0x7900, none }, /* 2@ */
      { 0x0433, 0x0423,   none, 0x7a00, none }, /* 3# */
      { 0x0534, 0x0524,   none, 0x7b00, none }, /* 4$ */
      { 0x0635, 0x0625,   none, 0x7c00, none }, /* 5% */
      { 0x0736, 0x075e, 0x071e, 0x7d00, none }, /* 6^ */
      { 0x0837, 0x0826,   none, 0x7e00, none }, /* 7& */
      { 0x0938, 0x092a,   none, 0x7f00, none }, /* 8* */
      { 0x0a39, 0x0a28,   none, 0x8000, none }, /* 9( */
      { 0x0b30, 0x0b29,   none, 0x8100, none }, /* 0) */
      { 0x0c2d, 0x0c5f, 0x0c1f, 0x8200, none }, /* -_ */
      { 0x0d3d, 0x0d2b,   none, 0x8300, none }, /* =+ */
      { 0x0e08, 0x0e08, 0x0e7f,   none, none }, /* backspace */
      { 0x0f09, 0x0f00,   none,   none, none }, /* tab */
      { 0x1071, 0x1051, 0x1011, 0x1000, 0x40 }, /* Q */
      { 0x1177, 0x1157, 0x1117, 0x1100, 0x40 }, /* W */
      { 0x1265, 0x1245, 0x1205, 0x1200, 0x40 }, /* E */
      { 0x1372, 0x1352, 0x1312, 0x1300, 0x40 }, /* R */
      { 0x1474, 0x1454, 0x1414, 0x1400, 0x40 }, /* T */
      { 0x1579, 0x1559, 0x1519, 0x1500, 0x40 }, /* Y */
      { 0x1675, 0x1655, 0x1615, 0x1600, 0x40 }, /* U */
      { 0x1769, 0x1749, 0x1709, 0x1700, 0x40 }, /* I */
      { 0x186f, 0x184f, 0x180f, 0x1800, 0x40 }, /* O */
      { 0x1970, 0x1950, 0x1910, 0x1900, 0x40 }, /* P */
      { 0x1a5b, 0x1a7b, 0x1a1b,   none, none }, /* [{ */
      { 0x1b5d, 0x1b7d, 0x1b1d,   none, none }, /* ]} */
      { 0x1c0d, 0x1c0d, 0x1c0a,   none, none }, /* Enter */
      {   none,   none,   none,   none, none }, /* L Ctrl */
      { 0x1e61, 0x1e41, 0x1e01, 0x1e00, 0x40 }, /* A */
      { 0x1f73, 0x1f53, 0x1f13, 0x1f00, 0x40 }, /* S */
      { 0x2064, 0x2044, 0x2004, 0x2000, 0x40 }, /* D */
      { 0x2166, 0x2146, 0x2106, 0x2100, 0x40 }, /* F */
      { 0x2267, 0x2247, 0x2207, 0x2200, 0x40 }, /* G */
      { 0x2368, 0x2348, 0x2308, 0x2300, 0x40 }, /* H */
      { 0x246a, 0x244a, 0x240a, 0x2400, 0x40 }, /* J */
      { 0x256b, 0x254b, 0x250b, 0x2500, 0x40 }, /* K */
      { 0x266c, 0x264c, 0x260c, 0x2600, 0x40 }, /* L */
      { 0x273b, 0x273a,   none,   none, none }, /* ;: */
      { 0x2827, 0x2822,   none,   none, none }, /* '" */
      { 0x2960, 0x297e,   none,   none, none }, /* `~ */
      {   none,   none,   none,   none, none }, /* L shift */
      { 0x2b5c, 0x2b7c, 0x2b1c,   none, none }, /* |\ */
      { 0x2c7a, 0x2c5a, 0x2c1a, 0x2c00, 0x40 }, /* Z */
      { 0x2d78, 0x2d58, 0x2d18, 0x2d00, 0x40 }, /* X */
      { 0x2e63, 0x2e43, 0x2e03, 0x2e00, 0x40 }, /* C */
      { 0x2f76, 0x2f56, 0x2f16, 0x2f00, 0x40 }, /* V */
      { 0x3062, 0x3042, 0x3002, 0x3000, 0x40 }, /* B */
      { 0x316e, 0x314e, 0x310e, 0x3100, 0x40 }, /* N */
      { 0x326d, 0x324d, 0x320d, 0x3200, 0x40 }, /* M */
      { 0x332c, 0x333c,   none,   none, none }, /* ,< */
      { 0x342e, 0x343e,   none,   none, none }, /* .> */
      { 0x352f, 0x353f,   none,   none, none }, /* /? */
      {   none,   none,   none,   none, none }, /* R Shift */
      { 0x372a, 0x372a,   none,   none, none }, /* * */
      {   none,   none,   none,   none, none }, /* L Alt */
      { 0x3920, 0x3920, 0x3920, 0x3920, none }, /* space */
      {   none,   none,   none,   none, none }, /* caps lock */
      { 0x3b00, 0x5400, 0x5e00, 0x6800, none }, /* F1 */
      { 0x3c00, 0x5500, 0x5f00, 0x6900, none }, /* F2 */
      { 0x3d00, 0x5600, 0x6000, 0x6a00, none }, /* F3 */
      { 0x3e00, 0x5700, 0x6100, 0x6b00, none }, /* F4 */
      { 0x3f00, 0x5800, 0x6200, 0x6c00, none }, /* F5 */
      { 0x4000, 0x5900, 0x6300, 0x6d00, none }, /* F6 */
      { 0x4100, 0x5a00, 0x6400, 0x6e00, none }, /* F7 */
      { 0x4200, 0x5b00, 0x6500, 0x6f00, none }, /* F8 */
      { 0x4300, 0x5c00, 0x6600, 0x7000, none }, /* F9 */
      { 0x4400, 0x5d00, 0x6700, 0x7100, none }, /* F10 */
      {   none,   none,   none,   none, none }, /* Num Lock */
      {   none,   none,   none,   none, none }, /* Scroll Lock */
      { 0x4700, 0x4737, 0x7700,   none, 0x20 }, /* 7 Home */
      { 0x4800, 0x4838,   none,   none, 0x20 }, /* 8 UP */
      { 0x4900, 0x4939, 0x8400,   none, 0x20 }, /* 9 PgUp */
      { 0x4a2d, 0x4a2d,   none,   none, none }, /* - */
      { 0x4b00, 0x4b34, 0x7300,   none, 0x20 }, /* 4 Left */
      { 0x4c00, 0x4c35,   none,   none, 0x20 }, /* 5 */
      { 0x4d00, 0x4d36, 0x7400,   none, 0x20 }, /* 6 Right */
      { 0x4e2b, 0x4e2b,   none,   none, none }, /* + */
      { 0x4f00, 0x4f31, 0x7500,   none, 0x20 }, /* 1 End */
      { 0x5000, 0x5032,   none,   none, 0x20 }, /* 2 Down */
      { 0x5100, 0x5133, 0x7600,   none, 0x20 }, /* 3 PgDn */
      { 0x5200, 0x5230,   none,   none, 0x20 }, /* 0 Ins */
      { 0x5300, 0x532e,   none,   none, 0x20 }, /* Del */
      {   none,   none,   none,   none, none },
      {   none,   none,   none,   none, none },
      { 0x565c, 0x567c,   none,   none, none }, /* \| */
      { 0x5700, 0x5700,   none,   none, none }, /* F11 */
      { 0x5800, 0x5800,   none,   none, none }  /* F12 */
      };

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Compatibility Functions:
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//#ifdef __WATCOMC__
#if 0                       // These do not work, probably because dx is modified

Bit8u inb(Bit16u port);
#pragma aux inb = "in al,dx" parm [dx] value [al] modify [] nomemory;

Bit16u inw(Bit16u port);
#pragma aux inw = "in ax,dx" parm [dx] value [ax] modify [] nomemory;

void outb(Bit16u port, Bit8u val);
#pragma aux outb = "out dx,al" parm [dx] [al] modify [] nomemory;

void outw(Bit16u port, Bit16u val);
#pragma aux outw = "out dx,ax" parm [dx] [ax] modify [] nomemory;

#else
//---------------------------------------------------------------------------
Bit8u inb(Bit16u port) {
    __asm {
        push dx
        mov  dx, port
        in   al, dx
        pop  dx
    }
}
//---------------------------------------------------------------------------
void outb(Bit16u port, Bit8u  val)
{
    __asm {
        push ax
        push dx
        mov  dx, port
        mov  al, val
        out  dx, al
        pop  dx
        pop  ax
    }   
}
//---------------------------------------------------------------------------
Bit16u inw(Bit16u port)
{
    __asm {
        push dx
        mov  dx, port
        in   ax, dx
        pop  dx
    }
}
//---------------------------------------------------------------------------
void outw(Bit16u port, Bit16u  val)
{
    __asm {
        push ax
        push dx
        mov  dx, port
        mov  ax, val
        out  dx, ax
        pop  dx
        pop  ax
    }
}
#endif

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Assembly functions to access memory directly
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
Bit8u read_byte(Bit16u s_segment, Bit16u s_offset)
{
    __asm {
        push bx
        push ds
        mov  ax, s_segment   // segment 
        mov  ds, ax
        mov  bx, s_offset    // offset 
        mov  al, ds:[bx]     // al = return value (byte) 
        pop  ds
        pop  bx
    }
}
//---------------------------------------------------------------------------
Bit16u read_word(Bit16u s_segment, Bit16u s_offset)
{
    __asm {
        push bx
        push ds
        mov  ax, s_segment // segment 
        mov  ds, ax
        mov  bx, s_offset  // offset 
        mov  ax, ds:[bx]   // ax = return value (word) 
        pop  ds
        pop  bx
    }
}
//---------------------------------------------------------------------------
void write_byte(Bit16u s_segment, Bit16u s_offset, Bit8u data)
{
    __asm {
        push ax
        push bx
        push ds
        mov  ax, s_segment  // segment  
        mov  ds, ax
        mov  bx, s_offset   // offset 
        mov  al, data       // data byte 
        mov  ds:[bx], al    // write data byte 
        pop  ds
        pop  bx
        pop  ax
    }
}
//---------------------------------------------------------------------------
void write_word(Bit16u s_segment, Bit16u s_offset, Bit16u data)
{
    __asm {
        push ax
        push bx
        push ds
        mov  ax, s_segment   // segment 
        mov  ds, ax
        mov  bx, s_offset    //  offset 
        mov  ax, data        //  data word 
        mov  ds:[bx], ax     //  write data word 
        pop  ds
        pop  bx
        pop  ax
    }
}

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Function prototypes:
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
#define BASESTK __based(__segname("_STACK"))

static Bit16u   get_CS(void);
static Bit16u   get_SS(void);
static void     memsetb(Bit16u s_segment, Bit16u s_offset, Bit8u value, Bit16u count);
static void     memcpyb(Bit16u d_segment, Bit16u d_offset, Bit16u s_segment, Bit16u s_offset, Bit16u count);
static void     wrch(Bit8u character);
static void     send(Bit16u action, Bit8u  c);
static void     put_int(Bit16u action, short val, short width, bx_bool neg);
static void     put_uint(Bit16u action, unsigned short val, short width, bx_bool neg);
static void     put_luint(Bit16u action, unsigned long val, short width, bx_bool neg);
static void     put_str(Bit16u action, Bit16u segment, Bit16u offset);
static void     bios_printf(Bit16u action, Bit8u *s, ...);
static Bit8u    get_boot_vector(Bit16u i, ipl_entry_t BASESTK *e);
static void     print_boot_device(ipl_entry_t BASESTK *e);
static void     print_boot_failure(Bit16u type, Bit8u reason);
static BOOL     dequeue_key(Bit8u BASESTK *scan_code, Bit8u BASESTK *ascii_code, int incr);
static BOOL     enqueue_key(Bit8u scan_code, Bit8u ascii_code);
static void     transf_sect_drive_a(Bit16u s_segment, Bit16u s_offset);
static Bit16u   GetRamdiskSector(Bit16u Sector);
static void     set_diskette_ret_status(Bit8u value);
static void     set_diskette_current_cyl(Bit8u drive, Bit8u cyl);


static Bit8u    inhibit_mouse_int_and_events(void);
static void     enable_mouse_int_and_events(void);
static Bit8u    send_to_mouse_ctrl(Bit8u sendbyte);
static Bit8u    get_mouse_data(void);
static void     set_kbd_command_byte(Bit8u command_byte);

void __cdecl    MakeRamdisk(void);
void __cdecl    print_bios_banner(void);
void __cdecl    int16_function(Bit16u rAX, Bit16u rCX, Bit16u rFLAGS);
void __cdecl    int09_function(Bit16u rAX);
void __cdecl    int14_function(Bit16u rAX, Bit16u rDX, Bit16u rDS, Bit16u rIP, Bit16u rCS, Bit16u rFLAGS);
void __cdecl    int13_harddisk         (Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);
void __cdecl    int13_diskette_function(Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);

void __cdecl    init_boot_vectors(void);
void __cdecl    int19_function(void);
void __cdecl    boot_halt(void);
void __cdecl    int1a_function(Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);

void __cdecl    int15_function(Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);
void __cdecl    int15_function_mouse(Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u,Bit16u);

//---------------------------------------------------------------------------
// External linkages
//---------------------------------------------------------------------------
extern Bit8u *int1E_table;

//---------------------------------------------------------------------------
#endif
//---------------------------------------------------------------------------

