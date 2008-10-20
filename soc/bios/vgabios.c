#include "vgabios.h"

/* Declares */
static Bit8u          read_byte();
static Bit16u         read_word();
static void           write_byte();
static void           write_word();
static Bit8u          inb();
static Bit16u         inw();
static void           outb();
static void           outw();

static Bit16u         get_SS();

static Bit8u find_vga_entry();

static void memsetb();
static void memsetw();
static void memcpyb();
static void memcpyw();

static void biosfn_set_video_mode();
static void biosfn_set_cursor_pos();
static void biosfn_get_cursor_pos();
static void biosfn_scroll();
static void biosfn_write_teletype();
static void biosfn_write_string();
extern Bit8u video_save_pointer_table[];

// This is for compiling with gcc2 and gcc3
#define ASM_START #asm
#define ASM_END   #endasm

ASM_START

MACRO SET_INT_VECTOR
  push ds
  xor ax, ax
  mov ds, ax
  mov ax, ?3
  mov ?1*4, ax
  mov ax, ?2
  mov ?1*4+2, ax
  pop ds
MEND

ASM_END

ASM_START
.text
.rom
.org 0

use16 8086

vgabios_start:
.byte	0x55, 0xaa	/* BIOS signature, required for BIOS extensions */

.byte	0x40		/* BIOS extension length in units of 512 bytes */


vgabios_entry_point:
           
  jmp vgabios_init_func

vgabios_name:
.ascii	"Zet/Bochs VGABios"
.ascii	" "
.byte	0x00

// Info from Bart Oldeman
.org 0x1e
.ascii  "IBM"
.byte   0x00

vgabios_version:
#ifndef VGABIOS_VERS
.ascii	"current-cvs"
#else
.ascii VGABIOS_VERS
#endif
.ascii	" "

vgabios_date:
.ascii  VGABIOS_DATE
.byte   0x0a,0x0d
.byte	0x00

vgabios_copyright:
.ascii	"(C) 2003 the LGPL VGABios developers Team"
.byte	0x0a,0x0d
.byte	0x00

vgabios_license:
.ascii	"This VGA/VBE Bios is released under the GNU LGPL"
.byte	0x0a,0x0d
.byte	0x0a,0x0d
.byte	0x00

vgabios_website:
.ascii	"Please visit :"
.byte	0x0a,0x0d
;;.ascii  " . http://www.plex86.org"
;;.byte	0x0a,0x0d
.ascii	" . http://zet.aluzina.org"
.byte	0x0a,0x0d
.ascii	" . http://bochs.sourceforge.net"
.byte	0x0a,0x0d
.ascii	" . http://www.nongnu.org/vgabios"
.byte	0x0a,0x0d
.byte	0x0a,0x0d
.byte	0x00
 

;; ========================================================
;;
;; Init Entry point
;;
;; ========================================================
vgabios_init_func:

;; init basic bios vars
  call init_bios_area

