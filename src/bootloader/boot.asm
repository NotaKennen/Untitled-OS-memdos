bits 16
%include "src/constants.asm"
org mbr_address

start:
    jmp main

main:
    ; data segments
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; stack
    mov ss, ax
    mov sp, stack_address

    ; ensure proper display mode
    mov al, 3
    int 10h

    ; print loading message
    mov si, msg_loading
    call print

    call load_ssb

;
; Loads the SSB into RAM and jumps to it
; No parameters
;
load_ssb:
    mov ah, 02h                 ; Function: Read Sectors
    mov al, ssb_sector_length   ; Number of sectors to read (adjust as needed)
    mov ch, 0                   ; Cylinder number (0 for first track)
    mov cl, ssb_sector_start    ; Sector number (starting from 2, as 1 is the MBR)
    mov dh, 0                   ; Head number (0 = first head)
    mov dl, 0                   ; Drive number (0 = floppy A)

    mov bx, ssb_address / 16    ; Load the second stage at address in memory
    mov es, bx                  ; Set ES to point to segment
    xor bx, bx
    int 13h                     ; BIOS interrupt
    jc .read_error              ; If Carry Flag is set, handle the error

    jmp ssb_address/16 :0000


.read_error:
    ; in case the ss_boot gave an error, inform the user and die
    mov si, msg_error
    call print
    cli
    jmp $

;
; Prints a string
; Parameters:
;   - SI: printable string
;
print:
    push bx
    push ax
    push si
    jmp .loop
.loop:
    lodsb
    or al, al
    jz .done

    mov bh, 0
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    pop si
    pop ax
    pop bx
    ret ; Go back
    
;
; System messages
;
msg_loading: db "Loading second stage bootloader... ", 0
msg_error: db "couldn't load second stage bootloader!", ENDL, 0

times 510-($-$$) db 0
dw 0AA55h