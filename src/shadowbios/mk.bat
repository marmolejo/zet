cls 

wcc -0 -wx -zu  -s -ot -d0 -ecc -ms  zetbios_c.c 
wdis -l zetbios_c.obj -s=zetbios_c.c

wasm -0 -w3 zetbios_a.asm
wdis -l zetbios_a.obj -s=zetbios_a.asm
 



