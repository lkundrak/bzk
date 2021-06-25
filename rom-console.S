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

.WORD 0xaa55	; Magic
.BYTE 0x90	; Placeholder for length in 512B paragraphs

_start:
.GLOBL _start
	xor ax, ax
	mov es, ax
	mov di, #0x60
	mov ax, #_run
	stosw
	mov ax, cs
	stosw
	retf

.GLOBL _run
_run:
	; Save some registers. No need to save CS; it's on the stack with
	; the return address already. It wouldn't make to save SS on the
	; old stack, so leave that for later.
	push ds
	push es
	push si
	push di

	; Copy text & data segment from CS:0000 to 0050:0000 in DRAM
	push cs
	pop ds
	mov cx, #0x50
	mov es, cx

	xor di, di
	xor si, si
	mov cx, #__edata
	cld
relocate:
	lodsb
	stosb
	loop relocate

	; Wipe BSS
	mov cx, #__end
	sub cx, #__edata
	xor ax, ax
bss:
	stosb
	loop bss

	; Proceed from the DRAM segment
	push es
	mov ax, #relocated
	push ax
	retf
relocated:

	; Setup the new segments, while saving old SS:SP on the new stack.
	mov ax, sp
	mov bx, ss

	mov cx, es
	mov ds, cx
	mov ss, cx

	xor sp,sp
	dec sp
	push ax
	push bx

	; Main loop
	mov ax, #0x0d
	push ax
	call _gotchar
	pop ax
main:
	call _getchar
	push ax
	call _gotchar
	pop ax
	cmp ax, ax
	jz main

	; Restore the old stack first.
	pop bx
	pop ax
	mov sp, ax
	mov ss, bx

	; Then recover the rest of the saved regs from the old stack.
	pop di
	pop si
	pop es
	pop ds

	; All done, restore the old CS:IP
	retf

.GLOBL _putchar
_putchar:
	push bp
	mov bp, sp
	mov al, [bp+4]
	cmp al, #0x0a
	jne not_lf
	mov ax, #0x0d
	push ax
	call _putchar
	inc sp
	inc sp
	mov al, [bp+4]
not_lf:
	mov ah, #0xe
	int 0x10
	pop bp
	ret

.GLOBL _getchar
_getchar:
	push bp
	mov bp, sp
	xor ax, ax
	int 0x16
	xor ah, ah
	pop bp
	ret
