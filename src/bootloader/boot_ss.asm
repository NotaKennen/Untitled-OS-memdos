bits 16
%include "src/constants.asm"
org ssb_address

start:
    jmp main

main:
    ; Print OK message
    mov si, msg_ok
    call print

    ; Load kernel
    mov si, msg_loading_kernel
    call print
    call load_kernel
    mov si, msg_ok
    call print

    ; Load GDT
    mov si, msg_loading_gdt
    call print
    call load_gdt
    mov si, msg_ok
    call print

    ; Enable PM
    mov si, msg_enabling_pm
    call print
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
; Loads and establishes the GDT
; No parameters
;
load_gdt:
    ret

;
; Enables PM, does not jump to kernel etc
; No parameters
;
enable_pm:
    ret

;
; System messages
;
msg_ok:             db 'OK', ENDL, 0
msg_loading_kernel: db 'Loading kernel... ', 0
msg_loading_gdt:    db 'Loading GDT... ', 0
msg_enabling_pm:    db 'Enabling protected mode... ', 0

times 510-($-$$) db 0
dw 0AA55h