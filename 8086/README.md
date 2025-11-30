# 8086

The 8086 is a 16-bit microprocessor that operates based on a fundamental principle known as the fetch-decode-execute cycle. A unique feature of the 8086 is its internal architecture, which is logically divided into two units that work in parallel to improve performance:

## A. Bus Interface Unit (BIU)
The BIU handles all memory and I/O (Input/Output) access. Its primary responsibilities are:
* Address Generation: It calculates the 20-bit physical memory address using the segment register and offset value.
* Bus Control: It manages the Address Bus (20 lines) and the Data Bus (16 lines) to communicate with external devices.
* Instruction Fetch: It prefetches up to 6 bytes of instruction code from memory (RAM) and stores them in a Queue. This is crucial for pipelining.

## B. Execution Unit (EU)
The EU is responsible for decoding and executing instructions. Its primary responsibilities are:
* Instruction Decoding: It takes the instruction bytes from the BIU's queue.
* Execution: It uses the Arithmetic Logic Unit (ALU) to perform the arithmetic and logical operations specified by the instruction.
* Register Management: It manages the general-purpose registers (like $\text{AX}$, $\text{BX}$, $\text{CX}$, $\text{DX}$) for data manipulation and addressing.
* Flag Management: It updates the Flag Register after an ALU operation to reflect the status of the operation (e.g., Carry, Zero, Sign).

The BIU fetches the next instructions while the EU is currently executing the previous instruction. This overlap is known as pipelining, and it allows the 8086 to process instructions faster than if the two actions happened strictly one after the other.

## 8086 PINS

The 8086 is a 40-pin chip. The pins are generally categorized by their function. Since the 8086 can operate in two different modes—Minimum Mode (for small systems with one processor) and Maximum Mode (for multi-processor systems)—some pins have dual functions.

Here we mostly focus only on Minimum Mode

[Refer](./pin.md)

## Bus

A bus is a set of electrical conductors (wires/pins) used to transmit data between components inside a computer system. The 8086 uses a system bus comprised of three main parts:

1. Address Bus: Used by the CPU (or DMA) to specify the physical memory address or I/O port it wants to read from or write to. The 8086 has a 20-bit address bus (lines $\text{A}_0$ to $\text{A}_{19}$), allowing it to address $2^{20} = 1\text{MB}$ of memory.

2. Data Bus: Used to transfer data between the CPU and memory/I/O devices. The 8086 has a 16-bit data bus (lines $\text{D}_0$ to $\text{D}_{15}$).

3. Control Bus: Used to carry control signals that govern the activities on the system, such as $\text{READ}/\text{WRITE}$ signals, $\text{Ready}$, and $\text{Interrupt}$ signals.

## Bus Control Terminology

