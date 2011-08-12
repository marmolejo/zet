a386 bios.8 bios.bin
..\tool\biossum bios.bin bios.abs
del rom.rom
..\tool\add rom.rom ..\fill32.bin ..\fill32.bin ..\fill32.bin ..\fill32.bin
..\tool\add rom.rom ..\fill32.bin ..\fill32.bin ..\fill32.bin ..\fill32.bin
..\tool\add rom.rom ..\fill32.bin ..\fill32.bin ..\fill32.bin ..\fill32.bin
..\tool\add rom.rom ..\fill32.bin ..\fill32.bin ..\fill48.bin bios.abs
