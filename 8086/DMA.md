The flow for a standard DMA operation in the 8086 Minimum Mode, typically involving an external **DMA Controller** (like the 8237).

## 8086 Minimum Mode DMA Flow

The DMA process involves three main phases: Request, CPU Relinquishes Control (Hold Acknowledge), and Data Transfer.


### Phase 1: CPU Setup (Programming the Controllers)

The CPU executes Programmed I/O ($\text{OUT}$) instructions to set up the transfer. Using $\text{OUT}$, it command the DMA controller

| Action | Doer | Instruction/Target | Purpose |
| :--- | :--- | :--- | :--- |
| **Set Memory Address** | CPU | $\text{OUT}$ to DMA Controller | Writes the starting **destination (Read)** or **source (Write)** RAM address. |
| **Set Transfer Count** | CPU | $\text{OUT}$ to DMA Controller | Writes the total number of bytes/words to move. |
| **Set Direction & Mode** | CPU | $\text{OUT}$ to DMA Controller | Writes the control word specifying if it's an **I/O Read** or **I/O Write** operation. |
| **Send I/O Command** | CPU | $\text{OUT}$ to Peripheral | **Initiates the transfer.** Tells the peripheral: "Start preparing data for a transfer (Read) or get ready to receive data (Write)." |

### Phase 2: DMA Request and CPU Hold

The process begins when a peripheral device needs to transfer a large block of data.

DRQ (DMA Request) is a pin on the DMA Controller chip, such as the 8237.

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Peripheral Request** | I/O Device | $\text{DRQ}$ (to DMA Controller) | The peripheral asserts its **DMA Request** line to the DMA Controller (e.g., 8237). |
| **Controller Request** | DMA Controller | $\mathbf{\text{HOLD}}$ (CPU Pin 31) | The DMA Controller asserts the $\mathbf{\text{HOLD}}$ pin to the 8086 CPU, requesting control of the system bus. |
| **CPU Completion** | 8086 CPU | Internal | The CPU completes its current bus cycle (if one is in progress) and prepares to tri-state its buses. |
| **CPU Acknowledge** | 8086 CPU | $\mathbf{\text{HLDA}}$ (CPU Pin 30) | The CPU asserts **Hold Acknowledge** ($\mathbf{\text{HLDA}}$) back to the DMA Controller. |

### Phase 3: CPU Bus Relinquishment (Tri-State)

Upon receiving $\mathbf{\text{HOLD}}$, the CPU acknowledges the request and effectively gets out of the way.

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **CPU Tri-States** | 8086 CPU | $\text{AD0-AD15}, \text{A16-A19}, \text{M}/\overline{\text{IO}}, \overline{\text{RD}}, \overline{\text{WR}}, \text{DT}/\overline{\text{R}}, \overline{\text{DEN}}, \text{ALE}$ | The CPU sets all its bus control and address/data lines to a **High-Impedance (Tri-State)** state. |
| **Controller Takes Over** | DMA Controller | $\mathbf{\text{HLDA}}$ (Input) | The $\text{HLDA}$ signal informs the DMA Controller that it now has exclusive control over the system buses. |

### Phase 4: DMA Data Transfer Cycles

The DMA Controller now becomes the **Bus Master** and performs the necessary data transfers between the peripheral and memory. The CPU remains in a paused state until the transfer is complete.

The DMA Controller executes a series of bus cycles, one for each word/byte transfer, until the transfer count is reached. 

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Output Address** | DMA Controller | $\text{A0-A19}$ | The Controller drives the next **20-bit Memory Address** onto the bus. |
| **Output Control** | DMA Controller | $\text{M}/\overline{\text{IO}}$ (HIGH) | The Controller asserts the $\mathbf{\text{M}/\overline{\text{IO}}}$ pin for a **Memory** operation. |
| **Command Strobe** | DMA Controller | $\overline{\text{MEMR}}$ / $\overline{\text{MEMW}}$ | The Controller asserts the appropriate memory command signal (read from or write to memory). |
| **I/O Command** | DMA Controller | $\overline{\text{IOR}}$ / $\overline{\text{IOW}}$ | The Controller asserts the appropriate I/O command signal (read from or write to the I/O device). |
| **Data Transfer** | Peripheral/Memory | $\text{D0-D15}$ | Data flows directly between the peripheral and memory over the data bus. |
| **Transfer Completion**| DMA Controller | Internal | The Controller decrements its internal counter and increments its address register. |

> **Note:** A DMA transfer typically uses **Hidden Bus Cycles** (sometimes called a "fly-by" transfer) where the DMA controller generates the memory address and the control signals for both the memory and the I/O device simultaneously, making the transfer very fast (one bus cycle per byte/word).

$\overline{\text{MEMR}}$, $\overline{\text{IOW}}$, $\overline{\text{MEMW}}$, and $\overline{\text{IOR}}$ are generally not pins on the 8086 CPU itself.

These signals are the separate, dedicated command signals produced by an external control chip typically  by the DMA Controller (like the 8237) during a DMA cycle.

In **Minimum Mode** , the 8086 simplifies its control by using **combined and directional** pins:

* $\overline{\text{RD}}$ (Read Command)
* $\overline{\text{WR}}$ (Write Command)
* $\text{M}/\overline{\text{IO}}$ (Memory/IO Selector)

