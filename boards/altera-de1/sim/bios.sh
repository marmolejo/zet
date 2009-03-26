#!/bin/sh
hexdump -v -e '1/1 "%02X"' -e '"\n"' ../../../src/bios/bios.out > bios.dat
