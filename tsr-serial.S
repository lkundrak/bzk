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

.GLOBL _start
_start:
	; Baud divisor = 12 (115200/12=9600)
	mov dx, #0x3fb
	mov al, #0x80
	out dx, al
	mov dx, #0x3f8
	mov al, #12
	out dx, al
	inc dx
	xor al, al
	out dx, al

	; 8n1
	mov dx, #0x3fb
	mov al, #0x03
	out dx, al

	; Set up FIFO
	dec dx
	mov al, #0xc7
	out dx, al

	; No interrupts
	dec dx
	;xor al, al
	mov al, #0x01 ; data in
	out dx, al

	; irqa cts rts
	mov dx, #0x3fc
	mov al, #0x0f
	out dx, al

	; Wipe BSS
	mov cx, #__end
	sub cx, #__edata
	mov di, #__edata
	xor ax, ax
bss:
	stosb
	loop bss

	push ax ; still a zero
	pop es

	mov di, #0x30
	eseg
		mov [di], #com_int
	eseg
		mov 2[di], cs


	; Unmask all?
	mov dx, #0x21
	in al, dx
	and al, #0xef
	out dx, al

	mov ax, #0x0d
	push ax
	call _gotchar
	pop ax

	mov dx, #__end
	inc dx
	int #0x27

not_reached:
	hlt
	jmp not_reached


.GLOBL com_int
com_int:
	cli
	pushf
	;pusha
	push ax
	push bx
	push cx
	push dx
	push ds

	push cs
	pop ds

	mov dx, #0x3fd
	inb al, dx
	and al, #0x01
	jz no_key

	mov dx, #0x3f8
	inb al, dx
	xor ah, ah

	push ax
	call _gotchar
	pop ax

no_key:
	; EOI
	mov dx, #0x20
	;xor al, al
	mov al, #0x20
	out dx, al

	pop ds
	;popa
	pop dx
	pop cx
	pop bx
	pop ax
	popf

	sti
	iret


.GLOBL _putchar
_putchar:
	push bp
	mov bp, sp

	mov al, [bp+4]
	cmp al, #0x0a
	jne tx_wait

	mov ax, #0x0d
	push ax
	call _putchar
	inc sp
	inc sp

tx_wait:
	mov dx, #0x3fd
	inb al, dx
	and al, #0x20
	jz tx_wait


	mov al, [bp+4]
	mov dx, #0x3f8
	out dx, al


	pop bp
	ret


.GLOBL _getchar
_getchar:
	push bp
	mov bp, sp

rx_wait:
	mov dx, #0x3fd
	inb al, dx
	and al, #0x01
	jz rx_wait

	mov dx, #0x3f8
	in al, dx
	xor ah, ah

	cmp al, #0x0a
	jne rx_not_cr
	mov al, #0x0d
rx_not_cr:

	pop bp
	ret
