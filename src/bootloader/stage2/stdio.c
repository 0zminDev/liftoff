#include "stdio.h"
#include "x86.h"

void putc(char c) { x86_Video_WriteCharTeletype(c, 0); }

void puts(const char *s) {
	while (*s) {
		putc(*s);
		s++;
	}
}

#define PRINTF_STATE_NORMAL 0
#define PRINTF_STATE_LENGHT 1
#define PRINTF_STATE_LENGHT_SHORT 2
#define PRINTF_STATE_LENGHT_LONG 3
#define PRINTF_STATE_SPEC 4

#define PRINTF_LENGHT_DEFAULT 0
#define PRINTF_LENGHT_SHORT_SHORT 1
#define PRINTF_LENGHT_SHORT 2
#define PRINTF_LENGHT_LONG 3
#define PRINTF_LENGHT_LONG_LONG 4

const char g_HexChars[] = "0123456789abcdef";

int *printf_num(int *argp, int length, bool isSigned, int radix) {
	char buffer[32];
	unsigned long long number;

	int number_sign = 1;
	int pos = 0;

	switch (length) {
	case PRINTF_LENGHT_SHORT_SHORT:
	case PRINTF_LENGHT_SHORT:
	case PRINTF_LENGHT_DEFAULT:
		if (isSigned) {
			int n = *argp;
			if (n < 0) {
				n = -n;
				number_sign = -1;
			}
			number = n;
		} else {
			number = *(unsigned int *)argp;
		}
		argp++;
		break;
	case PRINTF_LENGHT_LONG:
		if (isSigned) {
			long int n = *(long int *)argp;
			if (n < 0) {
				n = -n;
				number_sign = -1;
			}
			number = n;
		} else {
			number = *(unsigned long int *)argp;
		}
		argp++;
		break;
	case PRINTF_LENGHT_LONG_LONG:
		if (isSigned) {
			long long int n = *(long long int *)argp;
			if (n < 0) {
				n = -n;
				number_sign = -1;
			}
			number = n;
		} else {
			number = *(unsigned long long int *)argp;
		}
		argp += 2;
		break;
	default:
		return argp;
		break;
	}

	do {
		// NOTE: We are in 16 bits so we cannot just mod it here since DIV
		// RDX:RDX can only happen in 64 mode. we need to perform long div.
		uint32_t rem;
		x86_div64_32(number, radix, &number, &rem);
		buffer[pos++] = g_HexChars[rem];
	} while (number > 0);

	if (isSigned && number_sign < 0) {
		buffer[pos++] = '-';
	}

	while (--pos >= 0) {
		putc(buffer[pos]);
	}

	return argp;
}

void ASMCALL printf(const char *fmt, ...) {
	int *argp = (int *)&fmt;
	int state = PRINTF_STATE_NORMAL;
	int lenght = PRINTF_LENGHT_DEFAULT;
	int radix = 10;
	bool isSigned = true;

	argp += sizeof(fmt) / sizeof(int);
	while (*fmt) {
		switch (state) {
		case PRINTF_STATE_NORMAL:
			switch (*fmt) {
			case '%':
				state = PRINTF_STATE_LENGHT;
				lenght = PRINTF_LENGHT_DEFAULT;
				isSigned = true;
				radix = 10;
				fmt++;
				break;
			default:
				putc(*fmt);
				fmt++;
				break;
			}
			break;
		case PRINTF_STATE_LENGHT:
			switch (*fmt) {
			case 'h':
				lenght = PRINTF_LENGHT_SHORT;
				state = PRINTF_STATE_LENGHT_SHORT;
				fmt++;
				break;
			case 'l':
				lenght = PRINTF_LENGHT_LONG;
				state = PRINTF_STATE_LENGHT_LONG;
				fmt++;
				break;
			default:
				state = PRINTF_STATE_SPEC;
				break;
			}
			break;
		case PRINTF_STATE_LENGHT_SHORT:
			switch (*fmt) {
			case 'h':
				lenght = PRINTF_LENGHT_SHORT_SHORT;
				state = PRINTF_STATE_SPEC;
				fmt++;
				break;
			default:
				state = PRINTF_STATE_SPEC;
				break;
			}
			break;
		case PRINTF_STATE_LENGHT_LONG:
			switch (*fmt) {
			case 'l':
				lenght = PRINTF_LENGHT_LONG_LONG;
				state = PRINTF_STATE_SPEC;
				fmt++;
				break;
			default:
				state = PRINTF_STATE_SPEC;
				break;
			}
			break;
		case PRINTF_STATE_SPEC:
			switch (*fmt) {
			case 'c':
				putc((char)*argp);
				argp++;
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case 's':
				puts(*(char **)argp);
				argp += sizeof(char *) / sizeof(int);
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case '%':
				putc('%');
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case 'i':
			case 'd':
				radix = 10;
				isSigned = true;
				argp = printf_num(argp, lenght, isSigned, radix);
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case 'u':
				radix = 10;
				isSigned = false;
				argp = printf_num(argp, lenght, isSigned, radix);
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case 'X':
			case 'x':
			case 'p':
				radix = 16;
				isSigned = false;
				argp = printf_num(argp, lenght, isSigned, radix);
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			case 'o':
				radix = 8;
				isSigned = false;
				argp = printf_num(argp, lenght, isSigned, radix);
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			default:
				state = PRINTF_STATE_NORMAL;
				fmt++;
				break;
			}
			break;
		default:
			state = PRINTF_STATE_NORMAL;
			fmt++;
			break;
		}
	}
}
