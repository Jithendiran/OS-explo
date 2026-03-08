[org 0x7c00]          ; BIOS loads us here
org_start:
; org is used for lable address calculation only, it won't create empty or 0's till address 0x7c00, org_start address is 0x7c00 and this 0x7c00 is stored in object file, not address 0, but in file or storage memory (ssd, hdd) it lseek is start from 0

; 1. Load the GDT
cli                   ; Disable interrupts before touching system tables
lgdt [gdt_descriptor] ; Load the GDT pointer into the GDTR register

; 2. Switch to Protected Mode
mov eax, cr0
or eax, 0x1           ; Set bit 0 (PE - Protection Enable)
mov cr0, eax

; 3. Far Jump to flush the pipeline
; This is mandatory to transition from 16-bit to 32-bit instructions
jmp CODE_SEG:init_pm
;CODE_SEG base address is `0x00000000` and it's offset init_pm is based on wha assembler gives
; even in protected mode all the codes from line [org 0x7c00]  till end present, so we are using the label `init_pm` with new code segment

; -------------------------------------------------------------------------
; THE GDT DATA STRUCTURE
; -------------------------------------------------------------------------
gdt_start:
    ; Entry 0: The Null Descriptor (Mandatory 8 bytes of zeros)
    dd 0x0 
    dd 0x0

gdt_code:
    ; Entry 1: Code Segment Descriptor
    ; Base=0x0, Limit=0xfffff, Flags=Present, Ring 0, Executable, G=4kb
    dw 0xffff       ; Limit (bits 0-15)
    dw 0x0000       ; Base (bits 0-15)
    db 0x00         ; Base (bits 16-23)
    db 10011010b    ; Access byte (Present, Ring 0, Code, Readable)
    db 11001111b    ; Flags (4kb Granularity, 32-bit) + Limit (bits 16-19)
    db 0x00         ; Base (bits 24-31)

gdt_data:
    ; Entry 2: Data Segment Descriptor
    ; Same as code, but the Access byte says "Data" instead of "Code"
    dw 0xffff       
    dw 0x0000       
    db 0x00         
    db 10010010b    ; Access byte (Present, Ring 0, Data, Writable)
    db 11001111b    
    db 0x00         
gdt_end:

; The GDT Descriptor (The "Pointer" for the lgdt instruction)
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size (16-bit)
    dd gdt_start               ; Address (32-bit)

; Constants to help us reference the segments later
CODE_SEG equ gdt_code - gdt_start ; Should be 0x08
DATA_SEG equ gdt_data - gdt_start ; Should bit 0x10

; -------------------------------------------------------------------------

[bits 32]
init_pm:
    ; Now we are in 32-bit mode!
    ; We must update our segment registers to point to the Data Segment
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    
    ; Print a blue 'OK' to the top left of the screen to prove it works
    mov word [0xb8002], 0x1f4b ; 'K' with blue background
    mov word [0xb8000], 0x1f4f ; 'O' with blue background

    hlt ; Halt the CPU

times 510-($-$$) db 0
dw 0xaa55