| Terminology | Simple Meaning | Doer (Initiator) | Recipient (Target) | Example Statement | Explanation of Roles |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Latch** | To **capture and hold** a changing value (like an address) at a specific moment. | External **Latch Circuit** (e.g., 8282 chip) | Memory or I/O device | "The external latch circuit must **latch** the address during T1." | **Doer:** The Latch circuit physically captures the data. **Recipient:** The captured address is for the Memory chip's use. |
| **Strobe** | A brief, timed **signal pulse** used to trigger an action (specifically the latching of data/address). | **CPU** (e.g., the $\text{ALE}$ pin) | External Latch Circuit | "The CPU **strobes** the $\text{ALE}$ signal HIGH to indicate the address is ready." | **Doer:** The CPU sends the timing signal. **Recipient:** The Latch circuit receives the signal and performs the latching action. |
| **Assert** | To **activate** a signal by driving the pin to its active voltage level (usually Low for 8086 control signals). | **CPU** (or sometimes DMA/Peripheral) | Recipient Chip (Memory/I/O) | "The CPU **asserts** the $\text{RD}'$ signal to start a memory read." | **Doer:** The CPU sets the pin to the active state (LOW). (In this example it is LOW, for some other operations it will be HIGH. It depends on the pins, here activate doesn't mean power up, it means process has to start. Some operation will start on low signal, some on high) **Recipient:** The Memory chip sees the signal and prepares to output data. |
| **Deassert** | To **deactivate** a signal by driving the pin to its inactive voltage level (usually High). | **CPU** (or sometimes DMA/Peripheral) | Recipient Chip (Memory/I/O) | "The CPU **deasserts** the $\text{WR}'$ signal to complete the write operation." | **Doer:** The CPU releases the pin back to the inactive state (HIGH). **Recipient:** The Memory chip stops transferring data and saves the value. |
| **Sample** | To **read (check)** the current logical state (High or Low) of an input signal at a precise moment. | **CPU** | External Device Signal (e.g., $\text{READY}$) | "The CPU **samples** the $\text{READY}$ line near the end of $\text{T3}$." | **Doer:** The CPU performs the internal reading operation. **Recipient:** The $\text{READY}$ signal from the external device provides the information. |
| **Drive** | To actively **apply a voltage** (High or Low) to a bus line, essentially "putting data or address onto the bus." | **CPU** or **Memory/I/O** | The Bus (Data or Address) | "The Memory chip **drives** the requested data onto the Data Bus." | **Doer:** The Memory chip actively places the electrical signals on the bus wires. **Recipient:** The CPU is the ultimate recipient, waiting to read the data from the bus. |

##  Bus Cycles, T-States, READY Signal and WAIT States

In the 8086 microprocessor, all external communications (like reading an instruction, reading data from memory, or writing data to an I/O port) are organized into **Bus Cycles** (also called **Machine Cycles**).

A Bus Cycle is a complete sequence of events for a single bus operation. It has 4 T-state

### T-State Definition
A **T-State** (or **Clock State**) is the most basic unit of time in the 8086 timing. It is equal to one period of the system clock ($T_{CLK}$).

### The Standard Bus Cycle (Minimum of 4 T-States)
Every standard 8086 bus cycle (Read, Write, I/O Read, I/O Write, etc.) is composed of a minimum of **four T-states**, designated as $\mathbf{T1, T2, T3}$, and $\mathbf{T4}$.

| T-State | Primary Action | Purpose |
| :--- | :--- | :--- |
| **T1** | **Address Out** | The 8086 places the 20-bit memory address or 16-bit I/O address onto the multiplexed Address/Data Bus (A/D lines). The **ALE** (Address Latch Enable) signal is active high during this state to allow external latches to capture the address. |
| **T2** | **Set up Control Signals** | The 8086 removes the address and asserts the control signals (like $\text{RD}'$ or $\text{WR}'$, $\text{DEN}'$, $\text{DT}/\text{R}'$) to specify the type and direction of the operation (e.g., Read from Memory). |
| **T3** | **Data Transfer Window** | This is the main period where the addressed device (memory or I/O) is expected to respond. The device puts data onto the Data Bus (for a Read) or holds the written data on the bus (for a Write). **The READY signal is sampled near the end of T3.** |
| **T4** | **Data Latch/Cleanup** | The 8086 completes the operation. For a Read, the CPU **latches (reads) the data** from the bus. For a Write, the CPU stops driving the $\text{WR}'$ signal, ending the write operation. All bus signals are typically deactivated. |


### READY Signal and WAIT States

The four T-states ($\text{T1-T4}$) assume the external memory or I/O device is fast enough to complete the data transfer within the allotted time. However, slower devices exist.

### The READY Signal
The **READY** pin is an input to the 8086 that synchronizes the CPU with slower external hardware.

* **READY = HIGH (1):** The device is **ready**; it has completed the data transfer (e.g., the data is stable on the bus for a Read). The CPU proceeds to the next state ($\text{T4}$).
* **READY = LOW (0):** The device is **not ready**; it needs more time to complete the operation.

### WAIT States ($\mathbf{T_W}$)
A **WAIT State** ($\mathbf{T_W}$) is an **extra clock period** (or T-state) that the 8086 inserts between $\text{T3}$ and $\text{T4}$ of the bus cycle.

* **Function:** If the external device pulls the **READY** pin **LOW** (0) when the 8086 samples it (near the end of $\text{T2}$ and during $\text{T3}$), the 8086 will insert a $\text{TW}$ state instead of proceeding to $\text{T4}$.
* **CPU Action:** During a WAIT state, the CPU is momentarily **idle** (stalled) on the bus, but it continues to assert the control signals and maintain the bus state, giving the slow device more time.
* **Duration:** The 8086 will insert **consecutive $\mathbf{T_W}$ states** until the device sets the **READY** pin **HIGH** again, at which point the CPU immediately proceeds to $\text{T4}$ and finishes the cycle.

$$\text{Bus Cycle } = T_{CLK} \times (4 + T_W)$$

[Memory Flow](./memory-Flow.md)


---

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

1. Save Context: The CPU pushes the current state of its crucial registers, primarily the Flags Register (**FLAGS**), the Code Segment (**CS**), and the Instruction Pointer (**IP**), onto the stack. This saves the return address (CS:IP) and the status of the program being interrupted.
2. Disable/Clear Flags: The CPU typically **clears** the Interrupt Flag (**IF**) and the Trap Flag (**TF**) to prevent new maskable interrupts or single-stepping during the ISR.
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

### Interrupt Hierarchy and Scenarios

What happens when cpu is executing ISR, another interrupt occured

#### 1. $\text{INTR}$ While in an ISR (Prevented)
* Scenario: A peripheral device (like a keyboard) raises the $\text{INTR}$ line, but the CPU is currently executing an ISR (for, say, $\text{Int } \text{x80}$).
* Result: Nothing happens immediately. Since the CPU cleared the Interrupt Flag ($\text{IF}$) when it entered the first ISR, the $\text{INTR}$ signal is ignored (masked).
* Resolution: The $\text{INTR}$ signal must wait. When the current ISR finishes and executes the $\text{IRET}$ instruction, the original state of the $\text{Flags}$ (including $\text{IF}$) is restored. If the original $\text{IF}$ was set, interrupts are re-enabled, and the pending $\text{INTR}$ request will be serviced immediately after the return.

The $\text{8259A}$ has 8 interrupt request lines, labeled $\text{IR0}$ through $\text{IR7}$. It contains an Interrupt Request Register ($\text{IRR}$), which is essentially an 8-bit register. If an interrupt signal is received on $\text{IRx}$, the corresponding bit in the $\text{IRR}$ is set to '1'. This bit represents the pending state.

Therefore, you can have up to 8 hardware $\text{INTR}$ requests pending (waiting in the $\text{8259A}$'s $\text{IRR}$) while the CPU is executing a critical section of code with $\text{IF}=0$. Once $\text{IF}$ is restored to 1 by an $\text{IRET}$, the $\text{8259A}$ immediately raises the $\text{INTR}$ line again to service the next highest-priority pending request.

The default service order for pending interrupts is strictly based on the $\text{IR}$ line number, from lowest index to highest index, which corresponds to the highest priority to lowest priority. 

$$\mathbf{IR0} \text{ is highest,} \mathbf{IR1} \text{ is lowset}$$

The $\text{8259A}$ is "Programmable," which means this default priority can be altered

#### 2. Software Interrupt ($\text{INT}$ instruction) While in an ISR (Possible)
* Scenario: Your code, running within the $\text{Int } \text{x80}$ handler, executes another software interrupt, such as $\text{int } \text{21h}$ or perhaps a call to a simpler print routine $\text{int } \text{10h}$.
* Result: The new software interrupt will execute immediately.
* Why: The $\text{INT}$ instruction is just another CPU instruction. Unlike the hardware-triggered interrupt, the CPU executes it directly. It does not check the $\text{IF}$ flag.
* Action: The CPU performs a complete interrupt sequence:
  - It pushes the current $\text{Flags}$, $\text{CS}$, and $\text{IP}$ (the return address inside the first ISR) onto the current stack (which is the kernel stack).
  - It reads the vector from the Interrupt Vector Table (IVT).
  - It jumps to the second ISR.
* Nesting: This creates nested interrupts. When the second ISR finishes, it executes $\text{IRET}$ to return to the instruction inside the first ISR. The first ISR then completes its work and executes its $\text{IRET}$ to return to the user program

#### 3. Non-Maskable Interrupt ($\text{NMI}$) While in an ISR (Forced Preemption)
* Scenario: The $\text{NMI}$ pin is triggered (e.g., a critical memory error or watchdog timer event) while the CPU is executing the $\text{Int } \text{x80}$ handler.
* Result: The current ISR is preempted immediately, regardless of the state of the $\text{IF}$ flag.
* Why: The $\text{NMI}$ is non-maskable. The $\text{IF}$ flag is irrelevant.
* Action:
  - The CPU pushes the current $\text{Flags}$, $\text{CS}$, and $\text{IP}$ onto the current stack (the kernel stack).
  - It automatically vectors to the $\text{NMI}$ ISR (vector 2, address $0000:0008$).
  -  It jumps to the $\text{NMI}$ ISR.
* NMI ISR: The $\text{NMI}$ handler runs. When completed it willdo $\text{IRET}$ to resume the code that was interrupted (which was the first kernel $\text{Int } \text{x80}$ handler).

## TF vs INT 0x3

TF ($\text{Trap Flag}$) and $\text{INT 3}$ are both mechanisms used on the x86 architecture primarily for debugging, but they operate in fundamentally different ways.

### TF

* It is available in $\text{RFLAGS}$
* It is automatic, meaning per-instruction, exception generation by the CPU Hardware. For each instruction it generate  exception (kind of break point in this context) it is also know as Single-Stepping
* Automatically triggers the Debug Exception (Interrupt Vector $\text{1}$) after an instruction executes.

### INT 0x3

* Software Interrupt Instruction 
* Explicit instruction inserted into the code by a debugger or programmer. Sets a Software Breakpoint, Execution proceeds normally until the instruction is hit.
* Explicitly triggers the Breakpoint Exception (Interrupt Vector $\text{3}$) when the instruction is executed.

## Device communication

### 1. Interrupt IO

When a device want to notify cpu, it will raise a interrupt (eg:,.Keyboard)

### 2. I/O Port Access (Port-Mapped I/O)

This is a method where the CPU communicates with a device's registers (control, status, or data) using a dedicated, separate address space called the I/O space. This is the classic method used by many legacy devices in the x86 architecture (like the PIC, PIT, and old Serial/Parallel ports).

* Mechanism: The CPU uses special, dedicated instructions
    - OUT (to write data to an I/O port)
    - IN (to read data from an I/O port)
* Address Space: The I/O space is physically separate from the main memory space. The x86 architecture supports $2^{16} = 65,536$ I/O ports, addressed by 16 bits (from $0x0000$ to $0xFFFF$). I/O address space are not actual memory cells, but logical addresses that the CPU uses to point to a specific register on an I/O device.
* CPU Action: When the CPU executes an IN or OUT instruction, it asserts a special control line (like the $M/\overline{IO}$ pin on the 8086), telling the bus system that the address on the address bus refers to an I/O port, not a memory location.The Motherboard's I/O Controller has the 1 byte of storage, from where cpu reads
* Pros: Keeps memory and I/O logic separate; simplifies address decoding for I/O devices.
* Cons: Requires special instructions; access is slower than memory access and often more limited in flexibility.

Physical Device: when doing reading/writing we are doing operation on register or buffer located inside a specialized I/O Controller chip (like the $\mathbf{8259A\ PIC}$, the $\mathbf{8253\ Timer}$, or the $\mathbf{Keyboard\ Controller}$).

### Memory-Mapped I/O (MMIO)
This is a method where the registers of a peripheral device are mapped into the CPU's main memory address space. The CPU treats these device registers exactly as if they were RAM

* Mechanism: The CPU uses standard memory access instructions:
    - MOV (to read or write)
    - Any other instruction that accesses a memory location.
* Address Space: I/O device registers are assigned a unique, reserved range of physical memory addresses (e.g., the VGA Framebuffer is often at $0xA0000$ or higher). This range is marked as non-RAM.
* CPU Action: When the CPU executes a standard MOV instruction to a MMIO address, the bus system (or chipset) intercepts the request. Instead of routing the read/write operation to RAM chips, it routes the signal to the peripheral device that is listening for that specific address range.
So the RAM address are just a place holder, if we write or read on that location means we are not doing from RAM, actualling doing it on the device registers or storage
* Pros: Unified programming model (use all standard memory instructions); easier for compilers; generally faster access than I/O Ports
* Cons: Consumes a portion of the limited physical memory address space (less of an issue on 32-bit and 64-bit systems); requires careful handling (e.g., disabling caching) to ensure reads/writes hit the device registers immediately. Storage cells in these are not usable

Physical device: when doing reading/writing we are doing operation on specialized buffer (like $\mathbf{Video\ RAM\ (VRAM)}$) or a $\mathbf{ROM\ (Read-Only\ Memory)}$ chip. The data (comes from/ goes to) the memory contained within those specific chips.

When you $\mathbf{MOV\ AL, [B8000\text{H}]}$ (accessing text mode video memory), you are reading from the VRAM chip on the graphics card, not the main system DRAM/SRAM chips.

### Direct Memory Access (DMA)
DMA is a hardware mechanism that allows a peripheral device to read data from or write data to main memory directly, without involving the CPU in the actual data transfer process.
* Purpose: To offload high-volume, high-speed data transfers (like disk or network traffic) from the CPU, significantly improving system throughput and efficiency.
* Key Component: The DMA Controller (DMAC). This is a dedicated chip (like the 8237 in legacy systems) or built-in logic in modern chipsets/devices that orchestrates the transfer.
* CPU Involvement: Only for the initial setup and handling the final completion interrupt. When DMA complete it's work CPU will be notified

When DMA is doing the working, it is going to take complete control over the system bus so CPU has to be idel, Then what make DMA powerfull is CPU mov from disk max of 2 bytes, but DMA can handle in KB

When the DMA controller needs to transfer data, it must gain control of the system buses. The DMA controller doesn't necessarily take control of all CPU registers (like $AX, BX, CX,$ etc.); it takes control of the essential pathways:

* Address Bus: Used to specify the memory location.(Pins $\text{A0}$ through $\text{A19}$)
* Data Bus: Used to transfer the actual data. (Pins $\text{D0}$ through $\text{D7}$ or $\text{D15}$)
* Control Bus: Used to manage read/write operations. (Pins like $\text{RD}'$ (Read) and $\text{WR}'$ (Write))

During this period (while the DMA is using the bus), the CPU cannot access memory or I/O ports. Consequence: Since instruction fetching and execution heavily rely on accessing memory, the CPU is effectively IDLE (stalled/halted) and cannot run any part of the program.

While the CPU is idled by the DMA controller taking the buses, it is only paused from executing instructions that require bus access. The CPU itself is still powered on and internally active.

- Internal Operations: The CPU can still perform internal operations that do not require the bus. This includes things like:
- Simple register-to-register operations (e.g., $MOV AX, BX$).
- Arithmetic/Logical Operations on data currently held in its internal registers (e.g., $ADD AX, 10H$).
- Instruction Pre-fetch Queue: The 8086 has a 6-byte instruction pre-fetch queue. If the queue is full and the transfer is short, the CPU can continue executing instructions from its queue for a brief moment until it needs to fetch a new instruction from memory.

* Flow:

    1. Setup: The CPU (running the OS/driver) programs the DMAC and the peripheral device with:

        - The source (e.g., the disk's buffer or memory).

        - The destination (a buffer address in main memory).

        - The size (number of bytes to transfer).

    2. Request: The Peripheral Device sends a DMA Request (DRQ) signal to the DMAC.

    3. Transfer: The DMAC requests the Bus from the CPU using a Hold Request (HRQ). The CPU grants access (Hold Acknowledge - HLDA). The DMAC then becomes the temporary "bus master" and manages the transfer of the data block directly between the device and memory.

    4. Completion: Once the block is transferred, the DMAC releases the bus and sends an Interrupt to the CPU.


## Boot device/disk

When we power on system BIOS will call boot loader, boot loader will select the bootable disk to boot

How boot loader decide which disk is bootable?
If a disk's 1st 512byte is **MBR**, then it is bootable device

What MBR contains?
Small code which fit into 0 - 509 bytes, 510 and 511 is a special bytes, which makes this segment as **MBR**, which will store a signature in 510 and 511 location `0xAA55`, if the disk don't have this signature then boot loader will check for next device

BIOS always place boot MBR code from `0x07c00` memory location

To execute  `qemu-system-i386 -fda /tmp/boot.img`

[Programs](./program/README.md)