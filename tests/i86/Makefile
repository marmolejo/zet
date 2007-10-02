SRCBIOS=05_jump2.s
all: bench

bench: ../../bench/bios.dat

altera: ../../altera/zet/simulation/modelsim/bios0.dat ../../altera/zet/simulation/modelsim/bios1.dat

BIOS=bios0.out bios1.out

../../altera/zet/simulation/modelsim/bios0.dat: bios0.out
	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios0.out > ../../altera/zet/simulation/modelsim/bios0.dat

../../altera/zet/simulation/modelsim/bios1.dat: bios1.out
	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios1.out > ../../altera/zet/simulation/modelsim/bios1.dat

../../bench/bios.dat: bios.out
	hexdump -v -e '1/1 "%02X"' -e '"\n"' bios.out > ../../bench/bios.dat

$(BIOS): bios.out
	splitlh bios.out $(BIOS)

bios.out: bios.o
	objcopy -O binary -S bios.o bios.out

bios.o: $(SRCBIOS)
	as ${SRCBIOS} -o bios.o

clean:
	rm -f bios.out bios.o bios0.out bios1.out
