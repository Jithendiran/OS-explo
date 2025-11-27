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

    ;-------------------------------------------------debug----s
    ;(gdb) x/5h ($ss * 0x10) +$esp
    ;0xffff:	0x0000	0x0000	0x0000	0x0000	0x0000
    ;-------------------------------------------------debug----e

    push 0x1234     ; just to know the top of stack while debug

    ;-------------------------------------------------debug----s
    ;--- Current Instruction ---
    ;=> 0x7c0c:	call   0x189a7c18
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c0c
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
    call print_j

    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c0f in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c0f:	lcall  $0xfeeb,$0x7c18
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c0f
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

    call 0x0:print_far ; explicitly tell to load both seg:off
    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c14 in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c14:	jmp    0x7c14
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c14
    ;SS:ESP  : 0x00:0xfffb
    ;--- FLAGS Register Status (0x202) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfffb) ---
    ;0xfffd:  0x1234
    ;0xffff:  0x00
    ;0x10001:  0x00
    ;0x10003:  0x00
    ;0x10005:  0x00
    ;-------------------------------------------------debug----e

jmp $

print_j:
    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c16 in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c16:	nop
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c16
    ;SS:ESP  : 0x00:0xfffb
    ;--- FLAGS Register Status (0x202) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfffb) ---
    ;0xfffb:  0x7c0f  <--- next ip
    ;0xfffd:  0x1234  <--- our mark
    ;0xffff:  0x00
    ;0x10001:  0x00
    ;0x10003:  0x00
    ;-------------------------------------------------debug----e
    nop
    ret

print_far:
    ;-------------------------------------------------debug----s
    ;(gdb) next_step_dump 
    ;0x00007c18 in ?? ()
    ;
    ;--- Current Instruction ---
    ;=> 0x7c18:	nop
    ;
    ;--- Segment and Pointer Registers ---
    ;CS:EIP  : 0x00:0x7c18
    ;SS:ESP  : 0x00:0xfff9
    ;--- FLAGS Register Status (0x202) ---
    ;CF=0 PF=:0 AF=0 ZF=0 SF=0 TF=0 IF=1 DF=0 OF=0
    ;
    ;--- Stack Trace (SS:SP linear address: 0xfff9) ---
    ;0xfff9:  0x7c14  <--- next ip
    ;0xfffb:  0x00    <--- cs
    ;0xfffd:  0x1234  <--- our mark
    ;0xffff:  0x00
    ;0x10001:  0x00
    ;-------------------------------------------------debug----e

    nop
    retf ;---------far return

times 510 - ($ - $$) db 0
dw 0xAA55   
