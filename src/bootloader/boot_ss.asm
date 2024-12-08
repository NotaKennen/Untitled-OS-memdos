bits 16
%include "src/constants.asm"
org ssb_address

%define CODE_SEG 0x08
%define DATA_SEG 0x10

start: ; In case we ever need to add something to run before main
    jmp main

main:
    ; Print response to move
    mov si, msg_ok
    call print

    ; Load kernel //TODO: Enable A20 for use with non-emulators
    mov si, msg_loading_kernel
    call print
    call load_kernel
    mov si, msg_ok
    call print

    ; Disable the blinking cursor
    mov ah, 0x01    ; BIOS function to set cursor shape
    mov ch, 0x20    ; Set cursor start scanline to a value greater than end scanline
    mov cl, 0x00    ; Cursor end scanline (doesn't matter because it's hidden)
    int 0x10        ; Call BIOS interrupt


    ; Load GDT and enable PM
    mov si, msg_enabling_pm
    call print
    call InstallGDT
    call enable_pm ; response will be sent in Kernel

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
; Loads the kernel into memory, does not jump
; No parameters
;
load_kernel:
    mov ah, 02h                     ; Function: Read Sectors
    mov al, kernel_sector_length    ; Number of sectors to read (adjust as needed)
    mov ch, 0                       ; Cylinder number (0 for first track)
    mov cl, kernel_sector_start     ; Sector number (1: MBR, 2: SSB, 3: Kernel)
    mov dh, 0                       ; Head number (0 = first head)
    mov dl, 0                       ; Drive number (0 = floppy A)

    mov bx, kernel_address / 16     ; Load the second stage at address in memory
    mov es, bx                      ; Set ES to point to segment
    xor bx, bx
    int 13h                         ; BIOS interrupt
    jc .read_error                  ; If Carry Flag is set, handle the error

    ret
    
    .read_error
        mov si, msg_loading_kernel_err
        call print
        jmp $


;
; Enables PM, also jumps to kernel
; No parameters
;
enable_pm:
    ; double check that interrupts are disabled
    cli

    ; Enable PM register
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:.flush_pipeline

    bits 32
    .flush_pipeline:
        ; Set DS, ES, FS, and GS to point to the data segment descriptor
        mov ax, DATA_SEG
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        jmp 0x08:0x9000
    bits 16
;
; System messages
;
msg_ok:                     db 'OK', ENDL, 0
msg_loading_kernel:         db 'Loading kernel... ', 0
msg_loading_kernel_err:     db 'couldnt load kernel!', ENDL, 0
msg_enabling_pm:            db 'Enabling protected mode... ', 0

;*************************************************
; GDT

InstallGDT:             ; load GDT into GDTR
    cli
    lgdt [gdt_limit_and_base]
    sti
    ret

gdt_data:

    NULL_Desc:              ; null descriptor (necessary)
        dd    0
        dd    0

    CODE_Desc:
        dw    0xFFFF        ; segment length  bits 0-15 ("limit")
        dw    0             ; segment base    byte 0,1
        db    0             ; segment base    byte 2
        db    10011010b     ; access rights
        db    11001111b     ; bit 7-4: 4 flag bits:  granularity, default operation size bit,
                            ; 2 bits available for OS
                            ; bit 3-0: segment length bits 16-19
        db    0             ; segment base    byte 3

    DATA_Desc:
        dw    0xFFFF        ; segment length  bits 0-15
        dw    0             ; segment base    byte 0,1
        db    0             ; segment base    byte 2
        db    10010010b     ; access rights
        db    11001111b     ; bit 7-4: 4 flag bits:  granularity,
                            ; big bit (0=USE16-Segm., 1=USE32-Segm.), 2 bits avail.
                            ; bit 3-0: segment length bits 16-19
        db    0             ; segment base    byte 3

    CODE16_Desc:
        dw    0xFFFF
        dw    0
        db    0
        db    10011010b
        db    00001111b
        db    0

    end_of_gdt:
    gdt_limit_and_base:
    dw end_of_gdt - gdt_data - 1    ; limit (size/length of GDT)
    dd gdt_data                     ; base of GDT


times 512-($-$$) db 0