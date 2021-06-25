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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef NULL
#define NULL ((void *)0)
#endif

static void
sput (char *str)
{
	while (*str)
		putchar (*str++);
}

static void
puthex (unsigned num, int digits)
{
	if (digits)
		digits--;
	if (num >= 0x10 || digits)
		puthex (num / 0x10, digits);
	num %= 0x10;
	putchar (num > 9 ? 'a' + num - 10 : '0' + num);
}

static void
dump (unsigned seg, unsigned off, unsigned len)
{
	unsigned i = off & 0xf0;
	unsigned char printable[16];
	unsigned char c;

	sput ("		   0  1	 2  3  4  5  6	7   8  9  a  b	c  d  e	 f\n");
	for (i = (off & 0xfff0); i < ((off + len - 1) | 0x0f) + 1; i++) {
		if ((i & 0x0f) == 0x00) {
			puthex (seg, 4);
			putchar (':');
			puthex (i, 4);
			putchar (' ');
			putchar (' ');
		}
		if (i < off || i >= off + len) {
			putchar(' ');
			putchar(' ');
			c = ' ';
		} else {
			c = memr(seg, i);
			puthex (c, 2);
			if (c < 0x20 || c >= 0x7f)
				c = '.';
		}
		printable[i & 0x0f] = c;
		putchar (' ');
		if ((i & 0x0f) == 0x07) {
			putchar (' ');
		} else if ((i & 0x0f) == 0x0f) {
			putchar (' ');
			i &= 0xfff0;
			do {
				putchar (printable[i & 0x0f]);
			} while (++i & 0x0f);
			i--;
			putchar ('\n');
		}
	}
}

static int
isword (char *line, char *word) {
	do {
		if (*line != *word)
			return 0;
		line++;
		word++;
		if (*line == '\0' || *line == ' ')
			break;
	} while (*word);
	return 1;
}

static char *
nextword (char *line)
{
	if (!line)
		return NULL;
	while (*line != '\0' && *line != ' ')
		line++;
	while (*line == ' ')
		line++;
	if (*line == '\0')
		return NULL;
	return line;
}

static char *
gethex (char *line, unsigned *num)
{
	*num = 0;

	if (!line)
		return NULL;
	do {
		*num <<= 4;
		if (*line >= '0' && *line <= '9')
			*num |= *line - '0';
		else if (*line >= 'a' && *line <= 'f')
			*num |= *line - 'a' + 10;
		else
			return NULL;
	} while (*line++ && *line != ' ' && *line != ':' && *line);

	return line;
}

enum { SHELL, ENTER } state = SHELL;
unsigned seg = 0x0050;
unsigned io = 0x80;
unsigned off, len, val;
static unsigned char linebuf[78];

static void
printprompt ()
{
	switch (state) {
	case SHELL:
		sput ("$ ");
		break;
	case ENTER:
		puthex (seg, 4);
		putchar (':');
		puthex (off, 4);
		sput ("> ");
		break;
	}
}

