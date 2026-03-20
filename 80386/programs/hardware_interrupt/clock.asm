[bits 32]
[org 0x0000]

SCRN_SEL equ 0x18

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
    
    ;-----------------------------------Modify IDT    
    ; timer interrupt gate in IDT as item 8
    lea ebx,timer_interrupt             ;32bit address

    mov eax, 0x00080000             
    mov edx, ebx                        ;holds full address   

    mov ax, bx                          ; 0008xxxx 
    mov dx, 0x8E00                      ; xxxx8E00

    lea esi, [idt + 0x08*8]             ; 8th entry, each eight byte size 
    mov [esi], eax
    mov [esi+4], edx
    
    sti

    jmp $

nop

;======================================================================================

setup_idt:
    lea edx, ignore_int 
    mov eax, 0x00080000 
    mov ax, dx          
    mov dx, 0x8E00      
    lea edi, idt        
    mov ecx, 35         
rp_idt:
    mov [edi], eax      
    mov [edi+4], edx    
    add edi, 8          
    dec ecx             
    jne near rp_idt     
    lidt [lidt_opcode]
    ret

nop

ignore_int:
    push ds
    push eax

    mov eax, 0x10       ; Kernel Data Segment
    mov ds, ax

    mov eax, 'I'        ; pass `I` as parameter
    call write_char

    pop eax
    pop ds
    iret

nop

; This is the timer interrupt handler. The main function is to perform task switching operations.
align 4
timer_interrupt:

    push ds
    push eax

    mov eax, 0x10       ; Kernel Data Segment
    mov ds, ax

    mov eax, 'T'        
    call write_char

     ; --- Important --- ; without this clock interrupt won't happen
    mov al, 0x20        ; EOI command
    out 0x20, al        ; Send to Master PIC
    ; ---------------------

    pop eax
    pop ds
    iret

.end:
    pop eax
    pop ds
    iret

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

;============================================================================================

lidt_opcode:
    dw (idt_end - idt)-1    
    dd  idt             

nop

lgdt_opcode:
    dw (end_gdt-gdt)-1   
    dd gdt             

nop


; empty IDT
idt:        
    times 35 dq 0
idt_end:

nop

gdt:
    dq 0x0000000000000000
    dq 0x00c0_9a00_0000_07ff                ; Kernel code segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_9200_0000_07ff                ; kernel stack segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_920b_8000_0002                ; Display buffer, ( 000b8000 - 0x000BAFFF) 12 KiB
end_gdt:
nop

;============================================================================================

scr_loc:
    dd 0
nop

;============================================================================================

times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space

init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg

nop
;============================================================================================