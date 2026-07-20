#include "compiler.h"
#include "stdint.h"
#include "stdio.h"

// in stage2.asm we declare it by _cstart_ but here we do it without
// its cuz of the ASMCALL convention (_cdecl) requires function be mangled with
// a_ another way would be to call funtion __cstart_ but this is right aproach
// too
void ASMCALL cstart_(uint16_t bootDrive) { puts("Hello World from C!"); }
