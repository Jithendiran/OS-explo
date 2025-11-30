# I/O controller

I/O Controller (or Device Controller) is a separate hardware component or dedicated integrated circuit (IC) from the CPU and main RAM

It acts as an interface or mediator between the fast, standard system bus (which the CPU and RAM use) and the slower, specialized peripheral device (like a keyboard, disk drive, or network card).

The I/O controller is necessary because external I/O devices have characteristics that are vastly different from the CPU and memory:

1.  **Protocol Translation:** The CPU communicates using simple read/write bus cycles. The I/O device (e.g., a hard drive) requires a complex sequence of commands and specialized signals. The controller translates the CPU's general command (e.g., "Read byte from port $378\text{H}$") into the device's specific control sequences.
2.  **Buffering and Speed Matching:** I/O devices are significantly slower than the CPU and RAM. The controller contains **buffers** (small amounts of memory) to temporarily hold data, allowing the CPU to transfer a block of data quickly and move on, while the controller manages the slow, asynchronous transfer to the peripheral.
3.  **Status and Control:** The controller provides **Control Registers** (for the CPU to send commands) and **Status Registers** (for the CPU to check if the device is ready, busy, or has errors).
4.  **Interrupt Handling:** The controller can generate an **Interrupt** signal to the CPU when a long operation is complete or when the device requires attention (e.g., a keypress), freeing the CPU to perform other tasks while waiting.

In an 8086-based system, the I/O controllers are implemented using specialized, discrete ICs that connect to the system bus. Common examples from that era include:

* **8255 Programmable Peripheral Interface (PPI):** A general-purpose IC used to provide flexible parallel I/O ports.
* **8259 Programmable Interrupt Controller (PIC):** Manages interrupt requests from multiple I/O devices.
* **8251 Universal Synchronous/Asynchronous Receiver/Transmitter (USART):** Used for serial communication.

The 8259 Programmable Interrupt Controller (PIC) is not a general I/O controller, but a specialized peripheral chip to which other I/O controllers (or their devices) are connected.

The typical **buffer storage** in an I/O controller or device interface is usually a small amount of **dedicated, fast memory** designed to hold data temporarily during the transfer between the peripheral device and the system bus (CPU/RAM).

The specific size and type depend on the device and its required throughput, but here are the general characteristics:

##  Characteristics of I/O Buffers

### 1. Small Capacity
I/O buffers are typically **small** in size, ranging from a few **bytes** to a few **kilobytes (KB)**.

* **For simple devices (like a keyboard or serial port):** The buffer may only be a **single byte** or a small **FIFO (First-In, First-Out)** register to hold one or a few characters.
* **For complex devices (like network cards or disk controllers):** The buffers can be larger, perhaps **$4 \text{KB}$ to $32 \text{KB}$**, designed to hold an entire network packet or a sector of disk data.

### 2. Implementation Technology
The buffer is usually implemented using fast, on-chip memory technologies:

* **Registers:** For the smallest buffers, they are simply part of the **control and status registers** of the I/O chip.
* **SRAM (Static RAM):** For larger, faster buffers, the controller IC uses **SRAM** because it is faster than the main DRAM (Dynamic RAM) used for system memory, ensuring the controller can keep up with the burst speed of the system bus.

### 3. Purpose: Decoupling and Speed Matching

The primary function of the buffer is **decoupling** the two sides:

| Side | Characteristic | Role of Buffer |
| :--- | :--- | :--- |
| **Peripheral Device** | **Slow and Asynchronous** (data comes or goes when ready, e.g., a keypress). | The buffer **accepts bursts of data** from the system bus and holds it while the slow peripheral processes it (Write operation), or collects slow data from the peripheral and holds it until the system bus is ready for a fast transfer (Read operation). |
| **CPU/System Bus** | **Fast and Synchronous** (data must be transferred within the $\text{T3/T4}$ states of a bus cycle). | The buffer ensures **data is immediately available** for the CPU on a read, preventing the need for excessive $\mathbf{T_W}$ (wait states) caused by the slow peripheral. |


