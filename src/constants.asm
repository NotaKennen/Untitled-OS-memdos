%ifndef constants
%define constants

; 
; RAM ADDRESSES
;
%define mbr_address 0x7C00
%define ssb_address 0x8000
%define kernel_address 0x0000 ; //TODO: invent some space for the kernel
%define stack_address 0x7C00

;
; DISK LOCATIONS AND LENGTHS
;
%define ssb_sector_length 1
%define kernel_sector_length 1

%define ssb_sector_start 2
%define kernel_sector_start 3

;
; MISC
;
%define ENDL 0x0D, 0x0A 

%endif