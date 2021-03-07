# BZK (Boot Zedol) -- Simple & Stupid Boot ROM Monitor
#
# Run "perldoc bzk.pod" to view manual;
# "make bzk.pdf" to pretty-print one.
#
# Copyright (C) 2021 Lubomir Rintel <lkundrak@v3.sk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

CC = bcc

CFLAGS = -0 -ansi -vv
LDFLAGS = -x -M -d -i

all: bzk.rom bzk.8

%.o: %.c
	$(CC) $(CFLAGS) -A-l -A$^.lst -o $@ -c $<

%.o: %.S
	$(CC) $(CFLAGS) -A-l -A$^.lst -o $@ -c $<

bzk: lo.o main.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.rom: %
	perl mangle.pl <$< >$@

run: bzk.rom
	qemu-system-i386 -net none -monitor stdio -option-rom $<

dump: bzk
	objdump -b binary -m i8086 -D bzk

bzk.8: bzk.pod
	pod2man --center 'Boot ROM Reference' \
		--section 8 --date 2021-03-07 --release 1 $< >$@

bzk.pdf: bzk.8
	groff -Tpdf -mman $< >$@

clean:
	rm -f *.o *.lst *.8 *.pdf bzk bzk.rom

.PHONY: clean run dump
.SECONDARY:
