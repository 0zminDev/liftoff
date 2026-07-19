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

    ; so now we need interrupt to write to monitor we use int 0x10 viedo interupt with ah = 0eh print
    ; chars in TTY mode al is the charachter which we alrady have bh is text mode and bl is pixel color which we
    ; doesnt have in this mode returns nothing 7 8 a and d are control codes in al 
    
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