The external circuitry must combine these three signals to figure out the exact operation (e.g., $\overline{\text{RD}} + \text{M}/\overline{\text{IO}}(\text{HIGH}) = \text{Memory Read}$).

| Signal | Active State | Full Meaning | Generated By |
| :--- | :--- | :--- | :--- |
| $\mathbf{\overline{\text{MEMR}}}$ | LOW | **Memory Read** Command | DMA Controller |
| $\mathbf{\overline{\text{MEMW}}}$ | LOW | **Memory Write** Command | DMA Controller |
| $\mathbf{\overline{\text{IOR}}}$ | LOW | **I/O Read (Input)** Command | DMA Controller |
| $\mathbf{\overline{\text{IOW}}}$ | LOW | **I/O Write (Output)** Command | DMA Controller |

### Phase 5: Release of Control

When the full block of data has been transferred, the DMA Controller signals the CPU that it is done.

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Controller Drops Request** | DMA Controller | $\mathbf{\text{HOLD}}$ (HIGH) | The Controller deasserts the $\mathbf{\text{HOLD}}$ signal, releasing the request for bus control. |
| **CPU Resumes** | 8086 CPU | $\mathbf{\text{HLDA}}$ (LOW) | The CPU deasserts $\text{HLDA}$ in response, signaling the end of the DMA cycle. |
| **CPU Bus Takeover** | 8086 CPU | All Buses | The CPU immediately reactivates its bus control and address/data lines, resuming normal instruction execution from where it left off. |


## Types of DMA Mode

The types of DMA transfer modes define **how** the DMA Controller (DMAC) shares the system bus with the CPU to manage the transfer speed and CPU performance impact.

The three primary DMA modes for data transfer are:

1.  **Burst Mode**
2.  **Cycle Stealing Mode**
3.  **Transparent Mode**


### 1. Burst Mode (Block Transfer)

Burst mode is the **fastest** method for large data transfers, but it completely **halts the CPU** for the duration of the transfer.

* **Mechanism:** The DMAC asserts $\text{HOLD}$ and holds control of the system bus until the **entire block of data** is transferred (i.e., until the word count register reaches zero or an $\overline{\text{EOP}}$ signal is received).
* **CPU Impact:** The CPU is **blocked (held)** for the entire duration of the transfer.
* **Advantage:** Maximizes transfer speed and efficiency by minimizing the overhead of requesting and releasing the bus.
* **Disadvantage:** Can cause latency issues for time-critical peripherals, as the CPU is completely unresponsive until the burst is finished.
* **Used For:** High-speed, bulk data transfers like loading program segments from a hard disk drive (HDD) or solid-state drive (SSD).


### 2. Cycle Stealing Mode

Cycle Stealing mode provides a compromise, balancing high transfer speed with less severe CPU blockage.

* **Mechanism:** The DMAC transfers only **one byte or one word** of data per request.
    * The DMAC asserts $\text{HOLD}$ and transfers one data unit.
    * It then **releases the bus** by deasserting $\text{HOLD}$, allowing the CPU to execute instructions.
    * The peripheral re-asserts $\text{DRQ}$ for the next byte/word transfer.
* **CPU Impact:** The CPU is only **paused for one bus cycle** at a time. This slows the transfer speed but allows the CPU to continue executing its program in short intervals.
* **Advantage:** Good for devices that are too slow for burst mode but still need DMA. It prevents the CPU from being completely locked out.
* **Disadvantage:** High overhead due to the constant requesting ($\text{HOLD}$) and acknowledging ($\text{HLDA}$) for every single transfer.
* **Used For:** Slower, continuous streaming devices like early magnetic tape or audio devices.


### 3. Transparent Mode

Transparent mode has the lowest impact on CPU performance but is the slowest method of DMA transfer.

* **Mechanism:** The DMAC only requests the bus control ($\text{HOLD}$) when the CPU is already performing **internal operations** and is guaranteed *not* to use the bus. This often occurs during instruction decoding or internal register manipulation.
* **CPU Impact:** The CPU is **never actually stopped**; the transfer occurs during "free" bus cycles, making the DMA transfer invisible (transparent) to the CPU.
* **Advantage:** Does not slow down the CPU's program execution at all.
* **Disadvantage:** The DMA transfer speed is highly variable and often very slow, as the DMAC must wait for the CPU's internal cycles.
* **Used For:** Applications where CPU execution time is critical, and the transfer delay is acceptable.


### Additional Mode: Demand Mode (8237 Specific)

The **8237 DMA Controller** also supports a **Demand Mode**, which is a variation of Burst Mode.

* **Mechanism:** The transfer continues in a burst as long as the peripheral **keeps the $\text{DRQ}$ line asserted** (i.e., as long as the I/O device can *demand* data transfer).
* **Termination:** The transfer terminates if the transfer count reaches zero, an external $\overline{\text{EOP}}$ (End of Process) is received, or the **peripheral deasserts $\text{DRQ}$** (meaning its buffer is temporarily empty or full). The transfer resumes automatically when the peripheral re-asserts $\text{DRQ}$.
* **Used For:** Devices that transfer large blocks but may occasionally pause during the operation (e.g., waiting for a slow physical media rotation).