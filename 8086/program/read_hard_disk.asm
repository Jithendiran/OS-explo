;nasm -f bin read_hard_disk.asm -o /tmp/boot.img
;ndisasm -o 0x7c00 /tmp/boot.img
;qemu-system-i386 -fda /tmp/boot.img -nographic


ORG 0x7c00           
BITS 16             

start:

    mov ax, cs           ; cs is 0000H
    mov ds, ax           ; Set Data Segment (DS) = Code Segment (CS)
    mov ss, ax           ; Set Stack Segment (SS) = Code Segment (CS) for simplicity
    mov sp, 0xffff       ; Set Stack Pointer (SP)

    ; --- Setup Disk Read Parameters (INT 0x13, AH=02h) ---

    ; AH = 02h: Read Sectors from Drive
    mov ah, 0x02 ; read call

    ; AL: Number of sectors to read (1 sector: 512 bytes)
    mov al, 0x01         ; Read 1 sector

    ; CHS Addressing for Sector 2
    mov ch, 0x00    ; Cylinder 0
    mov cl, 0x02    ; Sector 2 
    mov dh, 0x00    ; Head 0
    mov dl, 0x00    ; Drive 0 (Floppy A:)

    ; ES:BX: Transfer Buffer Address (ES:Offset)
    ; We want to load the sector data into memory starting at 0x7E00.
    ; Since DS is 0x7C0, we can use ES=0 and BX=0x7E00, 
    
    ; Simple way: Set ES=0 and use BX for the full offset.
    mov bx, 0x0000          ; Load segment 0x0000
    mov es, bx              ; ES = 0x0000
    mov bx, 0x7e00          ; Set BX (Offset) to 0x7e00. 
                            ; Transfer address is ES:BX = 0x0000:0x7e00
                            ; 0x0000 * 0x10 = 0x00000 + 0x7E00 = 0x07E00

    ; --- Execute Disk Read ---
    int 0x13             ; Call Disk I/O Interrupt

    ; --- Check for Error ---
    ; If carry flag is set (CF=1), an error occurred.
    jc .disk_error

    ; --- Success Message ---
    mov si, MESSAGE_OK   ; Set SI to the success message
    call print_string    ; Print the success message

    jmp sector_2         ; Jump to second sector

.disk_error:
    mov si, MESSAGE_FAIL ; Set SI to the failure message
    call print_string    ; Print the error message
    jmp $                ; Halt

; --- Subroutine to Print String (Reusing code from Simple Print) ---
print_string:
    pusha                ; Save general purpose registers (ax, bx, cx, dx, bp, dp, si, di)

.print_loop:
    mov al, [si]         
    cmp al, 0
    je .print_done       
    mov ah, 0x0e
    int 0x10             
    inc si              
    jmp .print_loop

.print_done:
    popa                 ; Restore registers
    ret                  ; Return from subroutine

; --- Data ---
MESSAGE_OK:
    db 'Sector 2 Read Success!', 0x0D, 0x0A, 0
MESSAGE_FAIL:
    db 'Disk Read FAILED!\n', 0x0D, 0x0A, 0

times 510 - ($ - $$) db 0
dw 0xAA55

;----------------------------------from now bytes 512-1023bytes-------------------

sector_2:
    mov si, MESSAGE_2   ; Set SI to the success message
    call print_string    ; Print the success message

jmp $                ; Halt

; --- Data ---
MESSAGE_2:
    db 'Sector 2 executed', 0x0D, 0x0A, 0

times 1024 - ($ - $$) db 0

;ls -la /tmp/boot.img 
;-rw-rw-r-- 1 ji ji 1024 Nov 24 00:00 /tmp/boot.img