{ ALI M6117 shadow boot }

{ (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
  This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5. }

{ important: write back disk cache before shadow boot !!! }
{ e.g. smartdrv /c }

const
  idx=$22;
  dat=$23;
  timer=$40;
  post=$80;
  iowait=$eb;

var
  fi:file;
  buf:array[0..16383] of byte;
  bios:array[0..16383] of byte absolute $f000:$c000;
  rstflg:word absolute $0000:$0472;

begin
  assign(fi,'bios.abs');
  reset(fi,1);
  blockread(fi,buf,sizeof(buf));
  close(fi);

{  write('Copying BIOS to shadow RAM'); }
  asm
   	cli;
  end;
  port[timer+3]:=$50;	{ disable refresh }
  port[post]:=$c1;
  port[iowait]:=0;
  port[iowait]:=0;
  port[iowait]:=0;
  port[idx]:=$13;	{ unlock registers }
  port[dat]:=$c5;
  port[idx]:=$15;	{ enable shadow write }
  port[dat]:=$a0;
  move(buf,bios,sizeof(bios));
  port[post]:=$c2;
  port[idx]:=$15;	{ set read only shadow }
  port[dat]:=$50;
  if paramcount=0 then
    rstflg:=$1234;	{ skip hard disk wait }
  asm
    db $ea		{ jmp far }
    dw $fff0,$f000	{ $f000:$fff0 }
  end;
end.
