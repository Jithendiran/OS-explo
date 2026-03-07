[bits 32]
[org 0x0000]

LATCH    equ 11930
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
    call setup_gdt
    
    mov eax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, [init_stack]

;--------------------------------------------timer
    mov al, 0x36
    mov edx, 0x43
    out dx, al
    mov eax, LATCH
    mov edx, 0x40
    out dx, al
    mov al, ah
    out dx, al
; interrupt date in IDT as item 8
    mov eax, 0x00080000
    mov ax, timer_interrupt
    mov dx, 0x8E00
    mov ecx, 0x08
    lea esi, [idt + ecx*8]
    mov [esi], eax
    mov [esi+4], edx
; Set the system call trap gate descriptor at item 128 (0x80) of the IDT table
    mov ax, system_interrupt
    mov dx, 0xef00
    mov ecx, 0x08
    lea esi, [idt + ecx*8]
    mov [esi], eax
    mov [esi+4], edx
;------------
    pushf
    and dword [esp], 0xffffbfff
    popf
    mov eax, TSS0_SEL
    ltr ax
    mov eax, LDT0_SEL
    lldt word ax
    mov dword [current], 0
    sti

    push 0x17
    push init_stack
    pushf
    push 0x0f
    push task0
    iret
;--------------------------------------------------------------------

setup_gdt:
    lgdt [lgdt_opcode]
    ret

setup_idt:
    lea edx, ignore_int ; edx holds the full 32-bit address of ignore_int eg: 0x12345678
    mov eax, 0x00080000 ; eax has 0x00080000, top bits are selector
    mov ax, dx          ; take the bottom 16 bits of the handler address (0x5678) and put them in the bottom of eax. eax = 0x00085678
    mov dx, 0x8E00      ; Interrupt gate type is 14, plevel is 0. edx = 0x12348E00
    lea edi, idt        ; edi holds the IDT starting address
    mov ecx, 256        ; ecx holds the count 
rp_idt:
    mov [edi], eax      ; eax = 0x00085678, base = 0008, limit = 0x5678
    mov [edi+4], edx    ; edx = 0x12348E00  move 4 bytes, write limit = 0x1234 and perm, flags = 8E00
    add edi, 8          ; move to next IDT entry
    dec ecx             ; reduce counter
    jne near rp_idt          ; if exc is non zero, repeate
    lidt [lidt_opcode]
    ret


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

    

; The following are 3 interrupt handlers: default, timer, and system call interrupt.

; Ignore_int is default handler. If system generates other interrupts, it display char 'C'.
align 4
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

; This is the timer interrupt handler. The main function is to perform task switching operations.
align 4
timer_interrupt:

    push ds
    push eax

    ; switch kernel data segment
    mov eax, 0x10           
    mov ds, ax

    ; Then send EOI to 8259A to allow other interrupts.
    mov al, 0x20
    out 0x20, al

    ; check current task
    mov eax, 1
    cmp [current], eax

    je  .switch_0           ; if eax == 1, jmp to switch_0

.switch_1:
    mov [current], eax      ; current task is 0, switch to 1
    jmp  TSS1_SEL:0x00       ; CPU ignore this offset 0x00, take value from TSS1

    jmp .end                ; When return to Task 0, jump to cleanup

.switch_0:
    mov dword [current], 0        ; switch to 0
    jmp  TSS0_SEL:0x00       ; CPU ignore this offset 0x00, take value from TSS0

.end:
    pop eax
    pop ds
    iret

; The system call int 0x80 handler. This example has only one display char function.
align 4
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


;/********************************************************************************/
current:    ; 00000181 - 00000184
    dd 0
scr_loc:    ; 00000185 - 00000187
    dd 0


; empty IDT
align 4
lidt_opcode:
    dw (256*8)-1    ; limit (07FF)
    dd  idt         ; base address (000198)
lgdt_opcode:
    dw (end_gdt-gdt)-1  ; limit (3f00)
    dd gdt              ; base address (000398)