## 8086 Minimum Mode Interrupt Processing Flow

In Minimum Mode, the **8086 CPU directly outputs** the $\overline{\text{INTA}}$ signal, as that pin is dedicated for this function (Pin 24) instead of being the $\overline{\text{QS}1}$ pin as in Maximum Mode.


### Phase 1: Signal Generation

| Action | Doer | Pins Involved | Note |
:--- | :--- | :--- | :--- |
| Physical Event | Keyboard/Mouse | $\text{N/A}$ | Keystroke occurs. |
| Data Deposit | I/O Controller | $\text{I/O Data register}$ | Scan Code is stored in the peripheral's I/O Port. |
| Interrupt Request | I/O Controller | $\mathbf{\text{IRQ}n}$ (e.g., $\text{IRQ1}$) | The I/O controller asserts its specific **Interrupt Request** line to the $\mathbf{8259\text{A PIC}}$. |
| CPU Notification | 8259A PIC | $\mathbf{\text{INTR}}$ (CPU Pin 18) | The PIC drives the $\mathbf{\text{INTR}}$ pin **HIGH**, signaling the CPU that a device needs service. |


### Phase 2: CPU Acknowledge ($\overline{\text{INTA}}$ Bus Cycles)

The CPU, upon recognizing the $\text{INTR}$ and completing its current instruction, initiates two consecutive $\overline{\text{INTA}}$ bus cycles.

#### **Cycle 1: Direct Acknowledge Signal**

| Action | Doer | Pin Signal | Purpose | Note |
| :--- | :--- | :--- | :--- | :--- |
| Acknowledge Output | 8086 CPU | $\mathbf{\overline{\text{INTA}}}$ (Pin 24) | Driven **LOW** to the **PIC**, telling it: "I hear you." | The 8086 itself asserts the $\overline{\text{INTA}}$ pin .  |
| I/O Indicator | CPU | $\text{M}/\overline{\text{IO}}$ | **LOW** (I/O operation). | Indicates that the transfer involves an I/O device (the PIC). |
| Data Bus | CPU | $\text{D0-D15}$ | **Tri-stated** (off). | Bus is not used to transfer data in this first cycle. |
| Synchronization | 8259A PIC | $\text{READY}$ | PIC may drive $\text{READY}$ **LOW** to insert Wait states. | Standard bus cycle timing remains, allowing for Wait states. |


#### **Cycle 2: Fetch Interrupt Vector**

The CPU needs the 8-bit interrupt vector (or type number) from the 8259A PIC to locate the Interrupt Service Routine (ISR) address in the Interrupt Vector Table.

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| Vector Read Signal | **8086 CPU** | $\mathbf{\overline{\text{INTA}}}$ (Pin 24) | Driven **LOW** a second time. | This second pulse instructs the PIC to put the vector number on the data bus. |
| Read Command | **8086 CPU** | $\mathbf{\overline{\text{RD}}}$ | Driven **LOW** (Asserted). | This is a standard **Read** command, but it is combined with $\overline{\text{INTA}}$ to signal the PIC specifically. |
| Direction Control | **8086 CPU** | $\text{DT}/\overline{\text{R}}$ | **LOW** ($\overline{\text{R}}$ for Receive). | Tells the external data buffers (transceivers) that data is moving **INTO** the CPU. |
| Data Transfer | 8259A PIC | $\mathbf{\text{D0-D7}}$ | PIC places the **8-bit Interrupt Vector Number** on the low 8 bits of the data bus. | The CPU reads this number (e.g., 08H for IRQ0) to determine which ISR to run. |


### Phase 3: Saving State and Vectoring

