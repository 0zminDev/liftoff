bits 16 

section _TEXT class=CODE 

; CDECL spec 
; arguments passed right to left though stack 
; caller removes them from stack 
; retuns to ax - ints pointers 
; st0 - floats 
; caller must save eax ecx and edx and the rest by function 
; function mangled with a_ 
;
; Writes char to video 
;
; args: character, page 
;
; int 10h, ah=0Eh
global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    ; save previous pos of pointer
    push bp
    
    mov bp, sp ;move it to the beigneing of closure stack region sp will be the end bp will be the beginning 
    ; save bx
    push bx

    ; [bp + 0] - return offset small jmp becasue of sm memory type 
    ; [bp + 2] - char arg (bytes are converted to WORD cannot push single B to stack)
    ; [bp + 4] - page arg 
    mov ah, 0Eh 
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h 
    
    ;restore bx
    pop bx

    ; restore stack from closure 
    mov sp, bp
    ; restore old bp
    pop bp 
    ret
