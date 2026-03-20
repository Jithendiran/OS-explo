[org 0x0000]                          
SYSSEG  equ 0x1000                    ; Header program start location
SYSLEN  equ 10                         ; header program length in sectors, one sector is 512 bytes, 512 * 7 = 3584 bytes == 3.5KB 
DBOOT   equ 0x7c00                    
BOOTEIP equ 0x7c00
DB_20A  equ 0x7c000

move_:
    cli
    mov ax, 0x0000
    mov ds, ax
    mov si, BOOTEIP     ; source = 0x0000:0x7c00

    mov ax, DBOOT       
    mov es, ax
    mov di, 0x0000      ; Destination = 0x7c00:0x0000
    mov cx, 256
    rep movsw

    jmp DBOOT:start     ; 0x7c000

start:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, 0x0fff      ; 0x7C00:0x0FFF = 0x7CFFF, grow downwards , temp stack no worry

    mov si, START_MSG 
    call print_string    


load_from_floppy:
    mov ah, 0x02        ; BIOS read sector function
    mov al, SYSLEN      ; Number of sectors
    mov ch, 0x00        ; Cylinder 0
    mov cl, 0x02        ; Sector 2 (Sector 1 is the bootloader)
    mov dx, 0x00        ; Head 0

    mov bx, SYSSEG
    mov es, bx          ; Destination segment
    mov bx, 0x0000      ; Destination offset (ES:BX = 1000:0000)

    int 0x13
    jc disk_error
    mov si, MESSAGE_OK
    call print_string

; This will overwrite the existing IDT, stop the interrupts
load_to_start:
    cli
    mov ax, SYSSEG
    ; source 
    mov ds, ax      
    sub si, si      ; 0x1000:0x0000

    ; destination
    xor ax, ax      
    mov es, ax      
    sub di, di      ; 0x0000:0x0000

    mov cx, 0x0700  ; number of moves 1792 times, one word is 2 byte, need to transfer 8000, so (0x16^3)+(7x16^2)(0x16^1)(0x16^0)=1792, x2 = 3584 bytes
    rep movsw 

    ; revert ds
    mov ax, cs
    mov ds, ax

    add dword [gdt_descriptor+2], DB_20A
    add dword [idt_descriptor+2], DB_20A

    lidt [idt_descriptor]
    lgdt [gdt_descriptor]

; protected Mode
    mov eax, cr0
    or eax, 0x1           ; Set bit 0 (PE - Protection Enable)
    mov cr0, eax

    jmp 0x08:0x00

;----------------------GDT------------------------------
align 8
gdt:
    dw 0,0,0,0          ; The null descriptor (8 bytes of zeros)

head_code:
    ;---------------0----------------------------
    dw 0xFFFF           ; Limit (0-15):  65535 bytes
    dw 0x0000           ; base 0-15 ; pos 16-31 (1)
    ;---------------4-------------------------
    
    db 0x00             ; base 16-23; pos 0-7 (2)
    db 1001_1010b       ; POS = 8-15 flags | p=1, DPL=00, S=1, | Type(type exe(3) = 1, con(2) = 0, readonly(1) = 1), Accessed(0)=0;
    db 0100_0000b       ;G = 0 x = 1 0 = 0 AVL = 0 limit = 0000 
    ;base 24-31 (0)
    db 0x0
    ;----------------------------------------------------------------

head_data:
    ;---------------0----------------------------
    dw 0xFFFF           ; Limit (0-15):  65535 bytes
    dw 0x0000           ; base 0-15 ; pos 16-31 (1)
    ;---------------4-------------------------
    
    db 0x00             ; base 16-23; pos 0-7 (2)
    db 1001_0110b       ; POS = 8-15 flags | p=1, DPL=00, S=1, | Type(type exe(3) = 0, stack(2) = 1, readonly(1) = 0), Accessed(0)=0;
    db 0100_0000b       ;G = 0 x = 1 0 = 0 AVL = 0 limit = 0000 
    ;base 24-31 (0)
    db 0x0
    ;----------------------------------------------------------------
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt - 1 ; Bytes 0-1: The Size (Limit)
    dd gdt               ; Bytes 2-5: The 32-bit Physical Address (The Pointer)
;----------------------IDT------------------------------
nop
idt:
    dw 0x00
    dw 0, 0
idt_end:
idt_descriptor:
    dw idt_end - idt - 1 ; Size
    dd idt 
align 8
;----------------------utils----------------------------

disk_error:
    mov si, MESSAGE_FAIL ; Set SI to the failure message
    call print_string    ; Print the error message
    jmp $ 


print_string:
    pusha                

print_loop:
    mov al, [si]         
    cmp al, 0
    je print_done       
    mov ah, 0x0e
    int 0x10             
    inc si              
    jmp print_loop

print_done:
    popa                 
    ret                 

; --- Data ---
START_MSG:
    db 'Multi-Process', 0x0D, 0x0A, 0
MESSAGE_OK:
    db 'Sector  Read Success!', 0x0D, 0x0A, 0
MESSAGE_FAIL:
    db 'Disk Read FAILED!', 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xaa55