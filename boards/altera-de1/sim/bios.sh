#!/bin/sh
hexdump -v -e '1/1 "%02X"' -e '"\n"' ../../../soc/bios/bios.out > bios.dat
