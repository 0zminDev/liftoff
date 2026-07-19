
org 0x0              ; 0ffset to 7c00
bits 16                 ; setup 16 bits mode

%define ENDL 0x0D, 0x0A

start:
    mov si, msg_hello
    call puts

.halt:
    cli 
    hlt 
    jmp .halt 

; Prints a string to the screen
; - ds:si points to string
puts:
    push si
    push ax

.loop:
    lodsb               
    or  al, al          
    jz .done            
    
    mov ah, 0x0E
    mov bh, 0
    int 0x10

    jmp .loop           

.done:
    pop ax
    pop si
    ret

msg_hello: db 'Hello World from Stage2!', ENDL, 0
