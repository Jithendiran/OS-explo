[bits 32]
[org 0x0000]

SCRN_SEL equ 0x18   ; 0001_1000 ==   Index = 0001_1(3) TL = 0 DPL = 00
TSS0_SEL equ 0x20   ; 0010_0000 ==   Index = 0010_0(4) TL = 0 DPL = 00
LDT0_SEL equ 0x28   ; 0010_1000 ==   Index = 0010_1(5) TL = 0 DPL = 00

head_start:
    mov eax, 0x10   ; load data segment
    mov ds, ax
    lss esp, [init_stack]

    ;-------------------------------modify IDT

    lea ebx, system_interrupt
    mov [idt], bx              ; Low 16 bits
    shr ebx, 16                ; Move high 16 bits of address to low 16 of EBX
    or [idt+6], bx             ; Store in the high offset field of the descriptor

    ;---------------------------- Setup DT's
    
    lidt [lidt_opcode]
    lgdt [lgdt_opcode]    

    ; change segment as per new GDT
    mov eax, 0x10           ; 0001_0000 Index = 0001_0(2) TL = 0 DPL = 00 ; 2nd index
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, [init_stack]
    
    ;-------------------------------Flag setup
    ; clearing NT flag
    pushf
    and dword [esp], 0xffffbfff 
    popf

    ;-------------------------------Ragister setup
    ; load task register to task   
    mov eax, TSS0_SEL
    ltr ax                   

    ; load LDT
    mov eax, LDT0_SEL
    lldt word ax

    ;------------------------------Setup 
    push 0x17           ;   SS          ; 0001_0111 -> Index = 0001_0(2) T=1 DPL=11
    push init_stack     ;   ESP
    pushf               ;   EFLAGS
    push 0x0f           ;   CS
    push task0          ;   EIP
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

system_interrupt:
    push ds                 ; Save the user's data segmen 
    pusha                   ; Save all general registers

    ; Load Kernel Data Segment
    mov edx, 0x10
    mov ds, dx

    call write_char         ; write_char uses the char in AL

    popa                    ; Restore general registers
    pop ds                  ; Restore the user's data segment
    iret                    ; Return from interrupt

nop

scr_loc:
    dd 0
nop

lgdt_opcode:
    dw (end_gdt-gdt)-1  ; limit (3f00)
    dd gdt              ; base address (000398)

nop

gdt:
    dq 0x0000000000000000                  
    dq 0x00c0_9a00_0000_07ff                  
    dq 0x00c0_9200_0000_07ff               
    dq 0x00c0_92_0b_8000_0002               
    dw 0x68, tss0, 0xe9_00, 0x00            
    dw 0x40, ldt0, 0xe200, 0x0              
end_gdt:

nop

lidt_opcode:
    dw (idt_end-idt)-1      ; limit 
    dd  idt                 ; base address 

nop

; only defining interrupt 0, it is trap gate, used to transfer call to ring 0
idt:    
    ; This is gate DPL who can access
    ;   offset         P D  TYP   Not used  
    ;0000000000000000__1_11_01111_00000000
    ;  Ring0 code segment, This is to whom control transfer DPL
    ;          S=1, T=0 D=00  offset
    ;000000000_0001_0__00_____00000000_00000000
    ; 1 (index) * 8 (length) = 8 (th offset in GDT), this CPU do automatically
    dq 0x0000_EF00_0008_0000
    ; offset of the function `system_interrupt` has to be upated dynamically or by reading ndisasm hardcode the value
    ; modifying in run time is more robust
idt_end:
nop

;-------------------------------------------------------------------------------
times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg
;------------------------------------------------------------------------------
nop

align 8
ldt0: 
    dq 0x0000000000000000

    dq 0x00c0fa00000003ff        ; base = 00 ; g=1 x=1 0 avl=0 limit=0| p = 1 DLP=11 s=1 type code=1 conf=0 e/r= 1 a=0          base=00 |  base = 0000 limit = 03ff  => 03ff=1023 * 4096 = 4190208 == 3FF000 + FFF = 3FFFFF; 00000000-003FFFFF
    dq 0x00c0f200000003ff        ; stack segment
; Since it's base address also 00, it is using the same code 
nop

; tss0 content are 0 because segment , general register will taken from IRET
tss0:
    dd 0                    ; back link
    dd krn_stk0, 0x10       ; esp0, ss0
    dd 0, 0, 0, 0, 0        ; esp1, ss1, esp2, ss2, cr3     
    dd 0, 0, 0, 0, 0        ; eip, eflags, eax, ecx, edx
    dd 0, 0, 0, 0, 0        ; ebx esp, ebp, esi, edi
    dd 0, 0, 0, 0, 0, 0     ; es, cs, ss, ds, fs, gs
    dd LDT0_SEL, 0x8000000  ; ldt, trace bitmap 
    ; 0x8000000 is split into the 16-bit T-bit (Trap bit) and the 16-bit I/O Map Base Address.
    ; Low 16 bits (0x0000): The T-bit (Debug Trap Flag). If this bit is set to 1, the processor generates a debug exception whenever a task switch to this task occurs.
    ; High 16 bits (0x0800): The I/O Map Base Address. This is the offset from the start of the TSS to the I/O Permission Bit Map.
    ; The value 0x0800 (which is 2048 in decimal) is a very common "dummy" or "null" value, Points way past the end of the TSS; effectively disables I/O port access for this task.

nop

task0:
    mov ax, 0x17       ; Load User Data Segment
    mov ds, ax
    mov al, 65         ; Starting char 'A'
    
.repeat_alpha:
    int 0x00            ; Transfer call to ring 00
    
    mov ecx, 0xffff    ; Delay
.lp_0:
    loop .lp_0
    
    inc al             ; Increment char ('A' -> 'B', etc.)
    cmp al, 91         ; After 'Z' (90), reset to 'A'
    jne .repeat_alpha
    mov al, 65
    jmp .repeat_alpha

nop
times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
krn_stk0:
    dd krn_stk0     ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg