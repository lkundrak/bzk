#!/usr/bin/perl

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

my @bytes = map { ord($_) } split //, join '', <>;
my $len1 = scalar @bytes;

die unless $bytes[0] == 0x55 and $bytes[1] == 0xaa;

my $ckoff = $#bytes + 1;
$ckoff |= 0x1ff;
$bytes[2] = (($ckoff + 1) / 512);
$bytes[$ckoff] = 0xff;

my $cksum = 0;
$cksum += $_ // 0xff foreach @bytes;
$cksum &= 0xff;
$bytes[$ckoff] -= $cksum;
$bytes[$ckoff] -= 0x100;
$bytes[$ckoff] &= 0xff;

print join '', map { chr($_ // 0xff) } @bytes;

$ckoff++;
warn "$len1/$ckoff bytes.\n";
