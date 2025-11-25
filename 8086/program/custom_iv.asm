;nasm -f bin custom_iv.asm -o /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img

ORG 0x7c00
BITS 16

start:
    ; Set up a minimal stack segment at 0x0000:0xFFFF
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xffff
    mov ax, cs          
    mov ds, ax        

    ; ---  Print Initial Message  ---
    mov si, MESSAGE     
    mov ah, 0x0e        
.print_loop:
    mov al, [si]        
    cmp al, 0           
    je .install_handler 
    int 0x10    ; print one character         
    inc si              
    jmp .print_loop     


; INSTALL THE CUSTOM KEYBOARD HANDLER (INT 0x09) 
.install_handler:
    
    ; Setup ES:DI to point to the IVT entry for INT 0x09
    mov ax, 0x0000      ; The IVT is always at segment 0x0000
    mov es, ax
    mov di, 0x0024      ; Offset = 0x09 (Interrupt Number) * 4 bytes/vector = 0x24; 0x0000:0x0024

    ;--------------------------------------------------------------------!! Important---------------------------
    ; Write the new OFFSET of the handler (my_key_handler)
    ; my_key_handler will hold the offset address of the new handler code
    mov word [es:di], my_key_handler 
    add di, 2           ; Move to the segment part
    ; Write the new SEGMENT of the handler (CS)
    mov word [es:di], cs
    ;--------------------------------------------------------------------!! Important---------------------------

    ; Print confirmation
    mov si, CONFIRM_MSG
    mov ah, 0x0e
    int 0x10

.print_confirm_loop:
    mov al, [si]        ; Load character
    cmp al, 0
    je .halt_section    ; Jump when null terminator found
    int 0x10            ; Print ONE character in AL
    inc si
    jmp .print_confirm_loop

.halt_section:
    ; --- Halt and Wait for Interrupts ---
    
    sti                 ; enable the interrupts after start up
    hlt                 ; Halt the CPU and wait for an interrupt (like a keypress)
    jmp $               ; Infinite loop just in case HLT fails or gets reset
    

;--------------------------------------------------------------------!! Important---------------------------

; CUSTOM INTERRUPT SERVICE ROUTINE (ISR) - INT 0x09
my_key_handler:
    ; A proper ISR must save the state of all used registers!
    push ax
    push bx
    push cx
    push dx
    push si             ; Pushing SI/DI is good practice
    push di

    in al, 0x60 ;       ; This will read and empty the buffer, allow next interrupt to happen
    ; 1. Display a 'K' to show the handler ran
    mov al, 'K'         ; Character to display
    mov ah, 0x0e        ; Teletype function
    int 0x10            ; Print the character
    
    ; 2. Send End of Interrupt (EOI) to the Master PIC
    ; This is CRITICAL to allow further interrupts
    mov al, 0x20        ; EOI command
    out 0x20, al        ; Send EOI to PIC Master port 0x20

    ; Restore all registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ; Return from the interrupt
    iret  ; Interrupt Return - restores FLAGS, CS, and IP


MESSAGE     db 'Boot Success! Handler Installed...', 0x0D, 0x0A, 0 ; String followed by CR, LF, and Null Terminator
CONFIRM_MSG db 'Press any key:', 0x0D, 0x0A, 0 ; Confirmation message


times 510 - ($ - $$) db 0
dw 0xAA55                 