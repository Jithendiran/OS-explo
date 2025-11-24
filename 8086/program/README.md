## Programs

In 8086 there only real mode is supported, linux won't run here, but we can get some grip on basics. These programs are enough to get the grip

### 1. Simple Print and Segment Initialization

**Segment Initialization (CS, DS, SS)**
Point the segment where we need, Stack segment is used by local variable and interrupt. stack will grow downward, if we fill up many thing it might over write *IVT*

| $\mathbf{\text{AH}}$ **Value** | **Function Description** | $\mathbf{\text{Key Input Registers}}$ | $\mathbf{\text{Key Output Registers}}$ |
| :--- | :--- | :--- | :--- |
| $\mathbf{0\text{x}00}$ | **Set Video Mode** | $\text{AL}$: The desired video mode number (e.g., $0\text{x}03$ for $80 \times 25$ color text). | None (Action completes) |
| $\mathbf{0\text{x}01}$ | **Set Cursor Type** | $\text{CH}$: Cursor start line (scan line). $\text{CL}$: Cursor end line (scan line). | None (Action completes) |
| $\mathbf{0\text{x}02}$ | **Set Cursor Position** | $\text{BH}$: Display page number. $\text{DH}$: Row. $\text{DL}$: Column. | None (Action completes) |
| $\mathbf{0\text{x}03}$ | **Read Cursor Position** | $\text{BH}$: Display page number. | $\text{DH}$: Row. $\text{DL}$: Column. $\text{CH}$: Cursor start line. $\text{CL}$: Cursor end line. |
| $\mathbf{0\text{x}06}$ | **Scroll Window Up** | $\text{AL}$: Lines to scroll ($\text{0}$ clears window). $\text{CH}, \text{CL}$: Top/Left corner. $\text{DH}, \text{DL}$: Bottom/Right corner. | None (Action completes) |
| $\mathbf{0\text{x}0\text{C}}$ | **Write Graphics Pixel** | $\text{AL}$: Color value. $\text{CX}$: Column ($\text{X}$). $\text{DX}$: Row ($\text{Y}$). | None (Action completes) |
| $\mathbf{0\text{x}0\text{E}}$ | **Write Character (Teletype)** | $\text{AL}$: ASCII character to display. $\text{BH}$: Display page. $\text{BL}$: Foreground color (in graphics mode). | None (Action completes) |

$\text{CF} = 0 \implies$ success

$\text{CF} = 1 \implies$ Failure

[Program](./simple_print.asm)

### 2. Read Hard Disk Sector

**BIOS INT 0x13** (Disk I/O)

**Where it will used?**
1. To copy kernel image
2. Some times MBR program may exceed 512 bytes, in that case we will split the boot up function into two

**$\text{CHS}$ (Cylinder-Head-Sector) Addressing**
* $\text{C}$ (Cylinder): A collection of all tracks that are the same distance from the spindle across all platters. limit: 0 to 1023
* $\text{H}$ (Head): The number of the read/write head (and thus the platter surface) being used. Limit: 0 to 255
* $\text{S}$ (Sector): The individual, smallest addressable block of data on a track (usually 512 bytes), numbered starting from 1. Limit: 1 to 63

maximum addressable size of approximately $\mathbf{8.4 \text{ GiB}}$

| Register | Purpose (Input) | $\text{CHS}$ Value | Output/Result |
| :--- | :--- | :--- | :--- |
| **$\text{AH}$** | $0x00 \rightarrow$ reset, $0x02 \rightarrow $ Read sector, $0x03 \rightarrow$ write sector, $\cdots$ | $\text{N/A}$ | **Error Status** (if $\text{CF}=1$) |
| **$\text{AL}$** | **Number of Sectors** | $\text{N/A}$ | **Actual Sectors Read/Written** (usually same as input) |
| **$\text{CH}$** | **Cylinder Number (Low 8 Bits)** | **Cylinder (C)** | $\text{N/A}$ (May be preserved) |
| **$\text{CL}$** | **Sector Number (6 Bits) & Cylinder (High 2 Bits)** | **Sector (S)** | $\text{N/A}$ (May be preserved) |
| **$\text{DH}$** | **Head Number** | **Head (H)** | $\text{N/A}$ (May be preserved) |
| **$\text{DL}$** | **Drive Number** | $\text{N/A}$ | $\text{N/A}$ (Boot drive is often returned in $\text{DL}$ from the $\text{BIOS}$) |
| **$\text{ES}:\text{BX}$** | **Data Buffer Address** | $\text{N/A}$ | Segment ($\text{ES}$) and Offset ($\text{BX}$) of the memory buffer to/from which data is transferred. |

$\text{CF} = 0 \implies$ success

$\text{CF} = 1 \implies$ Failure

**$\text{LBA}$ (Logical Block Addressing)**
* Instead of three coordinates, $\text{LBA}$ uses a single integer index to address each sector (or "block") on the disk.
* The first sector is $\mathbf{\text{LBA } 0}$, the second is $\mathbf{\text{LBA } 1}$, and so on, up to the last sector

maximum addressable size of approximately
- 28-bit LBA $\implies$ $\mathbf{8.4 \text{ GiB}}$ 
- 48-bit LBA $\implies$ $\mathbf{144 \text{ PetaBytes}}$ 

[Program](./read_hard_disk.asm)

### 3. Load & Verify User Code

This is same as above program, written in different way

1. `nasm -f bin 3/load.asm -o /tmp/boot1.bin`
2. `nasm -f bin 3/user.asm -o /tmp/boot2.bin`
3. `cat /tmp/boot1.bin /tmp/boot2.bin > /tmp/boot.img`
4. `qemu-system-i386 -fda /tmp/boot.img -nographic`

```
ji@ji-MS-7E26:~$ ls -la /tmp/bo*
-rw-rw-r-- 1 ji ji 512 Nov 24 00:00 /tmp/boot1.bin
-rw-rw-r-- 1 ji ji  84 Nov 24 00:00 /tmp/boot2.bin
-rw-rw-r-- 1 ji ji 596 Nov 24 00:00 /tmp/boot.img
```

[Program1](./3/load.asm)
[Program2](./3/user.asm)

### 4. Transfer Control
### 5. User Process Exit
### 6. Print from User Space
### 7. Install Custom ISR (INT 0x09)
### 8. Basic PIC Setup
### 9. Simple Timer Interrupt
        switch between 2 tasks
### 10. I/O Port Access
### 11. Stack Switching

## Refer

https://grandidierite.github.io/bios-interrupts/