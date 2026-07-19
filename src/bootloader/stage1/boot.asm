org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

%include "./data/fat12_header.asm"

init:
    ; flush data segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    
    ; setup stack 
    mov ss, ax
    mov sp, 0x7C00
    
    ; Force start at offset zero from org 
    push es 
    push word .start
    retf

%include "main.asm"
%include "load_kernel.asm"

%include "./utils/error.asm"

%include "./utils/stdio.asm"
%include "./utils/disk.asm"

%include "./data/data.asm"

times 510-($-$$) db 0
dw 0AA55h

buffer:
