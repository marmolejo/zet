{ text lister, prints in landscape format for HP LJ2
  (c) 1987-2001 Pascal Dornier
  This file is licensed pursuant to the COMMON PUBLIC LICENSE Rev. 0.5.
  Version 010208 
  
  Compile using Borland Pascal 7.0 (versions 4.0 and later should also work) }

{$r-,i-,s-}

uses dos;

const
  { printer codes - modify for your printer ! }
  underline  =#27'&dD';        { start underlining }
  nounder    =#27'&d@';        { end   underlining }
  bl_on      =#27'(s3B';       { start boldface }
  bl_off     =#27'(s0B';       { end   boldface }
  formfeed   =#12;             { form feed }

  printerinit={#27'E'}#27'&l1O'#27'(10U'#27'(s0T'#27'(s16.66H'#27'&l8D';
             {reset  landscape IBM set   line prt  16.67 CPI }

  prtleft    = #27'&a0L'#27'&f0S';
             { left margin   push position }

  prtright   = #27'&f1S'#27'&a90L'#13;
             { pop pos   left margin  carriage return }

  printerexit={#27'E'}'';

  pagelen    =58;              	{ printed lines per page }

  prtfile    ='prn';		{ destination device }

var
  line     	:string;	{ input text line }
  head		:string[79];	{ header line }
  lineno,page   :word;		{ line, page number }
  form		:boolean;	{ form feed flag }
  fi            :text;		{ input file }
  fo            :text;		{ output file }
  yy,mm,dd,dw	:word;		{ date }

procedure outerr;
begin
  if ioresult<>0 then begin
    write('Write error');
    halt(1);
  end;
end;

procedure inerr;
begin
  if ioresult<>0 then begin
    write('Read error');
    halt(1);
  end;
end;

procedure prepheader;	{ prepare header line }
begin
  getdate(yy,mm,dd,dw);
  fillchar(head,sizeof(head),' ');
  head:=paramstr(1);
  head[0]:=#77;
  head[70]:=char(((yy mod 100)div 10)+ord('0'));
  head[71]:=char((yy mod 10)+ord('0'));
  head[72]:=char((mm div 10)+ord('0'));
  head[73]:=char((mm mod 10)+ord('0'));
  head[74]:=char((dd div 10)+ord('0'));
  head[75]:=char((dd mod 10)+ord('0'));
end;

procedure header; { print header line }
begin
  if odd(page) then begin
    if page<>1 then write(fo,formfeed);
    write(fo,prtleft);
  end else
    write(fo,prtright);

  lineno:=2;

  write(fo,#13#10,bl_on,head,page:3,bl_off,#13#10#13#10);
  inc(page);
  form:=true;
  outerr;
end;

procedure newline; { print line }
var
  bl_fl,ul_fl:boolean;
  i,col:integer;
begin
  bl_fl:=false;
  ul_fl:=false;
  col:=1;

  for i:=1 to length(line) do
    case line[i] of
      ^B:if not bl_fl then begin
           write(fo,bl_on);
           bl_fl:=true;
         end;
      ^I:begin
           repeat
             write(fo,' ');
             col:=succ(col);
           until (col=11) or (col=19) or (col>=41);
         end;
      ^L:begin
           header;
           col:=1;
         end;
      ^N:begin
           if bl_fl then write(fo,bl_off);
           if ul_fl then write(fo,nounder);
           bl_fl:=false;
           ul_fl:=false;
         end;
      ^U:if not ul_fl then begin
           write(fo,underline);
           ul_fl:=true;
         end;
      else begin
           write(fo,line[i]);
           col:=succ(col);
         end;
    end; {case}

  if ul_fl then
    while col<80 do begin
      write(fo,' ');
      col:=succ(col);
    end;

  form:=false;
  if bl_fl then write(fo,bl_off);
  if ul_fl then write(fo,nounder);
  writeln(fo);
  lineno:=lineno+1;

  if lineno=pagelen then header;
  outerr;
end;

begin { main }
  write('Assembly lister (C)1987-2001 PC Engines'#13#10);
  if paramcount<>1 then begin
    write('Usage: alist file');
    halt(1);
  end;

  assign(fi,paramstr(1));
  reset(fi);
  if ioresult<>0 then begin
    write('Couldn''t open ',paramstr(1));
    halt(1);
  end;

  page:=1;
  form:=false;
  prepheader;

  assign(fo,prtfile);
  rewrite(fo); outerr;

  write(fo,printerinit); outerr;
  header;
  while not eof(fi) do begin
    readln(fi,line); inerr;
    newline;
  end;
  close(fi); inerr;
  if not form then write(fo,formfeed);
  write(fo,printerexit); outerr;
  close(fo); outerr;
end.
  yy,mm,dd,dw:word;

procedure hexw(i:word);
begin
  write(hx[i shr 12],hx[hi(i) and 15],hx[lo(i) shr 4],hx[i and 15]);
end;

begin
  if paramcount<>2 then begin
    writeln('BIOSSUM usage: BIOSSUM infile outfile');
    halt(1);
  end;

  { read input file }

  new(b);
  assign(fi,paramstr(1));
  reset(fi,1);
  if ioresult<>0 then begin
    write('Could not open input file ',paramstr(1));
    halt(1);
  end;
  blockread(fi,b^,sizeof(b^),blen);
  close(fi);

  if blen<>$fff7 then writeln('Warning: input file length incorrect ?');

  { get start offset }

  startofs:=b^[$fff5]+swap(b^[$fff6]);	{ stored just after the reset vector }

  { find _32_ (paragraph aligned), insert checksum byte for 32 bit
    PCI BIOS header }

  asm
  	xor	bx,bx		{ clear offset }
	les	di,b		{ pointer to BIOS buffer }
	mov	di,startofs
	db $66			{ mov eax,"_32" }
	mov	ax,$335f
	dw	$5f32
@l1:	db $66			{ cmp [di],eax }
	cmp	[es:di],ax
	jz	@l2		{ :found header }
	add	di,16		{ next paragraph }
	jnz	@l1		{ :keep looking }
	jmp	@l9		{ not found }
	
@l2:	mov	bx,di		{ remember start address }
	xor	al,al		{ calculate checksum }
	mov	cx,10
@l3:	add	al,[es:di]
	inc	di
	loop	@l3
	neg	al
	stosb
	
@l9:	mov	pciofs,bx	{ return offset, 0 if not found }
  end;
  if pciofs=0 then
    writeln('_32_ area not found.')
  else begin
    write('_32_ area found at '); hexw(pciofs); writeln;
  end;

  { find _DAT (word aligned), insert checksum byte for BIOS read/write
    data area }

  asm
  	xor	bx,bx		{ clear offset }
	les	di,b		{ pointer to BIOS buffer }
	mov	di,startofs
	mov	cx,di
	neg	cx
	shr	cx,1
	mov	ax,$445F	{ _D }
@l1:	jcxz	@l9		{ bail if nothing left }
	repnz	scasw
	jnz	@l9		{ :not found }
	cmp	word [es:di],$5441	{ AT ? }
	jnz	@l1		{ :keep searching }
	lea	bx,[di-2]	{ save offset }
	
	mov	cx,[es:di+2]	{ get byte count }
	int	3	{&&&}
	add	di,4
	xor	al,al
@l2:	add	al,[es:di]	{ calculate checksum }
	inc	di
	loop	@l2
	neg	al		{ store checksum }
	stosb
	
@l9:	mov	datofs,bx	{ return offset, 0 if not found }
  end;
  if datofs=0 then
    writeln('_DAT area not found.')
  else begin
    write('_DAT area found at '); hexw(datofs); writeln;
  end;

  { insert BIOS date }

  b^[$fff5]:=(mm div 10)+zero;
  b^[$fff6]:=(mm mod 10)+zero;
  b^[$fff7]:=ord('/');
  b^[$fff8]:=(dd div 10)+zero;
  b^[$fff9]:=(dd mod 10)+zero;
  b^[$fffa]:=ord('/');
  b^[$fffb]:=((yy mod 100)div 10)+zero;
  b^[$fffc]:=(yy mod 10)+zero;
  b^[$fffd]:=$ff;

  { insert AT model byte }

  b^[$fffe]:=$fc;

  { calculate overall checksum }

  sum:=0;
  for i:=startofs to $fffe do
    inc(sum,b^[i]);

  i:=$ffff;	
  b^[i]:=-sum;

  { write output file }

  assign(fi,paramstr(2));
  rewrite(fi,1);
  if ioresult<>0 then begin
    write('Could not create output file ',paramstr(1));
    halt(1);
  end;

  if startofs=0 then begin
    blockwrite(fi,b^[0],$8000);		{ write 64KB in two pieces }
    blockwrite(fi,b^[$8000],$8000);
  end else
    blockwrite(fi,b^[startofs],$10000-startofs);

  if ioresult<>0 then begin
    write('Write error !');
    halt(1);
  end;
  close(fi);
end.
