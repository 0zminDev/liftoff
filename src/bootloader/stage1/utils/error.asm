;
; Error handlers
;
floppy_error:
    mov si, msg_read_failed 
    call puts
    jmp wait_key_and_reboot

stage_2_not_found_error:
    mov si, msg_stage_2_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0 
    int 16h                                         ; wait for key press 
    jmp 0FFFFh:0                                    ; jump to BIOS which should reboot it 

.halt:
    cli                                             ; disable interrupts 
    hlt
