/*
 * BZK (Boot Zedol) -- Simple & Stupid Boot ROM Monitor
 *
 * Run "perldoc bzk.pod" to view manual;
 * "make bzk.pdf" to pretty-print one.
 *
 * Copyright (C) 2021 Lubomir Rintel <lkundrak@v3.sk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

.GLOBL _memr
_memr:
	push bp
	mov bp, sp
	push ds
	mov ax, [bp+4]
	mov ds, ax
	mov si, [bp+6]
	xor ah, ah
	mov al, [si]
	pop ds
	pop bp
	ret

.GLOBL _inb
_inb:
	push bp
	mov bp, sp
	mov dx, [bp+4]
	inb al, dx
	xor ah, ah
	pop bp
	ret

.GLOBL _outb
_outb:
	push bp
	mov bp, sp
	mov dx, [bp+4]
	mov ax, [bp+6]
	outb dx, al
	pop bp
	ret

.GLOBL _inw
_inw:
	push bp
	mov bp, sp
	mov dx, [bp+4]
	inw ax, dx
	xor ah, ah
	pop bp
	ret

.GLOBL _outw
_outw:
	push bp
	mov bp, sp
	mov dx, [bp+4]
	mov ax, [bp+6]
	outw dx, ax
	pop bp
	ret

.GLOBL _setmem
_setmem:
	push bp
	mov bp, sp
	mov es, [bp+4]
	mov di, [bp+6]
	mov ax, [bp+8]
	stosb
	pop bp
	ret
