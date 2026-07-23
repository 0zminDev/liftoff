msg_loading:                    db 'Loading...', ENDL, 0
msg_read_failed:                db 'Disk read failed.', ENDL, 0
msg_stage_2_not_found:           db 'No stage2', ENDL, 0

file_stage_2_bin:                db 'STAGE2  BIN'
stage_2_cluster:                 dw 0
root_directory_end:             dw 0

STAGE_2_LOAD_SEGMENT:            equ 0x2000
STAGE_2_LOAD_OFFSET:             equ 0

