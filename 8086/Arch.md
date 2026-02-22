## The Core Components: BIU and EU

The 8086 CPU is split into two major units that work together to speed up processing.

1. Bus Interface Unit ($\text{BIU}$)
    The $\text{BIU}$ is the gatekeeper and communicator with the outside world (Memory and I/O).
    
    - Role: Handles all external bus activities.
    - Responsibilities: Address Generation (calc 20bit address), Bus Control (managing $\text{T1-T4}$ cycles and pins), Instruction Pre-fetching, Instruction Queuing (has 6 bytes queue) and Operand Transfer.

    Pins the $\text{BIU}$ Directly Controls/Accesses.

    - Address/Data Lines ($\text{AD0-AD15}, \text{A16/S3-A19/S6}$): Used to output memory addresses and transfer data.
    - $\mathbf{\text{BHE/s7}}$
    - Bus Control Signals: $\mathbf{\text{ALE}}$, $\mathbf{\text{RD}'}$, $\mathbf{\text{WR}'}$, $\mathbf{\text{M}/\overline{\text{IO}}}$, $\mathbf{\text{DT}/\overline{\text{R}}}$, $\mathbf{\text{DEN}'}$
    - Segment Registers: ($\text{CS, DS, SS, ES}$)
    - Instruction Pointer: ($\text{IP}$)
    - 6-byte Instruction Queue
    Remaining pins are connected with control unit

2. Execution Unit ($\text{EU}$)
    The $\text{EU}$ is the processor's internal engine that performs the work. Coltrol unit decides which to active

    - Role: Executes the instructions.
    - Responsibilities: Instruction Decode (reading from the queue), executing logic/math using the $\text{ALU}$, accessing and manipulating the internal Registers ($\text{AX, BX}$, etc.) and Flags, and managing control flow (like $\text{JMP}$ or $\text{INTR}$ checks).
        - The Control Unit (CU):  It decodes instructions and sends the Load/Enable signals to all other modules.
        - The ALU (Arithmetic Logic Unit): The calculator. It performs additions, subtractions, and logical operations (AND, OR, XOR).
    

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

    Queue is not flushed, data is directly transfered to registers
    
    The $\text{EU}$ accesses external pins indirectly by sending high-priority requests to the $\text{BIU}$, operations like this $\text{MOV AX, [BX]}$. BIU will complete it's current work then take up


## 8086 PINS

The 8086 is a 40-pin chip. The pins are generally categorized by their function. Since the 8086 can operate in two different modes—Minimum Mode (for small systems with one processor) and Maximum Mode (for multi-processor systems)—some pins have dual functions.

Here we mostly focus only on Minimum Mode

[Refer](./pin.md)

## Bus

A bus is a set of electrical conductors (wires/pins) used to transmit data between components inside a computer system. The 8086 uses a system bus comprised of three main parts:

1. Address Bus: Used by the CPU (or DMA) to specify the physical memory address or I/O port it wants to read from or write to. The 8086 has a 20-bit address bus (lines $\text{A}_0$ to $\text{A}_{19}$), allowing it to address $2^{20} = 1\text{MB}$ of memory.

2. Data Bus: Used to transfer data between the CPU and memory/I/O devices. The 8086 has a 16-bit data bus (lines $\text{D}_0$ to $\text{D}_{15}$).

3. Control Bus: Used to carry control signals that govern the activities on the system, such as $\text{READ}/\text{WRITE}$ signals, $\text{Ready}$, and $\text{Interrupt}$ signals.


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