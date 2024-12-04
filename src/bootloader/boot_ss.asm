org 0x7E00:0000
%define ENDL 0x0D, 0x0A  
[bits 16]

%define kernel_address      0x9200      ; kernel address, default 0x9200
%define kernel_size         1           ; kernel size in sectors, default 10
%define kernel_start_pos    3           ; what sector kernel starts in, default 3

start:
    mov ax, 0x7E00
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0
    mov ss, ax
    mov sp, 0x7CFF
    jmp main

;
; Prints something to the bios screen
; Parameters:
;   - si: printable string
;
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

; 
; Load the kernel
; No parameters
;
load_kernel:
    mov si, msg_load_kernel
    call print
    
    ; Load the second stage from the floppy disk using INT 13h-02h
    mov ah, 02h              ; Function: Read Sectors
    mov al, kernel_size      ; Number of sectors to read (adjust as needed)
    mov ch, 0                ; Cylinder number (0 for first track)
    mov cl, kernel_start_pos ; Sector number (1: MBR, 2: SS Boot, 3, Kernel)
    mov dh, 0                ; Head number (0 = first head)
    mov dl, 0                ; Drive number (0 = floppy A)
    mov bx, kernel_address   ; Load the kernel to this address in memory
    mov es, bx               ; Set ES to point to segment
    int 13h                  ; BIOS interrupt
    jc .load_error           ; If Carry Flag is set, handle the error

    ; OK
    mov si, msg_ok
    call print

    ; Inform the user that the move to the kernel is happening
    mov si, msg_moving
    call print

    ; Enable protected mode (ooohh scary)
    ; Also jumps directly to kernel inside the function
    call enable_pm

    ; Jump to the kernel at 0x9200:0000
    jmp kernel_address:0000 ; (enable pm jumps to it, so commented out)

.load_error:
    ; in case the kernel load gave an error, inform the user and die
    mov si, msg_load_error
    call print

    ; kys
    cli
    jmp $

;
; Enables Protected Mode
; No parameters
;
; Load the GDT
; Define the GDT in memory
ALIGN 8
gdt:
    ;null segment
    dw 0x0000                ; Null Segment (Descriptor 0)
    dw 0x0000
    db 0x00
    db 0x00
    db 0x00
    db 0x00

    ;gdt_code:
    dw 0xFFFF                ; Limit (16 bits, low part)
    dw 0x0000                ; Base Address (16 bits, low part)
    db 0x00                  ; Base Address (8 bits, middle part)
    db 0x9A                  ; Access Byte: Code Segment, Executable, Readable
    db 0xCF                  ; Flags: 4 KB Granularity, 32-bit mode
    db 0x00                  ; Base Address (8 bits, high part)

    ;gdt_data:
    dw 0xFFFF                ; Limit (16 bits, low part)
    dw 0x0000                ; Base Address (16 bits, low part)
    db 0x00                  ; Base Address (8 bits, middle part)
    db 0x92                  ; Access Byte: Data Segment, Read/Write
    db 0xCF                  ; Flags: 4 KB Granularity, 32-bit mode
    db 0x00                  ; Base Address (8 bits, high part)

    gdt_end:

    ; Create GDT descriptor
    gdt_descriptor:
        dw gdt_end - gdt - 1   ; Size of GDT (16 bits)
        dd gdt              ; Base address of GDT (32 bits)

; Load the GDT
enable_pm:
    cli                        ; Disable interrupts
    lgdt [gdt_descriptor]      ; Load GDT using LGDT

    mov eax, cr0
    or eax, 0x1                ; Set PE bit (bit 0)
    mov cr0, eax

    jmp 0x010:flush_pipeline   ; Jump to Code Segment (GDT entry 1: offset 0x08)

[bits 32]
flush_pipeline:
    jmp $
    mov ax, 0x10               ; Load Data Segment (GDT entry 2: offset 0x10)
    mov ds, ax                 ; Update Data Segment Register
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp $
    ; Continue execution in protected mode
    jmp kernel_address:0000
[bits 16]
;
; Main load function 
;
main:
    ; Print the entry message
    mov si, msg_ok
    call print

    call load_kernel

    ; Halt since we dont have anything to do
    cli
    jmp $

;
; Messages and variables
;
msg_ok:              db 'OK', ENDL, 0
msg_load_kernel:     db '[I] Loading kernel to memory... ', 0
msg_moving:          db '[I] Moving to kernel... ', 0
msg_load_error:      db 'Could not load kernel!', ENDL, 0

times 512-($-$$) db 0