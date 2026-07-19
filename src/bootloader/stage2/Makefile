
BUILD_DIR ?= build/
ASM ?= nasm
CC16 ?= ~/tools/watcom/binl64/wcc 
LD16 ?= ~/tools/watcom/binl64/wlink

SOURCES = $(wildcard *.c)
SOURCES_ASM = $(wildcard *.asm)

OBJECTS_C = $(patsubst *.c ) 

.PHONY: all clean 

all: stage2 

stage2: $(BUILD_DIR)/stage2.bin 

$(BUILD_DIR)/stage2.bin:
	$(ASM) stage2.asm -f bin -o $(BUILD_DIR)/stage2.bin 

clean:
	rm -f $(BUILD_DIR)/stage2.bin
