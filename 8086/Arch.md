## The Core Components: BIU and EU

The 8086 CPU is split into two major units that work together to speed up processing.

1. Bus Interface Unit ($\text{BIU}$)
    The $\text{BIU}$ is the gatekeeper and communicator with the outside world (Memory and I/O).
    
    - Role: Handles all external bus activities.
    - Responsibilities: Address Generation (calc 20bit address), Bus Control (managing $\text{T1-T4}$ cycles and pins), Instruction Pre-fetching, Instruction Queuing (has 6 bytes queue) and Operand Transfer.

    Pins the $\text{BIU}$ Directly Controls/Accesses.

    - Address/Data Lines ($\text{AD0-AD15}, \text{A16/S3-A19/S6}$): Used to output memory addresses and transfer data.
    - Bus Control Signals: $\mathbf{\text{ALE}}$, $\mathbf{\text{RD}'}$, $\mathbf{\text{WR}'}$, $\mathbf{\text{M}/\overline{\text{IO}}}$, $\mathbf{\text{DT}/\overline{\text{R}}}$, $\mathbf{\text{DEN}'}$
    - Bus Arbitration Signals: $\text{HOLD}/\text{HLDA}$
    - Status Signals: ($\text{S0, S1, S2}$)
    - Synchronization Signals: $\mathbf{\text{CLK}}$, $\mathbf{\text{READY}}$
    - Segment Registers: ($\text{CS, DS, SS, ES}$)
    - Instruction Pointer: ($\text{IP}$)
    - 6-byte Instruction Queue

2. Execution Unit ($\text{EU}$)
    The $\text{EU}$ is the processor's internal engine that performs the work.

    - Role: Executes the instructions.
    - Responsibilities: Instruction Decode (reading from the queue), executing logic/math using the $\text{ALU}$, accessing and manipulating the internal Registers ($\text{AX, BX}$, etc.) and Flags, and managing control flow (like $\text{JMP}$ or $\text{INTR}$ checks).

    Pins the $\text{EU}$ Directly Checks/Accesses (via internal logic)
    - $\mathbf{\text{NMI}}$, $\mathbf{\text{INTR}}$, $\mathbf{\text{TEST}'}$
    - General Purpose Registers ($\text{AX, BX, CX, DX}$, etc.)
    - Flags Register
    - Arithmetic Logic Unit ($\text{ALU}$)
    - 6-byte Instruction Queue

    **How the $\text{EU}$ Accesses External Memory/I/O?**
    The $\text{EU}$ accesses external pins indirectly by sending high-priority requests to the $\text{BIU}$, operations like this $\text{MOV AX, [BX]}$.

## The Execution Flow: Pipelining

The way the $\text{BIU}$ and $\text{EU}$ work together is called Pipelining, which is a form of asynchronous (parallel) operation.

### Pipelining Principle

While the $\text{EU}$ is executing the current instruction internally, the $\text{BIU}$ is simultaneously fetching the next instruction from memory and placing it in the queue. This is known as the Fetch-Execute Overlap.


| Timing | BIU Action (Fetch) | EU Action (Execute)|
|--------|--------------------|--------------------|
|t=1 to 4 Clocks|Fetches Instruction 1 bytes.|Waits (Queue is empty).|
|t=5 to 8 Clocks|Fetches Instruction 2 bytes.|Executes Instruction 1 (takes from queue).|
|t=9 to 12 Clocks|Fetches Instruction 3 bytes.|Executes Instruction 2 (takes from queue).|

### When Parallelism Breaks (Stalls)
The $\text{EU}$ is forced to wait (the pipeline stalls) when:
1. Queue is Empty: The $\text{EU}$ finishes an instruction but the $\text{BIU}$ has not filled the queue yet (e.g., after a $\text{JMP}$).

    #### Pipeline Flush ($\text{JMP, CALL, etc.}$)

    When the $\text{EU}$ executes an instruction that changes the Instruction Pointer ($\text{IP}$), the pre-fetched instructions in the queue become invalid:

    1. $\text{EU}$ Action: Executes the $\text{JMP}$ command.
    2. Pipeline Flush: The $\text{EU}$ signals the $\text{BIU}$ to discard (flush) all bytes in the $\mathbf{6\text{-byte Instruction Queue}}$.
    3. $\text{BIU}$ Restart: The $\text{BIU}$ loads the $\text{IP}$ with the new target address and immediately starts a new $\mathbf{\text{Memory Read Bus Cycle (T1-T4)}}$ to fetch the correct instruction from the new location.

2. External Access Needed: The $\text{EU}$ needs to read an operand from memory (e.g., $\text{MOV AX, [BX]}$). The $\text{EU}$ must pause and instruct the $\text{BIU}$ to perform a Bus Cycle to retrieve the data.

    #### What Happens Instead

    When the $\text{EU}$ needs an operand from memory, the following sequence occurs:

    1.  **$\text{EU}$ Request:** The $\text{EU}$ decodes $\text{MOV AX, [BX]}$ and realizes it needs the data pointed to by $\text{BX}$ from external memory.
    2.  **$\text{EU}$ Pause/Wait:** The $\text{EU}$ immediately **pauses** its execution flow for this instruction.
    3.  **$\text{BIU}$ Bus Cycle:** The $\text{EU}$ sends an internal request to the $\text{BIU}$ to perform a **Memory Read Bus Cycle ($\text{T1-T4}$)** at the address calculated using $\text{BX}$.
    4.  **$\text{BIU}$ Fetch Halts:** Crucially, while the $\text{BIU}$ is busy performing this required **operand fetch** (which is high priority), it **temporarily stops** its lower-priority task of **pre-fetching** the next instruction.
    5.  **Data Transfer:** The $\text{BIU}$ retrieves the operand data from memory and passes it directly to the $\text{EU}$'s internal registers.
    6.  **$\text{EU}$ Resumes:** The $\text{EU}$ finishes the $\text{MOV}$ instruction with the retrieved data.
    7.  **$\text{BIU}$ Restarts:** The $\text{BIU}$ resumes its job of pre-fetching the next instructions into the queue.

    Queue is not flushed, data is directly transfered to registers

## The 8086 Pipelined Execution Flow

The overall process is a continuous loop involving the $\text{BIU}$ and $\text{EU}$ working in parallel.

### 1. The Pipelined Stages

| Step | Unit | Action | Note |
| :--- | :--- | :--- | :--- |
| **1. Fetch** | **BIU** | Performs a **Memory Read Bus Cycle** ($\mathbf{T1-T4}$) to retrieve the next instruction byte(s) from memory ($\text{CS:IP}$). | The $\text{BIU}$ works independently, pre-fetching the next instruction into the $\mathbf{6\text{-byte Instruction Queue}}$. |
| **2. Queue/Buffer** | **BIU** | Stores the fetched bytes in the queue. | This step ensures the $\text{EU}$ is supplied continuously. |
|--|--|--|Once Queue has data EU will run parallely|
| **1. Decode** | **EU** | Reads the next instruction byte(s) from the **front of the queue** and determines the operation, destination, and source. | The $\text{EU}$ consumes bytes from the queue. |
| **2. Execute** | **EU** | Performs the operation. This stage can involve multiple internal clocks or trigger a bus cycle request to the $\text{BIU}$. | This is where the $\text{ALU}$ is used, registers are updated, or external bus access is requested. |

### 2. The Check/Priority Stage (End of Instruction)

After the $\text{EU}$ completes the **Execute** stage of the current instruction, it must perform checks for external/internal events *before* pulling the next instruction from the queue. This is where your priority sequence is used, and it's checked by the **$\text{EU}$'s internal control logic**.

The $\text{EU}$ performs its checks in the following **strict priority order**:

| Priority | Event/Check | Action Taken if High | Unit Responsible |
| :--- | :--- | :--- | :--- |
| **Highest** | **Internal Exception** (e.g., Division by Zero, $\text{INT 3}$) | **Immediate** hardware interruption. Pushes $\text{FLAGS, CS, IP}$ and jumps to the dedicated **Vector Table** address. | $\text{EU}$ |
| **High** | **Non-Maskable Interrupt ($\text{NMI}$ Pin)** | Checked by the $\text{EU}$'s logic. If active, the $\text{CPU}$ performs an interrupt sequence (Vector Type 2). | $\text{EU}$ |
| **Medium** | **Maskable Interrupt ($\text{INTR}$ Pin)** | Checked by the $\text{EU}$ **only if** the $\mathbf{\text{IF (Interrupt Flag)}=1}$. If active, the $\text{CPU}$ performs the $\text{INTA}'$ cycles to get the vector type. | $\text{EU}$ |
| **Lowest** | **Normal Execution Flow** | If no higher-priority events are pending, the $\text{EU}$ proceeds to the next step: **Decode** the next instruction from the queue. | $\text{EU}$ |


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
| **Tri-State / High Impedance** | To electrically **disconnect** a chip from the bus lines, making its pins appear as open circuits. | **CPU or Memory/I/O** |The Bus (Data or Address) | "When $\text{HLDA}$ is asserted, the CPU enters tri-state on the bus lines." |**Doer**: The chip (CPU/Memory/I/O) internally turns off its output drivers. **Recipient**: The Bus is freed, allowing another chip (like the DMA Controller) to take over as the driver. |

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

[Interrupt Flow](./InOut.md#8086-minimum-mode-interrupt-processing-flow)