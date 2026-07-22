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
; performs long division in 16 bits 
;
global _x86_div64_32:
_x86_div64_32:
    push bp
    mov bp, sp 

    push bx
    
    ; divisior ecx divident eax (upper 32 bits)
    mov eax, [bp + 8]
    mov ecx, [bp + 12]
    xor edx, edx 

    div ecx             ; eax quotient edx remainer 
    
    mov bx, [bp + 16]   ; take the result 
    mov [bx + 4], eax 

    mov eax, [bp + 4]
    div ecx

    mov [bx], eax 
    mov bx, [bp + 18]
    mov [bx], edx 

    pop bx

    mov sp, bp
    pop bp
    ret

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
