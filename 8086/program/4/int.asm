;nasm -f bin call.asm -o /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img -nographic -s -S

; focus on how data in stack, IF flag only before, inside and after call/ret 

ORG 0x7c00
BITS 16

start:
    ; --- Segment Initialization ---
    mov ax, cs      ; cs -> is 0x0000
    mov ds, ax      ; ax == ds == ss == 0x0000
    mov ss, ax      ; 
    mov sp, 0xffff  ; Stack Pointer to top of segment (0x0000:0xFFFF)

    push 0x1234     ; just to know the top of stack while debug


    ; --- Install handler ---
    mov ax, 0x0000
    mov es, ax
    mov di, 0x0200  ; SI points to the start of the 80h vector (Offset)
    mov word [es:di], custom_int80 
    add di, 2   
    mov word [es:di], cs

    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c1f in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c1f:	int    $0x80
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c1f
    ;SS:ESP  : 0x00:0xfffd
    ;--- FLAGS Register Status (0x202) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfffd) ---
    ;0xfffd:  0x1234
    ;0xffff:  0x00
    ;0x10001:  0x00
    ;0x10003:  0x00
    ;0x10005:  0x00
    ;-------------------------------------------------debug----e
    int 0x80

    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c21 in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c21:	jmp    0x7c21
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c21
    ;SS:ESP  : 0x00:0xfffd
    ;--- FLAGS Register Status (0x202) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfffd) ---
    ;0xfffd:  0x1234
    ;0xffff:  0x00
    ;0x10001:  0x00
    ;0x10003:  0x00
    ;0x10005:  0x00
    ;-------------------------------------------------debug----e
    jmp $


custom_int80:

    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c23 in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c23:	nop
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c23
    ;SS:ESP  : 0x00:0xfff7
    ;--- FLAGS Register Status (0x2) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=0 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfff7) ---
    ;0xfff7:  0x7c21 <--next ip
    ;0xfff9:  0x00   <--cs
    ;0xfffb:  0x202  <-- flag
    ;0xfffd:  0x1234 <-- our mark
    ;0xffff:  0x00
    ;-------------------------------------------------debug----e
    nop 

    iret

times 510 - ($ - $$) db 0
dw 0xAA55