# Power-On Sequence to Bootloader

### 1. CPU Reset and Initial Address
1. Power Applied & Power Good: When the power supply is turned on, the system logic generates a RESET signal to the CPU until the power is stable (receives the "Power Good" signal).

2. CPU Initialization: When the RESET signal is removed, the 8086 processor initializes its internal registers to specific, hardwired values:

    - CS (Code Segment): $\text{FFFFH}$
    - IP (Instruction Pointer): $\text{0000H}$
    - DS, ES, SS (Data/Extra/Stack Segments): $\text{0000H}$
    - Flags: Cleared/Undefined.

3. First Instruction Fetch: The CPU calculates the physical address using $(\text{CS} \times 10\text{H}) + \text{IP}$:
$$\text{Physical Address} = (\text{FFFFH} \times 10\text{H}) + \text{0000H} = \mathbf{FFFF0H}$$

This address is only 16 bytes from the end of the 1MB address space and is mapped to the System BIOS ROM chip.

BIOS code is written on a dedicated ROM chip on motherboard, on startup these code is mapped to RAM higher memory $\mathbf{F0000H}$ - $\mathbf{FFFFFH}$, Since first instruction is calculated as $\mathbf{FFFF0H}$, CPU start execution from here

### 2. BIOS Execution (ROM Code)

1. Execution Starts at $\text{FFFF0H}$ (The JMP): The instruction at $\text{FFFF0H}$ is typically a short or long JUMP instruction. This jump redirects the CPU to the main, larger part of the BIOS code (e.g., in the $\text{F0000H}$ region) to begin the main initialization routine

2. POST (Power-On Self-Test): The BIOS code executes the POST. This involves:
    - Checking the CPU and BIOS integrity.
    - Initializing the system chipset.
    - Testing and counting system RAM.
    - Initializing other essential hardware (keyboard, disk controllers, etc.).
    - It will initilize the RAM

3. Initializing RAM: 

The classic PC memory map is divided into two major regions: **Conventional Memory** (RAM below 640 KB) and the **Upper Memory Area** (UMA, or System Reserved Memory) between 640 KB and 1 MB.

$$2^{20}== 1\text{ MB} == 0 - 1048575\text{ Bytes} == 0x00000 - 0xFFFFF$$

| Address Range (Hex) | Size | Bytes Range | Component/Usage | Details |
| :--- | :--- | :--- | :--- | :--- |
| **00000H – 003FFH** | 1 KB | 0-1023 | **Interrupt Vector Table (IVT)** | Contains 256 interrupt vectors (4 bytes each). The BIOS initializes these with pointers to default interrupt handler routines (BIOS functions). |
| **00400H – 004FFH** | 256 Bytes | 1024 - 1279 | **BIOS Data Area (BDA)** | Contains system variables used by the BIOS and DOS, such as equipment list, base addresses of I/O devices (serial, parallel), keyboard buffer, and timer counts. |
| **00500H – 005FFH** | 256 Bytes | 1280 - 1535 | **Extended BIOS Data Area (EBDA)** | Reserved for the Extended BIOS Data Area (EBDA) if expanded by the BIOS. This is depends on the hardware, it may be consider as **Conventional RAM** |
|--|--|--|**Lower region**|--|
| **00600H – 9FFFFH** | $\approx$ 639 KB | 1536 - 655359 | **Conventional RAM** | The main memory area for the operating system, applications, and data. The BIOS tests and counts all available RAM up to this point (or $640 \text{KB}$ boundary). |
|--|--|--|**Upper region**|--|
| **A0000H – BFFFFH** | 128 KB | 655360 - 786431  | **Video RAM (VRAM)** | Dedicated memory used by the video card. $ \text{A0000H}-\text{AFFFFH}$ is for graphics modes; $ \text{B0000H}-\text{B7FFFH}$ is for monochrome text; $\text{B8000H}-\text{BFFFFH}$ is for color text. |
| **C0000H – C7FFFH** | 32 KB | 786432 - 819199 | **Video BIOS ROM** | Contains the firmware for the video adapter (VGA/EGA/etc.). The main BIOS executes this code during POST to initialize the display. |
| **C8000H – DFFFFH** | 96 KB | 819200 - 917503 | **Option ROMs** | Reserved for other **hardware expansion cards** (e.g., network cards, SCSI/RAID controllers, specialized disk controllers) that contain their own BIOS code for initialization and boot support. |
| **E0000H – EFFFFH** | 64 KB | 917504 - 983039  | **Unused/Reserved** | Often unused or reserved for the main BIOS code/data areas, particularly in modern systems using **Shadow RAM** (where the BIOS is copied from ROM to this RAM range for faster execution). |
| **F0000H – FFFFFH** | 64 KB | 983040 - 1048575 | **System BIOS ROM** | This is where the core **BIOS firmware** resides. The initial code executed from $\text{FFFF0H}$ is physically located here. If shadowing is enabled, this range is mapped to RAM for execution speed. |

4. Search for Boot Device: The BIOS consults its configuration (stored in CMOS) to determine the boot order (e.g., Floppy, Hard Disk, CD-ROM). It then attempts to read the first sector of the first bootable device.

