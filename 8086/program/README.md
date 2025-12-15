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

**How stack grows?**

As we know stack always grow in down wards, if stack start `ss:sp` = `0x0000:0xffff`, it's linear address is `0x0ffff == 0xffff`, if it grow by 2 bytes next address is `0xffff - 2 = 0xfffd`

Here the sequence of stack address for 2 bytes growth

$$\text{0xffff} \rightarrow \text{0xfffd} \rightarrow \text{0xfffb} \rightarrow \text{0xfff9} \rightarrow \text{0xfff7} \rightarrow \text{0xfff5} \rightarrow \text{0xfff3} \rightarrow \cdots $$

> [!TIP] 
> specia; gdb functions are defined for this program, execute like thi ` gdb -x ./4/gdb_helper.gdb` and give `continue`


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


`in` command to fetch from address

When we type some thing keyboard controller will place the scaned code at `0x60`, using `in` we are reading, if we don't read buffer will not be empties and interrupt will be in locked stage


`out` command to send to address

Once we read we will print `K` on screen and send `0x20` to PIC to indicate `EOI`, don't confuse `out 0x20 al`,`out 0x20 <reg>` this 20 indicate CPU send command to PIC, reg will hold the command in our example it is `0x20` which mean `EOI`, `iret` mean return from interrupt 

[Program](./custom_iv.asm)

### 6. User Process, Stack Switching and Exit

#### Memory plan

| Hex Address Range | Decimal Address Range | Size | Note |
| :--- | :--- | :--- | :--- |
| 00600 – 22FFC | 1536 – 143356 | $\approx 138.5\text{KB}$ | Kernel Code |
| 22FFD – 54FFD | 143357 – 347133 | $\approx 200\text{KB}$ | Kernel Stack |
| 54FFE – 6DFFE | 347134 – 449534 | $\approx 100\text{KB}$ | User Code |
| 6DFFF – 9FFFF | 449535 – 655359 | $\approx 200\text{KB}$ | User Stack |

The above table have some issues, when executing inside `int 0x10` code 

when `ss = 0x9FFF` and `sp = 0x000f`, after 12 by push value become `sp = 0x3` now current stack top `0x9fff3`, at this stage `push dword [cs:0x60e4]` code will execute it will push 4 bytes, so 4 - 3 = -1, address are repesented using unsigned values so it becomes `-1 == 0xffff`, so stack changed from  `0x9fff3` to `ss = 0x9FFF sp = 0xffff = 0xaffef`, but the expected address is `0x9FFEF`, it is not possible to mention -1 in address form so stack segment crashed

To resolve the issue instead of using `ss = 0x9FFF sp = 0x000f`, use  `ss = 0x9000 sp = 0xffff` both will give same result

#### program plan

The system's operation is divided into three main stages: **Boot, Kernel Initialization, and Application Run**.

##### 1. Boot and Kernel Startup

The process begins when the computer is turned on:

* The **Boot Loader** (a tiny program in the first disk sector) will load the **Kernel Code** into memory starting at the address **$0x00600$**.
* The Boot Loader then immediately transfers control (jumps) to the Kernel Code to start the operating system.
* Once running, the Kernel Code first sets up its own dedicated **Kernel Stack**.
* Next, the Kernel Code loads the **User Program** (application) into memory, starting at address **$0x54\text{FFE}$** .
* Finally, the kernel prepares a separate **User Stack** for the application.

##### 2. Application Run and System Calls

The kernel hands over control to the User Program, which runs on its own User Stack. When the application needs to perform a task the hardware or OS controls (like printing to the screen):

* The User Program makes a **System Call** by triggering the **$x80$ interrupt**.
* The CPU stops the User Program and immediately jumps to the **Kernel's Interrupt Handler** to process the request.
* The Kernel reads the **$\text{AH}$ register** to figure out which service the User Program needs.

##### 3. Service Execution

The kernel's $x80$ interrupt handler performs the requested service:
 The **$\text{DX}:\text{SI}$** registers contain the **memory address** of the text string to be printed. The kernel prints the text string until it sees a null character (the end-of-string marker).


Once a service is complete (except for Exit), the kernel returns control to the User Program so it can continue running.


`nasm -f bin 8086/program/5/loader.asm -o /tmp/load.img && nasm -f bin 8086/program/5/kernel.asm -o /tmp/ker.img && nasm -f bin 8086/program/5/user.asm -o /tmp/usr.img  && cat /tmp/load.img /tmp/ker.img /tmp/usr.img > /tmp/boot.img`

