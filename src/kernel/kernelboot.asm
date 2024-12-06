bits 32
%include "src/constants.asm"
extern kernel_main

section .text
_start:
    jmp main

main:
   call kernel_main

   jmp $ ; The kernel finished running ???
         ; If we get here, something broke hard

;
; System messages
; 
section .data
binary_tag: db "THIS_IS_THE_KERNEL"