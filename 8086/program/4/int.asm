;nasm -f bin call.asm -o /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img -nographic -s -S

; focus on how data in stack, IF flag only before, inside and after call/ret 

ORG 0x7c00
BITS 16

start:
    ; --- Segment Initialization ---
    mov ax, cs      ; cs -> is 0x07c00
    mov ds, ax      ; ax == ds == ss == 0x07c00
    mov ss, ax      ; 
    mov sp, 0xffff  ; Stack Pointer to top of segment (0x07c00:FFFF)

    push 0x1234     ; just to know the top of stack while debug


    ; --- Install handler ---
    mov ax, 0x0000
    mov es, ax
    mov di, 0x0200  ; SI points to the start of the 80h vector (Offset)
    mov word [es:di], custom_int80 
    add di, 2   
    mov word [es:di], cs

    ;-------------------------------------------------debug
    ;(gdb) info registers cs eip ss esp eflags 
    ;cs             0x0                 0
    ;eip            0x7c1f              0x7c1f
    ;ss             0x0                 0
    ;esp            0xfffd              0xfffd
    ;eflags         0x202               [ IOPL=0 IF ]

    ;(gdb)  x/8h ($ss * 0x10) +$esp
    ;0xfffd:	0x1234	0x0000	0x0000	0x0000	0x0000	0x0000	0x0000	0x0000

    int 0x80

    ;-------------------------------------------------debug
    ;(gdb) info registers cs eip ss esp eflags 
    ;cs             0x0                 0
    ;eip            0x7c21              0x7c21
    ;ss             0x0                 0
    ;esp            0xfffd              0xfffd
    ;eflags         0x202               [ IOPL=0 IF ]

    ;(gdb) x/8h ($ss * 0x10) +$esp
    ;0xfffd:	0x1234	0x0000	0x0000	0x0000	0x0000	0x0000	0x0000	0x0000
    
    ; cs:ip and flags got restored
    jmp $


custom_int80:

    ;-------------------------------------------------debug
    ;(gdb) info registers cs eip ss esp eflags 
    ;cs             0x0                 0
    ;eip            0x7c23              0x7c23
    ;ss             0x0                 0
    ;esp            0xfff7              0xfff7
    ;eflags         0x2                 [ IOPL=0 ]

    ; pushed in the order of flags, cs, ip
    ;(gdb) x/8h ($ss * 0x10) +$esp
    ;0xfff7:	0x7c21	0x0000	0x0202	0x1234	0x0000	0x0000	0x0000	0x0000

    mov al, 0x06  

    iret

times 510 - ($ - $$) db 0
dw 0xAA55