`qemu-system-i386 -fda /tmp/boot.img -nographic`

To get more info on debug follow the steps after gdb connection

`(gdb) source 8086/program/5/helper.py`

`(gdb) dash16`

### 7. Basic PIC Setup

In 8086 interrupts are calssified as

1.  **Processor-Defined Exceptions (0-4):** Used for critical errors like divide-by-zero or debug features.
2.  **Reserved/Hardware Interrupts (5-31):** Intel reserved for future interrupts.
3.  **User interrupts (32/Higher):** available for users

The  $\text{PIC}$ maps $\text{IRQ} \ 0 \text{-} 7$ to $\text{Interrupts } 0\text{x}08 \text{-} 0\text{x}0\text{F}$, in 8086 it may not cause problem but it uses the reserved space for future implementations, so it is the best practice to move the $\text{PIC}$ mappings to user interrupts region, user interrupt starts from $0x20$(32)

**why should remap?**

#### 1. The Reality for the 8086

In the original **8086/8088** processor and the original IBM PC architecture, the only reserved CPU exceptions are vectors $00h$ through $04h$.

| Vector (Hex) | Purpose on 8086 | Hardware IRQ Default |
| :---: | :---: | :---: |
| $00h$ | Divide by Zero | - |
| $01h$ | Single Step (Debug) | - |
| $02h$ | Non-Maskable Interrupt (NMI) | - |
| $03h$ | Breakpoint (INT 3) | - |
| $04h$ | Overflow (INTO) | - |
| **$08h$** | **Reserved by Intel** | **IRQ 0 (Timer)** |
| **$09h$** | **Reserved by Intel** | **IRQ 1 (Keyboard)** |
| ... | ... | ... |
| **$0Fh$** | **Reserved by Intel** | **IRQ 7 (Printer)** |

The hardware interrupts ($08h$ to $0Fh$) fall into the range that Intel had simply marked as **"Reserved"** for *future processor use*, but the 8086 CPU itself didn't generate any interrupts in that range.

**Conclusion for 8086:** Running DOS on an 8086/8088 machine *without* remapping would not cause an immediate system crash due to a CPU exception. The hardware IRQs would be handled correctly at $08h$ to $0Fh$, and the reserved vectors in the $05h-07h$ and $0Ah-1Fh$ ranges would simply remain unused.

#### 2. The Reason for the IBM PC's Flaw (Compatibility)

The IBM PC design decision to use the reserved $08h-0Fh$ range for the 8259 PIC's output was essentially an **architectural flaw**.

When the **80286** processor was released, it introduced new exceptions, and the later **80386** introduced even more, including the famous **General Protection Fault (GPF)**.

| New CPU Exception (286/386+) | Vector (Hex) | Conflicting Original IRQ |
| :---: | :---: | :---: |
| Invalid Opcode | **$06h$** | (None in the hardware range) |
| Device Not Available | **$07h$** | (None in the hardware range) |
| Double Fault | **$08h$** | **IRQ 0 (Timer)** |
| Invalid TSS | **$0Ah$** | **IRQ 2 (Cascade)** |
| Segment Not Present | **$0Bh$** | **IRQ 3 (COM2)** |
| Stack Segment Fault | **$0Ch$** | **IRQ 4 (COM1)** |
| General Protection Fault | **$0Dh$** | **IRQ 5 (LPT2/Sound Card)** |

**The Fatal Conflict:** If the system wasn't re-mapped, a General Protection Fault ($0Dh$) would trigger the **Hard Disk/LPT2 Interrupt Service Routine (ISR)**, leading to a catastrophic crash.

commands for PIC for example x20, x21? what are other and it's uses?


### 8. Direct Video Memory Access (MMIO)

  Concept: Directly writing text to memory location $\mathbf{0\text{xB}800:0\text{x}0000}$ (CGA/VGA text buffer) instead of using the slow $\text{INT } 0\text{x}10$ BIOS service.

  Benefit: This contrasts sharply with $\text{Port I/O}$ ($\text{in}/\text{out}$) and shows how a program can be much faster by directly accessing hardware memory.

### 9. Simple Timer Interrupt
        switch between 2 tasks
        use 2 c programs


## Refer

https://grandidierite.github.io/bios-interrupts/