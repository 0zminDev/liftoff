jmp short init
nop

bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1 
bdb_reserved_sectors:       dw 1 
bdb_fat_count:              db 2 
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0F0h
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


