	;
	; US ASCII keyboard layout table
	;
	; (C)1997-2001 Pascal Dornier / PC Engines; All rights reserved.
	; This file is licensed pursuant to the COMMON PUBLIC LICENSE 0.5.
	;

	;
	; key action codes (don't change !!!)
	;
k_nil	equ	0ffffh	;ignore key
k_lsh	equ	0fffeh	;left shift
k_rsh	equ	0fffdh	;right shift
k_lct	equ	0fffch	;left control
k_rct	equ	0fffbh	;right control
k_alt	equ	0fffah	;left alt
k_ral	equ	0fff9h	;right alt
k_cap	equ	0fff8h	;caps lock
k_num	equ	0fff7h	;num lock
k_scr	equ	0fff6h	;scroll lock
k_pau	equ	0fff5h	;pause
k_prt	equ	0fff4h	;print screen
k_boo	equ	0fff3h	;reboot system
k_sys	equ	0fff2h	;system request
k_brk	equ	0fff1h	;break
k_rct1	equ	0fff0h	;right control
k_dig	equ	0ffefh	;alt + digit
vecmin	equ	0ffefh 	;minimal action code
	;
	; US ASCII keyboard layout
	;
	; key entry structure:
	;
	; 0: control byte   0 = nothing special
	;                   1 = check caps lock
	;                   2 = check num lock if not E0 prefix
	; 1: normal scan code
	; 3: shift scan code
	; 5: control scan code
	; 7: alt scan code
	; 9: ctrl-alt scan code
	;
ct	equ	-0040h	;offset for control characters
kb_tab	db	0	;01 esc
	dw	011bh,011bh,011bh,0100h,k_nil
	db	0	;02 1
	dw	0200h+"1",0200h+"!",k_nil,7800h,k_nil
	db	0	;03 2
	dw	0300h+"2",0300h+"@",0300h,7900h,k_nil
	db	0	;04 3
	dw	0400h+"3",0400h+"#",k_nil,7a00h,k_nil
	db	0	;05 4
	dw	0500h+"4",0500h+"$",k_nil,7b00h,k_nil
	db	0	;06 5
	dw	0600h+"5",0600h+"%",k_nil,7c00h,k_nil
	db	0	;07 6
	dw	0700h+"6",0700h+"^",071eh,7d00h,k_nil
	db	0	;08 7
	dw	0800h+"7",0800h+"&",k_nil,7e00h,k_nil
	db	0	;09 8
	dw	0900h+"8",0900h+"*",k_nil,7f00h,k_nil
	db	0	;0a 9
	dw	0a00h+"9",0a00h+"(",k_nil,8000h,k_nil
	db	0	;0b 0
	dw	0b00h+"0",0b00h+")",k_nil,8100h,k_nil
	db	0	;0c -
	dw	0c00h+"-",0c00h+"_",0c1fh,8200h,k_nil
	db	0	;0d =
	dw	0d00h+"=",0d00h+"+",k_nil,8300h,k_nil
	db	0	;0e bs
	dw	0e08h,0e08h,0e7fh,0e00h,k_nil
	db	0	;0f tab
	dw	0f09h,0f00h,9400h,0a500h,k_nil
	db	1	;10 q
	dw	1000h+"q",1000h+"Q",1000h+ct+"Q",1000h,k_nil
	db	1	;11 w
	dw	1100h+"w",1100h+"W",1100h+ct+"W",1100h,k_nil
	db	1	;12 e
	dw	1200h+"e",1200h+"E",1200h+ct+"E",1200h,k_nil
	db	1	;13 r
	dw	1300h+"r",1300h+"R",1300h+ct+"R",1300h,k_nil
	db	1	;14 t
	dw	1400h+"t",1400h+"T",1400h+ct+"T",1400h,k_nil
	db	1	;15 y
	dw	1500h+"y",1500h+"Y",1500h+ct+"Y",1500h,k_nil
	db	1	;16 u
	dw	1600h+"u",1600h+"U",1600h+ct+"U",1600h,k_nil
	db	1	;17 i
	dw	1700h+"i",1700h+"I",1700h+ct+"I",1700h,k_nil
	db	1	;18 o
	dw	1800h+"o",1800h+"O",1800h+ct+"O",1800h,k_nil
	db	1	;19 p
	dw	1900h+"p",1900h+"P",1900h+ct+"P",1900h,k_nil
	db	0	;1a [
	dw	1a00h+"[",1a00h+"{",1a00h+ct+"[",1a00h,k_nil
	db	0	;1b ]
	dw	1b00h+"]",1b00h+"}",1b00h+ct+"]",1b00h,k_nil
	db	0	;1c cr / e0 keypad enter
	dw	1c0dh,1c0dh,1c0ah,1c00h,k_nil
	db	0	;1d left control, e0 right ctrl
	dw	k_lct,k_lct,k_lct,k_lct,k_lct
	db	1	;1e a
	dw	1e00h+"a",1e00h+"A",1e00h+ct+"A",1e00h,k_nil
	db	1	;1f s
	dw	1f00h+"s",1f00h+"S",1f00h+ct+"S",1f00h,k_nil
	db	1	;20 d
	dw	2000h+"d",2000h+"D",2000h+ct+"D",2000h,k_nil
	db	1	;21 f
	dw	2100h+"f",2100h+"F",2100h+ct+"F",2100h,k_nil
	db	1	;22 g
	dw	2200h+"g",2200h+"G",2200h+ct+"G",2200h,k_nil
	db	1	;23 h
	dw	2300h+"h",2300h+"H",2300h+ct+"H",2300h,k_nil
	db	1	;24 j
	dw	2400h+"j",2400h+"J",2400h+ct+"J",2400h,k_nil
	db	1	;25 k
	dw	2500h+"k",2500h+"K",2500h+ct+"K",2500h,k_nil
	db	1	;26 l
	dw	2600h+"l",2600h+"L",2600h+ct+"L",2600h,k_nil
	db	0 	;27 ;
	dw	2700h+";",2700h+":",k_nil,2700h,k_nil
	db	0	;28 '
	dw	2800h+"'",2822h,k_nil,2800h,k_nil
	db	0	;29 tilde
	dw	2900h+"`",2900h+"~",k_nil,k_nil,k_nil
	db	0	;2a left shift
	dw	k_lsh,k_lsh,k_lsh,k_lsh,k_lsh
	db	0	;2b \
	dw	2b00h+"\",2b00h+"|",2b00h+ct+"\",2b00h,k_nil
	db	1	;2c z
	dw	2c00h+"z",2c00h+"Z",2c00h+ct+"Z",2c00h,k_nil
	db	1	;2d x
	dw	2d00h+"x",2d00h+"X",2d00h+ct+"X",2d00h,k_nil
	db	1	;2e c
	dw	2e00h+"c",2e00h+"C",2e00h+ct+"C",2e00h,k_nil
	db	1	;2f v
	dw	2f00h+"v",2f00h+"V",2f00h+ct+"V",2f00h,k_nil
	db	1	;30 b
	dw	3000h+"b",3000h+"B",3000h+ct+"B",3000h,k_nil
	db	1	;31 n
	dw	3100h+"n",3100h+"N",3100h+ct+"N",3100h,k_nil
	db	1	;32 m
	dw	3200h+"m",3200h+"M",3200h+ct+"M",3200h,k_nil
	db	0	;33 ,
	dw	3300h+",",3300h+"<",k_nil,3300h,k_nil
	db	0	;34 .
	dw	3400h+".",3400h+">",k_nil,3400h,k_nil
	db	0	;35 / e0 keypad / 002f 002f 9500 a400 ffff &
	dw	3500h+"/",3500h+"?",9500h,3500h,k_nil
	db	0	;36 right shift
	dw	k_rsh,k_rsh,k_rsh,k_rsh,k_rsh
	db	0	;37 keypad *
	dw	3700h+"*",k_prt,9600h,3700h,k_nil
	db	0	;38 left alt e0 right alt
	dw	k_alt,k_alt,k_alt,k_alt,k_alt
	db	0	;39 space
	dw	3900h+" ",3900h+" ",3900h+" ",3900h+" ",k_nil
	db	0	;3a caps lock
	dw	k_cap,k_cap,k_cap,k_cap,k_cap
	db	0	;3b F1
	dw	3b00h,5400h,5e00h,6800h,k_nil
	db	0	;3c F2
	dw	3c00h,5500h,5f00h,6900h,k_nil
	db	0	;3d F3
	dw	3d00h,5600h,6000h,6a00h,k_nil
	db	0	;3e F4
	dw	3e00h,5700h,6100h,6b00h,k_nil
	db	0	;3f F5
	dw	3f00h,5800h,6200h,6c00h,k_nil
	db	0	;40 F6
	dw	4000h,5900h,6300h,6d00h,k_nil
	db	0	;41 F7
	dw	4100h,5a00h,6400h,6e00h,k_nil
	db	0	;42 F8
	dw	4200h,5b00h,6500h,6f00h,k_nil
	db	0	;43 F9
	dw	4300h,5c00h,6600h,7000h,k_nil
	db	0	;44 F10
	dw	4400h,5d00h,6700h,7100h,k_nil
	db	0	;45 num lock
	dw	k_num,k_num,k_pau,k_num,k_num
	db	0	;46 scroll lock
	dw	k_scr,k_scr,k_brk,k_scr,k_scr
	db	2	;47 home
	dw	4700h,4700h+"7",7700h,k_dig,k_nil
	db	2	;48 up
	dw	4800h,4800h+"8",8d00h,k_dig,k_nil
	db	2	;49 page up
	dw	4900h,4900h+"9",8400h,k_dig,k_nil
	db	0	;4a keypad -
	dw	4a00h+"-",4a00h+"-",8e00h,4a00h,k_nil
	db	2	;4b left
	dw	4b00h,4b00h+"4",7300h,k_dig,k_nil
	db	2	;4c center
	dw	4c00h,4c00h+"5",8f00h,k_dig,k_nil
	db	2	;4d right
	dw	4d00h,4d00h+"6",7400h,k_dig,k_nil
	db	0	;4e keypad +
	dw	4e00h+"+",4e00h+"+",9000h,4e00h,k_nil
	db	2	;4f end
	dw	4f00h,4f00h+"1",7500h,k_dig,k_nil
	db	2	;50 down
	dw	5000h,5000h+"2",9100h,k_dig,k_nil
	db	2	;51 page down
	dw	5100h,5100h+"3",7600h,k_dig,k_nil
	db	2	;52 ins
	dw	5200h,5200h+"0",9200h,k_dig,k_nil
	db	2	;53 delete
	dw	5300h,5300h+".",9300h,0a300h,k_boo
	db	0	;54 print screen / sys req
	dw	k_prt,k_nil,7200h,k_sys,k_nil
	db	0	;55 no key
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	db	0	;56 left shift
	dw	k_lsh,k_lsh,k_lsh,k_lsh,k_lsh
	db	0	;57 F11
	dw	8500h,8700h,8900h,8b00h,k_nil
	db	0	;58 F12
	dw	8600h,8800h,8a00h,8c00h,k_nil
	db	0	;59 no key
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	db	0	;5A no key
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	db	0	;5B windows key left (104 key kbd only)
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	db	0	;5C windows key right (104 key kbd)
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	db	0	;5D menu key (104 key kbd)
	dw	k_nil,k_nil,k_nil,k_nil,k_nil
	
maxscan	equ	5Dh
