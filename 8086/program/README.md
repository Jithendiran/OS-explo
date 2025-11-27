## Programs

In 8086 there only real mode is supported, linux won't run here, but we can get some grip on basics. These programs are enough to get the grip

`nasm -f bin boot.asm -o /tmp/boot.img` To compile the code

`ndisasm -o 0x7c00 /tmp/boot.img` To view the compiled code

`qemu-system-i386 -fda /tmp/boot.img -nographic` To execute the without graphics, we can't access keyboard and other stuffs

`qemu-system-i386 -fda /tmp/boot.img ` To start with graphics mode, we can access keyboard

### 1. Simple Print and Segment Initialization

Boot code will be found at `0x07c00`

in asm our 1st line will be `ORG 0x7c00`, here  `0x7c00 == 0x07c00`, because preceding 0 has no value

`0x07c00`, `0x7c000` these 2 are different address 

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

### 3. Load & Run User Code

IN 8086 there is no concept of kernel mode/ user mode and real mode / protected mode, every program have same level of authority and every thing run only in real mode

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

### 4. CALL and INT

* The $\text{CALL}/\text{RET}$ Flow (Subroutine)
  - A standard $\text{CALL}$ only pushes $\text{CS}:\text{IP}$ onto the stack. The $\text{RET}$ only restores $\text{CS}:\text{IP}$.
  - Stack: $\text{CALL}$ pushes 4 bytes ($\text{CS}$ and $\text{IP}$). $\text{RET}$ pops 4 bytes.
  - Registers: Only $\text{CS}$ and $\text{IP}$ are affected for the flow change. Flags are untouched.
  
  [Program](./4/call.asm)

* The $\text{INT}/\text{IRET}$ Flow (Interrupt)
  - An $\text{INT}$ pushes $\text{Flags}$, $\text{CS}$, and $\text{IP}$ onto the stack. The $\text{IRET}$ restores all three. This requires setting up the Interrupt Vector Table (IVT) first. 
  - Stack: $\text{INT}$ pushes 6 bytes ($\text{Flags, CS, and IP}$). $\text{IRET}$ pops 6 bytes.
  - Flags: $\text{INT}$ automatically disables interrupts (clears $\text{IF,TF}$). $\text{IRET}$ automatically restores the original Flag state (re-enabling interrupts).

  while executing interrupt, hardware `INTR` cannot happen, for more info [Read](../README.md#interrupt-hierarchy-and-scenarios) 

  [Program](./4/int.asm)

### 5. Install Custom ISR (INT 0x09)

Keyboad's hardcoded interrupt is `Type 0x09`, we will be writing a small custom function, which will over write the existing  

IVT is 4 bytes, 1st two bytes have offset and second 2 bytes will have the segment

[Read](../InOut.md)

`in` command to fetch from address

When we type some thing keyboard controller will place the scaned code at `0x60`, using `in` we are reading, if we don't read buffer will not be empties and interrupt will be in locked stage


`out` command to send to address

Once we read we will print `K` on screen and send `0x20` to PIC to indicate `EOI`, don't confuse `out 0x20 al`,`out 0x20 <reg>` this 20 indicate CPU send command to PIC, reg will hold the command in our example it is `0x20` which mean `EOI`, `iret` mean return from interrupt 

[Program](./custom_iv.asm)

### 6. User Process, Stack Switching and Exit
   do maual stack switch

   You must update both $\text{SS}$ and $\text{SP}$ atomically. If you change $\text{SS}$ and an interrupt occurs before you change $\text{SP}$, the interrupt will use the new $\text{SS}$ with the old $\text{SP}$, causing a crash (stack overflow/underflow). You must disable interrupts before changing $\text{SS}$ and $\text{SP}$.


   Idea is to mimic kernel and user process

   why are we using int 0x80, iret over call and ret?
   we can achieve the same result by using using call and return
   idea is to when we are handling the kernel code it has to disable the interrupts, it has to focus only on kernel part of code

   call, ret vs int, iret
   same program  
   
   `int 0x80` is available for user, when interrupt `0x80` is hitted based on the `ah` value perform the action

   if ah == 0x01 print

   if ah == 0x02 exit

   `nasm -f bin 5/loader.asm -o /tmp/boot1.bin`

   `nasm -f bin 5/user.asm -o /tmp/boot2.bin`

   `cat /tmp/boot1.bin /tmp/boot2.bin > /tmp/boot.img`

   `qemu-system-i386 -fda /tmp/boot.img -nographic`

### 7. Basic PIC Setup
        

        * memory mapping
### 8. I/O Port Access
        * Key Concept: Memory-Mapped vs. Port I/O
### 9. Simple Timer Interrupt
        switch between 2 tasks
        use 2 c programs


## Refer

https://grandidierite.github.io/bios-interrupts/