;; set int10 vect
  SET_INT_VECTOR(0x10, #0xC000, #vgabios_int10_handler)

;; display splash screen
  call _display_splash_screen

;; init video mode and clear the screen
  mov ax,#0x0003
  int #0x10

;; show info
  call _display_info

  retf
ASM_END

/*
 *  int10 handled here
 */
ASM_START
vgabios_int10_handler:
  pushf

int10_normal:
  push es
  push ds
  ;pusha ; we do this instead:

  push ax
  push cx
  push dx
  push bx
  push sp
  mov  bx, sp
  add  [bx], #10
  mov  bx, [bx+2]
  push bp
  push si
  push di

;; We have to set ds to access the right data segment
  mov   bx, #0xc000
  mov   ds, bx

  call _int10_func

  ; popa ; we do this instead:
  pop di
  pop si
  pop bp
  add sp, #2
  pop bx
  pop dx
  pop cx
  pop ax

  pop ds
  pop es
int10_end:
  popf
  iret
ASM_END

#include "vgatables.h"

// --------------------------------------------------------
/*
 *  Boot time bios area inits 
 */
ASM_START
init_bios_area:
  push  ds
  mov   ax, # BIOSMEM_SEG
  mov   ds, ax

;; init detected hardware BIOS Area
  mov   bx, # BIOSMEM_INITIAL_MODE
  mov   ax, [bx]
  and   ax, #0xffcf
;; set 80x25 color (not clear from RBIL but usual)
  or    ax, #0x0020
  mov   [bx], ax

;; Just for the first int10 find its children

;; the default char height
  mov   bx, # BIOSMEM_CHAR_HEIGHT
  mov   al, #0x10
  mov   [bx], al

;; Clear the screen 
  mov   bx, # BIOSMEM_VIDEO_CTL
  mov   al, #0x60
  mov   [bx], al

;; Set the basic screen we have
  mov   bx, # BIOSMEM_SWITCHES
  mov   al, #0xf9
  mov   [bx], al

;; Set the basic modeset options
  mov   bx, # BIOSMEM_MODESET_CTL
  mov   al, #0x51
  mov   [bx], al

;; Set the  default MSR
  mov   bx, # BIOSMEM_CURRENT_MSR
  mov   al, #0x09
  mov   [bx], al

  pop ds
  ret

_video_save_pointer_table:
  .word _video_param_table
  .word 0xc000

  .word 0 /* XXX: fill it */
  .word 0

  .word 0 /* XXX: fill it */
  .word 0

  .word 0 /* XXX: fill it */
  .word 0

  .word 0 /* XXX: fill it */
  .word 0

  .word 0 /* XXX: fill it */
  .word 0

  .word 0 /* XXX: fill it */
  .word 0

ASM_END

// --------------------------------------------------------
/*
 *  Boot time Splash screen
 */
static void display_splash_screen()
{
  write_byte (0xb800, 0x0, 'H');
//  write_byte (0xb800, 0x2, 'o');
}

// --------------------------------------------------------------------------------------------
/*
 *  Tell who we are
 */

static void display_info()
{
ASM_START
 mov ax,#0xc000
 mov ds,ax
 mov si,#vgabios_name
 call _display_string
 mov si,#vgabios_version
 call _display_string

 ;;mov si,#vgabios_copyright
 ;;call _display_string
 ;;mov si,#crlf
 ;;call _display_string

 mov si,#vgabios_license
 call _display_string
 mov si,#vgabios_website
 call _display_string
ASM_END
}

static void display_string()
{
 // Get length of string
ASM_START
 mov ax,ds
 mov es,ax
 mov di,si
 xor cx,cx
 not cx
 xor al,al
 cld
 repne 
  scasb
 not cx
 dec cx
 push cx

 mov ax,#0x0300
 mov bx,#0x0000
 int #0x10

 pop cx
 mov ax,#0x1301
 mov bx,#0x000b
 mov bp,si
 int #0x10
ASM_END
}

// --------------------------------------------------------
/*
 * int10 main dispatcher
 */
static void int10_func(DI, SI, BP, SP, BX, DX, CX, AX, DS, ES, FLAGS)
  Bit16u DI, SI, BP, SP, BX, DX, CX, AX, ES, DS, FLAGS;
{
 // BIOS functions
 switch(GET_AH())
  {
   case 0x00:
     biosfn_set_video_mode(GET_AL());
     switch(GET_AL()&0x7F)
      {case 6:
        SET_AL(0x3F);
        break;
       case 0:
       case 1:
       case 2:
       case 3:
       case 4:
       case 5:
       case 7:
        SET_AL(0x30);
        break;
      default:
        SET_AL(0x20);
      }
     break;
   case 0x02:
     biosfn_set_cursor_pos(GET_BH(),DX);
     break;
   case 0x03:
     biosfn_get_cursor_pos(GET_BH(),&CX,&DX);
     break;
   case 0x0E:
     // Ralf Brown Interrupt list is WRONG on bh(page)
     // We do output only on the current page !
     biosfn_write_teletype(GET_AL(),0xff,GET_BL(),NO_ATTR);
     break;
   case 0x13:
     biosfn_write_string(GET_AL(),GET_BH(),GET_BL(),CX,GET_DH(),GET_DL(),ES,BP);
     break;
  }
}

// ============================================================================================
// 
// BIOS functions
// 
// ============================================================================================

static void biosfn_set_video_mode(mode) Bit8u mode; 
{// mode: Bit 7 is 1 if no clear screen

 // Should we clear the screen ?
 Bit8u noclearmem=mode&0x80;
 Bit8u line,mmask,*palette,vpti;
 Bit16u i,twidth,theightm1,cheight;
 Bit8u modeset_ctl,video_ctl,vga_switches;
 Bit16u crtc_addr;

 // The real mode
 mode=mode&0x7f;

 // find the entry in the video modes
 line=find_vga_entry(mode);

 if(line==0xFF)
  return;

 vpti=line_to_vpti[line];
 twidth=video_param_table[vpti].twidth;
 theightm1=video_param_table[vpti].theightm1;
 cheight=video_param_table[vpti].cheight;
 
 // Read the bios vga control
 video_ctl=read_byte(BIOSMEM_SEG,BIOSMEM_VIDEO_CTL);

 // Read the bios vga switches
 vga_switches=read_byte(BIOSMEM_SEG,BIOSMEM_SWITCHES);

 // Read the bios mode set control
 modeset_ctl=read_byte(BIOSMEM_SEG,BIOSMEM_MODESET_CTL);

 // Set CRTC address VGA or MDA 
 crtc_addr=vga_modes[line].memmodel==MTEXT?VGAREG_MDA_CRTC_ADDRESS:VGAREG_VGA_CRTC_ADDRESS;

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
 write_word(BIOSMEM_SEG,BIOSMEM_VS_POINTER, video_save_pointer_table);
 write_word(BIOSMEM_SEG,BIOSMEM_VS_POINTER+2, 0xc000);

 // FIXME
 write_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MSR,0x00); // Unavailable on vanilla vga, but...
 write_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAL,0x00); // Unavailable on vanilla vga, but...
 
}

