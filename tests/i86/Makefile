s3roms :=  $(patsubst %.s,%.s3rom,$(wildcard *.s))
rtlroms := $(patsubst %.s,%.rtlrom,$(wildcard *s))
all: $(s3roms) $(rtlroms)

# altera: ../../altera/zet/simulation/modelsim/bios0.dat ../../altera/zet/simulation/modelsim/bios1.dat

# ../../altera/zet/simulation/modelsim/bios0.dat: bios0.out
#	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios0.out > ../../altera/zet/simulation/modelsim/bios0.dat

#../../altera/zet/simulation/modelsim/bios1.dat: bios1.out
#	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios1.out > ../../altera/zet/simulation/modelsim/bios1.dat

#../../sim/bios.dat: bios.out
#	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios.out > ../../sim/bios.dat
#	hexdump -v -e '1/2 "0x1%04_ax/%04x"' -e '"\n"' bios.out | awk -F/ '{printf "00%x/%s\n", rshift(strtonum($$1),1), $$2}' > ../../impl/spartan3an-sk/sim/flash-prom/memory_file

#$(BIOS): bios.out
#	splitlh bios.out $(BIOS)

%.s3rom: %.out
	hexdump -v -e '1/2 "0x1%04_ax/%04x"' -e '"\n"' $< | awk -F/ '{printf "00%x/%s\n", rshift(strtonum($$1),1), $$2}' > ../../impl/spartan3an-sk/sim/flash-prom/$@

%.mcs: %.out
	echo :020000040001F9 > $@
	hexdump -v -e '":20%04_ax00"' -e '32/1 "%02x"' -e '"00"' -e '"\n"' $< | tr a-z A-Z >> $@
	echo :00000001FF >> $@

%.rtlrom: %.out
	hexdump -v -e '1/1 "%02X"' -e '"\n"' $< > ../../sim/$@

%.rom: %.out
	out2rom-ml403 < $< > $@
	
%.bin: %.rom
	cat count.rom $< > $@

%.out: %.o
	objcopy -O binary -S $< $@

%.o: %.c
	as $< -o $@

clean:
	rm -f *.o *.out *.bin *.mcs ../../impl/spartan3an-sk/sim/flash-prom/*.s3rom ../../sim/*.rtlrom