align 8
idt:        ; 00000198
    times 256 dq 0

;------------------------------------
gdt:
    dq 0x0000000000000000
    dq 0x00c0_9a00_0000_07ff                ; Kernel code segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_9200_0000_07ff                ; kernel stack segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_920b_8000_0002                ; Display buffer, ( 000b8000 - 0x000BAFFF) 12 KiB
    dw 0x68, tss0, 0xe900, 0x00             ; DLP = 11, TSS, limit is 0x68 == 104bytes
    dw 0x40, ldt0, 0xe200, 0x0              ; DLP = 11, LDT, limit is 0x40 == 64bytes  
    dw 0x68, tss1, 0xe900, 0x00             ; DLP = 11, TSS, limit is 0x68 == 104bytes
    dw 0x40, ldt1, 0xe200, 0x0              ; DLP = 11, LDT, limit is 0x40 == 64bytes 
end_gdt:                                        

nop
;-----------------------------------------------------------------------------------
times 128 dd 0          ; 128 * 4 = 512 ; 512 bytes stack space

init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg


;============================================================== Task 0 LDT and TSS

align 8
ldt0: 
    dq 0x0000000000000000
    dq 0x00c0fa00000003ff        ; base = 00 ; g=1 x=1 0 avl=0   limit=0| p = 1 DLP=11 s=1 type code=1 conf=0 e/r= 1 a=0          base=00     |  base = 0000 limit = 03ff
    dq 0x00c0f200000003ff        ; stack segment

tss0:
    dd 0                    ; back link
    dd krn_stk0, 0x10       ; esp0, ss0
    dd 0, 0, 0, 0, 0        ; esp1, ss1, esp2, ss2, cr3
    dd 0, 0, 0, 0, 0        ; eip, eflags, eax, ecx, edx
    dd 0, 0, 0, 0, 0        ; ebx esp, ebp, esi, edi
    dd 0, 0, 0, 0, 0, 0     ; es, cs, ss, ds, fs, gs
    dd LDT0_SEL, 0x8000000  ; ldt, trace bitmap 


;Kernel 0 stack
times 128 dd 0          ; 128 * 4 = 512 ; 512 bytes stack space
krn_stk0:

;==============================================================Task 1 LDT and TSS
align 8
ldt1: 
    dq 0x0000000000000000
    dq 0x00c0fa00000003ff        ; base = 00 ; g=1 x=1 0 avl=0   limit=0| p = 1 DLP=11 s=1 type code=1 conf=0 e/r= 1 a=0          base=00     |  base = 0000 limit = 03ff
    dq 0x00c0f200000003ff        ; stack segment


; ---------------------------- task 1
tss1:
    dd 0                                                ; back link
    dd krn_stk1, 0x10                                   ; esp0, ss0
    dd 0, 0, 0, 0, 0                                    ; esp1, ss1, esp2, ss2, cr3
    dd task1, 0x200                                     ; eip, eflags
    dd 0, 0, 0                                          ; eax, ecx, edx
    dd 0, usr_stk1, 0, 0, 0                             ; ebx esp, ebp, esi, edi
    dd 0x17, 0x17, 0x17, 0x17, 0x17, 0x17               ; es, cs, ss, ds, fs, gs
    dd LDT1_SEL, 0x8000000                              ; ldt, trace bitmap


;---------------------------------------------------------------------Kernel 0 stack
times 128 dd 0          ; 128 * 4 = 512 ; 512 bytes stack space
krn_stk1:

;=========================================================== Programs tasks
task0:
    mov eax, 0x17
    mov ds, ax
    mov al, 65
    int 0x80
    mov ecx, 0xfff
.lp_0:
    loop .lp_0
    jmp task0   
;---------------------task1
task1:
    mov al, 66
    int 0x80
    mov ecx, 0xfff
.lp_1:
    loop .lp_1
    jmp task1 

;------------------------------- user stack
times 128 dd 0          ; 128 * 4 = 512 ; 512 bytes stack space
usr_stk1:
