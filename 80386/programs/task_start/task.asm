[bits 32]
[org 0x0000]

SCRN_SEL equ 0x18   ; 0001_1000 ==   Index = 0001_1(3) TL = 0 DPL = 00
LDT0_SEL equ 0x28   ; 0010_0000 ==   Index = 0010_0(4) TL = 0 DPL = 00
TSS0_SEL equ 0x20   ; 0010_1000 ==   Index = 0010_1(5) TL = 0 DPL = 00

head_start:
    mov eax, 0x10   ; load data segment
    mov ds, ax
    lgdt [lgdt_opcode]    

    ; change segment as per new GDT
    mov eax, 0x10                   ; 0001_0000 Index = 0001_0(2) TL = 0 DPL = 00 ; 2nd index
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
    push 0x17           ;   SS          ;; 0001_0111 -> Index = 0001_0(2) T=1 DPL=11
    push init_stack     ;   ESP
    pushf               ;   EFLAGS
                        ;       Index LDT   RLP
    push 0x0f           ;   CS  00001 1     11
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

scr_loc:
    dd 0
nop

lgdt_opcode:
    dw (end_gdt-gdt)-1  ; limit 
    dd gdt              ; base address 

nop

gdt:
    dq 0x0000000000000000                   ; 0 ;

    dq 0x00c0_9a00_0000_07ff                ; 8 ;   Kernel code segment, (00000000-007FFFFF) 8MiB
    dq 0x00c0_9200_0000_07ff                ; 10;   kernel stack segment, (00000000-007FFFFF) 8MiB

    dq 0x00c0_f2_0b_8000_0002               ; 18;   Display buffer, ( 000b8000 - 0x000BAFFF) 12 KiB, DLP=11

    ; little endian 
    ; TSS                                   ;  20
    ;  0-7   8-15  16-24    25-31           ; bit position
    ;              00 e9                    ; how it arranged                                    
    dw 0x68, tss0, 0xe9_00, 0x00            ; Limit = 104bytes      e9 = p=1 |DPL=11 |S=0 |Type=1001  TSS available

    ; LDT
    dw 0x40, ldt0, 0xe200, 0x0              ; 28;   DLP = 11, LDT, limit is 0x40 == 64bytes  
end_gdt:

nop

;-------------------------------------------------------------------------------
times 128 dq 0          ; 128 * 4 = 512 ; 512 bytes stack space
init_stack:
    dd init_stack   ; Stack segment offset position
    dw 0x10         ; Stack segment, same as kernel data seg
;------------------------------------------------------------------------------

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

task0:
    mov ax, 0x17       ; Load User Data Segment
    mov ds, ax
    mov al, 65         ; Starting char 'A'
    
.repeat_alpha:
    call write_char    ; Must be a CPL 3 safe routine
    
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
