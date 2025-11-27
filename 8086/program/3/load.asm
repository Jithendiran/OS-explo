ORG 0x7c00        
BITS 16           

start:
    ; --- Segment Initialization ---
    mov ax, cs
    mov ds, ax      
    mov ss, ax      
    mov sp, 0xffff  ; Stack Pointer to top of segment (0x0000:0xFFFF) => start from 0x0FFFF, grow in downwards, if stack push 2 bytes of data next address is 0x0FFFF - 2 = 0x0FFFD

    ; --- Print Message ---
    mov si, MESSAGE_LOAD
    call print_string

    ; --- Setup Load Parameters (INT 0x13, AH=02h) ---

    ; AH = 02h: Read Sectors from Drive
    mov ah, 0x02    

    ; AL: Number of sectors to read
    mov al, 0x01    

    ; CHS Addressing for Sector 2 
    mov ch, 0x00    
    mov cl, 0x02    
    mov dh, 0x00    
    mov dl, 0x00    

    ; --- Setup Destination Address: 0x1000:0000 (Physical 0x10000) ---
    ; This is a common place to load a small second stage.
    mov bx, 0x1000  ; Segment 0x1000
    mov es, bx      ; Set Extra Segment (ES) to 0x1000
    mov bx, 0x0000  ; Offset 0x0000
                    ; Buffer is at ES:BX = 0x1000:0000

    int 0x13
    jc .disk_error

    ; --- Success & Transfer Control ---
    mov si, MESSAGE_SUCCESS
    call print_string
    
    ;  JUMP TO THE NEWLY LOADED CODE
    ; We use a FAR JUMP (jmp segment:offset) to set both CS and IP
    jmp 0x1000:0000

.disk_error:
    mov si, MESSAGE_FAIL
    call print_string
    jmp $           ; Halt on failure

; --- Subroutine to Print String (Teletype Mode) ---
print_string:
    pusha
.print_loop:
    mov al, [si]
    cmp al, 0
    je .print_done
    mov ah, 0x0e    
    int 0x10
    inc si
    jmp .print_loop
.print_done:
    popa
    ret

; --- Data ---
MESSAGE_LOAD:     db 'Loading user code (Sector 2) to 0x10000...', 0x0D, 0x0A, 0
MESSAGE_SUCCESS:  db 'Load success. Jumping to user code...', 0x0D, 0x0A, 0
MESSAGE_FAIL:     db 'Disk Read FAILED!', 0x0D, 0x0A, 0

times 510 - ($ - $$) db 0
dw 0xAA55           ; Boot Signature