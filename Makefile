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
com_LDFLAGS = -T100 -Md


all: bzk.com bzk.rom bzk.8
bzk.bin: rom-console.o common.o main.o
bzk.com: tsr-serial.o common.o main.o


%.o: %.c
	$(CC) $(CFLAGS) -A-l -A$^.lst -o $@ -c $<

%.o: %.S
	$(CC) $(CFLAGS) -A-l -A$^.lst -o $@ -c $<

%.bin:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.rom: %.bin
	perl mangle.pl <$< >$@

%.com:
	$(CC) $(CFLAGS) $(LDFLAGS) $(com_LDFLAGS) -o $@ $^

%.8: %.pod
	pod2man --center 'System Tools Reference' \
		--section 8 --date 2021-06-25 --release 2 $< >$@

%.pdf: %.8
	groff -Tpdf -mman $< >$@

.PHONY: dumprom runrom

dumprom: bzk.bin
	objdump -b binary -m i8086 -D $<

runrom: bzk.rom
	qemu-system-i386 -net none -monitor stdio -option-rom $<


.PHONY: dumpcom runcom runcom-pty

dumpcom: bzk.com
	objdump -b binary -m i8086 -D $<

runcom: bzk.com
	mcopy -o -i fda.img $< ::
	qemu-system-i386 -net none -serial stdio -fda fda.img

runcom-pty: bzk.com
	mcopy -o -i fda.img $< ::
	rm -f PTY
	qemu-system-i386 -net none -serial pty -fda fda.img |awk '/char device redirected to/ {print $$5; fflush()}' >PTY


.PHONY: clean

clean:
	rm -f *.o *.lst *.bin *.8 bzk.com bzk.rom


.SECONDARY:
