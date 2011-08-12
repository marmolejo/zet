a386 bios.8 bios.bin
..\tool\biossum bios.bin bios.abs
cat ..\fill32.bin ..\fill32.bin ..\fill48.bin bios.abs >rom.rom
