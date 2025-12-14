; Purpose: A simple user application that calls kernel services.

BITS 16
ORG 0x000E ;
; ndisasm -o 0x00E /tmp/usr.img
; cs = 0x54ff ; to place debug point b *(0x54ff *16 + offset) choose offset from above output


start:
    
    mov ax, cs
    mov es, ax
    mov bx, ax
    mov ds, ax
    mov cx, ax

    mov ah, 0x01
    mov si, hello_message ; SI = Offset of the message
    int 0x80
    retf


; --- Data ---
hello_message db 'Hello from the 8086 User Program! System call success.', 0x0D, 0x0A, 0