.find_root_dir:
    ; Find LBA (start of root dir); Sectors - how much of the sectors in root dir 
    ; LBA = bdb_reserved_sectors + (bdb_fat_count * bdb_sectors_per_fat)
    ; sectors = bdb_dir_entries_count * entrySieze(32) / bytes-per_sector
    mov ax, [bdb_sectors_per_fat]                   
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bdb_reserved_sectors]                          ; ax = LBA
    push ax

    mov ax, [bdb_dir_entries_count]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]
    
    ; if the result isnt int add one to size else move to read
    test dx, dx
    jz .read_root_dir
    inc ax
    ; now in ax is sector to read and LBa is in stack 

.read_root_dir:
    ; read the root directory to the end of bootloader sector in ram 
    mov cl, al 
    pop ax 

    ; now we will need red dir end for later 
    push ax 
    add ax, cx 
    mov [root_directory_end], ax            ; save lda of dri end 
    pop ax

    mov dl, [ebr_drive_number]
    mov bx, buffer 
    call disk_read
    
    ; point di to buffer
    xor bx, bx
    mov di, buffer

.search_kernel:
    ; now we need to go each directory entry and compare 
    ; each name field with the name of kernel file 
    mov si, file_kernel_bin                         ; kernel filename 
    mov cx, 11                                      ; filename size 
    push di
    ; really convinient line compares 2 string bytes in memory increases them each time and repe is repeat until cx is zero and
    ; decrease each time 
    repe cmpsb
    pop di
    je .found_kernel 
    
    ; if not found kernel then move to next entry and check if not 
    ; already checked every entry
    add di, 32                                      ; move to next entry 
    inc bx                                          ; increment dir checked count 

    cmp bx, [bdb_dir_entries_count]
    jl .search_kernel
    
    ; here means there is not kernel in the drive
    jmp kernel_not_found_error

.found_kernel:
    ; save first cluster value low and high 
    mov ax, [di + 26]                               ; di still points to this dir root entry and offset for cluster value is 26 
    mov [kernel_cluster], ax

    ; read fat 
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer 
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; read fat chain 
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:
    ; read next cluster 
    ; calculate LBA of the cluster 
    mov ax, [kernel_cluster]
    sub ax, 2 
    xor cx, cx
    mov cl, [bdb_sectors_per_cluster]
    mul cx
    add ax, [root_directory_end]
    mov dl, [ebr_drive_number]
    call disk_read

    ; HACK: Could overflow
    ; NOTE: if a kernel will exceed 64kiB its going to be a problem for now lets leave this here 
    ; NOTE: and if theres gonna be more sector per cluster its should be add bytes in sector * sectors per cluster
    add bx, [bdb_bytes_per_sector]
    
    ; compute the next cluster 
    mov ax, [kernel_cluster]
    mov cx, 3 
    mul cx
    mov cx, 2 
    div cx

    ; so now in ax we have the value of shift to next cluster chain ring 
    ; and in dx we have the rest of divide and so we move condidtionally to next segment depending on this 
    ; computation
    mov si, buffer 
    add si, ax 
    mov ax, [ds:si]

    or dx, dx 
    jz .even 

.odd: 
    shr ax, 4 
    jmp .next_cluster_after 

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0ff8                          ; end of chain 
    jae .read_finish

    mov [kernel_cluster], ax 
    jmp .load_kernel_loop

.read_finish:
    ; load kernel 
    mov dl, [ebr_drive_number]
    mov ax, KERNEL_LOAD_SEGMENT
    mov ds, ax 
    mov es, ax 

    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

    jmp wait_key_and_reboot

    cli
    hlt

