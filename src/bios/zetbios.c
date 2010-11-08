/*
 *  Zet PC system BIOS
 *  Copyright (C) 2009, 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  Copyright (C) 2010        Donna Polehn <dpolehn@verizon.net>
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
//---------------------------------------------------------------------------
//  ZET Bios C Helper functions:
//  This file contains various functions in C called fromt the zetbios.asm
//  module. This module provides support fuctions and special code specific
//  to the Zet computer, specifically, special video support and disk support
//  for the SD and Flash types of disks. 
//
//  This code is compatible with the Open Watcom C Compiler.
//  Originally modified from the Bochs bios by Zeus Gomez Marmolejo
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

#include "zetbios.h"

//--------------------------------------------------------------------------
// Low level assembly functions
//--------------------------------------------------------------------------
#pragma aux get_CS = "mov ax, cs" modify [ax];
#pragma aux get_SS = "mov ax, ss" modify [ax];

#pragma aux read_byte = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  al, ds:[bx] " \
"       pop  ds          " \
parm [ax] [bx] modify [al];

#pragma aux read_word = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  ax, ds:[bx] " \
"       pop  ds          " \
parm [ax] [bx] modify [ax];

#pragma aux write_byte = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  ds:[bx], dl " \
"       pop  ds          " \
parm [ax] [bx] [dl];

#pragma aux write_word = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  ds:[bx], dx " \
"       pop  ds          " \
parm [ax] [bx] [dx];

#pragma aux inb  = "in  al, dx" parm [dx] modify [al];
#pragma aux outb = "out dx, al" parm [dx] [al];
#pragma aux inw  = "in  ax, dx" parm [dx] modify [ax];
#pragma aux outw = "out dx, ax" parm [dx] [ax];

#pragma aux memsetb = \
"       push es          " \
"       mov  es, bx      " \
"       cld              " \
"       rep  stosb       " \
"       pop  es          " \
parm [bx] [di] [al] [cx] modify [di cx];

#pragma aux memcpyb = \
"       push ds          " \
"       push es          " \
"       mov  ds, ax      " \
"       mov  es, bx      " \
"       cld              " \
"       rep  movsb       " \
"       pop  es          " \
"       pop  ds          " \
parm [bx] [di] [ax] [si] [cx] modify [di si cx];

#pragma aux wrch = \
"       xor  bx, bx      " \
"       mov  ah, 0x0e    " \
"       int  0x10        " \
parm [al] modify [ah bx];

//--------------------------------------------------------------------------
static void wcomport(Bit8u c)
{
    Bit8u  ticks;
    ticks = read_byte(0x0040, 0x006C); // get current tick count

    while(!inb(UART_LS & 0x40)) {     // wait for transmitter buffer to empty
        if((ticks + 50) < read_byte(0x0040, 0x006C)) break;
    }
    while((ticks + 70) < read_byte(0x0040, 0x006C));
    outb(UART,c);
}
//--------------------------------------------------------------------------
static void send(Bit16u action, Bit8u  c)
{
    if(action & BIOS_PRINTF_SCREEN) {
        if(c == '\n') wrch('\r');
        wrch(c);
    }
    if(action & BIOS_PRINTF_COMPORT)  wcomport(c);
}
//--------------------------------------------------------------------------
static void put_int(Bit16u action, short val, short width, bx_bool neg)
{
    short nval = val / 10;
    if(nval) put_int(action, nval, width - 1, neg);
    else {
        while(--width > 0) send(action, ' ');
        if(neg) send(action, '-');
    }
    send(action, val - (nval * 10) + '0');
}
//--------------------------------------------------------------------------
static void put_uint(Bit16u action, unsigned short val, short width, bx_bool neg)
{
    unsigned short nval = val / 10;
    if(nval) put_uint(action, nval, width - 1, neg);
    else {
        while(--width > 0) send(action, ' ');
        if(neg) send(action, '-');
    }
    send(action, val - (nval * 10) + '0');
}
//--------------------------------------------------------------------------
static void put_luint(Bit16u action, unsigned long val, short width, bx_bool neg)
{
    unsigned long nval = val / 10;
    if(nval) put_luint(action, nval, width - 1, neg);
    else {
        while(--width > 0) send(action, ' ');
        if(neg) send(action, '-');
    }
    send(action, val - (nval * 10) + '0');
}
//--------------------------------------------------------------------------
static void put_str(Bit16u action, Bit16u segment, Bit16u offset)
{
    Bit8u c;
    while(c = read_byte(segment, offset)) {
        send(action, c);
        offset++;
    }
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// bios_printf()  A compact variable argument printf function.
//   Supports %[format_width][length]format
//   where format can be x,X,u,d,s,S,c
//   and the optional length modifier is l (ell)
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static void bios_printf(Bit16u action, Bit8u *s, ...)
{
    Bit8u    c;
    bx_bool  in_format;
    short    i;
    Bit16u  *arg_ptr;
    Bit16u   arg_seg, arg, nibble, hibyte, format_width, hexadd;

    arg_ptr = (Bit16u  *)&s;
    arg_seg = get_SS();

    in_format = 0;
    format_width = 0;

    if((action & BIOS_PRINTF_DEBHALT) == BIOS_PRINTF_DEBHALT)
        bios_printf(BIOS_PRINTF_SCREEN, "FATAL: ");

    while(c = read_byte(get_CS(), (Bit16u)s)) {
        if( c == '%' ) {
            in_format = 1;
            format_width = 0;
        }
        else if(in_format) {
            if( (c >= '0') && (c <= '9') ) {
                format_width = (format_width * 10) + (c - '0');
            }
            else {
                arg_ptr++;              // increment to next arg
                arg = read_word(arg_seg, (Bit16u)arg_ptr);
                if(c == 'x' || c == 'X') {
                    if(format_width == 0) format_width = 4;
                    if(c == 'x') hexadd = 'a';
                    else         hexadd = 'A';
                    for(i = format_width-1; i >= 0; i--) {
                        nibble = (arg >> (4 * i)) & 0x000f;
                        send(action, (nibble<=9)? (nibble+'0') : (nibble-10+hexadd));
                    }
                }
                else if(c == 'u') {
                    put_uint(action, arg, format_width, 0);
                }
                else if(c == 'l') {
                    s++;
                    c = read_byte(get_CS(), (Bit16u)s);       // is it ld,lx,lu? 
                    arg_ptr++;                                // increment to next arg
                    hibyte = read_word(arg_seg, (Bit16u)arg_ptr);
                    if(c == 'd') {
                        if(hibyte & 0x8000) put_luint(action, 0L-(((Bit32u) hibyte << 16) | arg), format_width-1, 1);
                        else                put_luint(action, ((Bit32u) hibyte << 16) | arg, format_width, 0);
                    }
                    else if(c == 'u') {
                        put_luint(action, ((Bit32u) hibyte << 16) | arg, format_width, 0);
                    }
                    else if(c == 'x' || c == 'X') {
                        if(format_width == 0) format_width = 8;
                        if(c == 'x') hexadd = 'a';
                        else          hexadd = 'A';
                        for(i=format_width-1; i>=0; i--) {
                            nibble = ((((Bit32u) hibyte <<16) | arg) >> (4 * i)) & 0x000f;
                            send(action, (nibble<=9)? (nibble+'0') : (nibble-10+hexadd));
                        }
                    }
                }
                else if(c == 'd') {
                    if(arg & 0x8000) put_int(action, -arg, format_width - 1, 1);
                    else             put_int(action, arg, format_width, 0);
                }
                else if(c == 's') {
                    put_str(action, get_CS(), arg);
                }
                else if(c == 'S') {
                    hibyte = arg;
                    arg_ptr++;
                    arg = read_word(arg_seg, (Bit16u)arg_ptr);
                    put_str(action, hibyte, arg);
                }
                else if(c == 'c') {
                    send(action, arg);
                }
                else bios_printf(BIOS_PRINTF_DEBHALT,"bios_printf: unknown format\n");
                in_format = 0;
            }
        }
        else {
            send(action, c);
        }
        s ++;
    }

    if(action & BIOS_PRINTF_HALT) {  // freeze in a busy loop.
        __asm {
                        cli
            halt2_loop: hlt
                        jmp halt2_loop
        }
    }
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// print_bios_banner -  displays a the bios version
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
#define BIOS_COPYRIGHT_STRING   "(c) 2009, 2010 Zeus Gomez Marmolejo and (c) 2002 MandrakeSoft S.A."
#define BIOS_BANNER             "Zet Test BIOS - build date: "
#define BIOS_BUILD_DATE         "(build-date)\n"
#define BIOS_VERS               " Version: (git)\n"
#define BIOS_DATE               " Version date: (commit-date)\n\n"
void __cdecl print_bios_banner(void)
{
    bios_printf(BIOS_PRINTF_SCREEN,BIOS_BANNER);
    bios_printf(BIOS_PRINTF_SCREEN,BIOS_BUILD_DATE);
    bios_printf(BIOS_PRINTF_SCREEN,BIOS_VERS);
    bios_printf(BIOS_PRINTF_SCREEN,BIOS_DATE);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// BIOS Boot Specification 1.0.1 compatibility
//
// Very basic support for the BIOS Boot Specification, which allows expansion
// ROMs to register themselves as boot devices, instead of just stealing the
// INT 19h boot vector.
//
// This is a hack: to do it properly requires a proper PnP BIOS and we aren't
// one; we just lie to the option ROMs to make them behave correctly.
// We also don't support letting option ROMs register as bootable disk
// drives (BCVs), only as bootable devices (BEVs).
//
// http://www.phoenix.com/en/Customer+Services/White+Papers-Specs/pc+industry+specifications.htm
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static char drivetypes[][20]={"", "Floppy flash image", "SD card" };
void __cdecl init_boot_vectors(void)
{
    ipl_entry_t e;
    Bit8u       sd_error, switches;
    Bit16u      count = 0;
    Bit16u      hdi, fdi;
    Bit16u      ss = get_SS();

    memsetb(IPL_SEG, IPL_TABLE_OFFSET, 0, IPL_SIZE);  // Clear out the IPL table. 

    write_word(IPL_SEG, IPL_BOOTFIRST_OFFSET, 0xFFFF);  // User selected device not set 
    sd_error = read_byte(0x40, 0x8d);
    if(sd_error) {
        bios_printf(BIOS_PRINTF_SCREEN,"Error initializing SD card controller (at stage %d)\n", sd_error);

        // Floppy drive 
        e.type          = IPL_TYPE_FLOPPY;
        e.flags         = 0;
        e.vector        = 0;
        e.description   = 0;
        e.reserved      = 0;
        memcpyb(IPL_SEG, IPL_TABLE_OFFSET + count * sizeof(e), ss, (Bit16u)&e, sizeof(e));
        count++;
    }
    else {            // Get the boot sequence from the switches
        switches = inb(0xf100);
        if(switches) { hdi = 1; fdi = 0; }
        else         { hdi = 0; fdi = 1; }

        e.type = IPL_TYPE_HARDDISK; e.flags = 0; e.vector = 0; e.description = 0; e.reserved = 0;
        memcpyb(IPL_SEG, IPL_TABLE_OFFSET + hdi * sizeof(e), ss, (Bit16u)&e, sizeof(e));

        e.type = IPL_TYPE_FLOPPY; e.flags = 0; e.vector = 0; e.description = 0; e.reserved = 0;
        memcpyb(IPL_SEG, IPL_TABLE_OFFSET + fdi * sizeof(e), ss, (Bit16u)&e, sizeof(e));
        count = 2;
    }
    write_word(IPL_SEG, IPL_COUNT_OFFSET, count);   // Remember how many devices we have 
    write_word(IPL_SEG, IPL_SEQUENCE_OFFSET, 1);    // Try to boot first boot device 
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// print_boot_failure
//   displays the reason why boot failed
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static void print_boot_failure(Bit16u type, Bit8u reason)
{
    if(type == 0 || type > 0x03) BX_PANIC("Bad drive type\n");
    printf("Boot failed");
    if(type < 4) {      // Report the reason too 
        if(reason == 0)   printf(": not a bootable disk");
        else              printf(": could not read the boot disk");
    }
    printf("\n\n");
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// De-queue the key - Called only by INT16 Key stroke function:
// Takes a key stroke out of the keyboard buffere and returns the value
// If incr is 0, then it just checks for a key in the buffer but does not
// alter the buffer pointers.
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static BOOL __cdecl dequeue_key(Bit8u BASESTK *scan_code, Bit8u BASESTK *ascii_code, int incr)
{
    Bit16u buffer_start, buffer_end, buffer_head, buffer_tail;

    buffer_start = read_word(0x0040, 0x0080);
    buffer_end   = read_word(0x0040, 0x0082);
    buffer_head  = read_word(0x0040, 0x001a);
    buffer_tail  = read_word(0x0040, 0x001c);

    if(buffer_head != buffer_tail) {
        *ascii_code  = read_byte(0x0040, buffer_head);
        *scan_code   = read_byte(0x0040, buffer_head+1);
        if(incr) {
            buffer_head += 2;
            if(buffer_head >= buffer_end) buffer_head = buffer_start;
            write_word(0x0040, 0x001a, buffer_head);
        }
        return(1);
    }
    return(0);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT16 Support function - Keyboard support routine
// This function checks for if a key has been pressed and is waiting in the
// buffer for processing and returns the appropriate values.
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int16_function(Bit16u rAX, Bit16u rCX, Bit16u rFLAGS)
{
    Bit8u   scan_code, ascii_code;
    Bit8u   shift_flags, led_flags;
    Bit16u  kbd_code;

    shift_flags = read_byte(0x0040, 0x0017);
    led_flags   = read_byte(0x0040, 0x0097);

    switch(GET_AH()) {
        case 0x00:      // read keyboard input 
            if(!dequeue_key(&scan_code, &ascii_code, 1)) {          // if retirns a 0
                BX_PANIC("KBD: int16h: out of keyboard input\n");   // that means no key strokes waiting
            }
            if(scan_code !=0 && ascii_code == 0xF0) ascii_code = 0;
            else if(ascii_code == 0xE0)             ascii_code = 0;
            kbd_code = (scan_code << 8) | ascii_code;
            SET_AX(kbd_code);
            break;

        case 0x01:      // check keyboard status 
            if(dequeue_key(&scan_code, &ascii_code, 0)) {   // We have received a key
                if(scan_code !=0 && ascii_code == 0xF0) ascii_code = 0;
                else if(ascii_code == 0xE0)             ascii_code = 0;
                kbd_code = (scan_code << 8) | ascii_code;
                SET_AX(kbd_code);
                CLEAR_ZF();
            }
            else {              // if dequeue returns 0 then no key is waiting
                SET_ZF();       // Setting the zero flag means no key strokes waiting
            }
            break;

        case 0x02:     // get shift flag status 
            shift_flags = read_byte(0x0040, 0x17);
            SET_AL(shift_flags);              // Sets the AL register on the stack
            break;

        case 0x05:     // store key-stroke into buffer 
            if(!enqueue_key(GET_CH(), GET_CL())) SET_AL(0x01); 
            else                                 SET_AL(0x00); 
            break;

        case 0x09: // GET KEYBOARD FUNCTIONALITY 
            // bit Bochs Description
            //  7    0   reserved
            //  6    0   INT 16/AH=20h-22h supported (122-key keyboard support)
            //  5    1   INT 16/AH=10h-12h supported (enhanced keyboard support)
            //  4    1   INT 16/AH=0Ah supported
            //  3    0   INT 16/AX=0306h supported
            //  2    0   INT 16/AX=0305h supported
            //  1    0   INT 16/AX=0304h supported
            //  0    0   INT 16/AX=0300h supported
            SET_AL(0x30);
            
            break;

        case 0x10: // read MF-II keyboard input 
            if(!dequeue_key(&scan_code, &ascii_code, 1) ) {
                BX_PANIC("KBD: int16h: out of keyboard input\n");
            }
            if(scan_code !=0 && ascii_code == 0xF0) ascii_code = 0;
            kbd_code = (scan_code << 8) | ascii_code;
            SET_AX(kbd_code);
            break;

        case 0x11:  // check MF-II keyboard status 
            if(!dequeue_key(&scan_code, &ascii_code, 0) ) {
                SET_ZF();
                return;
            }
            if(scan_code !=0 && ascii_code == 0xF0) ascii_code = 0;
            kbd_code = (scan_code << 8) | ascii_code;
            SET_AX(kbd_code);
            CLEAR_ZF();
            break;

        case 0x12: // get extended keyboard status 
            shift_flags = read_byte(0x0040, 0x17);
            SET_AL(shift_flags);
            shift_flags = read_byte(0x0040, 0x18) & 0x73;
            shift_flags |= read_byte(0x0040, 0x96) & 0x0c;
            SET_AL(shift_flags);
            break;

        case 0x92:              // keyboard capability check called by DOS 5.0+ keyb *
            SET_AL(0x80);       // function int16 ah=0x10-0x12 supported
            break;

        case 0xA2:        // 122 keys capability check called by DOS 5.0+ keyb 
            break;        // don't change AH : function int16 ah=0x20-0x22 NOT supported
          
        case 0x6F:
            if(GET_AL() == 0x08) SET_AL(0x02); // unsupported, aka normal keyboard

        default:
            bios_printf(BIOS_PRINTF_INFO,"KBD: unsupported int 16h function %02x\n", GET_AH());
            break;
    }
}

//--------------------------------------------------------------------------
// Enqueue Key
//--------------------------------------------------------------------------
static BOOL enqueue_key(Bit8u scan_code, Bit8u ascii_code)
{
    Bit16u buffer_start, buffer_end, buffer_head, buffer_tail, temp_tail;

    buffer_start = read_word(0x0040, 0x0080);
    buffer_end   = read_word(0x0040, 0x0082);
    buffer_head  = read_word(0x0040, 0x001A);
    buffer_tail  = read_word(0x0040, 0x001C);

    temp_tail = buffer_tail;
    buffer_tail += 2;
    if(buffer_tail >= buffer_end) buffer_tail = buffer_start;
    if(buffer_tail == buffer_head) return(0);   // Buffer over run

    write_byte(0x0040, temp_tail, ascii_code);
    write_byte(0x0040, temp_tail+1, scan_code);
    write_word(0x0040, 0x001C, buffer_tail);
    return(1);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT09 Support function
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int09_function(Bit16u rAX)
{
    Bit8u scancode, asciicode, shift_flags;
    Bit8u mf2_flags, mf2_state;

    scancode = GET_AL();    // DS has been set to F000 before call
    if(scancode == 0) {
        BX_INFO("KBD: int09 handler: AL=0\n");
        return;
    }

    shift_flags = read_byte(0x0040, 0x17);
    mf2_flags   = read_byte(0x0040, 0x18);
    mf2_state   = read_byte(0x0040, 0x96);
    asciicode   = 0;

    switch(scancode) {
        case 0x3a:              // Caps Lock press 
            shift_flags ^= 0x40;
            write_byte(0x0040, 0x17, shift_flags);
            mf2_flags |= 0x40;
            write_byte(0x0040, 0x18, mf2_flags);
            break;

        case 0xba:              // Caps Lock release 
            mf2_flags &= ~0x40;
            write_byte(0x0040, 0x18, mf2_flags);
            break;

        case 0x2a:              // L Shift press 
            shift_flags |= 0x02;
            write_byte(0x0040, 0x17, shift_flags);
            break;

        case 0xaa:              // L Shift release 
            shift_flags &= ~0x02;
            write_byte(0x0040, 0x17, shift_flags);
            break;

        case 0x36:              // R Shift press 
            shift_flags |= 0x01;
            write_byte(0x0040, 0x17, shift_flags);
            break;

        case 0xb6:              // R Shift release 
            shift_flags &= ~0x01;
            write_byte(0x0040, 0x17, shift_flags);
            break;

        case 0x1d:              // Ctrl press 
            if((mf2_state & 0x01) == 0) {
                shift_flags |= 0x04;
                write_byte(0x0040, 0x17, shift_flags);
                if(mf2_state & 0x02) {
                    mf2_state |= 0x04;
                    write_byte(0x0040, 0x96, mf2_state);
                }
                else {
                    mf2_flags |= 0x01;
                    write_byte(0x0040, 0x18, mf2_flags);
                }
            }
            break;

        case 0x9d: // Ctrl release 
            if((mf2_state & 0x01) == 0) {
                shift_flags &= ~0x04;
                write_byte(0x0040, 0x17, shift_flags);
                if(mf2_state & 0x02) {
                    mf2_state &= ~0x04;
                    write_byte(0x0040, 0x96, mf2_state);
                }
                else {
                    mf2_flags &= ~0x01;
                    write_byte(0x0040, 0x18, mf2_flags);
                }
            }
            break;

        case 0x38: // Alt press 
            shift_flags |= 0x08;
            write_byte(0x0040, 0x17, shift_flags);
            if(mf2_state & 0x02) {
                mf2_state |= 0x08;
                write_byte(0x0040, 0x96, mf2_state);
            }
            else {
                mf2_flags |= 0x02;
                write_byte(0x0040, 0x18, mf2_flags);
            }
            break;

        case 0xb8: // Alt release 
            shift_flags &= ~0x08;
            write_byte(0x0040, 0x17, shift_flags);
            if(mf2_state & 0x02) {
                mf2_state &= ~0x08;
                write_byte(0x0040, 0x96, mf2_state);
            }
            else {
                mf2_flags &= ~0x02;
                write_byte(0x0040, 0x18, mf2_flags);
            }
            break;

        case 0x45: // Num Lock press 
            if((mf2_state & 0x03) == 0) {
                mf2_flags |= 0x20;
                write_byte(0x0040, 0x18, mf2_flags);
                shift_flags ^= 0x20;
                write_byte(0x0040, 0x17, shift_flags);
            }
            break;

        case 0xc5: // Num Lock release 
            if((mf2_state & 0x03) == 0) {
                mf2_flags &= ~0x20;
                write_byte(0x0040, 0x18, mf2_flags);
            }
            break;

        case 0x46: // Scroll Lock press 
            mf2_flags |= 0x10;
            write_byte(0x0040, 0x18, mf2_flags);
            shift_flags ^= 0x10;
            write_byte(0x0040, 0x17, shift_flags);
            break;

        case 0xc6: // Scroll Lock release 
            mf2_flags &= ~0x10;
            write_byte(0x0040, 0x18, mf2_flags);
            break;

        default:
            if(scancode & 0x80) {
                break; // toss key releases ... 
            }
            if(scancode > MAX_SCAN_CODE) {
                bios_printf(BIOS_PRINTF_INFO,"KBD: int09h_handler(): unknown scancode read: 0x%02x!\n", scancode);
                return;
            }
            if(shift_flags & 0x08) { // ALT 
                asciicode = scan_to_scanascii[scancode].alt;
                scancode = scan_to_scanascii[scancode].alt >> 8;
            }
            else if(shift_flags & 0x04) { // CONTROL 
                asciicode = scan_to_scanascii[scancode].control;
                scancode = scan_to_scanascii[scancode].control >> 8;
            }
            else if(((mf2_state & 0x02) > 0) && ((scancode >= 0x47) && (scancode <= 0x53))) {
                asciicode = 0xe0;   // extended keys handling 
                scancode = scan_to_scanascii[scancode].normal >> 8;
            }
            else if(shift_flags & 0x03) { // LSHIFT + RSHIFT 
                // check if lock state should be ignored  because a SHIFT key are pressed 
                if(shift_flags & scan_to_scanascii[scancode].lock_flags) {
                    asciicode = scan_to_scanascii[scancode].normal;
                    scancode = scan_to_scanascii[scancode].normal >> 8;
                }
                else {
                    asciicode = scan_to_scanascii[scancode].shift;
                    scancode = scan_to_scanascii[scancode].shift >> 8;
                }
            }
            else {         // check if lock is on 
            if(shift_flags & scan_to_scanascii[scancode].lock_flags) {
                asciicode = scan_to_scanascii[scancode].shift;
                scancode = scan_to_scanascii[scancode].shift >> 8;
            }
            else {
                asciicode = scan_to_scanascii[scancode].normal;
                scancode = scan_to_scanascii[scancode].normal >> 8;
            }
        }
        if(scancode==0 && asciicode==0) {
            BX_INFO("KBD: int09h_handler(): scancode & asciicode are zero?\n");
        }
        enqueue_key(scancode, asciicode);
        break;
    }
    if((scancode & 0x7f) != 0x1d) mf2_state &= ~0x01;
    mf2_state &= ~0x02;
    write_byte(0x0040, 0x96, mf2_state);
}

// INT13 Interupt handler function
#define SET_DISK_RET_STATUS(status) write_byte(0x0040, 0x0074, status)

void __cdecl int13_harddisk(rDS, rES, rDI, rSI, rBP, rBX, rDX, rCX, rAX, rIP, rCS, rFLAGS)
Bit16u rDS, rES, rDI, rSI, rBP, rBX, rDX, rCX, rAX, rIP, rCS, rFLAGS;
{
    Bit8u    drive, num_sectors, sector, head, status;
    Bit8u    drive_map, sd_error;
    Bit8u    n_drives;
    Bit16u   max_cylinder, cylinder;
    Bit16u   hd_cylinders;
    Bit8u    hd_heads, hd_sectors;
    Bit8u    sector_count;
    Bit16u   tempbx;
    Bit16u   addr_l, addr_h;
    Bit32u   log_sector;
    Bit8u    tmp;

    SET_IF();   // Turn on IF when Flag Register is popped off the stack

    write_byte(0x0040, 0x008e, 0);  // clear completion flag

    // at this point, DL is >= 0x80 to be passed from the floppy int13h handler code 
    // check how many disks first (cmos reg 0x12), return an error if drive not present 
    sd_error = read_byte(0x40, 0x8d);
    if(sd_error) drive_map = 0;
    else         drive_map = 1;

    n_drives = 1;

    if(!(drive_map & (1<<(GET_DL()&0x7f)))) {    // allow 0, 1, or 2 disks
        SET_AL(0x01);                            // Set AL register while on the stack frame
        SET_DISK_RET_STATUS(0x01);
        SET_CF();                                // error occurred 
        return;
    }

    switch(GET_AH()) {      // AH = Disk command

        case 0x00:                              // disk controller reset
            SET_AH(0x00);                       // Success
            SET_DISK_RET_STATUS(0);             // 
            set_diskette_ret_status(0);
            set_diskette_current_cyl(0, 0);     // current cylinder, diskette 1 
            set_diskette_current_cyl(1, 0);     // current cylinder, diskette 2 
            CLEAR_CF();                         // successful 
            break;

        case 0x01:                              // read disk status 
            status = read_byte(0x0040, 0x0074); // 
            SET_AH(status);                     // Return last status
            SET_DISK_RET_STATUS(0);             // 
            if(status) { SET_CF();   }          // set CF if error status read 
            else       { CLEAR_CF(); }          // 
            break;

        case 0x04:                              // verify disk sectors
        case 0x02:                              // read disk sectors
            drive        = GET_DL();            // Get drive number
            hd_cylinders = HD_CYLINDERS;        // get_hd_geometry(drive, &hd_cylinders, &hd_heads, &hd_sectors);
            hd_heads     = HD_HEADS;            // fixed geometry:
            hd_sectors   = HD_SECTORS;          // Hard drive sectors
            num_sectors  =  GET_AL();           // Number of sectors requested
            cylinder     = (GET_CL() & 0x00c0) << 2 | GET_CH();
            sector       = (GET_CL() & 0x3f);
            head         =  GET_DH();

            if((cylinder >= hd_cylinders) || (sector > hd_sectors) || (head >= hd_heads)) {
                SET_AH(0x01);
                SET_DISK_RET_STATUS(1);
                SET_CF();                   // error occurred 
                return;
            }
            if(GET_AH() == 0x04 ) {
                SET_AH(0x00);
                SET_DISK_RET_STATUS(0);
                CLEAR_CF();
                return;
            }
            log_sector = ((Bit32u)cylinder) * ((Bit32u)hd_heads) * ((Bit32u)hd_sectors)
                         + ((Bit32u)head) * ((Bit32u)hd_sectors) + ((Bit32u)sector) - 1;

            sector_count = 0;
            tempbx = rBX;

            __asm { sti }  //;; enable higher priority interrupts
            while(1) {
                addr_l = ((Bit16u) log_sector) << 9;
                addr_h =  (Bit16u) (log_sector >> 7);

                __asm {
                   mov   es, rES                // ES: destination segment
                   mov   di, tempbx             // DI: destination offset from bx
                   cmp   di, 0xfe00             // adjust if there will be an overrun
                   jbe   i13_f02_no_adjust
                   
                i13_f02_adjust:
                    sub   di, 0x0200            // sub 512 bytes from offset
                    mov   ax, es
                    add   ax, 0x0020            // add 512 to segment
                    mov   es, ax

                i13_f02_no_adjust:
                    mov   bx, addr_l
                    mov   cx, addr_h

                    mov   dx, 0x0100        // SD card IO Port 
                    mov   ax, 0x51          // CS = 0, command CMD17
                    out   dx, ax
                    mov   al, ch            // addr[31:24]
                    out   dx, al
                    mov   al, cl            // addr[23:16]
                    out   dx, al
                    mov   al, bh            // addr[15:8]
                    out   dx, al
                    mov   al, bl            // addr[7:0]
                    out   dx, al
                    mov   al, 0x0ff         // CRC (not used)
                    out   dx, al
                    out   dx, al            // wait

                i13_f02_read_res_cmd17:
                    in    al, dx            // card response
                    cmp   al, 0
                    jne   i13_f02_read_res_cmd17

                i13_f02_read_tok_cmd17:     // read data token: 0xfe
                    in    al, dx
                    cmp   al, 0x0fe
                    jne   i13_f02_read_tok_cmd17
                    mov   cx, 0x100
                    
                i13_f02_read_bytes:
                    in    al, dx                 // low byte
                    mov   bl, al
                    in    al, dx                 // high byte
                    mov   bh, al
                    mov   word ptr es:[di], bx   // eseg
                    add   di, 2
                    loop  i13_f02_read_bytes

                    mov   ax, 0xffff    //; we are done, retrieve checksum
                    out   dx, al        //; Checksum, 1st byte
                    out   dx, al        //; Checksum, 2nd byte
                    out   dx, al        //; wait
                    out   dx, al        //; wait
                    out   dx, ax        //; CS = 1 (disable SD)

                i13_f02_done:           //;; store real DI register back to temp bx
                    mov  tempbx, di
                }
                sector_count++;
                log_sector++;
                num_sectors--;
                if(num_sectors) continue;
                else            break;
            }
            SET_AH(0x00);                   // Indicate success
            SET_DISK_RET_STATUS(0);         // Set status
            SET_AL(sector_count);           // return sector count done
            CLEAR_CF();                     // successful
            break;

        case 0x03:                          // write disk sectors 
            drive        = GET_DL();        // get_hd_geometry(drive, &hd_cylinders, &hd_heads, &hd_sectors);
            hd_cylinders = HD_CYLINDERS;    // fixed geometry:
            hd_heads     = HD_HEADS;
            hd_sectors   = HD_SECTORS;

            num_sectors = GET_AL();
            cylinder    = GET_CH();
            cylinder   |= (((Bit16u) GET_CL()) << 2) & 0x300;
            sector      = (GET_CL() & 0x3f);
            head        = GET_DH();

            if((cylinder >= hd_cylinders) || (sector > hd_sectors) || (head >= hd_heads)) {
                SET_AH(0x01);
                SET_DISK_RET_STATUS(1);
                SET_CF();                   // error occurred 
                return;
            }
            log_sector = ((Bit32u)cylinder) * ((Bit32u)hd_heads) * ((Bit32u)hd_sectors)
                        + ((Bit32u)head) * ((Bit32u)hd_sectors) + ((Bit32u)sector) - 1;

            sector_count = 0;
            tempbx = rBX;

            __asm { sti }  //;; enable higher priority interrupts
            while(1) {
                addr_l = ((Bit16u) log_sector)<< 9;
                addr_h =  (Bit16u)(log_sector >> 7);

                __asm {
                        mov   es, rES           //;; ES: source segment
                        mov   si, tempbx        //;; SI: source offset from temp bx 
                        cmp   si, 0xfe00        //;; adjust if there will be an overrun
                        jbe   i13_f03_no_adjust
                        
                i13_f03_adjust:
                        sub   si, 0x0200    //; sub 512 bytes from offset
                        mov   ax, es
                        add   ax, 0x0020    //; add 512 to segment
                        mov   es, ax

                i13_f03_no_adjust:
                        mov   bx, addr_l
                        mov   cx, addr_h

                        mov   dx, 0x0100    //; SD card Port
                        mov   ax, 0x58      //; CS = 0, SD card command CMD24
                        out   dx, ax
                        mov   al, ch        //; addr[31:24]
                        out   dx, al
                        mov   al, cl        //; addr[23:16]
                        out   dx, al
                        mov   al, bh        //; addr[15:8]
                        out   dx, al
                        mov   al, bl        //; addr[7:0]
                        out   dx, al
                        mov   al, 0xff      //; CRC (not used)
                        out   dx, al
                        out   dx, al        //; wait

                i13_f03_read_res_cmd24:
                        in    al, dx        //; command response
                        cmp   al, 0
                        jne   i13_f03_read_res_cmd24
                        mov   al, 0xff      //; wait
                        out   dx, al
                        mov   al, 0xfe      //; start of block: token 0xfe
                        out   dx, al
                        mov   cx, 0x100
                        
                i13_f03_write_bytes:
                        mov   ax, word ptr es:[si]      // eseg
                        out   dx, al
                        mov   al, ah
                        out   dx, al
                        add   si, 2
                        loop  i13_f03_write_bytes
                        
                        mov   al, 0xff          //; send dummy checksum
                        out   dx, al
                        out   dx, al
                        
                        in    al, dx            //; data response
                        and   al, 0x0f
                        cmp   al, 0x05
                        je    i13_f03_good_write
                        hlt                     //; problem writing

                i13_f03_good_write:             //; write finished?
                        in    al, dx
                        cmp   al, 0
                        je    i13_f03_good_write

                        mov   ax,  0xffff       //; goodbye mr. writer!
                        out   dx, al            //; wait
                        out   dx, al            //; wait
                        out   dx, ax            //; CS = 1 (disable SD)

                i13_f03_done:   //;; store real SI register back to temp bx
                        mov  tempbx, si
                }

            sector_count++;
            log_sector++;
            num_sectors--;
            if(num_sectors) continue;
            else            break;
        }
        SET_AH(0x00);               // Return success
        SET_DISK_RET_STATUS(0);     // Set Status 
        SET_AL(sector_count);       // Return sectors done
        CLEAR_CF();                 // successful
        break;

        case 0x08:                        // Get Current Drive Parameters 
            drive        = GET_DL();      // same as get_hd_geometry(drive, &hd_cylinders, &hd_heads, &hd_sectors);
            hd_cylinders = HD_CYLINDERS;  // fixed geometry:
            hd_heads     = HD_HEADS;
            hd_sectors   = HD_SECTORS;
            max_cylinder = hd_cylinders - 2; // 0 based 
            SET_AL(0x00);
            tmp = (Bit8u)(max_cylinder & 0xff);
            SET_CH(tmp);
            tmp = (Bit8u)(((max_cylinder >> 2) & 0xc0) | (hd_sectors & 0x3f));
            SET_CL(tmp);
            tmp = (hd_heads - 1);
            SET_DH(tmp);
            SET_DL(n_drives);       // returns 0, 1, or 2 hard drives 
            SET_AH(0x00);
            SET_DISK_RET_STATUS(0);
            CLEAR_CF();             // successful 
            break;

        case 0x09:          // initialize drive parameters 
        case 0x0c:          // seek to specified cylinder 
        case 0x0d:          // alternate disk reset 
        case 0x10:          // check drive ready 
        case 0x11:          // recalibrate 
            SET_AH(0x00);
            SET_DISK_RET_STATUS(0);
            CLEAR_CF();                 // successful 
            break;

        case 0x14:                      // controller internal diagnostic 
            SET_AH(0x00);               // Status
            SET_DISK_RET_STATUS(0);
            CLEAR_CF();                 // successful
            SET_AL(0x00);               // Probably not needed
            break;

        case 0x15:                         // read disk drive size 
            drive        = GET_DL();       // same as get_hd_geometry(drive, &hd_cylinders, &hd_heads, &hd_sectors);
            hd_cylinders = HD_CYLINDERS;   // fixed geometry:
            hd_heads     = HD_HEADS;
            hd_sectors   = HD_SECTORS;
            
            __asm {
                    mov  al, hd_heads           //;; al = heads
                    mov  bl, hd_sectors         //;; bl = sectors
                    mul  bl                     //;; ax = al * bl = heads * sectors
                    mov  bx, hd_cylinders       //;; bx = cylinders
                    dec  bx                     //;; bx = cylinders - 1
                    mul  bx                     //;; dx:ax = bx*ax = (cylinders -1) * (heads * sectors)
                    mov  ss:rCX, dx             //;; BIOS wants 32bit result in CX:DX
                    mov  ss:rDX, ax             //;; which will be returned on the stack
            }

            SET_AH(0x03);           // hard disk accessible
            SET_DISK_RET_STATUS(0); // ??? should this be 0
            CLEAR_CF();             // successful
            break;

        default:
            BX_INFO("int13_harddisk: function %02xh unsupported, returns fail\n", GET_AH());
            SET_AH(0x01); // defaults to invalid function in AH or invalid parameter
            SET_DISK_RET_STATUS(GET_AH());
            SET_CF();     // error occurred
            break;
    }
}

// The principle of this routine is to copy directly from flash to the ram disk
// Using the same call that is used to read the flash disk. This routine is
// called from The assembly section during post. It is commented out here
// Because it was also commented out in the original zet bios and I tried
// uncommenting it there and building the old way and it did not work. It does
// not work here either. I have not been able to debug it. Maybe someone can
// figure it out. It would be nice to have, but it is not working right now.

void MakeRamdisk(void)
{
/*    
    Bit16u Sector, base_count;
    outb(EMS_ENABLE_REG, EMS_ENABLE_VAL);               // Turn on EMS from 0xB0000 - 0xBFFFF
    for(Sector = 0; Sector < SECTOR_COUNT; Sector++) {  // Configure the sector address
        outw(FLASH_PAGE_REG, Sector);                   // Select the Flash Disk Sector
        base_count = GetRamdiskSector(Sector);  // Select the Flash Page and get the address within the page of the Sector
        transf_sect_drive_a(EMS_SECTOR_OFFSET, base_count);     // We now have the correct page of flash selected and the sector is always in the same place so just pass the place to copy it too
    }
*/
}

