org 0x7C00              ; 0ffset to 7c00
bits 16                 ; setup 16 bits mode

%define ENDL 0x0D, 0x0A

;
;   FAT12 Header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 B
bdb_bytes_per_sector:      dw 512
bdb_sectors_per_cluster:    db 1 
bdb_reserved_sectors:       dw 1 
bdb_fat_count:              dw 2 
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; * 512 = 1440k whole floppy 
bdb_media_descriptor_type:  db 0F0h                 ; indicates floppy disk 3.5'
bdb_sectors_per_fat:        dw 9 
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2 
bdb_hidden_sectors:         dd 0 
bsb_large_sector_count:     dd 0 

; extended boot record 
ebr_drive_number:           db 0                    ; useless 
                            db 0                    ; must be zero 
ebr_signature:              db 29h 
ebr_volume_id:              db 21h, 37h, 42h, 00h   ; lmfao
ebr_volume_label:           db '0zminDev0S '        ; must be 11 b
ebr_system_id:              db 'FAT12   '           ; must be 8 B and this must be FAT12


start:
    jmp main

; Prints a string to the screen
; - ds:si points to string
puts:
    ; save regs to the stack 
    push si
    push ax
    push bx

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
    pop bx
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
    mov sp, 0x7C00

    ; read something 
    mov [ebr_drive_number], dl 

    mov ax, 1                   ; LBA = 1, second sector of disk 
    mov cl, 1                   ; 1 sector to read 
    mov bx, 0x7E00              ; place it after bootloader 
    call disk_read 

    ; prints hello world
    mov si, msg_hello
    call puts
    
    cli
    hlt
;
; Error handlers
;
floppy_error:
    mov si, msg_read_failed 
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0 
    int 16h                  ; wait for key press 
    jmp 0FFFFh:0             ; jump to BIOS which should reboot it 

.halt:
    cli                     ; disable interrupts 
    hlt 
;
; Disk routines 
;

;
; Converts LBA address ti CHS address 
; Paramters:
;   - ax: LDA address 
;
; Returns:
;   - cx [0-5]: sector number 
;   - cx [6-15]: cylinder 
;   - dh: head 
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx          ; clear dx

    ; NOTE theoretically we could have here 18 hardcoded
    div word [bdb_sectors_per_track]    ; ax = LBA/SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack 
    inc dx                              ; dx = (LBA % SectorsPerTrack) = 1 = sector 
    mov cx, dx 

    xor dx, dx 

    ;NOTE and here insted of div just bit shift as heads are 2 bit for now its fine
    div word [bdb_heads]                ; ax = (LBA/SectorsPerTrack)/Heads = cylinder
                                        ; dx  = (LBa/SectorsPerTRack)%Heads = head
    mov dh, dl
    mov ch, al 
    shl ah, 6                           ; do this like that to prevent Partial Register Stall 
    or cl, ah

    pop ax 
    mov dl, al 
    pop ax
    ret

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address 
;   - cl: number of sectors to read max 128  
;   - dl: drive number 
;   - es:bs: memory location to store the data
;
disk_read:

    push ax                                         ; save them 
    push bx
    push cx
    push dx 
    push di 

    push cx                                         ; save the count of sectors to read 
    call lba_to_chs                                 ; change to chs 
    pop ax                                          ; hence i dont need lba no more i save stored count of sectors here 
    ; so for disk read we have everything we need to setup ah to 02h 
    mov ah, 02h 
    ; now interrupt the docs for floppy disks say its reads are unreliable
    ; and they suggest to loop 3 times for it to ensure read 

    mov di, 3                                       ; retry count 

.retry:
    pusha                                           ; idk what it will override so i just paste there everything 
    stc                                             ; some BIOS dont set it so we do it 

    int 13h                                         ; do an disk read if carry is 0 then operation succeded and w can move on if not retry
    jnc .done
    
    ; failde call reset
    popa 
    call disk_reset 

    dec di 
    test di, di                                     ; di-- if di = 0 then it failed too many times 
    jnz .retry 

.fail:
    jmp floppy_error

.done:
    popa

    pop di                                         ; restore them 
    pop dx
    pop cx
    pop bx
    pop ax
    ret 

; 
; Resets controller 
; Parameters:
;   - di: drive number 
;
disk_reset:
    ; so just read from the pegining and it resets if it failed then fuck it and make error honestly 
    pusha 
    mov ah, 0
    stc 
    int 13h 
    jc floppy_error 
    popa 
    ret 

msg_hello:                  db 'Hello World!', ENDL, 0
msg_read_failed:            db 'Disk read failed.', ENDL, 0

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
