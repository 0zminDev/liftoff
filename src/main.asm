org 0x7C00              ; 0ffset to 7c00
bits 16                 ; setup 16 bits mode

%define ENDL 0x0D, 0x0A

start:
    jmp main

; Prints a string to the screen
; - ds:si points to string
puts:
    ; save regs to the stack 
    push si
    push ax

.loop:
    lodsb               ; loads next byte from ds:si in al 
    or  al, al          ; dos nothing to al but does sets up zero flag if its zero so we know if its null
    jz .done            ; if zero is set then return

    ; so now we need interrupt to write to monitor we use int 0x10 viedo interupt with ah = 0eh print
    ; chars in TTY mode al is the charachter which we alrady have bh is text mode and bl is pixel color which we
    ; doesnt have in this mode returns nothing 7 8 a and d are control codes in al 
    
    mov ah, 0x0E
    mov bh, 0
    int 0x10

    jmp .loop           ; else go to the start of the loop

.done:
    ; take stack variables back then return
    pop ax
    pop si
    ret

main:
    ; setup data segments
    mov ax, 0           ; can't write directly to ds/es in 16 bits
    mov ds, ax          ; data segment
    mov es, ax          ; extera segment

    ; setup stack 
    mov ss, ax
    mov sp, 0x7C00      ; grows downwards

    ; prints hello world
    mov si, msg_hello
    call puts

    hlt

.halt:                  ; if not stopped still do nothing
    jmp .halt

msg_hello: db 'Hello World!', ENDL, 0

; NOTE: both org times and dw are directives not intructions
times 510-($-$$) db 0   ; move though ram sector till the end write 0 everywhere
dw 0AA55h               ; set directive for bios

; segment:[bsae + index + displacement]
; segment - CS DS ES FS GS or SS
; base - BP/BX
; index - SI/DI
; displacement - any signed constant cant be set without intermidiate register
; this is for 16 bits onl

; var: dw 100

; mov ax, var     ; copy offset
; mov ax, [var]   ; copy content

; array: dw 100, 200, 300

; mov bx, array
; mov si, 2 * 2       ; array[2] WORD is 2 B wide as its 16bits structure
; mov ax, [bx + si]   ; so in ax i will have 300 word 
