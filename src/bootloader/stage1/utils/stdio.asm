; Prints a string to the screen
; - ds:si points to string
puts:
    ; save regs to the stack 
    push si
    push ax
    push bx

.loop:
    lodsb                                           ; loads next byte from ds:si in al 
    or  al, al                                      ; dos nothing to al but does sets up zero flag if its zero so we know if its null
    jz .done                                        ; if zero is set then return

    mov ah, 0x0E
    mov bh, 0
    int 0x10

    jmp .loop                                       ; else go to the start of the loop

.done:
    ; take stack variables back then return
    pop bx
    pop ax
    pop si
    ret

