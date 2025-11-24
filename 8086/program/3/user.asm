ORG 0x0000        ; This code will be placed at the start of the second sector (LBA 1)
BITS 16           ; Use 16-bit instructions

; The jump will land here (CS:IP = 0x1000:0000) 

start_user_code:
    ; IMPORTANT: DS/ES/SS still point to the original boot segment!
    ; We must re-initialize what ever we need, typically all.
    ; For this simple print, we just set DS to our new CS for simplicity.
    mov ax, cs      ; AX = 0x1000
    mov ds, ax      ; Set Data Segment (DS) to 0x1000
    
    mov si, USER_MESSAGE
    call print_string
    
    jmp $           ; Halt execution

; --- Subroutine to Print String  ---
print_string:
    pusha
    mov ah, 0x0e
.print_loop:
    mov al, [si]
    cmp al, 0
    je .print_done
    int 0x10
    inc si
    jmp .print_loop
.print_done:
    popa
    ret

; --- Data ---
USER_MESSAGE:
    db '*** User Code Executed Successfully from 0x10000! ***', 0x0D, 0x0A, 0
