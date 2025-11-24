# 8086

The 8086 microprocessor's architecture is built around segmentation, a collection of 16-bit registers for various purposes, and a 16-bit Flag register to reflect the CPU's status and control operations. It has $1\text{ MB RAM}$, 20 bit address bus

[Refer How 8086 start](./startup.md)

## Memory Segmentation

The 8086 has a 20-bit address bus, allowing it to address $2^{20} = 1\text{ MB}$ of memory. However, its registers are only 16-bit. **Segmentation** is the technique used to access the 1 MB memory space by logically dividing it into $64\text{ KB}$ segments

- A Bit is a single binary digit (0 or 1).
- 8 bits make up 1 Byte (e.g., $1111\ 1111_2$)
- 16 bits make up 2 Bytes (e.g., $1111\ 1111\ 1111\ 1111_2$)

Every 4 bits can be represented by a single hexadecimal digit (0-F).
16 bits is $16/4 = 4$ hexadecimal digits.
- $16\text{-bit range: } 0000\ 0000\ 0000\ 0000_2 \text{ to } 1111\ 1111\ 1111\ 1111_2$
- Hex Range: $0000\text{H}$ to $FFFF\text{H}$, $H$ means hexa

### How 16 Bits Access 64 KB?
- 16-bit register can hold $2^{16}$ different values
- A 16-bit binary number ranges from $0000\text{H}$ to $FFFF\text{H}$ (in hexadecimal).
- A 16-bit register can address 65,536 unique memory locations, which is 64 KB.
- In computer memory, each location holds 1 byte.

### To access 1 MB (1,048,576 Bytes) how many bits needs?

$2^{20} = 1,048,576$ bytes, since single register can hold max of 16 bit we need 2 registers

**How 2 registers are used?**
1. Segment Address (16 bits): This value, stored in a segment register, acts as the starting point or base address for the 64 KB segment. **upper 16 bits**
2. Offset Address (16 bits): This value acts as the displacement or index from that starting point, up to 64 KB away. **lower 4 bits**

$$16 + 4 = 20$$

$$PA = (\text{Segment Address} \times 10\text{H}) + \text{Offset Address}$$

- 
$$\text{Segment Address} \times 10\text{H}$$
Segment Address = 07C0
$$07\text{C}0\text{H} \times 10\text{H} = \mathbf{07\text{C}00\text{H}}$$

- 
$$ + \text{Offset Address}$$
Offset Address = 0020

$$\begin{aligned} &\quad 07\text{C}00\text{H} \\ + &\quad 00020\text{H} \\ \hline &\quad \mathbf{07\text{C}20\text{H}} \end{aligned}$$

The 8086 only uses the lowest 20 bits of this sum, dropping any carry out of the 20th bit.

The final 20-bit address is $07C20$.

Segment are base address and offset are index in arrays it will be like this
`segment[offset]`

in asm we reffer like this `07c0`:`0020`

## Registers
The 8086 microprocessor is a 16-bit processor with a comprehensive set of 14 registers, all 16 bits wide, categorized into four groups: `General Purpose`, `Segment`, `Pointer & Index`. It also has a 16-bit `Flag Register` with 9 active flags.

### General Purpose Registers (Data Registers)

These four registers can be used as a whole (16-bit) or split into two separate 8-bit registers (High and Low bytes). They are primarily used for arithmetic, logic, and data transfer operations.

| Register | 16-bit Name | 8-bit Parts | Primary Function |
| :--- | :--- | :--- | :--- |
| **A** | **AX** (Accumulator) | **AH** (High), **AL** (Low) | Favored for arithmetic, I/O operations, and data manipulation. |
| **B** | **BX** (Base) | **BH** (High), **BL** (Low) | Often used as a **Base Register** to hold the offset address of data in memory. |
| **C** | **CX** (Count) | **CH** (High), **CL** (Low) | Used as a **Counter** in loop instructions (`LOOP`) and for shift/rotate instructions. |
| **D** | **DX** (Data) | **DH** (High), **DL** (Low) | Used for **I/O port addressing** and for 32-bit arithmetic operations. |

**DX brief**

* I/O Port Addressing

    When the processor needs to perform Input/Output (I/O) operations using the IN (Input) or OUT (Output) instructions, the DX register is used to hold the 16-bit address of the I/O port.

    This allows the processor to communicate with devices outside the main memory, such as a keyboard controller, a timer, or an old-style graphics card.

