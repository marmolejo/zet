/*
 *  Zet PC system VGA BIOS
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

#include "vgabios.h"
#include "vgatables.h"
#include "vgafonts.h"

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// int10 main dispatcher
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
void int10_func(rDI, rSI, rBP, rSP, rBX, rDX, rCX, rAX, rDS, rES, rFLAGS)
Bit16u rDI, rSI, rBP, rSP, rBX, rDX, rCX, rAX, rDS, rES, rFLAGS;
{
    switch(GET_AH()) {     // BIOS functions
        case 0x00:  
            biosfn_set_video_mode(GET_AL());
            switch((rAX & 0x007F)) {
                case 6:  SET_AL(0x3F);   break;
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 7:  SET_AL(0x30);   break;
                default: SET_AL(0x20);
            }
            break;
        case 0x01:
            biosfn_set_cursor_shape(GET_CH(), GET_CL());
            break;
        case 0x02:
            biosfn_set_cursor_pos(GET_BH(), rDX);
            break;
        case 0x03:
            biosfn_get_cursor_pos(GET_BH(), (Bit16u *)&rCX, (Bit16u *)&rDX);
            break;
        case 0x05:
            biosfn_set_active_page(GET_AL());
            break;
        case 0x06:
            biosfn_scroll(GET_AL(),GET_BH(),GET_CH(),GET_CL(),GET_DH(),GET_DL(),0xFF,SCROLL_UP);
            break;
        case 0x07:
            biosfn_scroll(GET_AL(),GET_BH(),GET_CH(),GET_CL(),GET_DH(),GET_DL(),0xFF,SCROLL_DOWN);
            break;
        case 0x08:
            biosfn_read_char_attr(GET_BH(), (Bit16u *)&rAX);
            break;
        case 0x09:
            biosfn_write_char_attr(GET_AL(), GET_BH(), GET_BL(), rCX);
            break;
        case 0x0A:
            biosfn_write_char_only(GET_AL() ,GET_BH(), GET_BL(), rCX);
            break;
        case 0x0E: // Ralf Brown Interrupt list is WRONG on bh(page), we do output only on the current page !
            biosfn_write_teletype(GET_AL(),0xff,GET_BL(),NO_ATTR);
            break;
        case 0x11:
            switch(GET_AL()) {
                case 0x04:
                case 0x14:  
                    biosfn_load_text_8_16_pat(GET_AL(),GET_BL());
                    break;
            }
            break;
        case 0x13:
            biosfn_write_string(GET_AL(),GET_BH(),GET_BL(),rCX,GET_DH(),GET_DL(),rES,rBP);
            break;
    }
}

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// BIOS functions - mode: Bit 7 is 1 if no clear screen
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
static void biosfn_set_video_mode(Bit8u mode)
{ 
    Bit8u noclearmem = mode & 0x80;
    Bit8u line, mmask, *palette, vpti;
    Bit16u i, twidth, theightm1, cheight;
    Bit8u modeset_ctl, video_ctl, vga_switches;
    Bit16u crtc_addr;
 
    mode = mode & 0x7f;             // The real mode
    line = find_vga_entry(mode);    // find the entry in the video modes
    if(line == 0xFF)  return;       // Could not find it

    vpti = line_to_vpti[line];
    twidth = video_param_table[vpti].twidth;
    theightm1 = video_param_table[vpti].theightm1;
    cheight = video_param_table[vpti].cheight;

    video_ctl = read_byte(BIOSMEM_SEG,BIOSMEM_VIDEO_CTL);    // Read the bios vga control
    vga_switches = read_byte(BIOSMEM_SEG,BIOSMEM_SWITCHES);  // Read the bios vga switches
    modeset_ctl = read_byte(BIOSMEM_SEG,BIOSMEM_MODESET_CTL);// Read the bios mode set control

    // Then we know the number of lines
    // FIXME

    // if palette loading (bit 3 of modeset ctl = 0)
    if((modeset_ctl & 0x08) == 0) {             // Set the PEL mask
        outb(VGAREG_PEL_MASK, vga_modes[line].pelmask);
        outb(VGAREG_DAC_WRITE_ADDRESS, 0x00);    // Set the whole dac always, from 0
        // From which palette
        switch(vga_modes[line].dacmodel) {
            case 0:  palette = (Bit8u *)&palette0;  break;
            case 1:  palette = (Bit8u *)&palette1;  break;
            case 2:  palette = (Bit8u *)&palette2;  break;
            case 3:  palette = (Bit8u *)&palette3;  break;
        }
        // Always 256*3 values
        for(i = 0; i < 0x0100; i++) {
            if(i<=dac_regs[vga_modes[line].dacmodel]) {
                outb(VGAREG_DAC_DATA,palette[(i*3)+0]);
                outb(VGAREG_DAC_DATA,palette[(i*3)+1]);
                outb(VGAREG_DAC_DATA,palette[(i*3)+2]);
            }
            else {
                outb(VGAREG_DAC_DATA, 0);
                outb(VGAREG_DAC_DATA, 0);
                outb(VGAREG_DAC_DATA, 0);
            }
        }
    }
    inb(VGAREG_ACTL_RESET);        // Reset Attribute Ctl flip-flop

    // Set Attribute Ctl
    for(i=0;i<=0x13;i++){
        outb(VGAREG_ACTL_ADDRESS, i);
        outb(VGAREG_ACTL_WRITE_DATA, video_param_table[vpti].actl_regs[i]);
    }
    outb(VGAREG_ACTL_ADDRESS, 0x14);
    outb(VGAREG_ACTL_WRITE_DATA, 0x00);

    // Set Sequencer Ctl
    outb(VGAREG_SEQU_ADDRESS, 0);
    outb(VGAREG_SEQU_DATA, 0x03);
    for(i=1;i<=4;i++) {
        outb(VGAREG_SEQU_ADDRESS, i);
        outb(VGAREG_SEQU_DATA, video_param_table[vpti].sequ_regs[i - 1]);
    }

    // Set Grafx Ctl
    for(i=0;i<=8;i++) {
        outb(VGAREG_GRDC_ADDRESS, i);
        outb(VGAREG_GRDC_DATA, video_param_table[vpti].grdc_regs[i]);
    }

    // Set CRTC address VGA or MDA
    crtc_addr = vga_modes[line].memmodel == MTEXT ? VGAREG_MDA_CRTC_ADDRESS : VGAREG_VGA_CRTC_ADDRESS;

    // Disable CRTC write protection
    outw(crtc_addr,0x0011);
    // Set CRTC regs
    for(i=0; i<=0x18; i++) {
        outb(crtc_addr, i);
        outb(crtc_addr+1, video_param_table[vpti].crtc_regs[i]);
    }

    // Set the misc register
    outb(VGAREG_WRITE_MISC_OUTPUT, video_param_table[vpti].miscreg);

    // Enable video
    outb(VGAREG_ACTL_ADDRESS, 0x20);
    inb(VGAREG_ACTL_RESET);

    if(noclearmem==0x00) {
        if(vga_modes[line].class == TEXT) {
            memsetw(vga_modes[line].sstart, 0, 0x0720, 0x4000); // 32k
        }
        else {
            if(mode<0x0d) {
                memsetw(vga_modes[line].sstart, 0, 0x0000, 0x4000); // 32k
            }
            else {
                outb( VGAREG_SEQU_ADDRESS, 0x02 );
                mmask = inb( VGAREG_SEQU_DATA );
                outb( VGAREG_SEQU_DATA, 0x0f ); // all planes
                memsetw(vga_modes[line].sstart, 0, 0x0000, 0x8000); // 64k
                outb( VGAREG_SEQU_DATA, mmask );
            }
        }
    }

    // Set the BIOS mem
    write_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MODE,mode);
    write_word(BIOSMEM_SEG,BIOSMEM_NB_COLS,twidth);
    write_word(BIOSMEM_SEG,BIOSMEM_PAGE_SIZE,*(Bit16u *)&video_param_table[vpti].slength_l);
    write_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS,crtc_addr);
    write_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS,theightm1);
    write_word(BIOSMEM_SEG,BIOSMEM_CHAR_HEIGHT,cheight);
    write_byte(BIOSMEM_SEG,BIOSMEM_VIDEO_CTL,(0x60|noclearmem));
    write_byte(BIOSMEM_SEG,BIOSMEM_SWITCHES,0xF9);
    write_byte(BIOSMEM_SEG,BIOSMEM_MODESET_CTL,read_byte(BIOSMEM_SEG,BIOSMEM_MODESET_CTL)&0x7f);

    // FIXME We nearly have the good tables. to be reworked
    write_byte(BIOSMEM_SEG,BIOSMEM_DCC_INDEX,0x08);    // 8 is VGA should be ok for now
    write_word(BIOSMEM_SEG,BIOSMEM_VS_POINTER, (Bit16u)video_save_pointer_table);
    write_word(BIOSMEM_SEG,BIOSMEM_VS_POINTER+2, 0xc000);

    // FIXME
    write_byte(BIOSMEM_SEG, BIOSMEM_CURRENT_MSR, 0x00); // Unavailable on vanilla vga, but...
    write_byte(BIOSMEM_SEG, BIOSMEM_CURRENT_PAL, 0x00); // Unavailable on vanilla vga, but...

    if(vga_modes[line].class==TEXT) {
        biosfn_set_cursor_shape(0x06, 0x07);
    }

    // Set cursor pos for page 0..7
    for(i = 0; i < 8; i++) biosfn_set_cursor_pos(i, 0x0000);

    biosfn_set_active_page(0x00);   // Set active page 0

    // Write the fonts in memory
    if(vga_modes[line].class==TEXT)  {
        __asm {
            mov ax, 0x1104     //;; copy and activate 8x16 font
            mov bl, 0x00
            int 0x10
            mov ax, 0x1103
            mov bl, 0x00
            int 0x10
        }
    }
}

//---------------------------------------------------------------------------
static void biosfn_set_cursor_shape(Bit8u CH, Bit8u CL)
{
    Bit16u cheight,curs,crtc_addr;
    Bit8u modeset_ctl;

    CH &= 0x3f;
    CL &= 0x1f;

    curs=(CH<<8)+CL;
    write_word(BIOSMEM_SEG,BIOSMEM_CURSOR_TYPE,curs);

    modeset_ctl=read_byte(BIOSMEM_SEG,BIOSMEM_MODESET_CTL);
    cheight = read_word(BIOSMEM_SEG,BIOSMEM_CHAR_HEIGHT);
    if((modeset_ctl&0x01) && (cheight>8) && (CL<8) && (CH<0x20)) {
        if(CL!=(CH+1))  CH = ((CH+1) * cheight / 8) -1;
        else            CH = ((CL+1) * cheight / 8) - 2;
        CL = ((CL+1) * cheight / 8) - 1;
    }
    // CTRC regs 0x0a and 0x0b
    crtc_addr=read_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS);
    outb(crtc_addr,0x0a);
    outb(crtc_addr+1,CH);
    outb(crtc_addr,0x0b);
    outb(crtc_addr+1,CL);
}

//---------------------------------------------------------------------------
static void biosfn_set_cursor_pos(Bit8u page, Bit16u cursor)
{
    Bit8u current;
    Bit16u crtc_addr;

    if(page>7) return;  // Should not happen...
    
    write_word(BIOSMEM_SEG, BIOSMEM_CURSOR_POS+2*page, cursor); // Bios cursor pos
    current=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);    // Set the hardware cursor
    if(page==current) {     
        crtc_addr=read_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS);  // CRTC regs 0x0e and 0x0f
        outb(crtc_addr,0x0e);
        outb(crtc_addr+1,(cursor&0xff00)>>8);
        outb(crtc_addr,0x0f);
        outb(crtc_addr+1,cursor&0x00ff);
    }
}

//---------------------------------------------------------------------------
static void biosfn_get_cursor_pos(Bit8u page, Bit16u *shape, Bit16u *pos)
{
    Bit16u ss = get_SS();

    write_word(ss, (Bit16u)shape, 0);       // Default
    write_word(ss, (Bit16u)pos,   0);

    if(page>7)return;              // FIXME should handle VGA 14/16 lines
    write_word(ss, (Bit16u)shape, read_word(BIOSMEM_SEG, BIOSMEM_CURSOR_TYPE));
    write_word(ss, (Bit16u)pos,   read_word(BIOSMEM_SEG,BIOSMEM_CURSOR_POS+page*2));
}

//---------------------------------------------------------------------------
static void biosfn_set_active_page(Bit8u page)
{
    Bit16u cursor,dummy,crtc_addr;
    Bit16u nbcols,nbrows,address;
    Bit8u mode,line;

    if(page>7)return;

    // Get the mode
    mode=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MODE);
    line=find_vga_entry(mode);
    if(line==0xFF)return;

    // Get pos curs pos for the right page
    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
    
    if(vga_modes[line].class==TEXT) {
        // Get the dimensions
        nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);
        nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;

        // Calculate the address knowing nbcols nbrows and page num
        address=SCREEN_MEM_START(nbcols,nbrows,page);
        write_word(BIOSMEM_SEG,BIOSMEM_CURRENT_START,address);

        // Start address
        address=SCREEN_IO_START(nbcols,nbrows,page);
    }
    else {
        address = page * (*(Bit16u *)&video_param_table[line_to_vpti[line]].slength_l);
    }

    // CRTC regs 0x0c and 0x0d
    crtc_addr=read_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS);
    outb(crtc_addr,0x0c);
    outb(crtc_addr+1,(address&0xff00)>>8);
    outb(crtc_addr,0x0d);
    outb(crtc_addr+1,address&0x00ff);

    // And change the BIOS page
    write_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE,page);

    // Display the cursor, now the page is active
    biosfn_set_cursor_pos(page,cursor);
}

//---------------------------------------------------------------------------
static void biosfn_scroll(nblines, attr, rul, cul, rlr, clr, page, dir)
Bit8u nblines;Bit8u attr;Bit8u rul;Bit8u cul;Bit8u rlr;Bit8u clr;Bit8u page;Bit8u dir;
{
    // page == 0xFF if current
    Bit8u mode,line,cols;
    Bit16u nbcols,nbrows,i;
    Bit16u address;

    if(rul>rlr)return;
    if(cul>clr)return;

    // Get the mode
    mode=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MODE);
    line=find_vga_entry(mode);
    if(line==0xFF)return;

    // Get the dimensions
    nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;
    nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);

    // Get the current page
    if(page==0xFF) page = read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);

    if(rlr>=nbrows)rlr=nbrows-1;
    if(clr>=nbcols)clr=nbcols-1;
    if(nblines>nbrows)nblines=0;
    cols=clr-cul+1;

    if(vga_modes[line].class==TEXT) {
        // Compute the address
        address=SCREEN_MEM_START(nbcols,nbrows,page);
        #ifdef DEBUG
            printf("Scroll, address %04x (%04x %04x %02x)\n",address,nbrows,nbcols,page);
        #endif
        if(nblines==0&&rul==0&&cul==0&&rlr==nbrows-1&&clr==nbcols-1) {
            memsetw(vga_modes[line].sstart,address,(Bit16u)attr*0x100+' ',nbrows*nbcols);
        }
        else {          // if Scroll up
            if(dir==SCROLL_UP) {
                for(i=rul;i<=rlr;i++) {
                    if((i+nblines>rlr)||(nblines==0))
                        memsetw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,(Bit16u)attr*0x100+' ',cols);
                    else
                        memcpyw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,vga_modes[line].sstart,((i+nblines)*nbcols+cul)*2,cols);
                }
            }
            else {
                for(i=rlr;i>=rul;i--) {
                    if((i<rul+nblines)||(nblines==0))
                        memsetw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,(Bit16u)attr*0x100+' ',cols);
                    else
                        memcpyw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,vga_modes[line].sstart,((i-nblines)*nbcols+cul)*2,cols);
                    if(i>rlr) break;
                }
            }
        }
    }
}

//---------------------------------------------------------------------------
static void biosfn_read_char_attr(Bit8u page, Bit16u *car)
{
    Bit16u ss=get_SS();
    Bit8u xcurs,ycurs,mode,line;
    Bit16u nbcols,nbrows,address;
    Bit16u cursor,dummy;

    // Get the mode
    mode = read_byte(BIOSMEM_SEG, BIOSMEM_CURRENT_MODE);
    line = find_vga_entry(mode);
    if(line == 0xFF) return;

    // Get the cursor pos for the page
    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
    xcurs=cursor&0x00ff;ycurs=(cursor&0xff00)>>8;

    // Get the dimensions
    nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;
    nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);

    // Compute the address
    address = SCREEN_MEM_START(nbcols,nbrows,page)+(xcurs+ycurs*nbcols)*2;

    write_word(ss, (Bit16u)car, read_word(vga_modes[line].sstart,address));
}

//---------------------------------------------------------------------------
static void biosfn_write_char_attr(Bit8u car, Bit8u page, Bit8u attr, Bit16u count)
{
    Bit8u  xcurs, ycurs, mode, line;
    Bit16u nbcols, nbrows, address;
    Bit16u cursor, dummy;

    // Get the mode
    mode = read_byte(BIOSMEM_SEG, BIOSMEM_CURRENT_MODE);
    line = find_vga_entry(mode);
    if(line == 0xFF) return;

    // Get the cursor pos for the page
    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
    xcurs=cursor&0x00ff;ycurs=(cursor & 0xff00) >>8;

    // Get the dimensions
    nbrows=read_byte(BIOSMEM_SEG, BIOSMEM_NB_ROWS)+1;
    nbcols=read_word(BIOSMEM_SEG, BIOSMEM_NB_COLS);

    // Compute the address
    address=SCREEN_MEM_START(nbcols,nbrows,page) +( xcurs+ycurs*nbcols)*2;

    dummy=((Bit16u)attr<<8)+car;
    memsetw(vga_modes[line].sstart,address,dummy,count);
}

//---------------------------------------------------------------------------
static void biosfn_write_char_only(Bit8u car, Bit8u page, Bit8u attr, Bit16u count)
{
    Bit8u xcurs, ycurs, mode, line;
    Bit16u nbcols, nbrows, address;
    Bit16u cursor, dummy;

    // Get the mode
    mode = read_byte(BIOSMEM_SEG, BIOSMEM_CURRENT_MODE);
    line = find_vga_entry(mode);
    if(line == 0xFF) return;

    // Get the cursor pos for the page
    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
    xcurs = cursor & 0x00ff; ycurs  =(cursor & 0xff00) >> 8;

    // Get the dimensions
    nbrows = read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;
    nbcols = read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);

    // Compute the address
    address=SCREEN_MEM_START(nbcols,nbrows,page)+(xcurs+ycurs*nbcols)*2;

    while(count-->0) {
        write_byte(vga_modes[line].sstart,address,car);
        address+=2;
    }
}

//---------------------------------------------------------------------------
static void biosfn_write_teletype(Bit8u car, Bit8u page, Bit8u attr, Bit8u flag)
{
    // flag = WITH_ATTR / NO_ATTR
    Bit8u  xcurs, ycurs, mode, line;
    Bit16u nbcols, nbrows, address;
    Bit16u cursor, dummy;

    // special case if page is 0xff, use current page
    if(page==0xff) page=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);

    // Get the mode
    mode=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MODE);
    line=find_vga_entry(mode);
    if(line==0xFF)return;

    // Get the cursor pos for the page
    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
    xcurs = cursor & 0x00ff; ycurs =(cursor&0xff00)>>8;

    // Get the dimensions
    nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;
    nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);

    switch(car) {
        case 7:          //FIXME should beep
            break;
        case 8:
            if(xcurs>0)xcurs--;
        break;

        case '\r':
            xcurs=0;
            break;

        case '\n':
            ycurs++;
            break;

        case '\t':
            do {
                biosfn_write_teletype(' ',page,attr,flag);
                biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&cursor);
                xcurs=cursor&0x00ff;ycurs=(cursor&0xff00)>>8;
            } while(xcurs%8==0);
            break;

        default:
            if(vga_modes[line].class==TEXT)  {
                // Compute the address
                address=SCREEN_MEM_START(nbcols,nbrows,page)+(xcurs+ycurs*nbcols)*2;

                // Write the char
                write_byte(vga_modes[line].sstart,address,car);

                if(flag==WITH_ATTR) write_byte(vga_modes[line].sstart,address+1,attr);
            }
            xcurs++;
    }

    // Do we need to wrap ?
    if(xcurs==nbcols) {
        xcurs=0;
        ycurs++;
    }

    // Do we need to scroll ?
    if(ycurs==nbrows) {
        if(vga_modes[line].class==TEXT) {
            biosfn_scroll(0x01,0x07,0,0,nbrows-1,nbcols-1,page,SCROLL_UP);
        }
        ycurs-=1;
    }

    // Set the cursor for the page
    cursor=ycurs; cursor<<=8; cursor+=xcurs;
    biosfn_set_cursor_pos(page,cursor);
}

//--------------------------------------------------------------------------
static void set_scan_lines(Bit8u lines)
{
    Bit16u crtc_addr, cols, vde;
    Bit8u  crtc_r9, ovl, rows;

    crtc_addr = read_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS);
    outb(crtc_addr, 0x09);
    crtc_r9 = inb(crtc_addr+1);
    crtc_r9 = (crtc_r9 & 0xe0) | (lines - 1);
    outb(crtc_addr+1, crtc_r9);

    write_word(BIOSMEM_SEG,BIOSMEM_CHAR_HEIGHT, lines);
    outb(crtc_addr, 0x12);
    vde = inb(crtc_addr+1);
    outb(crtc_addr, 0x07);
    ovl = inb(crtc_addr+1);
    vde += (((ovl & 0x02) << 7) + ((ovl & 0x40) << 3) + 1);
    rows = vde / lines;
    write_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS, rows-1);
    cols = read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);
    write_word(BIOSMEM_SEG,BIOSMEM_PAGE_SIZE, rows * cols * 2);
}

//--------------------------------------------------------------------------
static void get_font_access()
{
    __asm {
                        mov     dx, VGAREG_SEQU_ADDRESS
                        mov     ax, 0x0100
                        out     dx, ax
                        mov     ax, 0x0402
                        out     dx, ax
                        mov     ax, 0x0704
                        out     dx, ax
                        mov     ax, 0x0300
                        out     dx, ax
                        mov     dx, VGAREG_GRDC_ADDRESS
                        mov     ax, 0x0204
                        out     dx, ax
                        mov     ax, 0x0005
                        out     dx, ax
                        mov     ax, 0x0406
                        out     dx, ax
    }
}
//--------------------------------------------------------------------------
static void release_font_access()
{
        __asm {
                        mov     dx, VGAREG_SEQU_ADDRESS
                        mov     ax, 0x0100
                        out     dx, ax
                        mov     ax, 0x0302
                        out     dx, ax
                        mov     ax, 0x0304
                        out     dx, ax
                        mov     ax, 0x0300
                        out     dx, ax
                        mov     dx, VGAREG_READ_MISC_OUTPUT
                        in      al, dx
                        and     al, 0x01
                        push    cx
                        mov     cl, 2
                        shl     al, cl
                        pop     cx
                        or      al, 0x0a
                        mov     ah, al
                        mov     al, 0x06
                        mov     dx, VGAREG_GRDC_ADDRESS
                        out     dx, ax
                        mov     ax, 0x0004
                        out     dx, ax
                        mov     ax, 0x1005
                        out     dx, ax
        }
}

//--------------------------------------------------------------------------
static void biosfn_load_text_8_16_pat(Bit8u AL, Bit8u BL)
{
    Bit16u blockaddr, dest, i, src;

    get_font_access();
    blockaddr = ((BL & 0x03) << 14) + ((BL & 0x04) << 11);
    for(i=0;i<0x100;i++) {
        src = i * 16;
        dest = blockaddr + i * 32;
        memcpyb(0xA000, dest, 0xC000, (Bit16u)(vgafont16 + src), 16);
    }
    release_font_access();
    if(AL>=0x10) {
        set_scan_lines(16);
    }
}

//--------------------------------------------------------------------------
static void biosfn_write_string(flag, page, attr, count, row, col, seg, offset)
Bit8u flag;Bit8u page;Bit8u attr;Bit16u count;Bit8u row;Bit8u col;Bit16u seg;Bit16u offset;
{
    Bit16u newcurs,oldcurs,dummy;
    Bit8u  car;

    biosfn_get_cursor_pos(page, (Bit16u *)&dummy, (Bit16u *)&oldcurs);   // Read curs info for the page

    if(row==0xff) {              // if row=0xff special case : use current cursor position
        col=oldcurs&0x00ff;
        row=(oldcurs&0xff00)>>8;
    }

    newcurs=row; newcurs<<=8; newcurs+=col;
    biosfn_set_cursor_pos(page,newcurs);

    while(count--!=0)  {
        car=read_byte(seg,offset++);
        if((flag&0x02)!=0)
            attr=read_byte(seg,offset++);
        biosfn_write_teletype(car,page,attr,WITH_ATTR);
    }

    if((flag&0x01)==0) biosfn_set_cursor_pos(page,oldcurs);      // Set back curs pos
}

//---------------------------------------------------------------------------
// Print function
//---------------------------------------------------------------------------
void printf(Bit8u *s)
{
    Bit8u    c;
    Boolean  in_format;
    unsigned format_width, i;
    Bit16u  *arg_ptr;
    Bit16u   arg_seg, arg, digit, nibble;

    arg_ptr = (Bit16u  *)&s;
    arg_seg = get_SS();

    in_format = 0;
    format_width = 0;

    while(c = read_byte(0xc000, (Bit16u)s)) {
        if( c == '%' ) {
            in_format = 1;
            format_width = 0;
        }
        else if(in_format) {
            if((c >= '0') && (c <= '9') ) {
                format_width = (format_width * 10) + (c - '0');
            }
            else if(c == 'x') {
                arg_ptr++;      // increment to next arg
                arg = read_word(arg_seg, (Bit16u)arg_ptr);
                if(format_width == 0) format_width = 4;
                i = 0;
                digit = format_width - 1;
                for(i=0; i<format_width; i++) {
                    nibble = (arg >> (4 * digit)) & 0x000f;
                    if(nibble <= 9) outb(0x0500, nibble + '0');
                    else            outb(0x0500, (nibble - 10) + 'A');
                    digit--;
                }
                in_format = 0;
            }
        }
        else {
            outb(0x0500, c);
        }
        s ++;
    }
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// Video Utils
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
static Bit8u find_vga_entry(Bit8u mode)
{
    Bit8u i, line = 0xFF;
    for(i = 0; i <= MODE_MAX; i++)
        if(vga_modes[i].svgamode == mode) {
            line=i;
            break;
        }
    return line;
}

//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
// Low level assembly functions
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
Bit16u get_CS(void) { __asm { mov  ax, cs } }
Bit16u get_SS(void) { __asm { mov  ax, ss } }

//--------------------------------------------------------------------------
static void memsetw(Bit16u s_segment, Bit16u s_offset, Bit16u value, Bit16u count)
{
    __asm {
                    push    ax
                    push    cx
                    push    es
                    push    di

                    mov     cx, count      // count
                    cmp     cx, 0x00
                    je      memsetw_end
                    mov     ax, s_segment  // segment
                    mov     es, ax
                    mov     ax, s_offset   // offset
                    mov     di, ax
                    mov     ax, value      // value
                    cld
                    rep stosw

    memsetw_end:    pop     di
                    pop     es
                    pop     cx
                    pop     ax
    }
}

//--------------------------------------------------------------------------
//  memset of count bytes
//--------------------------------------------------------------------------
static void memsetb(Bit16u s_segment, Bit16u s_offset, Bit8u value, Bit16u count)
{
    __asm {
                    push ax
                    push cx
                    push es
                    push di
                    mov  cx, count        // count 
                    test cx, cx
                    je   memsetb_end
                    mov  ax, s_segment    // segment 
                    mov  es, ax
                    mov  ax, s_offset     // offset 
                    mov  di, ax
                    mov  al, value        // value 
                    cld
                    rep stosb
     memsetb_end:   pop di
                    pop es
                    pop cx
                    pop ax
    }
}
//--------------------------------------------------------------------------
//  memcpy of count bytes 
//--------------------------------------------------------------------------
static void memcpyb(Bit16u d_segment, Bit16u d_offset, Bit16u s_segment, Bit16u s_offset, Bit16u count)
{
    __asm {
                    push ax
                    push cx
                    push es
                    push di
                    push ds
                    push si
                    mov  cx, count      // count 
                    test cx, cx
                    je   memcpyb_end
                    mov  ax, d_segment  // dest segment 
                    mov  es, ax
                    mov  ax, d_offset   // dest offset  
                    mov  di, ax
                    mov  ax, s_segment  // ssegment 
                    mov  ds, ax
                    mov  ax, s_offset   // soffset  
                    mov  si, ax
                    cld
                    rep  movsb
      memcpyb_end:  pop si
                    pop ds
                    pop di
                    pop es
                    pop cx
                    pop ax
    }
}

//---------------------------------------------------------------------------
// Copy memory words
//---------------------------------------------------------------------------
static void memcpyw(Bit16u d_segment, Bit16u d_offset, Bit16u s_segment, Bit16u s_offset, Bit16u count)
{
    __asm {
            push    ax
            push    cx
            push    es
            push    di
            push    ds
            push    si
            mov     cx, count       // count
            cmp     cx, 0x0000
            je      memcpyw_end
            mov     ax, d_segment   // dsegment
            mov     es, ax
            mov     ax, d_offset    // doffset
            mov     di, ax
            mov     ax, s_segment   // ssegment
            mov     ds, ax
            mov     ax, s_offset    // soffset
            mov     si, ax
            cld
            rep     movsw

memcpyw_end:
            pop si
            pop ds
            pop di
            pop es
            pop cx
            pop ax
    }
}

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
// I/O Utility Functions:
//---------------------------------------------------------------------------
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

//---------------------------------------------------------------------------
static void vgabiosend() {
    __asm {
        db      'vgabios ends here'
        db      0x00
    vgabios_end:
        db      0xCB          // BLOCK_STRINGS_BEGIN
    }
}

//---------------------------------------------------------------------------
//      END of C
//---------------------------------------------------------------------------

