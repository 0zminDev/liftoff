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

    xor dx, dx                                      ; clear dx

    ; NOTE: theoretically we could have here 18 hardcoded
    div word [bdb_sectors_per_track]                ; ax = LBA/SectorsPerTrack
                                                    ; dx = LBA % SectorsPerTrack 
    inc dx                                          ; dx = (LBA % SectorsPerTrack) = 1 = sector 
    mov cx, dx 

    xor dx, dx 

    ;NOTE and here insted of div just bit shift as heads are 2 bit for now its fine
    div word [bdb_heads]                            ; ax = (LBA/SectorsPerTrack)/Heads = cylinder
                                                    ; dx  = (LBa/SectorsPerTRack)%Heads = head
    mov dh, dl
    mov ch, al 
    shl ah, 6                                       ; do this like that to prevent Partial Register Stall 
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

