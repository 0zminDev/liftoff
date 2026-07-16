org 0x7C00              ; 0ffset to 7c00
bits 16                 ; setup 16 bits mode

main:
    hlt                 ; do nothing

.halt:                  ; if not stopped still do nothing
    jmp .halt

; NOTE: both org times and dw are directives not intructions
times 510-($-$$) db 0   ; move though ram sector till the end write 0 everywhere
dw 0AA55h               ; set directive for bios
