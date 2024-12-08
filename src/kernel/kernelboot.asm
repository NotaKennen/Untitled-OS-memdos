bits 32
extern kernel_main

section .text
_start:
    jmp main

main:
   call kernel_main