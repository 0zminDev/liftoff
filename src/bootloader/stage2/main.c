#include "compiler.h"
#include "stdint.h"
#include "stdio.h"

// in stage2.asm we declare it by _cstart_ but here we do it without
// its cuz of the ASMCALL convention (_cdecl) requires function be mangled with
// a_ another way would be to call funtion __cstart_ but this is right aproach
// too
void ASMCALL cstart_(uint16_t bootDrive) {
	puts("Hello World from C!\r\n");
	printf("Test %% %s %c %d %lx %llu %hd %hhd\r\n", "abc", 'z', 1, 2ul, 3ull,
		   (short)4, (char)5);
}