// The RAM Disk is stored at 0x110000 to 0x277FFF in the SDRAM
static Bit16u GetRamdiskSector(Bit16u Sector)
{
    Bit16u Page;
    // The bits above the upper five bits tells us which memory location
    // The lower five bits tells us where in the 16K Page the Sector is
    Page = RAM_DISK_BASE + (Sector >> 5);
    outb(EMS_PAGE1_REG, Page);       // Set the first 16K
    return((Sector & 0x001F) << 9); // Return the memory location within the sector
}

//  Transfer Sector drive
#define FLASH_FLOPPY   0x010000         // Starting address of floppy on flash

static void transf_sect_drive_a(Bit16u Sector, Bit16u s_segment, Bit16u s_offset)
{
    Bit32u Flash_Addr;
    Bit16u  MSB, LSB;

    Flash_Addr = (Bit32u)Sector;
    Flash_Addr = (Flash_Addr * 256 + FLASH_FLOPPY) & 0x00FFFFFF; // can not be more than 24 bits
    MSB = (Flash_Addr >> 16) & 0xFFFF;  // Most  siginificant bits of the address
    LSB = (Flash_Addr      ) & 0xFFFF;  // Least siginificant bits  of the address

    __asm {
                push  ax                 // Save all the registers we are
                push  bx                 // about to use onto the stack
                push  cx
                push  dx
                push  di
                push  ds

                mov   ax, s_segment      // Load the segment address
                mov   ds, ax             // intot the data segment register
                mov   bx, s_offset       // load the offset
                cmp   bx, 0xfe00         // adjust if there will be an overrun
                jbe   transf_dat         // If no adjustment needed, do the transfer

                sub   bx, 0x0200         // sub 512 bytes from offset
                mov   ax, ds             // get the old segment
                add   ax, 0x0020         // add 512 to segment
                mov   ds, ax             // make this our new segment

    transf_dat: mov   dx, FLASH_PORT+2   // Set DX reg to FLASH IO port for upper address bits
                mov   ax, MSB            // Load start address MSB
                out   dx, ax             // Save MSB address word
                mov   cx, 256            // 512 bytes in 1 sector, done 1 word at a time
                mov   di, bx             // put offset into data index register
                mov   bx, LSB            // Flash LSB

   sectloop:    mov   ax, bx             // Put bx into ax
                mov   dx, FLASH_PORT     // Set DX reg to FLASH IO port for LSB
                out   dx, ax             // Save LSB address word
                mov   dx, FLASH_PORT     // Set DX reg to FLASH IO port
                in    ax, dx             // read byte from flash
                mov   ds:[di], ax        // write word
                inc   di                 // Increment to next RAM address
                inc   di                 // Increment to next RAM address
                inc   bx                 // Increment to next flash address location
                loop  sectloop           // Loop 256 times

                pop   ds
                pop   di
                pop   dx
                pop   cx
                pop   bx                 // Restore all our
                pop   ax                 // saved registers from the stack
    }
}

