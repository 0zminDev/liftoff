.start:
    ; BIOS sets up dl to drive number
    mov [ebr_drive_number], dl 

    mov si, msg_loading
    call puts

    ; Take drive params from BIOS instead of floppy_disk (floppy_disk reads are unreliable)
    push es
    mov ah, 08h 
    int 13h
    jc floppy_error
    pop es
    
    ; cx contains both sectors_per_track and plater count (whic will always be 1 so we erase this data which is useless)
    and cl, 0x3F
    xor ch, ch 
    mov [bdb_sectors_per_track], cx

    ; head count needs to be incremented idk why its like that
    inc dh
    mov [bdb_heads], dh 

