{$r-,i-,s-}

{ BIOS checksum utility

  (C)2001 Pascal Dornier / PC Engines
  This file is licensed pursuant to the COMMON PUBLIC LICENSE Rev. 0.5.

  - find _32_ (paragraph aligned), insert checksum byte for 32 bit
    PCI BIOS header

  - find _DAT (word aligned), insert checksum byte for BIOS read/write
    data area

  - insert BIOS date

  - insert model byte

  - insert overall checksum byte

  Compile using Borland Pascal 7.0 (older versions likely to work too)
}

uses dos;

const
  zero=ord('0');
  hx:array[0..15] of char = '0123456789ABCDEF';

type
  bios=array[0..$fffe] of byte;

var
  b:^bios;
  fi:file;
  blen:word;
  startofs,datofs,pciofs:word;
  i:word;
  sum:byte;
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

  getdate(yy,mm,dd,dw);
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