// INT13 Diskette service function
void __cdecl int13_diskette_function(rDS, rES, rDI, rSI, rBP, rBX, rDX, rCX, rAX, rIP, rCS, rFLAGS)
Bit16u rDS, rES, rDI, rSI, rBP, rBX, rDX, rCX, rAX, rIP, rCS, rFLAGS;
{
    Bit8u  drive, num_sectors, track, sector, head;
    Bit8u  drive_type, num_floppies;
    Bit16u last_addr, base_address, base_count;
    Bit16u log_sector, j, RamAddress;

    SET_IF();   // Turn on IF when Flag Register is popped off the stack
    switch(GET_AH()) {
    
        case 0x00:                // Disk controller reset
            drive = GET_DL();     // Was here but that meant that drive was not set for other cases
            set_diskette_ret_status(0);
            set_diskette_current_cyl(drive, 0); // Current cylinder
            SET_AH(0);                          // disk operation status (see ~INT 13,STATUS~)
            CLEAR_CF();                         // CF = 0 if Successful
            break;

        case 0x01:                              // Disk status
            set_diskette_ret_status(0);
            SET_AL(0);                          // no error
            CLEAR_CF();                         // CF = 0 if Successful
            break;

        case 0x02:                      // Read Diskette Sectors
            num_sectors = GET_AL();     // number of sectors to read (1-128 dec.)
            track       = GET_CH();     // track/cylinder number (0-1023 dec., see below)
            sector      = GET_CL();     // CL = sector number (1-17 dec.)
            head        = GET_DH();     // head number (0-15 dec.)
            drive       = GET_DL();     // drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)

            if((drive > 1) || (head > 1) || (sector == 0) || (num_sectors == 0) || (num_sectors > 72)) {
                BX_INFO("int13_diskette: read/write/verify: parameter out of range\n");
                set_diskette_ret_status(1);
                SET_AH(1);
                SET_AL(0);       // No sectors have been read
                SET_CF();        // An error occurred
                return;
            }

            // a 1.44MB floppy actually has 1,474,560 bytes, 2*80*18= 2880 sectors *512= 1,474,560 (ta da)
            //   2 sides (2 heads)
            //  80 tracks per side
            //  18 sectors per track
            // 512 bytes per sector
            log_sector  = track * 36 + head * 18 + sector - 1;  // Calculate the first sector we are going to read
            if(drive == DRIVE_A) {                   // This is the Flash Based Drive
                for(j = 0; j < num_sectors; j++) {
                    transf_sect_drive_a((log_sector + j), rES, (rBX + (j << 9)));   // now just pass the place to copy it too, j<<9 is the same thing as multiplying by 512
                }                                                                   // a good optimizing compiler probably does this for you anyway
            }
            else {                  // This is the SDRAM based drive
                base_address = (rES << 4) + rBX;           // Base Address is upper 12 bits of segment + offset
                base_count   = (num_sectors * 512);        // Number of bytes to be transfered 
                last_addr = base_address + base_count -1;  // Compute the last address is in the same segment
                if(last_addr < base_address) {             // If the last address is less than the base then there must have been an overflow above !
                    BX_INFO("int13_diskette - 03: 64K boundary overrun\n");
                    SET_AH(0x09);
                    set_diskette_ret_status(0x09);
                    SET_AL(0x00);                                    // No sectors have been read
                    SET_CF();                                        // An error occurred
                    return;
                }
                for(j = 0; j < num_sectors; j++) {
                    BX_INFO("int13_diskette - 02: Accessing ramdisk\n");
                    RamAddress = GetRamdiskSector(log_sector + j);  // Pass in the sector which will set the right RAM page and give back the ram address
                    base_count = base_address + (j << 9);
                    memcpyb(last_addr, base_count, EMS_SECTOR_OFFSET, RamAddress, SECTOR_SIZE);  // Copy the sector
                }
            }
            set_diskette_current_cyl(drive, track); // ??? should track be new val from return_status[3] ?
            SET_AH(0);      // AH = 0, sucess AL = number of sectors read (same value as passed)
            CLEAR_CF();     // success
            break;

        case 0x08:                  // read diskette drive parameters
            drive = GET_DL();       //BX_DEBUG_INT13_FL("floppy f08\n");
            if(drive > 1) {
                BX_INFO("int13_diskette - 08: drive >1\n");
                SET_AX(0);
                SET_BX(0);
                SET_CX(0);
                SET_DX(0);
                SET_WORD(rES, 0);
                SET_WORD(rDI, 0);
                SET_DL(num_floppies);
                SET_CF();
                return;
            }
            drive_type = 0x44;      /// inb_cmos(0x10);
            num_floppies = 0;
            if(drive_type & 0xf0) num_floppies++;
            if(drive_type & 0x0f) num_floppies++;
            if(drive == 0) drive_type >>= 4;
            else           drive_type &= 0x0f;
            SET_BH(0);
            SET_BL(drive_type);     // CMOS Drive type
            SET_AH(0);
            SET_AL(0);
            SET_DL(num_floppies);
            switch(drive_type) {
                case 0:                         // none
                    SET_CX(0x00);               // N/A
                    SET_DH(0x00);               // max head #
                    break;

                case 1:                         // 360KB, 5.25"
                    SET_CX(0x2709);             // 40 tracks, 9 sectors
                    SET_DH(0x01);               // max head #
                    break;

                case 2:                         // 1.2MB, 5.25"
                    SET_CX(0x4f0f);             // 80 tracks, 15 sectors
                    SET_DH(0x01);               // max head #
                    break;

                case 3:                         // 720KB, 3.5"
                    SET_CX(0x4f09);             // 80 tracks, 9 sectors
                    SET_DH(0x01);               // max head #
                    break;

                case 4:                         // 1.44MB, 3.5"
                    SET_CX(0x4f12);             // 80 tracks, 18 sectors
                    SET_DH(0x01);               // max head #
                    break;

                case 5:                         // 2.88MB, 3.5"
                    SET_CX(0x4f24);             // 80 tracks, 36 sectors
                    SET_DH(0x01);               // max head #
                    break;

                case 6:                         // 160k, 5.25"
                    SET_CX(0x2708);             // 40 tracks, 8 sectors
                    SET_DH(0x00);               // max head #
                    break;

                case 7:                         // 180k, 5.25"
                    SET_CX(0x2709);             // 40 tracks, 9 sectors
                    SET_DH(0x00);               // max head #
                    break;

                case 8:                         // 320k, 5.25"
                    SET_CX(0x2708);             // 40 tracks, 8 sectors
                    SET_DH(0x01);               // max head #
                    break;

                default:                        // Somthing went wrong
                    BX_PANIC("floppy: int13: bad floppy type\n");
                    break;
            }
            SET_WORD(rDI, 0xefc7);  // This table is hard coded into the bios at this location
            SET_WORD(rES, 0xf000);  // This is done for compatibility purposes
            CLEAR_CF();             // success, disk status not changed upon success 
            break;
        
        case 0x15:                  // read diskette drive type
            drive = GET_DL();       // BX_DEBUG_INT13_FL("floppy f15\n");
            if(drive > 1) {
                BX_INFO("int13_diskette - 15: drive >1\n");
                SET_AH(0);          // only 2 drives supported
                SET_CF();           // set_diskette_ret_status here ???
                return;
            }
            drive_type = 0x44;            // inb_cmos(0x10);
            if(drive == 0) drive_type >>= 4;
            else           drive_type &= 0x0f;
            if(drive_type == 0) SET_AH(0); // drive not present
            else                SET_AH(1); // drive present, does not support change line
            CLEAR_CF();                     // successful
            break;

        case 0x03:                      // Write disk sector
            num_sectors = GET_AL();     // number of sectors to write (1-128 dec.)
            track       = GET_CH();     // track/cylinder number (0-1023 dec.)
            sector      = GET_CL();     // sector number (1-17 dec., see below)
            head        = GET_DH();     // DH = head number (0-15 dec.)
            drive       = GET_DL();     // drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)

            if(drive == DRIVE_B) {      // Writing only works on Drive B
                if((drive > 1) || (head > 1) || (sector == 0) || (num_sectors == 0) || (num_sectors > 72)) {
                    BX_INFO("int13_diskette: read/write/verify: parameter out of range\n");
                    SET_AH(0x01);
                    set_diskette_ret_status(1);
                    SET_AL(0x00);                          // No sectors have been read
                    SET_CF();                              // An error occurred
                    return;
                }
                base_address = (rES << 4) + rBX;           // Base Address is upper 12 bits of segment + offset
                base_count   = (num_sectors * 512);        // Number of bytes to be transfered 
                last_addr = base_address + base_count -1;  // Compute the last address is in the same segment
                if(last_addr < base_address) {             // If the last address is less than the base then there must have been an overflow above !
                    BX_INFO("int13_diskette - 03: 64K boundary overrun\n");
                    SET_AH(0x09);
                    set_diskette_ret_status(0x09);
                    SET_AL(0x00);                                    // No sectors have been read
                    SET_CF();                                        // An error occurred
                    return;
                }
                log_sector    = track * 36 + head * 18 + sector - 1;    // Calculate the first sector we are going to read

                // This is the SDRAM based drive
                for(j = 0; j < num_sectors; j++) {
                    RamAddress = GetRamdiskSector(log_sector + j);   // Pass in the sector which will set the right RAM page and give back the ram address
                    base_count = base_address + (j << 9);
                    memcpyb(EMS_SECTOR_OFFSET, RamAddress, rES, base_count, SECTOR_SIZE);        // Copy the sector
                }
                set_diskette_current_cyl(drive, track);   // ??? should track be new val from return_status[3] ?
                SET_AH(0x00); // success  - AL = number of sectors read (same value as passed)
                CLEAR_CF();   // success
                break;
            }
        default:     // If not B Drive, then Fall Through to error message
            BX_INFO("int13_diskette: unsupported AH=%02x\n", GET_AH());
            SET_AH(0x01); // signal error
            set_diskette_ret_status(1);
            SET_CF();
            break;
    }
}
//--------------------------------------------------------------------------
static void set_diskette_ret_status(Bit8u value)
{
    write_byte(0x0040, 0x0041, value);
}
//--------------------------------------------------------------------------
static void set_diskette_current_cyl(Bit8u drive, Bit8u cyl)
{
    if(drive > 1) drive = 1;    // Temporary hack: for MSDOS
    write_byte(0x0040, 0x0094 + drive, cyl);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// Get boot vector - only called by INT19 Support Function
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static Bit8u get_boot_vector(Bit16u i, ipl_entry_t BASESTK *e)
{
    Bit16u count;
    Bit16u ss = get_SS();
    count = read_word(IPL_SEG, IPL_COUNT_OFFSET); // Get the count of boot devices, and refuse to overrun the array 
    if(i >= count) return(0);                     // OK to read this device 
    memcpyb(ss, (Bit16u)e, IPL_SEG, IPL_TABLE_OFFSET + i * sizeof(*e), sizeof(*e));
    return(1);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// print_boot_device - displays the boot device  - only called by INT19 Support Function
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static void print_boot_device(ipl_entry_t BASESTK *e)
{
    Bit16u type;
    char description[33];
    Bit16u ss = get_SS();
    type = e->type;
  
    if(type == IPL_TYPE_BEV) type = 0x04; // NIC appears as type 0x80 
    if(type == 0 || type > 0x04) BX_PANIC("Bad drive type\n");

    bios_printf(BIOS_PRINTF_SCREEN, "Booting device: %s", drivetypes[type]);
 
    if(type == 4 && e->description != 0) {    // print product string if BEV, first 32 bytes are significant 
        memcpyb(ss, (Bit16u)&description, (Bit16u)(e->description >> 16), (Bit16u)(e->description & 0xffff), 32);
        description[32] = 0; // terminate string 
        bios_printf(BIOS_PRINTF_SCREEN, " [%S]", ss, description);
    }
    bios_printf(BIOS_PRINTF_SCREEN, "\n\n");
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT14 Support Function - Serail Comm
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int14_function(Bit16u rAX, Bit16u rDX, Bit16u rDS, Bit16u rIP, Bit16u rCS, Bit16u rFLAGS)
{
    Bit16u addr, timer, val16;
    Bit8u  counter, val8;

    addr    = read_word(0x0040, (rDX << 1));
    counter = read_byte(0x0040, 0x007C + rDX);

    __asm { sti };

    if((rDX < 4) && (addr > 0)) {
        switch(GET_AH()) {
            case 0:
                outb((addr + 3), inb(addr + 3) | 0x80);
                if(GET_AL() & 0xE0 == 0) {
                    outb(addr, 0x17);
                    outb(addr+1, 0x04);
                }
                else {
                    val16 = 0x600 >> (((GET_AL()) & 0xE0) >> 5);
                    outb(addr, val16 & 0xFF);
                    outb((addr + 1), val16 >> 8);
                }
                val8 = GET_AL() & 0x1F; outb((addr + 3), val8);
                val8 = inb(addr + 5); SET_AH(val8);
                val8 = inb(addr + 6); SET_AL(val8);
                CLEAR_CF();
                break;
            case 1:
                timer = read_word(0x0040, 0x006C);
                while(((inb(addr+5) & 0x60) != 0x60) && (counter)) {
                     val16 = read_word(0x0040, 0x006C);
                    if(val16 != timer) {
                        timer = val16;
                        counter--;
                    }
                }
                if(counter > 0) {
                    outb(addr, GET_AL());
                    val8 = inb(addr + 5); SET_AH(val8);
                }
                else {
                    SET_AH(0x80);
                }
                CLEAR_CF();
                break;
            case 2:
                timer = read_word(0x0040, 0x006C);
                while(((inb(addr + 5) & 0x01) == 0) && (counter)) {
                    val16 = read_word(0x0040, 0x006C);
                    if(val16 != timer) {
                        timer = val16;
                        counter--;
                    }
                }
                if(counter > 0) {
                    val8 = inb(addr + 5); SET_AH(val8);
                    val8 = inb(addr    ); SET_AL(val8);
                }
                else {
                    SET_AH(0x80);
                }
                CLEAR_CF();
                break;
            case 3:
                val8 = inb(addr + 5); SET_AH(val8);
                val8 = inb(addr + 6); SET_AL(val8);
                CLEAR_CF();
                break;
            default:
                SET_CF();       // Unsupported
        }
    }
    else {
        SET_CF(); // Unsupported
    }
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT15 STUB - Support Function - nothing really supported here 
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int15_function(rDI, rSI, rBP, rBX, rDX, rCX, rAX, rES, rDS,  rIP, rCS, rFLAGS)
Bit16u rDI, rSI, rBP, rBX, rDX, rCX, rAX;   // REGS pushed via pusha
Bit16u rES, rDS,  rIP, rCS, rFLAGS;
{                           
    Bit16u ebda_seg=read_word(0x0040,0x000E);        // BX_DEBUG_INT15("int15 AX=%04x\n",regs.u.r16.ax);

    switch(GET_AH()) {

         case 0x52:         // removable media eject
            CLEAR_CF();
            SET_AH(0);      // "ok ejection may proceed"
            break;

        case 0x91:          // Interrupt complete.  Called by Int 16h when key becomes available 
            CLEAR_CF();
            SET_AH(0);      // "ok ejection may proceed"
            break;

        case 0xc0:
            SET_WORD(rBX, BIOS_CONFIG_TABLE);   // This table is hard coded into the bios at this location
            SET_WORD(rES, 0xf000);              // This is the segment address of the rom bios
            SET_AH(0);                          // success
            CLEAR_CF();                         // CF clear on success
            break;

        case 0xc1:
            SET_WORD(rES, ebda_seg);  // return ebda segment address on stack
            CLEAR_CF();
            break;
      
        default:        
            BX_INT15_DEBUG_PRINTF("INT15 Unsupported Function AL= %02x AH= %02x\n", (GET_AL()), (GET_AH()));  
            SET_CF();
            SET_AH(UNSUPPORTED_FUNCTION);
            break;
    }
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT15 - Mouse Support Function
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int15_function_mouse(rDI, rSI, rBP, rBX, rDX, rCX, rAX, rES, rDS,  rIP, rCS, rFLAGS)
Bit16u rDI, rSI, rBP, rBX, rDX, rCX, rAX;   // REGS pushed via pusha
Bit16u rES, rDS,  rIP, rCS, rFLAGS;
{
    Bit8u  comm_byte, mouse_data1, mouse_data2, mouse_data3;
    Bit8u  mouse_flags_2;
    Bit16u mouse_driver_seg;
    Bit16u mouse_driver_offset;
    Bit16u ebda_seg = read_word(0x0040,0x000E);

    BX_INT15_DEBUG_PRINTF("INT15 AL= %02x BH= %02x\n", (GET_AL()), (GET_BH()));        // Debugging info

    if(GET_AH() != 0xC2) {          // Defensive measure, should always be 0xC2 here due to asm call
        SET_CF();
        SET_AH(UNSUPPORTED_FUNCTION);
        BX_INT15_DEBUG_PRINTF("Error int15 mouse AH != 0xC2\n", (unsigned)(GET_AH()));
        return;
    }

    // Return Codes status in AH
    // =========================
    // 00: success
    // 01: invalid subfunction (AL > 7)
    // 02: invalid input value (out of allowable range)
    // 03: interface error
    // 04: resend command received from mouse controller, device driver should attempt command again
    // 05: cannot enable mouse, since no far call has been installed
    // 80/86: mouse service not implemented

    switch(GET_AL()) {
        case 0:                     // Disable/Enable Mouse functions, set by BH
            switch(GET_BH()) {
                case 0:                                     // Disable Mouse            
                    inhibit_mouse_int_and_events();         // disable IRQ12 and packets
                    mouse_data1 = send_to_mouse_ctrl(0xF5); // disable mouse command
                    if(mouse_data1 == 0xFA) {               // Proper Ack was returned
                        CLEAR_CF();                         // Sucess flag indication
                        SET_AH(0);                          // Sucess Code
                    }
                    else {                                  // Did not receive ack
                        SET_CF();                           // Error flag
                        SET_AH(3);                          // Interface error code
                        BX_INT15_DEBUG_PRINTF("Disable Mouse returned %02x (should be ack)\n", (unsigned)mouse_data1); 
                    }
                    break;
                    
                case 1:                                         // Enable Mouse 
                    mouse_flags_2 = read_byte(ebda_seg, 0x027);
                    if((mouse_flags_2 & 0x80) == 0) {           // INT 15h C2 Enable Mouse, no far call handler
                        SET_CF();                               // Error Flag
                        SET_AH(5);                              // No far call installed Error code
                    }
                    else {
                        inhibit_mouse_int_and_events();         // disable IRQ12 and packets
                        mouse_data1 = send_to_mouse_ctrl(0xF4); // Send enable mouse command to mouse
                        if(mouse_data1 == 0xFA) {           // Proper Ack was returned
                            enable_mouse_int_and_events();  // turn IRQ12 and packet generation on
                            CLEAR_CF();                     // Sucess flag indication
                            SET_AH(0);                      // Sucess Code
                        }
                        else {                              // did not receive ack from mouse
                            SET_CF();                       // Error flag
                            SET_AH(3);                      // Interface error code
                            BX_INT15_DEBUG_PRINTF("Enable Mouse returned %02x (should be ack)\n", (unsigned)mouse_data1); 
                        }
                    }
                    break;

                default:            // Invalid subfunction  
                    SET_CF();       // Error Flag
                    SET_AH(1);      // Invalid subfunction return code
                    break;
            }
            break;
            
        case 5:                             // Initialize Mouse 
            if((GET_BH()) == 3) {                                       // Must always be a 3
                write_byte(ebda_seg, 0x0026, 0x00);                     // Reset packet count
                write_byte(ebda_seg, 0x0027, 0x03);                     // Set packet size
                CLEAR_CF();                                             // Sucess flag indication
                SET_AH(0);                                              // Sucess Code
            }
            else {                          // Invalid input
                SET_CF();                   // Error Flag
                SET_AH(2);                  // Invalid input return code
                BX_INT15_DEBUG_PRINTF("Initialize Mouse invalid input %02x\n", (unsigned)(GET_BH())); 
            }
            break;
                
        case 1:                                         // Reset Mouse
            inhibit_mouse_int_and_events();             // disable IRQ12 and packets
            write_byte(ebda_seg, 0x0026, 0x00);         // Reset packet count
            write_byte(ebda_seg, 0x0027, 0x03);         // Set packet size
            mouse_data3 = send_to_mouse_ctrl(0xFF);     // reset mouse command
            if(mouse_data3 == 0xFA) {                   // Received proper ack
                mouse_data1 = get_mouse_data();         // Mouse should return AA
                mouse_data2 = get_mouse_data();         // Mouse should return 00
                enable_mouse_int_and_events();          // turn IRQ12 and packet generation on
                CLEAR_CF();                             // Sucess flag indication
                SET_AH(0);                              // Sucess Code
                SET_BL(mouse_data1);                    // Return mouse codes
                SET_BH(mouse_data2);                    // Return mouse codes
            }
            else if(mouse_data3 == 0xFE) {              // Mouse sends this if there is some problem
                SET_CF();                               // Error Flag
                SET_AH(3);                              // Interface error return code
                BX_INT15_DEBUG_PRINTF("Reset Mouse returned %02x\n", (unsigned)mouse_data3);

            }
            else {                                      // no valid mouse response received
                SET_CF();                               // Error Flag
                SET_AH(3);                              // Interface error return code
                BX_INT15_DEBUG_PRINTF("Mouse reset returned %02x (should be ack)\n", (unsigned)mouse_data3);
            }
            break;

        case 2:                                     // Set Sample Rate
            switch(GET_BH()) {
                case 0:  mouse_data1 =  10; break; //  10 reports/sec
                case 1:  mouse_data1 =  20; break; //  20 reports/sec
                case 2:  mouse_data1 =  40; break; //  40 reports/sec
                case 3:  mouse_data1 =  60; break; //  60 reports/sec
                case 4:  mouse_data1 =  80; break; //  80 reports/sec
                case 5:  mouse_data1 = 100; break; // 100 reports/sec (default)
                case 6:  mouse_data1 = 200; break; // 200 reports/sec
                default: mouse_data1 =   0;
            }
            if(mouse_data1 == 0) {
                SET_CF();                               // Error Flag
                SET_AH(UNSUPPORTED_FUNCTION);           // Return unsupported function code
                BX_INT15_DEBUG_PRINTF("Set Sample Rate Invalid parm %02x\n", (unsigned)(GET_BH()));
            }
            else {                                          // User tried to send an unsupported value
//                mouse_data2 = send_to_mouse_ctrl(0xF3);     // set sample rate command to mouse
//                mouse_data2 = send_to_mouse_ctrl(mouse_data1); // then send the data
                CLEAR_CF();                     // Sucess flag indication
                SET_AH(0);                      // Sucess Code
            }
/*
                mouse_data2 = send_to_mouse_ctrl(0xF3);     // set sample rate command to mouse
                if(mouse_data2 == 0xFA) {                          // If we received proper ack code
                    mouse_data2 = send_to_mouse_ctrl(mouse_data1); // then send the data
                    if(mouse_data2 == 0xFA) {                      // If we received proper ack code
                        CLEAR_CF();                     // Sucess flag indication
                        SET_AH(0);                      // Sucess Code
                    }
                }
                else {                                  // Mouse did not send the ack code
                    SET_CF();                           // Error Flag
                    SET_AH(UNSUPPORTED_FUNCTION);       // Return unsupported function code
                    BX_INT15_DEBUG_PRINTF("Set Sample Rate returned %02x (should be ack)\n", (unsigned)mouse_data2);
                }
            }
*/
            break;

        case 3:             // Set Resolution
            // BH:
            //      0 =  25 dpi, 1 count  per millimeter
            //      1 =  50 dpi, 2 counts per millimeter
            //      2 = 100 dpi, 4 counts per millimeter
            //      3 = 200 dpi, 8 counts per millimeter
            if((GET_BH()) < 4) {                                // Make sure this is a supported value
                comm_byte = inhibit_mouse_int_and_events();     // disable IRQ12 and packets
                mouse_data1 = send_to_mouse_ctrl(0xE8);         // set resolution command
                if(mouse_data1 != 0xFA) {
                    SET_CF();                           // Error Flag
                    SET_AH(UNSUPPORTED_FUNCTION);       // Return unsupported function code
                    BX_INT15_DEBUG_PRINTF("Set Resolution returned1 %02x (should be ack)\n", (unsigned)mouse_data1);
                }
                else {
                    mouse_data1 = send_to_mouse_ctrl(GET_BH());    // Send value to mouse
                    if(mouse_data1 != 0xFA) {
                        SET_CF();                           // Error Flag
                        SET_AH(3);                          // Interface error return code
                        BX_INT15_DEBUG_PRINTF("Set Resolution returned2 %02x (should be ack)\n", (unsigned)mouse_data1);
                    }
                    else {                                  // If all acks were received properly
                        CLEAR_CF();                         // Sucess flag indication
                        SET_AH(0);                          // Sucess Code
                    }
                }
                set_kbd_command_byte(comm_byte);            // restore IRQ12 and serial enable
            }
            else {                                      // User sent an unsupported value to us
                SET_CF();                               // Error Flag
                SET_AH(UNSUPPORTED_FUNCTION);           // Return unsupported function code
                BX_INT15_DEBUG_PRINTF("Set Resolution invalid parm %02x\n", (unsigned)(GET_BH()));
            }
            break;

        case 4:                                     // Get Device ID
            inhibit_mouse_int_and_events();         // disable IRQ12 and packets
            mouse_data1 = send_to_mouse_ctrl(0xF2); // get mouse ID command
            if(mouse_data1 == 0xFA) {               // If ack received
                mouse_data2 = get_mouse_data();     // get device ID
                CLEAR_CF();                         // Sucess flag indication
                SET_AH(0);                          // Sucess Code
                SET_BH(mouse_data2);                // return the paramter
            }
            else {                                  // Mouse did not recognize the 0xF2 command
                SET_CF();                           // Error Flag
                SET_AH(UNSUPPORTED_FUNCTION);       // Return unsupported function code
                BX_INT15_DEBUG_PRINTF("Get Device ID returned %02x (should be ack)\n", (unsigned)mouse_data1);
            }
            break;

        case 6:                    // Return Status & Set Scaling Factor...
            switch(GET_BH()) {
                case 0:                             // Return Status
                    comm_byte = inhibit_mouse_int_and_events();     // disable IRQ12 and packets
                    mouse_data1 = send_to_mouse_ctrl(0xE9);         // get mouse info command
                    if(mouse_data1 == 0xFA) {
                        mouse_data1 = get_mouse_data();
                        mouse_data2 = get_mouse_data();
                        mouse_data3 = get_mouse_data();
                        CLEAR_CF();
                        SET_AH(0);
                        SET_BL(mouse_data1);
                        SET_CL(mouse_data2);
                        SET_DL(mouse_data3);
                    }
                    else {
                        SET_CF();                           // Error Flag
                        SET_AH(UNSUPPORTED_FUNCTION);       // Return unsupported function code
                        BX_INT15_DEBUG_PRINTF("Get Status returned %02x (should be ack)\n", (unsigned)mouse_data1);
                    }
                    set_kbd_command_byte(comm_byte);        // restore IRQ12 and serial enable
                    break;

                case 1:     // Set Scaling Factor to 1:1
                case 2:     // Set Scaling Factor to 2:1
                    comm_byte = inhibit_mouse_int_and_events(); // disable IRQ12 and packets
                    if((GET_BH()) == 1) mouse_data1 = send_to_mouse_ctrl(0xE6);
                    else                mouse_data1 = send_to_mouse_ctrl(0xE7);
                    if(mouse_data1 == 0xFA) {
                        CLEAR_CF();
                        SET_AH(0);
                    }
                    else {
                        SET_CF();                           // Error Flag
                        SET_AH(UNSUPPORTED_FUNCTION);
                        BX_INT15_DEBUG_PRINTF("Set Scaling returned1 %02x (should be ack)\n", (unsigned)mouse_data1);
                    }
                    set_kbd_command_byte(comm_byte); // restore IRQ12 and serial enable
                    break;

                default: BX_INT15_DEBUG_PRINTF("Error: INT 15h C2 AL=6, BH=%02x\n", (unsigned)(GET_BH()));
                    break;
            }
            break;

       case 7:         // Set Mouse Handler Address
           mouse_driver_seg    = rES;
           mouse_driver_offset = rBX;
           write_word(ebda_seg, 0x0022, mouse_driver_offset);
           write_word(ebda_seg, 0x0024, mouse_driver_seg);
           mouse_flags_2 = read_byte(ebda_seg, 0x0027);
           if(mouse_driver_offset == 0 && mouse_driver_seg == 0) {  // remove handler
               if((mouse_flags_2 & 0x80) != 0 ) {
                   mouse_flags_2 &= ~0x80;
                   inhibit_mouse_int_and_events(); // disable IRQ12 and packets
               }
           }
           else {      // install handler
               mouse_flags_2 |= 0x80;
           }
           write_byte(ebda_seg, 0x0027, mouse_flags_2);
           CLEAR_CF();
           SET_AH(0);
           break;

       default:
           BX_INT15_DEBUG_PRINTF("case default INT 15h C2 AL=%02x, BH=%02x\n", (unsigned char)(GET_AH()),(unsigned char)(GET_BH()));
           SET_AH(1);                   // invalid function
           SET_CF();
           break;
    }
}

//--------------------------------------------------------------------------
// static char panic_msg_keyb_buffer_full[] = "%s: keyboard input buffer full\n";

//--------------------------------------------------------------------------
// Wait for data - waits for data to come in by checking control register.
// returns after either the data came in, or there was a time out
//--------------------------------------------------------------------------
static void wait_mouse_event(void)
{
    Bit8u  ticks;
    ticks = read_byte(0x0040, 0x006C); // get current tick count
    while((inb(MOUSE_CNTL) & 0x01) != 0x01) {
        if((ticks +10) < read_byte(0x0040, 0x006C)) {
            BX_INT15_DEBUG_PRINTF("wait mouse timeout\n");
            break; // time out
        }
    }
}

//--------------------------------------------------------------------------
// Turn off IRQ generation and aux data line
//--------------------------------------------------------------------------
static Bit8u inhibit_mouse_int_and_events(void)
{
    Bit8u command_byte, prev_command_byte;
//  if(inb(MOUSE_CNTL) & 0x02)  BX_PANIC(panic_msg_keyb_buffer_full,"inhibmouse");
    outb(MOUSE_CNTL, 0x20);             // send command to read command byte
    wait_mouse_event();
    prev_command_byte = inb(MOUSE_PORT);
    command_byte = prev_command_byte;                   //while ( (inb(0x64) & 0x02) );
//  if(inb(MOUSE_CNTL) & 0x02)  BX_PANIC(panic_msg_keyb_buffer_full,"inhibmouse");
    command_byte &= 0xfd;       // turn off IRQ 12 generation
    command_byte |= 0x20;       // disable mouse serial clock line
    outb(MOUSE_CNTL, 0x60);     // write command byte
    outb(MOUSE_PORT, command_byte);
    return(prev_command_byte);
}

//--------------------------------------------------------------------------
// Turn on IRQ generation and aux data line
//--------------------------------------------------------------------------
static void enable_mouse_int_and_events(void)
{
    Bit8u command_byte;
//  if(inb(MOUSE_CNTL) & 0x02)  BX_PANIC(panic_msg_keyb_buffer_full,"enabmouse");
    outb(MOUSE_CNTL, 0x21);              // send command byte
    outb(MOUSE_CNTL, 0x20);              // send command byte
    wait_mouse_event();
    command_byte = inb(0x60);
//  if(inb(MOUSE_CNTL) & 0x02) BX_PANIC(panic_msg_keyb_buffer_full,"enabmouse");
    command_byte |= 0x02;       // turn on IRQ 12 generation
    command_byte &= 0xdf;       // enable mouse serial clock line
    outb(MOUSE_CNTL, 0x60);           // write command byte
    outb(MOUSE_PORT, command_byte);
}

//--------------------------------------------------------------------------
// Send Keyboard command byte
//--------------------------------------------------------------------------
static void set_kbd_command_byte(Bit8u command_byte)
{
//  if(inb(MOUSE_CNTL) & 0x02) BX_PANIC(panic_msg_keyb_buffer_full,"setkbdcomm");
//  outb(MOUSE_CNTL, 0xD4);
    outb(MOUSE_CNTL, 0x60);           // write command byte
    outb(MOUSE_PORT, command_byte);
}

//--------------------------------------------------------------------------
// wait for chance to write to ctrl
//--------------------------------------------------------------------------
static Bit8u send_to_mouse_ctrl(Bit8u sendbyte)
{
//  if(inb(MOUSE_CNTL) & 0x02) BX_PANIC(panic_msg_keyb_buffer_full,"sendmouse");
    Bit8u try, mouse_data; 
    try = 5;                                    // Try 5 times before giving up
    do {
        outb(MOUSE_CNTL, 0xD4);                 // Enable sending to mouse
        outb(MOUSE_PORT, sendbyte);             // Send the byte to mouse
        mouse_data = get_mouse_data();          // if no mouse attached, it will return RESEND
        if(mouse_data == 0xFA) break;           // Success
        try--;                                  // Decerement tries
    } while(try);                               // Keep going until try is zero
    return(mouse_data);
}

//--------------------------------------------------------------------------
// Get Mouse Data
//--------------------------------------------------------------------------
static Bit8u get_mouse_data(void)
{
    Bit8u  data;
    wait_mouse_event();
    data = inb(MOUSE_PORT);
    return(data);
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT19 Support Function
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int19_function(void)
{
    Bit16u bootdev;
    Bit8u  bootdrv;
    Bit16u bootseg;
    Bit16u bootip;
    Bit16u status;
    ipl_entry_t e;

    #if SHOW_INT15_DEBUG_MSGS
        outb(UART_LC, 0x83);    // set up uart for 115.2kbps
        outb(UART_TR, 0x01);    // set up uart for 115.2kbps
        outb(UART_IE, 0x00);    // set up uart for 115.2kbps
        outb(UART_LC, 0x03);    // set up uart for 115.2kbps
    #endif

    // Here we assume that BX_ELTORITO_BOOT is defined, so
    //   CMOS regs 0x3D and 0x38 contain the boot sequence:
    //     CMOS reg 0x3D & 0x0f : 1st boot device
    //     CMOS reg 0x3D & 0xf0 : 2nd boot device
    //     CMOS reg 0x38 & 0xf0 : 3rd boot device
    //   boot device codes:
    //     0x00 : not defined
    //     0x01 : first floppy
    //     0x02 : first harddrive
    //     0x03 : first cdrom
    //     0x04 - 0x0f : PnP expansion ROMs (e.g. Etherboot)
    //     else : boot failure
   
    bootdev  = read_word(IPL_SEG, IPL_SEQUENCE_OFFSET);   // Read user selected device 
    bootdev -= 1;       // Translate from CMOS runes to an IPL table offset by subtracting 1 

    if(get_boot_vector(bootdev, &e) == 0) {     // Read the boot device from the IPL table 
        printf("Invalid boot device (0x%x)\n", bootdev);
        return;
    }
    // Do the loading, and set up vector as a far pointer to the boot
    // address, and bootdrv as the boot drive 
    print_boot_device(&e);

    switch(e.type) {
        case IPL_TYPE_FLOPPY:   // FDD 
        case IPL_TYPE_HARDDISK: // HDD 
            bootdrv = (e.type == IPL_TYPE_HARDDISK) ? 0x80 : 0x00;
            bootseg = 0x07c0;
            status = 0;

            __asm {                     // This little routine loads the DOS
                push ax                 // boot sector from disk into the boot location
                push bx                 // Save the working registers
                push cx
                push dx
                mov  dl, bootdrv        // This is the boot drive
                mov  ax, bootseg        // This is the boot segment
                mov  es, ax             // Load segment into ES
                xor  bx, bx             // Offset is zero
                mov  ah, 0x02           // Disk function 2, read diskette sector
                mov  al, 0x01           // Read 1 sector
                mov  ch, 0x00           // From track 0
                mov  cl, 0x01           // and sector 1
                mov  dh, 0x00           // using head 0
                int  0x13               // Call the read sector bios function
                jnc  int19_load_done    // If Carry flag is clear, then status is good    
                mov  ax, 0x0001         // If not then set status flag to bad
                mov  status, ax         // Store it
            int19_load_done:            // Exit the function
                pop  dx                 // By popping our regs
                pop  cx
                pop  bx
                pop  ax
            }

            if(status != 0) {                       // Indicates we had a disk error
                print_boot_failure(e.type, 1);      // show "could not read the boot disk"
                return;
            }

            if(read_word(bootseg, 0x01fe)!= 0xaa55) {    // this is the magic number
                print_boot_failure(e.type, 0);           // "not a bootable disk"
                return;
            }

            bootip   = (bootseg & 0x0fff) << 4;         // Canonicalize bootseg:bootip 
            bootseg &= 0xf000;                          // For the right place to jump to
            break;

        default:                                        // if here then the disk is no good
            return;
    }

    BX_INFO("Booting from %x:%x\n", bootseg, bootip);        // Debugging info 

    __asm {                 // This routine Jumps to the boot vector we just loaded
        pushf               // iret pops ip, then cs, then flags, so push them in the opposite order.
        mov  ax, bootseg    // Here is the return segment to jump to 
        push ax             // push it so it will get popped when we iret
        mov  ax, bootip     // Jump to the start
        push ax             // again push it for later
        mov  ax, 0xaa55     // Set the magic number in ax and the boot drive in dl.
        mov  dl, bootdrv    // Set the boot drive number
        xor  bx, bx         // Clear BX register
        mov  ds, bx         // Data segment  DS = 0
        mov  es, bx         // Also set ES to 0
        mov  bp, bx         // Base pointer = 0
        iret                // Now Go!
    }
    
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// BOOT HALT
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl boot_halt(void)
{
    printf("No more devices to boot - System halted.\n");
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// INT 1A Support function - Time-of-day Service Entry Point
// Input:   AH = 00
// Output:
//          AL = midnight flag, 1 if 24 hours passed since reset
//          CX = high order word of tick count
//          DX = low order word of tick count
//  - incremented approximately 18.206 times per second
//  - at midnight CX:DX is zero
//  - this function can be called in a program to assure the date is
//  updated after midnight; this will avoid the passing two midnights
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
void __cdecl int1a_function(rAX, rCX, rDX, rDI, rSI, rBP, rBX, rDS, rIP, rCS, rFLAGS)
Bit16u rAX, rCX, rDX, rDI, rSI, rBP, rBX, rDS, rIP, rCS, rFLAGS;
{
    Bit16u ticks_low;
    Bit16u ticks_high;
    Bit8u  midnight_flag;
    
    __asm { sti }
    switch(GET_AH()) {
        case 0:             // Get current clock count
            __asm { cli }
            ticks_low     = read_word(0x0040, 0x006C);
            ticks_high    = read_word(0x0040, 0x006E);
            midnight_flag = read_byte(0x0040, 0x0070);
            SET_CX(ticks_high);
            SET_DX(ticks_low); 
            SET_AL(midnight_flag);
            write_byte(0x0040, 0x0070, 0);  // reset flag
            __asm { sti }
            CLEAR_CF();       // Status OK, AH should already be 0  
            break;

        case 1:             // Set Current Clock Count
            __asm { cli }
            ticks_high    = rCX;
            ticks_low     = rDX;
            midnight_flag = 0;      // reset flag
            write_word(0x0040, 0x006C, ticks_low);
            write_word(0x0040, 0x006E, ticks_high);
            write_word(0x0040, 0x0070, midnight_flag);
            __asm { sti }
            SET_AH(0);
            CLEAR_CF();       // Status OK  
            break;
            
        default:
            SET_CF(); // Unsupported
    }
}   


//---------------------------------------------------------------------------
//  End
//---------------------------------------------------------------------------

