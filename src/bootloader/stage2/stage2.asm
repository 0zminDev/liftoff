bits 16 

section _ENTRY class=CODE 

extern _cstart_
global entry 

entry:
    cli
    mov ax, ds 
    mov ss, ax 
    mov sp, 0 
    mov bp, sp 
    sti 

    ; boot drive in dl so we send it as argument to main c function
    xor dh, dh
    push dx 
    call _cstart_ 

    cli 
    hlt 
