;nasm -f bin simple_print.asm -o /tmp/boot.img
;ndisasm -o 0x7c00 /tmp/boot.img 
;qemu-system-i386 -fda /tmp/boot.img -nographic


ORG 0x7c00  ; instructs the assembler to set its location counter; it is offset value, not segment value
; code segment (cs) will point to 0000H

BITS 16           ; Use 16-bit instructions (Real Mode)

start:
    ; stack is needed, interrupt, call push will use stack
    mov ax, 0x0000
    mov ss, ax          ; Set Stack Segment to 0
    mov sp, 0xffff      ; Set Stack Pointer to the top of the 64KB segment (0x10000)

    ; Setup Data Segment (DS)
    ; The DS register MUST point to the segment where our MESSAGE is stored.
    ; Since our code starts at 0x7C00, and our message is right after the code, 
    ; we need DS to point to the same segment as the code (CS).
    mov ax, cs          ; Copy the Code Segment (CS) value into AX
    mov ds, ax          ; Set the Data Segment (DS) to the same value

    ; SI (Source Index) will point to the beginning of our message string.
    ; MESSAGE holds the offset address
    mov si, MESSAGE     ; SI now holds the OFFSET of the MESSAGE label

    ;Setup Video Function
    mov ah, 0x0e        ; BIOS Teletype function (INT 0x10)

    .print_loop:
    ; Load Character and Check for End
    mov al, [si]        ; Load the byte (character) at DS:[SI] into AL
    cmp al, 0           ; Compare the character to the null terminator (0)
    je .done            ; If AL == 0, jump to the .done label (exit loop)

    ; Print Character
    int 0x10            ; Call BIOS to print character in AL

    ; Advance Pointer
    inc si              ; Increment SI to point to the next character

    ; Loop Back
    jmp .print_loop     ; Go back to the top of the loop

.done:
    jmp $               ; Infinite loop to halt execution

MESSAGE:
    db 'Boot Success!', 0   ; Our string, followed by a Null Terminator (0)

times 510 - ($ - $$) db 0  ; Fill the rest of the 512 bytes with zeros; padding
; $ - current address
; $$ - starting address of the current section
;(Current Address) - (Start Address) = Size of code in bytes.

dw 0xAA55                 ; The magic boot signature at bytes 510 and 511
; The above signature is the key to find this is a boot device, if not found bios looks for next device

;ls -la /tmp/boot.img 
;-rw-rw-r-- 1 ji ji 512 Nov 24 00:00 /tmp/boot.img