### 3. Loading the Bootloader

1. Read First Sector (MBR/VBR): The BIOS uses its internal disk access routines (INT 13H) to read Sector 0 (the first 512 bytes) of the selected boot device.

2. Signature Check: The BIOS checks for the valid boot signature ($\mathbf{0xAA55}$) at the very end of the 512-byte sector (offsets $\text{0x1FE}$ == 510 and $\text{0x1FF}$ == 511). If the signature is not found, the BIOS moves to the next boot device.

3. Boot Sector Load: If the signature is valid, the BIOS loads the entire 512-byte boot sector (which contains the first-stage bootloader code) into a specific memory location:
 * Physical Address: $\mathbf{0x07C00} \implies \mathbf{0x07C0}:\mathbf{0x0000}$
 * Note: IBM pc came with MSDOS - it's size is $\text{32 KiB}$. This address was chosen by the original IBM PC designers to leave $\text{1 KB}$ space ($\text{0x7C00}$ to $\text{0x7FFF}$) below the $\text{32 KiB}$ memory boundary ($\text{0x8000}$) for the bootloader, its stack, and any data it needs, while keeping the lowest memory free for the IVT and BIOS data area. 

4. Transfer Control: The BIOS finally transfers execution control to the loaded bootloader by issuing a far jump or a return instruction that sets the CPU's registers to point to the start of the newly loaded code:

    * CS:IP is set to $\mathbf{0x07C0:0x0000}$ which resolve to the physical address $\mathbf{0x07C00}$.

---

| Segment:Offset Pair  | Linear Address | What it is |
| :--- | :--- | :--- |
| **$0x0000:0x7C00$**  | $0x07C00$ | **Most Common** convention, especially for floppy/hard disk boots. |
| **$\mathbf{0x07C0:0x0000}$** | $0x07C00$ | **Alternate** convention used by some older or CD-ROM BIOS implementations. |

So best thing here is to always confirm the working system how it initilize

#### How to check the start address?


After compilation we would get a binary file, bydecoding it we will get some idea

command to decode `ndisasm -o 0x7c00 /tmp/boot.img`

```
Segment:Offset      Machine Code        Human-readable - asm
-------------------------------------------------------------
00007C00            8CC8                mov ax,cs
00007C02            8ED8                mov ds,ax
00007C04            8ED0                mov ss,ax
00007C06            BCFFFF              mov sp,0xffff
00007C09            683412              push word 0x1234
00007C0C            E80700              call 0x7c16
00007C0F            9A197CC007          call 0x7c0:0x7c19
00007C14            EBFE                jmp short 0x7c14
00007C16            B06A                mov al,0x6a
00007C18            C3                  ret
00007C19            B06A                mov al,0x6a
00007C1B            C3                  ret
00007C1C            0000                add [bx+si],al
00007C1E            0000                add [bx+si],al
00007C20            0000                add [bx+si],al
00007C22            0000                add [bx+si],al
00007C24            0000                add [bx+si],al
00007C26            0000                add [bx+si],al
...
00007DFE            55                  push bp
00007DFF            AA                  stosb
```

Here address is `00007C00` means `0x000:0x07c0`, here problem with this approach is `-o 0x7c00` we are expliciting setting the address, if we remove the option it will look like below 

```
$ ndisasm  /tmp/boot.img
00000000  8CC8              mov ax,cs
00000002  8ED8              mov ds,ax
00000004  8ED0              mov ss,ax
00000006  BCFFFF            mov sp,0xffff
00000009  683412            push word 0x1234
0000000C  E80700            call 0x16
...
000001FC  0000              add [bx+si],al
000001FE  55                push bp
000001FF  AA                stosb
```

best way to verify is to do live debugging

1. command `qemu-system-i386 -fda /tmp/boot.img -nographic -s -S` to start the program

2. In new terminal connect with gdb, and stop at address
`break *0x7c00`

`0x7c00` == `0x07c00` , we are placing the debugging as linear address, so what ever the approach it followed to init the cs, it always lead to linear address `0x7c00`

3. examine the registers
```
0x0000fff0 in ?? ()
(gdb) break *0x07c00
Breakpoint 1 at 0x7c00
(gdb) c
Continuing.

Breakpoint 1, 0x00007c00 in ?? ()
(gdb) info registers cs eip ss
ss   sse  
(gdb) info registers cs eip ss esp ds 
cs             0x0                 0
eip            0x7c00              0x7c00
ss             0x0                 0
esp            0x6f08              0x6f08
ds             0x0                 0
(gdb) 

```

As per the GDB CS:IP is setted to `0x0:0x7c00`  which is equal to `0x0000:0x7c00`

so this point CS:IP is set to $\mathbf{0x07C0:0x0000}$ historically may be correct, i don't have actual 8086 hardware and it's component to verify it's true nature

better approach is always verify

We might confuse why `IP` named as `eip`, this is knows as extended registers, that we will get to know in future, since we run in modern hardware this will be the case, i tried the same with `bochs emulator` it also set the same `cs:ip` of `0x0000:0x7c00`