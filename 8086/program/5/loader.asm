; Purpose: Loads the kernel from disk into 0x00600 and jumps to it.
; Must be exactly 512 bytes.

BITS 16
ORG 0x7C00

jmp short main
nop

%include "constant.inc"  ;

; --- Code ---
main:
    cli
    ; Initialize Segments (DS = ES = 0x07C0)
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xffff
    


    ; Load Kernel using LBA-to-CHS conversion (Simplified, common on modern VMs)
    mov ah, 0x02    ; AH = Read Sector
    mov al, KERNEL_SECTORS ; AL = sectors to read
    mov ch, 0x00    ; CH = Cylinder 0
    mov cl, KERNEL_LBA ; CL = Starting Sector 2
    mov dh, 0x00    ; DH = Head 0
    mov dl, 0x00    ; DL = Drive 00h (Floppy Disk)
    
    mov bx, KERNEL_CODE_SEGMENT
    mov es, bx ; ES:BX = 0x0060:0x0000 (0x00600)
    mov bx, 0x0000
    int 0x13        ; Call Disk BIOS
    
    jc disk_error

    mov si, load_msg
    call print_string

    jmp KERNEL_CODE_SEGMENT:0x0000 ; Jump to kernel entry point
    hlt

disk_error:
    mov si, err_msg
    call print_string
    cli
    hlt

print_string:
    lodsb           ; Load byte from DS:SI into AL, then it will increment SI
    or al, al       ; Test if AL is NULL (end of string)
    jz .done
    mov ah, 0x0E    ; AH=0Eh: Teletype output
    int 0x10
    jmp print_string
.done:
    ret

; --- Data ---
err_msg db 'Disk Read Error!',  0x0D, 0x0A, 0
load_msg db 'In  Loader!',  0x0D, 0x0A, 0

; --- Padding and Magic Number ---
times 510 - ($ - $$) db 0
dw 0xAA55