[bits 32]
[org 0x0000]

SCRN_SEL equ 0x18
LDT0_SEL equ 0x28
LDT1_SEL equ 0x38
TSS0_SEL equ 0x20
TSS1_SEL equ 0x30


head_start:
    mov eax, 0x10   ; load data segment
    mov ds, ax
    lss esp, [init_stack]
    
    call setup_idt

    lgdt [lgdt_opcode]
    
    mov eax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, [init_stack]
    sti
    hlt

;=====================================================================================
nop

setup_idt:
    lea edx, ignore_int ; edx holds the full 32-bit address of ignore_int eg: 0x12345678
    mov eax, 0x00080000 ; eax has 0x00080000, top bits are selector
    mov ax, dx          ; take the bottom 16 bits of the handler address (0x5678) and put them in the bottom of eax. eax = 0x00085678
    mov dx, 0x8E00      ; Interrupt gate , plevel is 0. edx = 0x12348E00
    lea edi, idt        ; edi holds the IDT starting address
    mov ecx, 256        ; ecx holds the count 
rp_idt:
    mov [edi], eax      ; eax = 0x00085678, base = 0008, limit = 0x5678
    mov [edi+4], edx    ; edx = 0x12348E00  move 4 bytes, write limit = 0x1234 and perm, flags = 8E00
    add edi, 8          ; move to next IDT entry
    dec ecx             ; reduce counter
    jne near rp_idt     ; if exc is non zero, repeate
    lidt [lidt_opcode]
    ret

nop

write_char:

    push gs
    push eax
    push ebx
    
    ; Setup Segment
    mov  bx, SCRN_SEL       ; Load selector into 16-bit bx
    mov  gs, bx             ; Move to GS (segment registers need 16-bit source)
    
    ; Get current position
    mov  ebx, [scr_loc]     
    
    ; Display Logic
    shl  ebx, 1             ; Multiply by 2 (2 bytes per char)
    mov  [gs:ebx], al       ; Writes char to screen.
    shr  ebx, 1             ; Divide by 2 to return to logical index
    
    ; Increment and Wrap-around
    inc  ebx                ; Move to next slot
    cmp  ebx, 2000          ; Check if we are past the 80x25 limit
    jb   .save              ; If Below 2000, keep the value
    mov  ebx, 0             ; If 2000 or more, reset to top-left
    
.save:
    mov  [scr_loc], ebx     ; Store updated index back to memory
    pop  ebx
    pop  eax
    pop  gs
    ret

    
nop

; The following are 3 interrupt handlers: default, timer, and system call interrupt.

; Ignore_int is default handler. If system generates other interrupts, it display char 'C'.

ignore_int:
    push ds
    push eax

    mov eax, 0x10       ; Kernel Data Segment
    mov ds, ax

    mov eax, 67         ; pass `C` as parameter
    call write_char

    pop eax
    pop ds
    iret

;===================================================================================
nop

times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space

init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg


;===================================================================================


nop

lidt_opcode:
    dw (256*8)-1    ; 
    dd  idt         ; 

nop

lgdt_opcode:
    dw (end_gdt-gdt)-1  ; 
    dd gdt              ;

nop

; empty IDT
idt:        
    times 256 dq 0
idt_end:

nop

gdt:
    dq 0x0000000000000000
    dq 0x00c0_9a00_0000_07ff                ; Kernel code segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_9200_0000_07ff                ; kernel stack segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_920b_8000_0002                ; Display buffer, ( 000b8000 - 0x000BAFFF) 12 KiB
end_gdt:
nop
;===================================================================================

scr_loc:
    dd 0
nop