// --------------------------------------------------------------------------------------------
static void biosfn_set_cursor_pos (page, cursor) 
Bit8u page;Bit16u cursor;
{
 Bit8u xcurs,ycurs,current;
 Bit16u nbcols,nbrows,address,crtc_addr;

 // Should not happen...
 if(page>7)return;

 // Bios cursor pos
 write_word(BIOSMEM_SEG, BIOSMEM_CURSOR_POS+2*page, cursor);

 // Set the hardware cursor
 current=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);
 if(page==current)
  {
   // Get the dimensions
   nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);
   nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;

   xcurs=cursor&0x00ff;ycurs=(cursor&0xff00)>>8;
 
   // Calculate the address knowing nbcols nbrows and page num
   address=SCREEN_IO_START(nbcols,nbrows,page)+xcurs+ycurs*nbcols;
   
   // CRTC regs 0x0e and 0x0f
   crtc_addr=read_word(BIOSMEM_SEG,BIOSMEM_CRTC_ADDRESS);
   outb(crtc_addr,0x0e);
   outb(crtc_addr+1,(address&0xff00)>>8);
   outb(crtc_addr,0x0f);
   outb(crtc_addr+1,address&0x00ff);
  }
}

// --------------------------------------------------------------------------------------------
static void biosfn_get_cursor_pos (page,shape, pos) 
Bit8u page;Bit16u *shape;Bit16u *pos;
{
 Bit16u ss=get_SS();

 // Default
 write_word(ss, shape, 0);
 write_word(ss, pos, 0);

 if(page>7)return;
 // FIXME should handle VGA 14/16 lines
 write_word(ss,shape,read_word(BIOSMEM_SEG,BIOSMEM_CURSOR_TYPE));
 write_word(ss,pos,read_word(BIOSMEM_SEG,BIOSMEM_CURSOR_POS+page*2));
}

// --------------------------------------------------------------------------------------------
static void biosfn_scroll (nblines,attr,rul,cul,rlr,clr,page,dir)
Bit8u nblines;Bit8u attr;Bit8u rul;Bit8u cul;Bit8u rlr;Bit8u clr;Bit8u page;Bit8u dir;
{
 // page == 0xFF if current

 Bit8u mode,line,cheight,bpp,cols;
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
 if(page==0xFF)
  page=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);

 if(rlr>=nbrows)rlr=nbrows-1;
 if(clr>=nbcols)clr=nbcols-1;
 if(nblines>nbrows)nblines=0;
 cols=clr-cul+1;

 if(vga_modes[line].class==TEXT)
  {
   // Compute the address
   address=SCREEN_MEM_START(nbcols,nbrows,page);
#ifdef DEBUG
   printf("Scroll, address %04x (%04x %04x %02x)\n",address,nbrows,nbcols,page);
#endif

   if(nblines==0&&rul==0&&cul==0&&rlr==nbrows-1&&clr==nbcols-1)
    {
     memsetw(vga_modes[line].sstart,address,(Bit16u)attr*0x100+' ',nbrows*nbcols);
    }
   else
    {// if Scroll up
     if(dir==SCROLL_UP)
      {for(i=rul;i<=rlr;i++)
        {
         if((i+nblines>rlr)||(nblines==0))
          memsetw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,(Bit16u)attr*0x100+' ',cols);
         else
          memcpyw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,vga_modes[line].sstart,((i+nblines)*nbcols+cul)*2,cols);
        }
      }
     else
      {for(i=rlr;i>=rul;i--)
        {
         if((i<rul+nblines)||(nblines==0))
          memsetw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,(Bit16u)attr*0x100+' ',cols);
         else
          memcpyw(vga_modes[line].sstart,address+(i*nbcols+cul)*2,vga_modes[line].sstart,((i-nblines)*nbcols+cul)*2,cols);
         if (i>rlr) break;
        }
      }
    }
  }
}

