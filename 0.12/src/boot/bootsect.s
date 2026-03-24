; nasm -f bin tmp.s -o boot.bin 
SYSSIZE     equ 0x3000
SETUPLEN    equ 4		            ; how 4? size of setup segment is 2 KB 	2048 bytes, each sector in floppy can hold 512 bytes, 2048/512 = 4	sector
BOOTSEG     equ 0x07c0			
INITSEG     equ 0x9000			
SETUPSEG    equ 0x9020			
SYSSEG      equ 0x1000			
ENDSEG      equ SYSSEG + SYSSIZE		

ROOT_DEV    equ 0
SWAP_DEV    equ 0

global  begtext, begdata, begbss, endtext, enddata, endbss

.text:
begtext:

.data:
begdata:

.bss:
begbss:

.text:

    mov     ax,     BOOTSEG
	mov     ds,     ax

	mov     ax,     INITSEG
	mov     es,     ax

	mov     cx,     256
	sub     si,     si
	sub     di,     di

	rep     movsw

	jmp	    INITSEG:go

; bootsect moved itself to 0x90000

go:
    ; segment alignment
    mov	    ax,     cs		
    mov	    ds,     ax
	mov	    es,     ax

	mov	    dx,     0xfef4	
	push    ax

	mov	    ss,     ax		; 0x9000
	mov	    sp,     dx      ; 0xfef4 = 0x9fef4 
    
    ; Diskette Parameter Table (DPT) is a 12-Byte 
    ; 0x9ff00 - 0x0c (12) = 0x9fef4
    ;   Offset, Size,       Description,                                    Typical Value
    ;   0x00,   Byte,       Step rate & Head unload time,                   0xDF
    ;   0x01,   Byte,       Head load time & DMA mode,                      0x02
    ;   0x02,   Byte,       Motor-off delay (clock ticks),                  0x25
    ;   0x03,   Byte,       "Bytes per sector (0=128, 1=256, 2=512)",       0x02 (512)
    ;   0x04,   Byte,       Last sector on track (Sectors per track),       0x12 (18 for 1.44MB)
    ;   0x05,   Byte,       Gap length between sectors,                     0x1B
    ;   0x06,   Byte,       Data length (if sector size is 0),              0xFF
    ;   0x07,   Byte,       Gap length for format,                          0x54
    ;   0x08,   Byte,       Fill byte for format,                           0xF6
    ;   0x09,   Byte,       Head settle time (milliseconds),                0x0F
    ;   0x0A,   Byte,       Motor start time (1/8 seconds),                 0x08
    ;   0x0B,   Byte,       Maximum track number (highest cylinder),        0x4F (79)

    ;------------------------------------------clone disk config
    ; Locating the Diskette Parameter Table (DPT)
    push    0
    pop     fs
    mov     bx,     0x78    ; 0x00078     interrupt 1Eh the Diskette Parameter Table

    ; lgs si, [fs:bx] loads the 32-bit far pointer at fs:bx 
    ; The offset goes into si, the segment goes into gs.
    lgs     si,     [fs:bx]

    ; The Relocation (Copying)
    mov     di,     dx          ; dx was 0xfef4
    mov     cx,     6           ; count of 6 words (12 bytes)
    cld                         ; clear direction flag (forward move)

    ; repeat moving word from [gs:si] 0x0000:0x0078 to [es:di] 0x9000:0xfef4
    rep     gs      movsw       ; The 'gs' here tells the CPU: "Use GS instead of DS"


    ;-------------------------------------------modifying speed
    ; 1. Patch the sector count in our new table
    ; The 5th byte (offset 4) in the DPT is 'Sectors per Track'
    ; We set it to 18 (for a standard 1.44MB 3.5" floppy)
    mov     di,         dx              ; Reset di to the start of the new table
    mov     byte [es:di+4], 18

    ; 2. Update the Interrupt Vector Table (IVT) 
    ; fs was 0, bx was 0x78. We point the vector to our new table at es:di
    mov     [fs:bx],    di              ; Update Offset (0xfef4)
    mov     [fs:bx+2],  es              ; Update Segment (0x9000)

    ; 3. Restore Segments
    ; Earlier we did 'push ax' (where ax was 0x9000). Now we restore it.
    pop     ax
    mov     fs,         ax              ; fs = 0x9000
    mov     gs,         ax              ; gs = 0x9000

    ; 4. Reset Floppy Disk Controller (FDC)
    ; This forces the BIOS to re-read the parameters we just changed
    xor     ah,         ah              ; Function 0: Reset disk system
    xor     dl,         dl              ; Drive 0: Floppy A:
    int     0x13                        ; Call BIOS

    ;-------------------------------------------- load setup 

load_setup:
    ; 90000 - 901FF bootsect code
    ; es already in 0x9000
    mov     ah,         0x02
    mov     al,         SETUPLEN
    mov     ch,         0x00            ; Cylinder 0
    mov     cl,         0x02            ; Sector 2 (Sector 1 is the bootloader)
    mov     dx,         0x00            ; Head 0
    mov     bx,         0x0200          ; dest offset = 0x9000+0x0200 = 0x90200
    int     0x13

    jc disk_error
    mov si, MESSAGE_OK
    call print_string

ok_load_setup:
    ; read disk drive parameters
    xor     dl,         dl              ; DL=0  set to drive 0 (floppy A)
    mov     ah,         0x08            ; AH=8 is get drive parameters
    int     0x13
    ; BIOS returns:
    ; CH = low 8 bits of max cylinder
    ; CL = max sector number (bits 0-5), high 2 bits of max cylinder (bits 6-7)
    
    xor     ch,         ch
    and     cl,         0x3F            ; Mask out the top 2 bits (the cylinder bits)
    mov     [cs:sectors], cx            ; save the sectors 
    
    ; move es to 0x90000
    mov     ax,         INITSEG
    mov     es,         ax

    mov si, msg1
    call print_string

    ; load the system at 0x1000
    ; length of the SYSSEG is 196KB loaded between 0x10000-0x40000 = 256KB
    ; 64 * 3 = 192, 64 * 4 = 256, so location  0x10000-0x40000 is used
    mov     ax,         SYSSEG
    mov     es,         ax



; Data variables - placed in the data section or after the code
sread:  dw 1 + SETUPLEN                 ; Sectors read on current track ; 1 (bootsect) + 4 (setup)
head:   dw 0                            ; Current head
track:  dw 0                            ; Current track


read_it:
    mov     ax,          es             ; ax = 0x1000
    test    ax,          0x0FFF         ; Check if ES is 64KB aligned
die:    
    jne     die                         ; If not aligned, halt
    xor     bx,          bx             ; bx is the offset within the segment
    
rp_read:
    mov     ax,          es
    cmp     ax,          ENDSEG         ; Have we reached the end segment?
    jb      ok1_read                    ; if ENDSEG is greater than ax, CF flag will set, meaning our read operation not completed yet
    ret

ok1_read:
    mov     ax,          [cs:sectors]   ; Get sectors per track (saved earlier)     ; 18
    sub     ax,          [cs:sread]     ; Calculate sectors remaining on track      ; 18 - 5 = 13
                                        ; flags CF=0, ZF=0, SF=0, OF=0, PF=1, AF=1

    mov     cx,          ax             ; 13 = 0000 0000 0000 1101

    shl     cx,          9              ; CX = sectors * 512 bytes = 13 * 512 = 6656 bytes
    ;after shl = 0001 1010 0000 0000    ; flags CF=0, ZF=0, SF=0, OF=0, PF=1, AF=-

    add     cx,          bx             ; Add current offset
    ; after add = 0001 1010 0000 0000   ; flags CF=0, ZF=0, SF=0, OF=0, PF=1, AF=0
    
    jnc     ok2_read                    ; If no carry, we don't cross 64KB boundary, Result < 64KB
    ; cx and bx are 16 bit, Maximum they can add upto 64KB, if exceed, carry flag set, also mean we crossed the boundry
    je      ok2_read                    ; If zero flag set, exactly 64KB
    ; if result is all 0's and CF=1 means we are exactly at the 64KB
    
    ; If we would cross 64KB, calculate how many sectors fit instead
    xor     ax,         ax
    sub     ax,         bx             ; ax = 64KB - bx
    shr     ax,         9              ; convert bytes back to sectors
    
ok2_read:
    call read_track        ; Perform the actual BIOS read
    mov cx, ax             ; Save number of sectors actually read
    add ax, [cs:sread]     ; Update our progress on this track
    cmp ax, [cs:sectors]
    jne ok3_read           ; If track not finished, skip ahead
    
    ; Logic for Head/Track switching
    mov ax, 1
    sub ax, [cs:head]      ; Toggle head (0 -> 1 or 1 -> 0)
    jne ok4_read           ; If now head 1, track is the same
    inc word [cs:track]    ; If back to head 0, increment track
    
ok4_read:
    mov [cs:head], ax      ; Save new head
    xor ax, ax             ; Reset sectors read on this new track/head
    
ok3_read:
    mov [cs:sread], ax     ; Update sread
    shl cx, 9              ; CX = sectors read * 512
    add bx, cx             ; Update memory offset
    jnc rp_read            ; If we haven't wrapped 64KB, loop
    
    ; If we wrapped 64KB, move to the next segment
    mov ax, es
    add ax, 0x1000         ; Advance ES by 64KB (0x1000 * 16)
    mov es, ax
    xor bx, bx             ; Reset offset to 0
    jmp rp_read






;------------------------------------------------------Print

print_string:
    pusha                

print_loop:
    mov al, [si]         
    cmp al, 0
    je print_done       
    mov ah, 0x0e
    int 0x10             
    inc si              
    jmp print_loop

print_done:
    popa                 
    ret

;--------------------------------------------------------



sectors:
	dw 0

disk_error:
    mov si, MESSAGE_FAIL ; Set SI to the failure message
    call print_string    ; Print the error message
    jmp $ 

msg1:
	db "Loading",  0x0D, 0x0A, 0

MESSAGE_OK:
    db 'Sector  Read Success!', 0x0D, 0x0A, 0

MESSAGE_FAIL:
    db 'Disk Read FAILED!', 0x0D, 0x0A, 0

times 506-($-$$) db 0
swap_dev:
	dw SWAP_DEV

root_dev:
	dw ROOT_DEV

boot_flag:
	dw 0xAA55

.text:
endtext:

.data:
enddata:

.bss:
endbss: