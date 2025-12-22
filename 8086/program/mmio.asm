;nasm -f bin mmio.asm -o /tmp/boot.img
;ndisasm -o 0x7c00 /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img


BITS 16
ORG 0x7C00 

start:

    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7C00


write_char_direct:
    mov ax, 0xB800          ; Segment for Color Text Video Memory
    mov es, ax              ; Load into Extra Segment
    
    ; Calculate offset: (row * 80 + col) * 2
    ; For now, let's just write 'A' to the top-left corner (0,0)
    mov di, 0               ; Offset 0
    
    mov al, 'A'             ; ASCII character
    mov ah, 0x1F            ; Attribute: White text (0xF) on Blue background (0x1)
    
    mov [es:di], ax         ; Write both bytes at once to 0xB800:0000

done:
    hlt  


times 510 - ($ - $$) db 0
dw 0xAA55 