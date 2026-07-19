msg_loading:                    db 'Loading...', ENDL, 0
msg_read_failed:                db 'Disk read failed.', ENDL, 0
msg_kernel_not_found:           db 'No kernel', ENDL, 0

file_kernel_bin:                db 'KERNEL  BIN'
kernel_cluster:                  dw 0
root_directory_end:             dw 0

KERNEL_LOAD_SEGMENT:            equ 0x2000
KERNEL_LOAD_OFFSET:             equ 0

