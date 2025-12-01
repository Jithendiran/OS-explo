; Filename: kernel.asm
; Purpose: Sets up environment, registers INT x80 handler, and runs user program.

BITS 16
ORG 0x0000 ; Assembly offset within the 0x00600 segment

%include "constant.inc"


start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    
    mov ax, KERNEL_STACK_SEGMENT
    mov ss, ax
    mov sp, KERNEL_STACK_POINTER
    
    mov ax, 0x0000
    mov es, ax
    mov word [es:0x0200], int_x80_handler 
    mov word [es:0x0202], cs


    ; Load program
    mov ah, 0x02    ; read call
    mov al, 0x01    ; Read 1 sector
    mov ch, 0x00    ; Cylinder 0
    mov cl, 0x03    ; Sector 3 
    mov dh, 0x00    ; Head 0
    mov dl, 0x00    ; Drive 0
    mov bx, USER_CODE_SEGMENT
    mov es, bx
    mov bx, USER_CODE_OFFSET
    int 0x13
    jc .disk_error

    mov si, kernel_msg
    call KERNEL_CODE_SEGMENT:print_k

    ;----------------------------------User prepare
    ; setup code and stack segment for user
    pusha
    mov [Kernel_sp_save], sp

    mov ax, USER_CODE_SEGMENT
    mov ds, ax
    mov es, ax
    mov bx, ax

    mov ax, USER_STACK_SEGMENT
    mov ss, ax
    mov sp, USER_STACK_POINTER
    call USER_CODE_SEGMENT:USER_CODE_OFFSET 

    mov ax, KERNEL_STACK_SEGMENT
    mov ss, ax 
    mov sp, [Kernel_sp_save]
    popa
    
    jmp $


.disk_error:
    mov si, MESSAGE_FAIL ; Set SI to the failure message
    call KERNEL_CODE_SEGMENT:print_k    ; Print the error message
    jmp $  

print_k:

    .loop:
        lodsb           ; Load byte from DS:SI into AL (updates SI)
        or al, al       ; Check for null terminator
        jz .done
        mov ah, 0x0E    ; AH=0Eh: Teletype output
        int 0x10        ; Call BIOS
        jmp .loop
    .done:
        retf    

int_x80_handler:
    ; Save caller's registers (IMPORTANT for interrupts)
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    
    ;cmp ah, 0x01
    je service_print
    
    ; cmp ah, 0x02
    ; je service_exit
    
    jmp service_unknown ; Fall through for unknown service

service_print:
    ; Print string from DS:SI till null (using BIOS INT 10h for simplicity)
    call KERNEL_CODE_SEGMENT:print_k
    jmp int_x80_exit ; Finished service, exit interrupt


service_exit:
    mov si, kernel_done
    call KERNEL_CODE_SEGMENT:print_k
    hlt              ; Halt the CPU 

service_unknown:
    mov si, unknown_service
    call KERNEL_CODE_SEGMENT:print_k
    ; Fall-through to exit

int_x80_exit:
    ; Restore registers and return from interrupt
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret ; Return from interrupt  

; --- Data ---
kernel_done db 'Exiting!', 0x0D, 0x0A, 0
kernel_msg:
    db 'In  Kernel!', 0x0D, 0x0A, 0
unknown_service :
    db 'Unknown service!!!!', 0x0D, 0x0A, 0
MESSAGE_FAIL:
    db 'Disk Read FAILED!\n', 0x0D, 0x0A, 0
Kernel_sp_save:
    dw 0
; --- Padding  ---
times 512 - ($ - $$) db 0