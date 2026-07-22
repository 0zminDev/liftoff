#pragma once

#include "compiler.h"
#include "stdint.h"

void ASMCALL x86_div64_32(uint64_t dividend, uint32_t divizor,
						  uint64_t *quotientOut, uint32_t *reminderOut);
void ASMCALL x86_Video_WriteCharTeletype(char c, uint8_t page);
