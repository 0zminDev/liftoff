
BUILD_DIR ?= build/

ASM ?= nasm
ASMFLAGS ?= -f obj

CC16 ?= wcc

#  -4 compatible with oldest possible cpu instructions only 
#  -d3 cenerated more symbols for debbuging 
#  -s do not runtime stack overflow as we need to make ctr manually
#  -wx enable all errors 
#  -ms small memory layout 
#  -zl do not include standard lib as we need to implement it manually
#  -zq only show warning and error 
CC16FLAGS ?= -4 -d3 -s -wx -ms -zl -zq 

LD16 ?= wlink

SOURCES_C = $(wildcard *.c)
SOURCES_ASM = $(wildcard *.asm)

OBJECTS_C = $(patsubst %.c, $(BUILD_DIR)/stage2/c/%.obj, $(SOURCES_C)) 
OBJECTS_ASM = $(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM))

.PHONY: all stage2 clean always 

all: stage2 

stage2: $(BUILD_DIR)/stage2.bin 

$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_C)
	$(LD16) NAME $(BUILD_DIR)/stage2.bin FILE \{ ${OBJECTS_ASM} ${OBJECTS_C} \} OPTION MAP=${BUILD_DIR}/stage2.map @linker.lnk

$(BUILD_DIR)/stage2/c/%.obj: %.c always
	$(CC16) $(CC16FLAGS) -fo=$@ $< 

$(BUILD_DIR)/stage2/asm/%.obj: %.asm always 
	$(ASM) $(ASMFLAGS) -o $@ $< 

always:
	mkdir -p $(BUILD_DIR)/stage2/c 
	mkdir -p $(BUILD_DIR)/stage2/asm 

clean:
	rm -f $(BUILD_DIR)/stage2.bin
