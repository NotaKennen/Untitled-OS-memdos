%define ENDL 0x0D, 0x0A  
%define self_location 0x9200
extern kernel_main
[bits 32]

section .text
global _start
_start:
    jmp $
    ; set the cool regs
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    jmp main

main:  
    ; re-setup stack for protected mode
    ;mov ss, ax
    ;mov sp, 0x7C00

    ; send the response message
    ;mov si, msg_ok
    ;call print

    ; Check for protected mode
    mov eax, cr0  ; read CR0 register
    test eax, 1   ; check if PE bit is set
    jz not_protected_mode  ; jump if not in protected mode

    ; Enter C
    ;call kernel_main

    ; nothing to do so just stay still
    call halt

;
; Prints a message to the bios console (REAL MODE)
; Parameters:
;   - SI: String address (pointer?) ((just put the string or something))
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
; Halts the computer
; No parameters
;
halt:
    cli
    hlt 
    jmp $

; 
; Run this if the kernel is not running in protected mode
; No parameters
;
not_protected_mode:
    mov si, msg_no_protect
    call print
    call halt
    
msg_ok:             db 'OK', ENDL, 0
msg_no_protect:     db 'Kernel is not running in protected mode!', ENDL, 0