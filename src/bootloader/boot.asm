org 0x7C00              ; 0ffset to 7c00
bits 16                 ; setup 16 bits mode

%define ENDL 0x0D, 0x0A

;
;   FAT12 Header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 B
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1 
bdb_reserved_sectors:       dw 1 
bdb_fat_count:              db 2 
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
    ; setup data segments
    mov ax, 0                                       ; can't write directly to ds/es in 16 bits
    mov ds, ax                                      ; data segment
    mov es, ax                                      ; extera segment
    
    ; setup stack 
    mov ss, ax
    mov sp, 0x7C00
    
    ; Some BIOSes might not start at zero so we force it 
    push es 
    push word .after 
    retf

.after:
    ; read something 
    ; BIOS sets up dl to drive number
    mov [ebr_drive_number], dl 

    ; prints hello world
    mov si, msg_loading
    call puts
    
    ; read drive params instead of relying on data on formatted disk which might be fucked up for some reason 
    push es
    mov ah, 08h 
    int 13h
    jc floppy_error 
    pop es

    and cl, 0x3F                                    ; remove top 2 bits 
    xor ch, ch 
    mov [bdb_sectors_per_track], cx                 ; sector count 

    inc dh                                          ; head count 
    mov [bdb_heads], dh 
    
    ; read FAT root directory
    mov ax, [bdb_sectors_per_fat]                   ; LBA of root dir = reserved + fats * sectors_per_fat;
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                                          ; ax = (fats * sectors_per_fat)
    add ax, [bdb_reserved_sectors]                  ; ax = LBA 
    push ax                                         ; save it on stack

    mov ax, [bdb_dir_entries_count]                   ; size = 32*number_of_entries/bytes-per_sector 
    shl ax, 5                                           ; mul * 5 (2^5) 
    xor dx, dx                                          ; clear the reprocity reg
    div word [bdb_bytes_per_sector]

    test dx, dx                                     ; id dx != 0 add 1 
    jz .root_dir_after
    inc ax

.root_dir_after:
    mov cl, al 
    pop ax 
    mov dl, [ebr_drive_number]
    mov bx, buffer 
    call disk_read

    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, file_kernel_bin                         ; kernel filename 
    mov cx, 11                                      ; filename size 
    push di
    ; really convinient line compares 2 string bytes in memory increases them each time and repe is repeat until cx is zero and
    ; decrease each time 
    repe cmpsb
    pop di
    je .found_kernel 

    add di, 32                                      ; move to next entry 
    inc bx                                          ; increment dir checked count 

    cmp bx, [bdb_dir_entries_count]
    jl .search_kernel

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
    mov ax, [kernel_cluster]
    ; HACK: change this beofre cheanging the disk from floppy_disk 
    add ax, 31
    mov cl, 1 
    mov dl, [ebr_drive_number]
    call disk_read

    ; HACK: Could overflow
    add bx, [bdb_bytes_per_sector]
    
    ; compute the next cluster 
    mov ax, [kernel_cluster]
    mov cx, 3 
    mul cx
    mov cx, 2 
    div cx

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

;
; Error handlers
;
floppy_error:
    mov si, msg_read_failed 
    call puts
    jmp wait_key_and_reboot

kernel_not_found_error:
    mov si, msg_kernel_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0 
    int 16h                                         ; wait for key press 
    jmp 0FFFFh:0                                    ; jump to BIOS which should reboot it 

.halt:
    cli                                             ; disable interrupts 
    hlt 

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

    xor dx, dx                                      ; clear dx

    ; NOTE theoretically we could have here 18 hardcoded
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

msg_loading:                    db 'Loading...', ENDL, 0
msg_read_failed:                db 'Disk read failed.', ENDL, 0
msg_kernel_not_found:           db 'Cannot find kernel', ENDL, 0

file_kernel_bin:                db 'KERNEL  BIN'
kernel_cluster:                  dw 0

KERNEL_LOAD_SEGMENT:            equ 0x2000
KERNEL_LOAD_OFFSET:             equ 0

; NOTE: both org times and dw are directives not intructions
times 510-($-$$) db 0                               ; move though ram sector till the end write 0 everywhere
dw 0AA55h                                           ; set directive for bios

buffer:

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
