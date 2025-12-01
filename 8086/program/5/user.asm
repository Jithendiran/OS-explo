; Purpose: A simple user application that calls kernel services.

BITS 16
ORG 0x000D ;

start:
    
    mov ax, cs
    mov es, ax
    mov bx, ax
    mov ds, ax
    mov cx, ax

    mov ah, 0x01
    mov si, hello_message ; SI = Offset of the message
    int 0x80 ; Execute system call

    retf
    ; --- 2. Call Exit Service (AH=0x02) ---
    ;mov ah, 0x02
    ;mov bh, 0x00 ; Exit code 00 (Success)
    ;int 0x80 ; Execute system call (this should halt the CPU)


; --- Data ---
hello_message db 'Hello from the 8086 User Program! System call success.', 0