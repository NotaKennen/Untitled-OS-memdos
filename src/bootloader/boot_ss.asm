bits 16
%include "src/constants.asm"

start:
    jmp main

;
; GDT
;
gdt_data:
    ;null segment
    dd 0x0000                 ; Null Segment (Descriptor 0)
    dd 0x0000
    
    ;gdt_code:
    dw 0xFFFF                 ; Limit (16 bits, low part)
    dw 0x0000                 ; Base Address (16 bits, low part)
    db 0x00                   ; Base Address (8 bits, middle part)
    db 10011010b              ; Access Byte: Code Segment, Executable, Readable
    db 11001111b              ; Flags: 4 KB Granularity, 32-bit mode
    db 0x00                   ; Base Address (8 bits, high part)
    
    ;gdt_data:
    dw 0xFFFF                 ; Limit (16 bits, low part)
    dw 0x0000                 ; Base Address (16 bits, low part)
    db 0x00                   ; Base Address (8 bits, middle part)
    db 10010010b              ; Access Byte: Data Segment, Read/Write
    db 11001111b              ; Flags: 4 KB Granularity, 32-bit mode
    db 0x00                   ; Base Address (8 bits, high part)
    
    gdt_end:
; Create GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_data - 1  ; Size of GDT (16 bits)
    dd gdt_data                ; Base address of GDT (32 bits)

;
; Loads and establishes the GDT
; No parameters
;
load_gdt:
    cli
    pusha
    lgdt [gdt_descriptor]
    popa
    ret
;

org ssb_address

main:
    ; Print response to move
    mov si, msg_ok
    call print

    ; Load kernel //TODO: Load kernel
    mov si, msg_loading_kernel
    call print
    call load_kernel
    mov si, msg_skip
    call print

    ; Load GDT and enable PM
    mov si, msg_enabling_pm
    call print
    call load_gdt
    call enable_pm ; response will be sent in Kernel
    
    ; Move to kernel
    ;Load it first

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
    ret

;
; Enables PM, does not jump to kernel etc
; No parameters
;
enable_pm:
    ; double check that interrupts are disabled
    cli

    ; Enable PM register
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:.flush_pipeline

bits 32
.flush_pipeline:
    ; set code segment to code selector (0x08)
    mov ax, 0x08
    mov cs, ax

    ; set data segments to data selector (0x10)
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov esp, 0x9000
    jmp $

    
bits 16
;
; System messages
;
msg_ok:             db 'OK', ENDL, 0
msg_skip:           db 'SKIP', ENDL, 0
msg_loading_kernel: db 'Loading kernel... ', 0
msg_enabling_pm:    db 'Enabling protected mode... ', 0

times 512-($-$$) db 0