// --------------------------------------------------------------------------------------------
static void biosfn_write_teletype (car, page, attr, flag) 
Bit8u car;Bit8u page;Bit8u attr;Bit8u flag;
{// flag = WITH_ATTR / NO_ATTR

 Bit8u cheight,xcurs,ycurs,mode,line,bpp;
 Bit16u nbcols,nbrows,address;
 Bit16u cursor,dummy;

 // special case if page is 0xff, use current page
 if(page==0xff)
  page=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_PAGE);

 // Get the mode
 mode=read_byte(BIOSMEM_SEG,BIOSMEM_CURRENT_MODE);
 line=find_vga_entry(mode);
 if(line==0xFF)return;

 // Get the cursor pos for the page
 biosfn_get_cursor_pos(page,&dummy,&cursor);
 xcurs=cursor&0x00ff;ycurs=(cursor&0xff00)>>8;

 // Get the dimensions
 nbrows=read_byte(BIOSMEM_SEG,BIOSMEM_NB_ROWS)+1;
 nbcols=read_word(BIOSMEM_SEG,BIOSMEM_NB_COLS);

 switch(car)
  {
   case 7:
    //FIXME should beep
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
    do
     {
      biosfn_write_teletype(' ',page,attr,flag);
      biosfn_get_cursor_pos(page,&dummy,&cursor);
      xcurs=cursor&0x00ff;ycurs=(cursor&0xff00)>>8;
     }while(xcurs%8==0);
    break;

   default:

    if(vga_modes[line].class==TEXT)
     {
      // Compute the address  
      address=SCREEN_MEM_START(nbcols,nbrows,page)+(xcurs+ycurs*nbcols)*2;

      // Write the char 
      write_byte(vga_modes[line].sstart,address,car);

      if(flag==WITH_ATTR)
       write_byte(vga_modes[line].sstart,address+1,attr);
     }
    xcurs++;
  }

 // Do we need to wrap ?
 if(xcurs==nbcols)
  {xcurs=0;
   ycurs++;
  }

 // Do we need to scroll ?
 if(ycurs==nbrows)
  {
   if(vga_modes[line].class==TEXT)
    {
     biosfn_scroll(0x01,0x07,0,0,nbrows-1,nbcols-1,page,SCROLL_UP);
    }
   ycurs-=1;
  }
 
 // Set the cursor for the page
 cursor=ycurs; cursor<<=8; cursor+=xcurs;
 biosfn_set_cursor_pos(page,cursor);
}

// --------------------------------------------------------------------------------------------
static void biosfn_write_string (flag,page,attr,count,row,col,seg,offset) 
Bit8u flag;Bit8u page;Bit8u attr;Bit16u count;Bit8u row;Bit8u col;Bit16u seg;Bit16u offset;
{
 Bit16u newcurs,oldcurs,dummy;
 Bit8u car,carattr;

 // Read curs info for the page
 biosfn_get_cursor_pos(page,&dummy,&oldcurs);

 // if row=0xff special case : use current cursor position
 if(row==0xff)
  {col=oldcurs&0x00ff;
   row=(oldcurs&0xff00)>>8;
  }

 newcurs=row; newcurs<<=8; newcurs+=col;
 biosfn_set_cursor_pos(page,newcurs);
 
 while(count--!=0)
  {
   car=read_byte(seg,offset++);
   if((flag&0x02)!=0)
    attr=read_byte(seg,offset++);

   biosfn_write_teletype(car,page,attr,WITH_ATTR);
  }
 
 // Set back curs pos 
 if((flag&0x01)==0)
  biosfn_set_cursor_pos(page,oldcurs);
}

// ============================================================================================
//
// Video Utils
//
// ============================================================================================
 
// --------------------------------------------------------------------------------------------
static Bit8u find_vga_entry(mode) 
Bit8u mode;
{
 Bit8u i,line=0xFF;
 for(i=0;i<=MODE_MAX;i++)
  if(vga_modes[i].svgamode==mode)
   {line=i;
    break;
   }
 return line;
}

