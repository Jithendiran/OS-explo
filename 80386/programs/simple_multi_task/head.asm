[bits 32]
[org 0x0000]

SCRN_SEL equ 0x18
LDT0_SEL equ 0x28   
TSS0_SEL equ 0x20  

LDT1_SEL equ 0x38
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

    ;---------------------------
    ; system interrupt

    lea ebx,system_interrupt             ;32bit address

    mov eax, 0x00080000             
    mov edx, ebx                        ;holds full address   

    mov ax, bx                          ; 0008xxxx 
                                        ; DPL = 11 and Type = Trap
    mov dx, 0xEF00                      ; xxxxEF00

    lea esi, [idt + 0x20*8]             ; 32th entry, each eight byte size 
    mov [esi], eax
    mov [esi+4], edx

    sti                                 ; only work if sti placed before pushing EFLAGS; check comment at 80

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
    push 0x17           ;   SS          ;; 0001_0111 -> Index = 0001_0(2) T=1 DPL=11
    push init_stack     ;   ESP
    pushf               ;   EFLAGS
                        ;       Index LDT   RLP
    push 0x0f           ;   CS  00001 1     11
    push task0          ;   EIP
    
    iret

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


    ; check current task
    mov eax, 1
    cmp [current], eax

    je  .switch_0           ; if eax == 1, jmp to switch_0

.switch_1:

    mov [current], eax      ; current task is 0, switch to 1

    mov eax, 'X'
    call write_char
    ;jmp $

    jmp  TSS1_SEL:0x00       ; CPU ignore this offset 0x00, take value from TSS1

    jmp .end                ; When return to Task 0, jump to cleanup

.switch_0:
    mov dword [current], 0        ; switch to 0

    mov eax, 'y'
    call write_char
    ;jmp $

    jmp  TSS0_SEL:0x00       ; CPU ignore this offset 0x00, take value from TSS0

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
    dq 0x0000000000000000                   ;0
    dq 0x00c0_9a00_0000_07ff                ;1; Kernel code segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_9200_0000_07ff                ;2; kernel stack segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_920b_8000_0002                ;3; Display buffer, ( 000b8000 - 0x000BAFFF) 12 KiB

    ; task0
    dw 0x68, tss0, 0xe900, 0x00             ;4; DLP = 11, TSS, limit is 0x68 == 104bytes
    dw 0x40, ldt0, 0xe200, 0x0              ;5; DLP = 11, LDT, limit is 0x40 == 64bytes  
    ; task1
    dw 0x68, tss1, 0xe900, 0x00             ;6; DLP = 11, TSS, limit is 0x68 == 104bytes
    dw 0x40, ldt1, 0xe200, 0x0              ;7; DLP = 11, LDT, limit is 0x40 == 64bytes

end_gdt:
nop

;============================================================================================

scr_loc:
    dd 0
nop

current:    
    dd 0
nop

;============================================================================================

times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space

init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg

nop
;============================================================================================

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

nop

;============================================================================================
task0:
    
    mov ax, 0x17       ; Load User Data Segment
    mov ds, ax
    mov al, 65         ; Starting char 'A'
    
.repeat_alpha:
    int 0x20           ; 20(hex) == 32 (dec)     
    
    mov ecx, 0xffff    ; Delay
.lp_0:
    loop .lp_0
    jmp .repeat_alpha

nop

;================================================================================
nop
times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
krn_stk0:
    dd krn_stk0     ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg

;=====================================================================================================
nop
ldt1: 
    dq 0x0000000000000000
    dq 0x00c0fa00000003ff        ; base = 00 ; g=1 x=1 0 avl=0   limit=0| p = 1 DLP=11 s=1 type code=1 conf=0 e/r= 1 a=0          base=00     |  base = 0000 limit = 03ff
    dq 0x00c0f200000003ff        ; stack segment

nop
; ---------------------------- task 1
tss1:
    dd 0                                                ; back link
    dd krn_stk1, 0x10                                   ; esp0, ss0
    dd 0, 0, 0, 0, 0                                    ; esp1, ss1, esp2, ss2, cr3
    dd task1, 0x200                                     ; eip, eflags
    dd 0, 0, 0, 0                                       ; eax, ecx, edx, ebx
    dd usr_stk1, 0, 0, 0                                ; esp, ebp, esi, edi
    dd 0x17, 0x0f, 0x17, 0x17, 0x17, 0x17               ; es, cs, ss, ds, fs, gs
    dd LDT1_SEL, 0x8000000                              ; ldt, trace bitmap

nop

;=======================================================================================================
task1:
    
    mov ax, 0x17       ; Load User Data Segment
    mov ds, ax
    mov al, 'B'         ; Starting char 'B'
    
.repeat_alpha:
    int 0x20           ; 20(hex) == 32 (dec)     
    
    mov ecx, 0xffff    ; Delay
.lp_0:
    loop .lp_0
    jmp .repeat_alpha

nop

;=============================================================================================================

times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
krn_stk1:

nop

times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
usr_stk1:

nop