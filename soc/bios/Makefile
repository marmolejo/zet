.SUFFIXES: .cc

srcdir = .


SHELL = /bin/sh



CXX = g++
CXXFLAGS = -g3 -O0 -D_FILE_OFFSET_BITS=64 -D_LARGE_FILES

LDFLAGS = 
LIBS =  -lm
RANLIB = ranlib

BCC = bcc
GCC = gcc
GCC32 = gcc -m32
AS86 = as86

BX_INCDIRS = -I.. -I$(srcdir)/.. -I../iodev -I$(srcdir)/../iodev
LOCAL_CXXFLAGS =

BUILDDATE = `date '+%m/%d/%y'`
BIOS_BUILD_DATE = "-DBIOS_BUILD_DATE=\"$(BUILDDATE)\""
#
# -------- end configurable options --------------------------
#

bios: biossums zet-bios

clean:
	rm -f  *.o *.a *.s _rombios*_.c rombios*.txt rombios*.sym
	rm -f  usage biossums

bios-clean:
	rm -f  zet-bios

.cc.o:
	$(CXX) -c $(BX_INCDIRS) $(CXXFLAGS) $(LOCAL_CXXFLAGS) $< -o $@

zet-bios: rombios.c biossums rombios.h
	$(GCC32) $(BIOS_BUILD_DATE) -DLEGACY -E -P $< > _rombiosl_.c
	$(BCC) -o rombiosl.s -C-c -D__i86__ -0 -S _rombiosl_.c
	sed -e 's/^\.text//' -e 's/^\.data//' rombiosl.s > _rombiosl_.s
	$(AS86) _rombiosl_.s -b tmpl.bin -u- -w- -g -0 -j -O -l rombiosl.txt
	-perl ${srcdir}/makesym.perl < rombiosl.txt > rombiosl.sym
	mv tmpl.bin $@
	./biossums $@
	rm -f  _rombiosl_.s

biossums: biossums.c
	$(GCC) -o biossums biossums.c