// --------------------------------------------------------------------------------------------
static void memsetw(seg,offset,value,count)
  Bit16u seg;
  Bit16u offset;
  Bit16u value;
  Bit16u count;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push cx
    push es
    push di

    mov  cx, 10[bp] ; count
    cmp  cx, #0x00
    je   memsetw_end
    mov  ax, 4[bp] ; segment
    mov  es, ax
    mov  ax, 6[bp] ; offset
    mov  di, ax
    mov  ax, 8[bp] ; value
    cld
    rep
     stosw

memsetw_end:
    pop di
    pop es
    pop cx
    pop ax

  pop bp
ASM_END
}

// --------------------------------------------------------------------------------------------
static void memcpyw(dseg,doffset,sseg,soffset,count)
  Bit16u dseg;
  Bit16u doffset;
  Bit16u sseg;
  Bit16u soffset;
  Bit16u count;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push cx
    push es
    push di
    push ds
    push si

    mov  cx, 12[bp] ; count
    cmp  cx, #0x0000
    je   memcpyw_end
    mov  ax, 4[bp] ; dsegment
    mov  es, ax
    mov  ax, 6[bp] ; doffset
    mov  di, ax
    mov  ax, 8[bp] ; ssegment
    mov  ds, ax
    mov  ax, 10[bp] ; soffset
    mov  si, ax
    cld
    rep
     movsw

memcpyw_end:
    pop si
    pop ds
    pop di
    pop es
    pop cx
    pop ax

  pop bp
ASM_END
}

// --------------------------------------------------------------------------------------------
static Bit8u
read_byte(seg, offset)
  Bit16u seg;
  Bit16u offset;
{
ASM_START
  push bp
  mov  bp, sp

    push bx
    push ds
    mov  ax, 4[bp] ; segment
    mov  ds, ax
    mov  bx, 6[bp] ; offset
    mov  al, [bx]
    ;; al = return value (byte)
    pop  ds
    pop  bx

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
static Bit16u
read_word(seg, offset)
  Bit16u seg;
  Bit16u offset;
{
ASM_START
  push bp
  mov  bp, sp

    push bx
    push ds
    mov  ax, 4[bp] ; segment
    mov  ds, ax
    mov  bx, 6[bp] ; offset
    mov  ax, [bx]
    ;; ax = return value (word)
    pop  ds
    pop  bx

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
static void
write_byte(seg, offset, data)
  Bit16u seg;
  Bit16u offset;
  Bit8u  data;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push bx
    push ds
    mov  ax, 4[bp] ; segment
    mov  ds, ax
    mov  bx, 6[bp] ; offset
    mov  al, 8[bp] ; data byte
    mov  [bx], al  ; write data byte
    pop  ds
    pop  bx
    pop  ax

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
static void
write_word(seg, offset, data)
  Bit16u seg;
  Bit16u offset;
  Bit16u data;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push bx
    push ds
    mov  ax, 4[bp] ; segment
    mov  ds, ax
    mov  bx, 6[bp] ; offset
    mov  ax, 8[bp] ; data word
    mov  [bx], ax  ; write data word
    pop  ds
    pop  bx
    pop  ax

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
 Bit8u
inb(port)
  Bit16u port;
{
ASM_START
  push bp
  mov  bp, sp

    push dx
    mov  dx, 4[bp]
    in   al, dx
    pop  dx

  pop  bp
ASM_END
}

  Bit16u
inw(port)
  Bit16u port;
{
ASM_START
  push bp
  mov  bp, sp

    push dx
    mov  dx, 4[bp]
    in   ax, dx
    pop  dx

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
  void
outb(port, val)
  Bit16u port;
  Bit8u  val;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push dx
    mov  dx, 4[bp]
    mov  al, 6[bp]
    out  dx, al
    pop  dx
    pop  ax

  pop  bp
ASM_END
}

// --------------------------------------------------------------------------------------------
  void
outw(port, val)
  Bit16u port;
  Bit16u  val;
{
ASM_START
  push bp
  mov  bp, sp

    push ax
    push dx
    mov  dx, 4[bp]
    mov  ax, 6[bp]
    out  dx, ax
    pop  dx
    pop  ax

  pop  bp
ASM_END
}

Bit16u get_SS()
{
ASM_START
  mov  ax, ss
ASM_END
}

// --------------------------------------------------------------------------------------------

ASM_START 
;; DATA_SEG_DEFS_HERE
ASM_END

ASM_START
.ascii "vgabios ends here"
.byte  0x00
vgabios_end:
.byte 0xCB
;; BLOCK_STRINGS_BEGIN
ASM_END
