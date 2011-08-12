rem program flash EPROM
copy rom.rom \emp
cd \emp
copy sst39010.ini emp20.ini
emp20
cd \tb2\ali1487
