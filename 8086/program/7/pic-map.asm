;nasm -f bin pic-map.asm -o /tmp/boot.img
;ndisasm -o 0x7c00 /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img


BITS 16
ORG 0x7C00 

; Define constants for PIC ports
NEW_VECTOR_MASTER      equ 0x20 
NEW_VECTOR_SLAVE       equ 0x28

MASTER_COMMAND equ 0x20
MASTER_DATA    equ 0x21
SLAVE_COMMAND  equ 0xA0
SLAVE_DATA     equ 0xA1

start:
    ; Reset segment registers
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7C00

;  SETUP THE IVT (Interrupt Vector Table) for timer and disk handler
; ----------------------------------------------------
    ; SEND OCW2 (End of Interrupt)
    ; For Master IRQs (0-7), send to Master only.
    ; For Slave IRQs (8-15), send to BOTH Slave and Master.
    ; Timer (IRQ0 -> Vector 0x20)
    
    mov word [0x20 * 4], timer_handler     
    mov word [0x20 * 4 + 2], cs        

    ; Disk/IDE (IRQ14 -> Vector 0x2E) 
    ; IRQ14 is Slave IRQ 6. (Base 0x28 + 6 = 0x2E)
    mov word [0x2E * 4], disk_handler
    mov word [0x2E * 4 + 2], cs

; PIC cycle start
; ----------------------------------------------------
    ; ---ICW1  Start Initialization Sequence ---
    ; 0x11 = 00010001b (Bit 4=1: ICW1, Bit 0=1: ICW4 needed)
    mov al, 0x11            ; Select ICW1, Edge Triggered Mode, needs ICW4
    out MASTER_COMMAND, al  ; Send to Master PIC
    out SLAVE_COMMAND, al   ; Send to slave PIC

    ; ---ICW2  Set the New Base Vector (The Remap) ---
    mov al, NEW_VECTOR_MASTER      ; Set IRQ0 base to 0x20
    out MASTER_DATA, al            ; Send to Master PIC Data Port
    mov al, NEW_VECTOR_SLAVE       ; Set IRQ8 base to 0x28
    out SLAVE_DATA, al             ; Send to Slave PIC data Port

    ; ---ICW3  Cascade Setup  ---
    ; Master: Tell it Slave is on IR2 (Bit 2 = 1 -> 00000100b)
    mov al, 0x04
    out MASTER_DATA, al
    ; Slave: Tell it its "Identity" is 2 (Binary 2 -> 00000010b)
    mov al, 0x02
    out SLAVE_DATA, al

    ; ---ICW4  8086 Mode ---
    ; 0x01 = 00000001b (8086 mode, Normal EOI)
    mov al, 0x01            ; Set 8086/8088 mode
    out MASTER_DATA, al
    out SLAVE_DATA, al
; ----------------------------------------------------
; PIC cycle end

    ; --- OCW1 (Masking): Unmask all IRQs ---
    mov al, 0x00            ; Mask register: 0x00 = all IRQs enabled
    out MASTER_DATA, al ; Send to Master PIC Data Port

    call print_msg
    cli                     
    hlt                     

msg_hello db "PIC Remapped to 0x20. Bootloader initialized.", 0x0D, 0x0A, 0x00


print_msg:
    push ax
    push bx
    push si
    push es

    mov si, msg_hello       
    mov ah, 0x0E            
    mov bx, 0x0007          

.next_char:
    mov al, [si]            
    cmp al, 0x00            
    je .done                

    int 0x10                
    inc si                  
    jmp .next_char

.done:
    pop es
    pop si
    pop bx
    pop ax
    ret


; in interrupt handler only EOI part is shown here

; --- 4. THE ISR WITH OCW2 ---
timer_handler:
    push ax
    
    ; [Visual feedback: print a dot to the screen]
    mov al, '.'
    mov ah, 0x0E
    int 0x10

    ; SEND EOI to Master only
    
    mov al, 0x20
    out MASTER_COMMAND, al         ; OCW2 sent to Master
    
    pop ax
    iret

disk_handler:
    push ax
    
    ; ... [Handle disk data] ...

    ; Send EOI to BOTH PICs
    mov al, 0x20
    out SLAVE_COMMAND, al   ; Tell Slave we are done
    out MASTER_COMMAND, al  ; Tell Master the cascade is clear
    
    pop ax
    iret

times 510 - ($ - $$) db 0

dw 0xAA55 