static void
shellline (char *line)
{
	if (line == NULL) {
		linebuf[0] = '\0';
		goto prompt;
	}

	if (*line == '\0')
		goto prompt;

	if (isword (line, "dump")) {
		line = nextword (line);
		if (line)
			line = gethex (line, &off);
		if (line && *line == ':') {
			seg = off;
			if (*++line != ' ')
				line = gethex (line, &off);
			else
				off = 0;
		}
		if (line) {
			line = nextword (line);
			line = gethex (line, &len);
			line = nextword (line);
			if (line) {
				putchar ('\x07');
				goto prompt;
			}
		}
		if (!len)
			len = 0x80;
		dump(seg, off, len);
		off += len;
		linebuf[0] = 'd';
		linebuf[1] = '\0';
		goto prompt;
	}

	if (isword (line, "enter")) {
		line = nextword (line);
		if (line)
			line = gethex (line, &off);
		if (line && *line == ':') {
			seg = off;
			if (*++line != ' ') {
				line = gethex (line, &off);
				line = nextword (line);
			} else {
				off = 0;
			}
		}
		if (!line || *line == '\0') {
			state = ENTER;
			linebuf[0] = '\0';
			goto prompt;
		}
		while (line) {
			line = gethex (line, &val);
			line = nextword (line);
			setmem (seg, off, val);
			off++;
		}
		goto prompt;
	}

	if (isword (line, "inb")) {
		line = nextword (line);
		if (line) {
			line = gethex (line, &io);
			line = nextword (line);
		}
		if (line) {
			putchar ('\x07');
			goto prompt;
		}
		puthex (io, 4);
		sput(": ");
		puthex (inb (io), 2);
		putchar('\n');
		goto prompt;
	}

	if (isword (line, "outb")) {
		line = nextword (line);
		if (line) {
			line = gethex (line, &val);
			line = nextword (line);
		}
		if (line) {
			io = val;
			line = gethex (line, &val);
			line = nextword (line);
		}
		if (line) {
			putchar ('\x07');
			goto prompt;
		}
		outb(io, val);
		goto prompt;
	}

	if (isword (line, "in")) {
		line = nextword (line);
		if (line) {
			line = gethex (line, &io);
			line = nextword (line);
		}
		if (line) {
			putchar ('\x07');
			goto prompt;
		}
		puthex (io, 4);
		sput(": ");
		if (isword (linebuf, "inw"))
			puthex (inw (io), 4);
		else
			puthex (inb (io), 2);
		putchar('\n');
		goto prompt;
	}

	if (isword (line, "out")) {
		line = nextword (line);
		if (line) {
			line = gethex (line, &val);
			line = nextword (line);
		}
		if (line) {
			io = val;
			line = gethex (line, &val);
			line = nextword (line);
		}
		if (line) {
			putchar ('\x07');
			goto prompt;
		}
		if (isword (linebuf, "outw"))
			outw(io, val);
		else
			outb(io, val);
		goto prompt;
	}

	if (isword (line, "help") || isword (line, "?")) {
		sput("d[ump] [seg:][off] [len]\n");
		sput("e[nter] [seg:][off] [val ...]\n");
		sput("i[nb]|inw [adr]\n");
		sput("ou[t]|outw [adr] [val]\n");
		goto prompt;
	}

	sput("Err.\x07\n");
	linebuf[0] = '\0';
prompt:
	printprompt ();
}

static void
enterline (char *line)
{
	if (!line || *line == '\0') {
		state = SHELL;
	} else {
		while (line && *line) {
			line = gethex (line, &val);
			if (line)
				setmem (seg, off++, val);
			line = nextword (line);
		}
	}

	linebuf[0] = '\0';
	printprompt ();
}

static void
gotline (char *line)
{
	switch (state) {
	case SHELL:
		shellline (line);
		break;
	case ENTER:
		enterline (line);
		break;
	}
}

int
gotchar (char c)
{
	static int i;

	if (c >= 0x20 && c < 0x7f) {
		if (i == sizeof(linebuf) - 1) {
			putchar ('\x07');
			return 0;
		}
		linebuf[i++] = c;
		putchar (c);
		return 0;
	}

	/* Kill Letter */
	if (c == 0x7f)
	       c = 0x8;
	if (c == 0x8) {
		if (i == 0) {
			putchar ('\x07');
			return 0;
		}
		linebuf[--i] = '\0';
		putchar (c);
		putchar (' ');
		putchar (c);
		return 0;
	}

	/* Kill Word */
	if (c == 0x17) {
		while (i && linebuf[i - 1] == ' ') {
			sput ("\b \b");
			i--;
		}
		while (i && linebuf[i - 1] != ' ') {
			sput ("\b \b");
			i--;
		}
		return 0;
	}

	/* Kill Line */
	if (c == 0x3) {
		linebuf[i] = '\0';
		sput ("^C\n");
		i = 0;
		gotline (linebuf);
		return 0;
	}

	/* Enter */
	if (c == 0xd) {
		if (i)
			linebuf[i] = '\0';
		putchar ('\n');
		i = 0;
		gotline (linebuf);
		return 0;
	}

	/* Finished */
	if (c == 0x4) {
		if (i == 0) {
			putchar ('\n');
			gotline (NULL);
			return 0;
		}
		linebuf[i] = '\0';
		sput ("^D\n");
		i = 0;
		gotline (linebuf);
		return 1;
	}

	putchar ('\x07');
	return 0;
}
