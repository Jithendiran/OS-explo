; --- Data ---
KERNEL_SECTORS          equ 1     ; our kernel code is not more than 512 bytes, but minimum size to read is 512 bytes, 1 sector is 512 bytes
KERNEL_LBA              equ 2     ; Starting sector on disk (after boot sector)


; stack grow down, so give higher order address 
; --- Segment Definitions ---
KERNEL_CODE_SEGMENT  equ 0x0060 ; Kernel is loaded at 0x0060:0000 : 00600
KERNEL_CODE_OFFSET   equ 0x0000 ;
KERNEL_STACK_SEGMENT equ 0x54FF ; SS:SP base for 0x54FFD (0x54FF:0x000D)
KERNEL_STACK_POINTER equ 0x000D ;

USER_CODE_SEGMENT    equ 0x54FF ; User code at 0x54FF:0x000E (0x54FFE)
USER_CODE_OFFSET     equ 0x000E ;
USER_STACK_SEGMENT   equ 0x6DFF ; SS:SP base for 0x9FFFF (0x6DFF:0x000F)
USER_STACK_POINTER   equ 0x000F ;