* Extender for 32-bit Operations

    When dealing with large numbers, the 16-bit DX register is paired with the 16-bit AX (Accumulator) register to handle 32-bit values.

    How limit of segment is determined?
    Build brick by brick

### Segment Registers

These four registers hold the **starting addresses** (segment base addresses) of the four currently accessible $64\text{ KB}$ memory segments.

| Register | Name | Purpose |
| :--- | :--- | :--- |
| **CS** | **Code Segment** | Holds the base address of the segment containing the program instructions. |
| **DS** | **Data Segment** | Holds the base address of the segment containing most of the program's data variables. |
| **SS** | **Stack Segment** | Holds the base address of the segment containing the program's stack. |
| **ES** | **Extra Segment** | An additional data segment register, often used as a destination pointer in string operations. |

Imagine the 1 MB of RAM is a very long bookcase. The four segment registers (CS, DS, SS, ES) are just four bookmarks, each marking the start of a 64 KB section (a segment). You can move these four bookmarks anywhere in the bookcase to focus on different sections, but the entire bookcase (the 1 MB) is still there.

### Pointer and Index Registers

These registers typically hold the **Offset Address** within a segment.

| Register | Name | Purpose | Default Segment |
| :--- | :--- | :--- | :--- |
| **IP** | **Instruction Pointer** | Holds the offset of the **next instruction** to be executed in the **CS** segment. | **CS** |
| **SP** | **Stack Pointer** | Holds the offset of the **top of the stack** in the **SS** segment. | **SS** |
| **BP** | **Base Pointer** | Holds an offset in the **SS** segment, often used to access parameters/local variables on the stack. | **SS** |
| **SI** | **Source Index** | Holds the offset of the **source** data in string operations. | **DS** |
| **DI** | **Destination Index** | Holds the offset of the **destination** data in string operations. | **ES** |

### Flag Register

The 8086 uses a 16-bit Flag Register, where **9 bits are actively used** as flags to indicate the status of the CPU after an arithmetic/logic operation (Status Flags) or to control its operation (Control Flags).

#### Status Flags (6 Flags)

These flags are automatically set or reset by the ALU after an operation to reflect the result's properties.

| Flag | Full Name | Bit | Description |
| :--- | :--- | :--- | :--- |
| **CF** | **Carry Flag** | D0 | Set (1) if a carry/borrow is generated out of the most significant bit (MSB) during an unsigned operation. |
| **PF** | **Parity Flag** | D2 | Set (1) if the result's low 8 bits have an **even** number of '1's (even parity). |
| **AF** | **Auxiliary Carry Flag** | D4 | Set (1) if a carry/borrow is generated out of bit 3 into bit 4 (used primarily for BCD arithmetic). |
| **ZF** | **Zero Flag** | D6 | Set (1) if the result of an operation is **zero**. |
| **SF** | **Sign Flag** | D7 | Copies the value of the MSB of the result (1 for negative, 0 for positive in signed operations). |
| **OF** | **Overflow Flag** | D11 | Set (1) if the result of a **signed** operation is too large (overflow) or too small (underflow) to fit in the destination. |

#### Control Flags (3 Flags)

These flags are set or reset by the programmer to control the CPU's operation.

| Flag | Full Name | Bit | Description |
| :--- | :--- | :--- | :--- |
| **TF** | **Trap Flag** | D8 | Set (1) to enable **single-step** mode for debugging, causing an interrupt after every instruction. |
| **IF** | **Interrupt Flag** | D9 | Set (1) to enable maskable hardware interrupts; Reset (0) to disable them (mask interrupts). |
| **DF** | **Direction Flag** | D10 | Controls the direction of string operations: **0** for auto-increment (low address to high), **1** for auto-decrement (high address to low). |

## Interrupt

An interrupt is a signal to the microprocessor (CPU), generated by either hardware or software, that causes the CPU to temporarily halt its normal program execution and diverts the CPU's attention to a different piece of code called the Interrupt Service Routine (ISR) or Interrupt Handler, which is specifically designed to deal with the event. Once the ISR finishes, the CPU resumes the original program from exactly where it left off.

8086 microprocessor supports up to 256 different interrupt types (numbered 0 to 255).

