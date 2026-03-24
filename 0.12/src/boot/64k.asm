; nasm -f bin /tmp/64k.asm -o /tmp/64k.bin
; qemu-system-i386 -drive format=raw,file=/tmp/64k.bin -s -S
bits 16
org 0x7c00          ; Bootloader start address

start:
    mov ax, 0x1000
    mov ds, ax      ; Set Segment to 0x1000
    mov si, 0xFFFD  ; Set Offset to 0xFFFD

    inc si          ; SI = 0xFFFE
    inc si          ; SI = 0xFFFF
    inc si          ; SI = 0x0000 (The Wrap!)
    
    ;debug step by step from line number 1, after line 13 ds not incremented to 0x2000, so we have to do that manually
    nop

    ;corrected flow
    mov ax, 0x1000
    mov ds, ax 
    mov si, 0xFFFF

    ; inc doesn't affect carry flag
    add si, 1       ; SI becomes 0x0000, CF becomes 1

    jnc skip_inc_ds ; Jump if Carry is NOT set
    
    mov ax, ds      ; Move DS to AX to do math
    add ax, 0x1000
    mov ds, ax      ; DS is now 0x2000


    nop     
skip_inc_ds:
    jmp $           ; Infinite loop

times 510-($-$$) db 0
dw 0xaa55           ; Boot signature