@echo off
rem  Assemble and link file for the XCDROM driver.
..\nasm32\nasm -o XGCDRX86.sys -l XGCDRX86.lst XGCDRX86.asm