Once the 8086 CPU has successfully fetched the 8-bit **Interrupt Vector Number** (let's call it $N$) from the 8259A PIC in **Cycle 2**, the CPU performs a sequence of internal, non-bus-cycle operations to transfer control to the Interrupt Service Routine (ISR). This is done automatically by the hardware.

| Action | Doer | Pins Involved | Significance |
| :--- | :--- | :--- | :--- |
| Clear Interrupt Flags | CPU | Internal $\text{IF}$ and $\text{TF}$ | The **Interrupt Flag ($\text{IF}$)** is automatically **cleared ($\text{IF}=0$)** to prevent further maskable interrupts. The **Trap Flag ($\text{TF}$)** is also **cleared ($\text{TF}=0$)** to disable single-stepping. |
| Push Flags | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **PUSH** operation to save the current contents of the 16-bit **Flags Register** onto the stack. |
| Push CS | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **PUSH** operation to save the 16-bit **Code Segment ($\text{CS}$)** register onto the stack. This is the segment of the instruction that would have executed next. |
| Push IP | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **PUSH** operation to save the 16-bit **Instruction Pointer ($\text{IP}$)** register onto the stack. This points to the exact instruction that was interrupted. |
| Calculate Vector Address | CPU | Internal Logic | The CPU multiplies the 8-bit Vector Number ($N$) by 4 to get the $\mathbf{20\text{-bit}}$ physical address of the Interrupt Vector Table entry: $\text{Vector\_Address} = N \times 4$. |
| Fetch ISR Address | CPU | $\text{AD0-AD19}, \overline{\text{RD}}, \text{M}/\overline{\text{IO}}$ (HIGH) | The CPU reads two $16\text{-bit}$ words from $\text{Vector\_Address}$: **New $\text{IP}$** (word 1) and **New $\text{CS}$** (word 2). This requires two consecutive memory **Read** bus cycles. **see memory Read cycle** |
| Load Registers | CPU | $\text{CS}, \text{IP}$ | The fetched **New $\text{CS}$** is loaded into the **$\text{CS}$ register**, and the fetched **New $\text{IP}$** is loaded into the **$\text{IP}$ register**. |
| Execute ISR | CPU | $\text{CS}, \text{IP}$ | The CPU immediately begins executing the first instruction of the Interrupt Service Routine (ISR) located at the new $\text{CS}:\text{IP}$. |



### Phase 4: Returning to the Main Program

The ISR ends with the instruction $\mathbf{\text{IRET}}$ (Interrupt Return).

| Action | Doer | Pins Involved | Significance |
| :--- | :--- | :--- | :--- |
| EOI Command |ISR (Software) | $\text{I/O Write}$ (to PIC) | The ISR executes a MOV/OUT instruction to write the $\mathbf{EOI}$ command to the PIC, clearing the $\text{ISR}$ bit. |
| Pop IP | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **POP** operation, restoring the original $\text{IP}$ value from the stack. |
| Pop CS | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **POP** operation, restoring the original $\text{CS}$ value from the stack. |
| Pop Flags | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a **POP** operation, restoring the original **Flags Register** (including the original $\text{IF}$ and $\text{TF}$) from the stack. |
| Resume Execution | CPU | $\text{CS}, \text{IP}$ | Execution resumes at the exact instruction that was interrupted. |

**End of Interrupt (EOI) Command**

The Interrupt Service Routine (ISR) must explicitly tell the 8259A PIC that the interrupt has been fully serviced so the PIC can manage its internal state, clear the In-Service Register (ISR) bit for that interrupt level, and enable lower-priority interrupts.

This is done by issuing an End of Interrupt (EOI) command from the CPU to the 8259A PIC.

Without the EOI command, the PIC would be unable to properly process future interrupts.

## Complete NMI Flow

The $\text{NMI}$ flow is much simpler and faster because the key difference is that $\text{NMI}$ requires zero external bus cycles for acknowledge ($\overline{\text{INTA}}$ is not involved), as the vector number (Type 2) is hardwired inside the CPU.

### Phase 1: Signal Detection (Hardware Level)

| Action | Doer | Pins Involved | Significance |
| :--- | :--- | :--- | :--- |
| Physical Event | External Circuitry | $\text{NMI}$ (Pin 17) | An event like a memory parity error or power failure asserts the $\text{NMI}$ pin with a **Low-to-High** transition. |
| NMI Detection | 8086 CPU | $\text{NMI}$ | The CPU samples the $\text{NMI}$ pin at the end of the current instruction's execution. Unlike $\text{INTR}$, the $\text{NMI}$ signal is **edge-triggered** (L-to-H) and **unaffected** by the $\text{IF}$ flag. |


### Phase 2: CPU Internal State Save (Non-Bus Cycles)

The CPU immediately prepares to service the Type 2 interrupt without any external negotiation. These steps are fast, internal register transfers and stack adjustments.

| Action | Doer | Pins/Registers Involved | Significance |
| :--- | :--- | :--- | :--- |
| Clear Interrupt Flags | CPU | Internal $\text{IF}$ and $\text{TF}$ | The **Interrupt Flag ($\text{IF}$)** is automatically **cleared ($\text{IF}=0$)** to block subsequent maskable interrupts. The **Trap Flag ($\text{TF}$)** is also **cleared ($\text{TF}=0$)** to disable single-stepping. |
| Push Flags | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a $\mathbf{16\text{-bit PUSH}}$ to save the current contents of the **Flags Register** onto the stack. |
| Push CS | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a $\mathbf{16\text{-bit PUSH}}$ to save the current **Code Segment ($\text{CS}$)** register onto the stack. |
| Push IP | CPU | $\text{SS}, \text{SP}$ (Stack Pointers) | The CPU performs a $\mathbf{16\text{-bit PUSH}}$ to save the current **Instruction Pointer ($\text{IP}$)** register onto the stack. |


### Phase 3: Vector Fetch and Service Jump (Bus Cycles)

The CPU knows the vector address is fixed at **$8\text{H}$**, so it performs two consecutive **Memory Read** bus cycles to fetch the new $\text{CS}$ and $\text{IP}$ from the Interrupt Vector Table (IVT).

#### **Cycle 1: Fetch New IP (Offset)**

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| Address Output | CPU | $\mathbf{\text{AD0-AD19}}$ | Outputs the physical address $\mathbf{\text{00008H}}$. |
| Memory Command | CPU | $\text{M}/\overline{\text{IO}}$ | **HIGH** (Memory operation). |
| Read Command | CPU | $\mathbf{\overline{\text{RD}}}$ | **LOW** (Asserted) for a Memory Read. |
| Data Transfer | Memory | $\text{D0-D15}$ | Memory places the $\mathbf{16\text{-bit New } \text{IP}}$ on the data bus. |
| Register Load | CPU | $\text{IP}$ | The fetched value is loaded into the **$\text{IP}$ register**. |

#### **Cycle 2: Fetch New CS (Segment)**

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| Address Output | CPU | $\mathbf{\text{AD0-AD19}}$ | Outputs the physical address $\mathbf{\text{0000AH}}$ ($00008\text{H} + 2$). |
| Memory Command | CPU | $\text{M}/\overline{\text{IO}}$ | **HIGH** (Memory operation). |
| Read Command | CPU | $\mathbf{\overline{\text{RD}}}$ | **LOW** (Asserted) for a Memory Read. |
| Data Transfer | Memory | $\text{D0-D15}$ | Memory places the $\mathbf{16\text{-bit New } \text{CS}}$ on the data bus. |
| Register Load | CPU | $\text{CS}$ | The fetched value is loaded into the **$\text{CS}$ register**. |


### Phase 4: Execution and Return

| Action | Doer | Pins/Registers Involved | Significance |
| :--- | :--- | :--- | :--- |
| Execute ISR | CPU | $\text{CS}, \text{IP}$ | Execution begins at the first instruction of the Non-Maskable Interrupt Service Routine. |
| IRET Instruction | CPU (Software) | N/A | The ISR concludes with the $\mathbf{\text{IRET}}$ (Interrupt Return) instruction. |
| Pop Flags, CS, IP | CPU | $\text{SS}, \text{SP}$ | The $\text{IRET}$ instruction automatically performs three **POP** operations, restoring the original **Flags**, $\mathbf{\text{CS}}$, and $\mathbf{\text{IP}}$ from the stack. |
| Resume Execution | CPU | $\text{CS}, \text{IP}$ | Execution resumes at the exact instruction that was originally interrupted. |