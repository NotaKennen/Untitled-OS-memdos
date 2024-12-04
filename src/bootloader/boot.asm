org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A  

; ssb - second stage bootloader
%define ssb_address 0x7E00  ; where ssb should be stored in memory
%define ssb_size 1          ; how large is the ssb (in sectors)
%define ssb_start 2         ; what sector ssb starts in

jmp short start 
nop

;
; FAT12 Headers
;
bdb_oem:                    db 'MSWIN4.1'         ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880               ; 2880 * 512 = 1.44mb
bdb_media_descriptor_type:  db 0F0h               ; 0F0h = 3.5 inch floppy disk
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                  ; 0x00 floppy, 0x80 hdd, useless
                            db 0                  ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 00h, 00h, 00h, 00h ; Serial number, can be anything
ebr_volume_label:           db 'VOLUMELABEL'      ; 11 bytes
ebr_system_id:              db 'FAT12   '         ; 8 bytes

;
; Functions
;

;
; Prints something to the bios screen
; Parameters:
;   - si: printable string
print:
    ; push any necessary registers and move to main loop
    push si
    push ax
    push bx
    jmp .loop


.loop:
    lodsb               ; loads next character in al
    or al, al           ; verify if next character is null
    jz .done            ; If the character is null, jump to .done

    mov bh, 0           ; page number to 0
    mov ah, 0x0e        ; function number = 0Eh : Display Character
    int 0x10            ; call INT 10h, BIOS video service
    jmp .loop           ; redo the loop

.done:
    ; pop everything necessary and return
    pop bx
    pop ax
    pop si
    ret

ss_boot:
    ; Load the second stage from the floppy disk using INT 13h-02h
    mov ah, 02h             ; Function: Read Sectors
    mov al, ssb_size        ; Number of sectors to read (adjust as needed)
    mov ch, 0               ; Cylinder number (0 for first track)
    mov cl, ssb_start       ; Sector number (starting from 2, as 1 is the MBR)
    mov dh, 0               ; Head number (0 = first head)
    mov dl, 0               ; Drive number (0 = floppy A)
    mov bx, ssb_address     ; Load the second stage at 0x7E00 in memory
    mov es, bx              ; Set ES to point to 0x7E00 segment
    int 13h                 ; BIOS interrupt
    jc .read_error          ; If Carry Flag is set, handle the error

    ; Jump to the second stage at 0x8000:0000
    jmp ssb_address:0000

.read_error:
    ; in case the ss_boot gave an error, inform the user and die
    mov si, msg_no_ss_error
    call print

    ; kys
    cli
    jmp $

;
; Main execution
;
start:
    jmp main

main:
    ; setup data segments
    mov ax, 0            ; can't write to es/ds directly
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7C00       ; stack grows downwards from where we are loaded in memory

    ; ensure proper display mode
    mov al, 3
    int 10h

    ; print boot message
    mov si, msg_boot
    call print

    ; load the ss bootloader to memory
    call ss_boot

;
; Messages
;
msg_boot:           db '[I] Loading second stage bootloader... ', 0
msg_no_ss_error:    db 'Could not load second stage bootloader!', ENDL, 0



times 510-($-$$) db 0
dw 0AA55h