[Refer 1](https://yassinebridi.github.io/asm-docs/8086_bios_and_dos_interrupts.html)

[Refer 2](https://wiki.osdev.org/Interrupt_Vector_Table)

Interrupt Vector Table (IVT), which is located in the first 1 Kilobyte (KB) of memory (addresses $00000H$ to $003FFH$), It holds the ISR for each interrupt

* Interrupt Vectors: The table contains 256 entries. Each entry, called an interrupt vector, is 4 bytes long and stores the segmented address (a 16-bit Code Segment, CS, and a 16-bit Instruction Pointer, IP) of the Interrupt Service Routine (ISR) for a specific interrupt type.
* Total Size: $256 \text{ entries} \times 4 \text{ bytes/entry} = 1024 \text{ bytes} = 1\text{ KB}$.

The 256 interrupt types are categorized as follows:

| Type Range | Count | Usage |
| :---: | :---: | :--- |
| **0 to 4** | 5 | **Dedicated Interrupts** for CPU exceptions/fixed operations (e.g., Divide by Zero, Non-Maskable Interrupt (NMI), Breakpoint, Overflow). |
| **5 to 31** | 27 | **Reserved by Intel** for future use (though some became defined in later x86 processors). |
| **32 to 255** | 224 | **Available for User** (user-defined software interrupts via the `INT n` instruction and hardware interrupts via the `INTR` pin). |

### The Interrupt Process
When an interrupt occurs, the CPU performs the following sequence:

1. Save Context: The CPU pushes the current state of its crucial registers, primarily the Flags Register (FLAGS), the Code Segment (CS), and the Instruction Pointer (IP), onto the stack. This saves the return address (CS:IP) and the status of the program being interrupted.
2. Disable/Clear Flags: The CPU typically clears the Interrupt Flag (IF) and the Trap Flag (TF) to prevent new maskable interrupts or single-stepping during the ISR.
3. Identify Handler: The CPU determines the Interrupt Type Number (a value from 0 to 255).9 It uses this number as an index into the Interrupt Vector Table (IVT), which is stored in the first $1\text{ KB}$ of memory ($0000\text{H}$ to $03\text{FFH}$).
4. Load ISR Address: The IVT entry contains the 4-byte (16-bit CS and 16-bit IP) segmented address of the corresponding ISR. The CPU loads these new CS:IP values.
5. Execute ISR: The CPU executes the ISR.
6. Return: The ISR ends with an IRET (Interrupt Return) instruction, which pops the saved IP, CS, and FLAGS back off the stack, restoring the original program state and resuming normal execution.

### Types of Interrupts in the 8086

#### 1. Hardware Interrupts (External)

Generated by external I/O devices or control signals sent to the CPU's pins.

| Type | Pin | Description | Maskable |
| :--- | :--- | :--- | :--- |
| **Maskable** | **INTR** (Interrupt Request) | Used by devices (keyboard, timer, etc.) to request service. Can be **enabled/disabled** by setting/clearing the **Interrupt Flag (IF)** using `STI`/`CLI` instructions. | **Yes** |
| **Non-Maskable** | **NMI** (Non-Maskable Interrupt) | Reserved for critical, high-priority events like power failure or memory errors. **Cannot be disabled** by software. It is always Type 2. | **No** |

#### 2. Software Interrupts (Internal)

These are non maskable

Triggered by program instructions or by the CPU itself due to exceptional conditions.

| Type | Source | Description |
| :--- | :--- | :--- |
| **Programmed** | **`INT n` instruction** | An intentional instruction written in the program to call an ISR, where $n$ is the interrupt type number. |
| **Exceptions/Traps** | **Instruction Execution** | Generated automatically by the CPU when an error condition occurs: |
| | **Type 0** | **Divide Error:** Generated if division by zero is attempted. |
| | **Type 1** | **Single Step:** Generated after every instruction if the **Trap Flag (TF)** is set (used for debugging). |
| | **Type 3** | **Breakpoint:** Caused by the single-byte instruction `INT 3` (used by debuggers). |
| | **Type 4** | **Overflow:** Caused by the `INTO` instruction if the **Overflow Flag (OF)** is set. |

### How the System Knows an Interrupt Occurs

The CPU is constantly checking for interrupt signals in two main ways:

1. Hardware Pins (External Events)
The 8086 has dedicated pins that external hardware devices use to signal an interrupt:

    * NMI (Non-Maskable Interrupt) Pin: The CPU detects a rising edge (a change from low to high voltage) on this pin and immediately initiates a Type 2 interrupt. This cannot be ignored by the software.

    * INTR (Interrupt Request) Pin: The CPU checks the state of this pin at the end of every instruction. If the Interrupt Flag (IF) is set and the INTR pin is active, the CPU initiates an interrupt process

2. Instruction Execution (Internal Events)

    * Software Interrupts (INT n): The CPU recognizes it as part of instruction decoding.
    * CPU Exceptions: The Execution Unit (EU) detects error conditions during an instruction's execution, such as a divide-by-zero (Type 0) or an attempt to use the INTO instruction when the Overflow Flag (OF) is set (Type 4).

[Input/Output operations explained](./InOut.md)

### How the CPU Identifies the Interrupt Type

Once the CPU detects an interrupt, it needs to know which of the 256 possible handlers it should jump to. This is done by obtaining an 8-bit number called the Interrupt Type Number (or Vector Number)

| Interrupt Source | How the CPU Gets the Type Number |
| :--- | :--- |
| **Software (`INT n`)** | The number $n$ is part of the instruction itself (e.g., in `INT 13H`, the type is $13\text{H}$). |
| **NMI** | This is a fixed, non-programmable interrupt **Type 2**. |
| **Exceptions (e.g., Divide Error, single/Step trap,..)** | These are fixed, dedicated types wired into the CPU's internal logic (e.g., Divide Error is always **Type 0**, Trap is **Type 1**). |
| **Maskable Hardware (`INTR`)** | After the CPU acknowledges the interrupt by pulsing the **$\overline{INTA}$ (Interrupt Acknowledge)** pin, the external **Programmable Interrupt Controller (PIC)** (like the 8259A chip) places the 8-bit interrupt type number onto the data bus for the CPU to read. |

Once the CPU has the Type Number, it calculates the address of the corresponding Interrupt Service Routine (ISR) using the Interrupt Vector Table (IVT):
$$\text{IVT Address} = \text{Type Number} \times 4$$

### How the NMI Differentiates Sources

The differentiation is achieved by making the **ISR for Type 2** a "master" routine that uses software to inspect the system's external hardware registers to determine the *exact* cause of the interrupt.

#### Step 1. External Hardware Latching

* The **NMI pin** on the 8086 is a *single input*. When any critical event occurs (memory error, power monitor trip, etc.), the external circuitry is designed to send a signal to this single NMI pin.
* The hardware that detected the fault (e.g., a memory controller for parity, a voltage monitor for power) also **latches** the status of the fault in a dedicated **Status Register** located at an I/O port address.

#### Step 2. The NMI-ISR Polling Routine

When the CPU receives the NMI:

1.  The CPU executes its built-in NMI procedure, which pushes registers to the stack and jumps to the single, fixed **Type 2 ISR** address ($00008H$).
2.  The **Type 2 ISR** begins execution. The first thing it does is **read the external Status Register** via an I/O port instruction (like `IN`).
3.  The ISR then **checks the bits** in that Status Register:
    * If bit 0 is set, it might mean a **Memory Parity Error**.
    * If bit 1 is set, it might mean a **Power Fail Warning**.
    * And so on.
4.  Based on the status bits it reads, the ISR branches to the appropriate **sub-routine** to handle the specific fault (e.g., start a graceful shutdown for a power failure, or halt the system for a fatal memory error).


### What Registers are Saved?
The 8086 CPU automatically saves only the minimum context required to ensure the correct return to the interrupted program: FLAG, CS:IP

The CPU does not automatically save the General Purpose (AX, BX, CX, DX) or Index/Pointer (SI, DI, BP) registers because The ISR may only need to use one or two general registers. Saving all of them every time would be wasteful.

#### The Role of the ISR and Stack
* The ISR's Responsibility: If the Interrupt Service Routine (ISR) needs to use any general registers (AX, BX, etc.) or index registers (SI, DI, etc.), the programmer must explicitly save them to the stack at the start of the ISR using PUSH instructions and restore them at the end using POP instructions.

* The Stack is Essential: The entire interrupt mechanism relies on the stack. The CPU pushes the FLAGS, CS, and IP onto the stack using the current SS:SP pair. The stack must be configured correctly and have enough space to handle the interrupt and any registers the ISR might push manually.

---

## Boot device/disk

When we power on system BIOS will call boot loader, boot loader will select the bootable disk to boot

How boot loader decide which disk is bootable?
If a disk's 1st 512byte is **MBR**, then it is bootable device

What MBR contains?
Small code which fit into 0 - 509 bytes, 510 and 511 is a special bytes, which makes this segment as **MBR**, which will store a signature in 510 and 511 location `0xAA55`, if the disk don't have this signature then boot loader will check for next device

BIOS always place boot MBR code from `0x07c00` memory location

To execute  `qemu-system-i386 -fda /tmp/boot.img`

[Programs](./program/README.md)