# RAM

## Detailed Flow: Memory Read Operation ($\mathbf{T1 - T4}$)

This sequence details the actions taken by the **CPU** (Initiator) and the **Memory/External Circuits** (Recipient) during the minimum mode four T-states to fetch data from RAM.


### $\mathbf{T1}$: The Address Strobe (Labeling)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Output Address** | CPU | $\text{A1-A19}$ | CPU **drives** the upper 19 bits of the memory address onto the bus. |
| **Output Byte Select** | CPU | $\mathbf{A0}$ (LOW/HIGH) | **LOW** ($\text{A0}=0$) selects the **Even Byte** ($\text{D0-D7}$). **HIGH** ($\text{A0}=1$) selects the **Odd Byte** ($\text{D8-D15}$). |
| **Output High Enable** | CPU | $\mathbf{\overline{\text{BHE}}}$ (LOW/HIGH) | **LOW** ($\overline{\text{BHE}}=0$) indicates the **High Byte** ($\text{D8-D15}$) is involved. (This pin serves as $\text{S7}$ after $\text{T1}$). |
| **Assert $\text{ALE}$** | CPU | $\text{ALE}$ (HIGH Pulse) | Provides a **strobe** signal for the external latch circuits to capture all address and byte-select information ($\text{A0}-\text{A19}$ and $\overline{\text{BHE}}$). |
| **Assert $\text{M}/\overline{\text{IO}}$** | CPU | $\text{M}/\overline{\text{IO}}$ (HIGH) | Tells the system this is a **Memory** operation, not I/O. |
| **Latch Address** | External Latch | Input | On the $\text{ALE}$ falling edge, the latch **captures and holds** the address, freeing the $\text{AD}$ lines. The address and BHE is stored in memory circuit |

The $\mathbf{\text{S7}}$ status bit is always HIGH (Logic 1) during the $\text{T2-T4}$ phases when the CPU is operating in Minimum Mode.

**When $\text{ALE}$ is Deasserted (Drops)?**

$\text{ALE}$ drops (goes LOW) at the end of T1.
* The latch circuit does not send a notification back to the CPU. The CPU's timing is internally determined by its clock and control logic. The latch circuit is designed to capture the address on the falling edge (HIGH-to-LOW transition) of the $\text{ALE}$ signal.

* By dropping $\text{ALE}$ at the end of $\text{T1}$, the CPU achieves its goal: it separates the address (latched externally) from the data/status information that will follow on the same pins in $\text{T2, T3, T4}$.

**what would happen if CPU needs to read only low byte or full word, but address for that value' $\text{A0}$ is 1 what it would do?**

The CPU's Bus Interface Unit (BIU) handles this misaligned access automatically, which involves generating multiple bus cycles and internal data manipulation

* Scenario 1: Full 16-bit Word Read (Misaligned)
    * Since the address is odd ($\text{A0}=1$), the 16-bit word spans two physically separate memory banks and two addresses.
    * The CPU breaks the single read instruction into **two separate 8-bit bus cycles**:
        1.  **1st Cycle:** Reads the High Byte (the lower addressed byte) via the $\text{D8-D15}$ lines ($\mathbf{\overline{\text{BHE}}}=0, \mathbf{\text{A0}}=1$).
        2.  **2nd Cycle:** Reads the Low Byte (the higher addressed byte) via the $\text{D0-D7}$ lines ($\mathbf{\overline{\text{BHE}}}=1, \mathbf{\text{A0}}=0$).
    * The CPU then **internally reassembles** the two bytes into the correct 16-bit word. This takes twice as long as an aligned read.

* Scenario 2: Low Byte Read Only (Odd Address)
    * The CPU calculates the location is an **odd address** ($\text{A0}=1$), meaning the data resides in the **High Bank** connected to the $\text{D8-D15}$ lines.
    * The CPU performs a **single bus cycle** using $\mathbf{\overline{\text{BHE}}}=0$ and $\mathbf{\text{A0}}=1$ to enable the High Bank.
    * The byte is transferred over the $\text{D8-D15}$ data lines.
    * The CPU then **internally shifts** this received byte from the high lines down to the low byte of the target register.


### $\mathbf{T2}$: The Command and Direction (Ordering)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Assert $\mathbf{\text{RD}'}$** | CPU | $\text{RD}'$ (LOW) | Sends the **Read Command** to the memory device, telling it to prepare the data. |
| **Assert $\overline{\text{DEN}}$** | CPU | $\overline{\text{DEN}}$ (LOW) | **Enables** the external Data Transceivers, preparing them for data transfer. |
| **Assert $\mathbf{\text{DT}/\overline{\text{R}}}$** | CPU | $\text{DT}/\overline{\text{R}}$ (LOW, $\overline{\text{R}}$ state) | Configures the Transceivers to flow data **FROM** the bus **TO** the CPU (Receive). |
| **Output Status** | CPU | $\mathbf{\text{S3-S6}}$ | These bits are **valid from $\mathbf{T2}$ onwards**:
| $\mathbf{\text{S6}}$ | Always **LOW** (0). |
| $\mathbf{\text{S5}}$ | Indicates the state of the **Interrupt Enable Flag ($\text{IF}$)**. |
| $\mathbf{\text{S4} / \text{S3}}$ | Encodes the **Segment Register** used for the address (e.g., $\text{SS}, \text{DS}, \text{CS}$). |
| **Address Decoding** | Memory Circuit | $\text{A0-A19}$ (Latched) | Memory uses the latched address to locate the requested data word. |
| **Deassert $\text{READY}$** | Memory Circuit |  $\text{READY}$ (LOW) | The memory system must drive this line low near the end of $\text{T2}$ (or early $\text{T3}$) if it anticipates needing wait states. |

**Why $\mathbf{\overline{\text{DEN}}}$ (Data Enable) is Needed**

External Data Transceivers boost the CPU's driving capacity for the data lines ($\text{D0-D15}$). These transceivers are essentially switches that must be turned ON and OFF at the correct times to ensure a clean data transfer.

$\overline{\text{DEN}}$ performs two critical functions:

1. Preventing Bus Contention During T1

    During the $\mathbf{T1}$ state, the $\text{AD0-AD15}$ lines are carrying the **Address**. If the Data Transceivers were constantly active (enabled), they would be attempting to drive the address lines, which is incorrect for a data transfer device and could cause signal conflict (contention) on the bus.

    * $\overline{\text{DEN}}$ is **HIGH** (Inactive) during $\mathbf{T1}$.
    * This ensures the Data Transceivers are **disabled** (electrically disconnected) during the address phase, allowing only the $\text{ALE}$ and the address to be correctly handled.

2. Timing the Data Window (Enabling the Transfer)

    $\overline{\text{DEN}}$ is only asserted **LOW** (Active) from $\mathbf{T2}$ through $\mathbf{T4}$ of the bus cycle.

    * The CPU uses $\overline{\text{DEN}}$ as the **"Go!" signal** for the data buffers.
    * Once $\overline{\text{DEN}}$ goes LOW, the Transceivers are **enabled**, and they immediately follow the direction set by $\text{DT}/\overline{\text{R}}$. This creates a clean, dedicated time window for the data to be driven onto or read from the bus.



**Why $\mathbf{\text{DT}/\overline{\text{R}}}$ is Needed?**

In the 8086 system (especially in Minimum Mode), the Data Bus ($\text{D0-D15}$) is often connected to the CPU through a set of external chips called Data Transceivers (or buffers), like the 8286 or 8287. These chips are necessary to boost the electrical driving power of the data signals. The $\text{DT}/\overline{\text{R}}$ pin's job is to tell these external transceivers which way the data should flow through them.

* CPU Asserts $\mathbf{\text{RD}'}$ (Read Command):This is the command that tells the **Memory Chi**p to put its data onto the bus.The CPU is now acting as the Recipient of the data.

* CPU Asserts $\mathbf{\text{DT}/\overline{\text{R}}}$ (Direction Control):For a Read operation, the CPU wants to Receive data.Therefore, the CPU drives the $\text{DT}/\overline{\text{R}}$ pin $\mathbf{LOW}$ ($\mathbf{\overline{\text{R}}}$ state).This LOW signal tells the **external Data Transceive**r: "Set your internal switch to allow data to flow from the Bus INTO the CPU."


### $\mathbf{T3}$: Data Setup and Synchronization (Waiting)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Output Data** | Memory Device | $\text{D0-D15}$ (Data Bus) | The memory chip **drives** the requested 16-bit data onto the data lines. |
| **Sample $\text{READY}$** | CPU | $\text{READY}$ (Input) | CPU **checks** if the memory has delivered the data and is ready to finish the cycle. |
| **Insert Wait States** | CPU | $\mathbf{T_W}$ (States) | **If $\text{READY}$ is LOW**, the CPU pauses here, inserting $\mathbf{T_W}$ states to give the slow memory time to finish. |

### $\mathbf{T_w}$: CPU Halt/Wait
| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Asserts $\text{READY}$** | Memory Device | $\text{READY}$ (HIGH) |  The Memory Device Drive $\text{READY}$ HIGH . When Data is ready|


### $\mathbf{T4}$: Data Transfer and Cycle End (Receiving)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Read Data** | CPU | $\text{D0-D15}$ (Internal) | CPU **latches** the data from the Data Bus into an internal register (e.g., the instruction queue or $AX$). |
| **Deassert $\mathbf{\text{RD}'}$** | CPU | $\text{RD}'$ (HIGH) | Terminates the read command and tells the memory device to stop driving the bus. |
| **Deassert $\overline{\text{DEN}}$** | CPU | $\overline{\text{DEN}}$ (HIGH) | **Disables** the Data Transceivers, removing the CPU's influence from the bus lines. |
| **Cycle Complete** | All | Bus lines | The entire bus system returns to an **idle state**, ready for the next bus cycle ($\text{T1}$). |
| **Status Update** | CPU | $\mathbf{\text{S3-S6}}$ | Status signals remain valid until the end of $\text{T4}$. |


## Write flow

In write flow every thing remains same as read, only the $\text{RD}'$ and $\text{DT}/\overline{\text{R}}$ pins are swapped and the data is output by the CPU instead of the memory.

Captured only changed states

### $\mathbf{T2}$: The Command and Direction (Ordering)
| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| Assert $\mathbf{\text{WR}'}$ | CPU | $\text{WR}'$ (LOW) | Sends the Write Command to the memory device, telling it to prepare to accept data.|
|**Output Data**| CPU | $\text{D0-D15}$ (on $\text{AD}$ lines) | The CPU begins outputting the data it wants to write. |
| $\cdots$ |  $\cdots$ |  $\cdots$ |  $\cdots$ |
Assert $\mathbf{\text{DT}/\overline{\text{R}}}$ | CPU |  $\text{DT}/\overline{\text{R}}$ (HIGH, $\text{T}$ state)| Configures the Transceivers to flow data FROM the CPU TO the bus (Transmit).|
| $\cdots$ |  $\cdots$ |  $\cdots$ |  $\cdots$ |

The CPU continues to drive the data onto the bus for the memory to receive till $T_{3}$

### $\mathbf{T4}$: Cycle End (Terminating)
| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| Deassert $\mathbf{\text{WR}'}$ | CPU | $\text{WR}'$ (HIGH) |  Terminates the write command. This signal's HIGH-to-LOW transition is often used by the memory chip to internally latch the data into its cells. |
| Stop Driving Data | CPU |  $\text{D0-D15}$ (Data Bus) | The CPU stops driving the data onto the bus. |
| $\cdots$ |  $\cdots$ |  $\cdots$ |  $\cdots$ |

# I/O

The **I/O (Input/Output)** operation flow is nearly identical to the Memory flow, but with one critical change: the state of the $\mathbf{\text{M}/\overline{\text{IO}}}$ pin.


##  Detailed Flow: I/O Read (Input) Operation ($\mathbf{T1 - T4}$)

An I/O Read operation fetches data from a peripheral device (like a keyboard controller or a network card) located at a specific port address. The **address** for I/O is only 16 bits ($\mathbf{\text{A0}}$ to $\mathbf{\text{A15}}$).

### $\mathbf{T1}$: The Address Strobe (Port Selection)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Output Address** | CPU | $\text{A0-A15}$ | CPU **drives** the 16-bit **I/O Port Address** onto the bus lines ($\text{AD0-AD15}$). |
| **Assert $\text{ALE}$** | CPU | $\text{ALE}$ (HIGH Pulse) | **Strobes** external latches to capture the I/O port address. |
| **Assert $\mathbf{\text{M}/\overline{\text{IO}}}$** | CPU | $\text{M}/\overline{\text{IO}}$ (**LOW**) | **CRITICAL CHANGE:** Tells the system this is an **I/O** operation. |
| **Latch Address** | External Latch | Input | On the $\text{ALE}$ falling edge, the latch **captures and holds** the port address, freeing the $\text{AD}$ lines. |
| **$\mathbf{\overline{\text{BHE}}}$ State** | CPU | $\overline{\text{BHE}}$ | The $\overline{\text{BHE}}$ pin (and $\text{A0}$) is still used to select a byte or word I/O port transfer. |


### $\mathbf{T2}$: The Command and Direction (Ordering)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Assert $\mathbf{\text{RD}'}$** | CPU | $\text{RD}'$ (LOW) | Sends the **Read Command (Input)** to the I/O port. |
| **Assert $\overline{\text{DEN}}$** | CPU | $\overline{\text{DEN}}$ (LOW) | **Enables** the external Data Transceivers. |
| **Assert $\mathbf{\text{DT}/\overline{\text{R}}}$** | CPU | $\text{DT}/\overline{\text{R}}$ (LOW, $\overline{\text{R}}$ state) | Configures the Transceivers to flow data **FROM** the bus **TO** the CPU (Receive). |
| **Output Status** | CPU | $\mathbf{\text{S3-S6}}$ | Status bits are **valid from $\mathbf{T2}$ onwards**. |
| **Port Decoding** | I/O Circuit | Latched $\text{A0-A15}, \overline{\text{BHE}}$ | The I/O circuitry uses the port address to locate the target peripheral register. |
| **Drive $\text{READY}$ LOW** | I/O Circuit | $\text{READY}$ (LOW) | If required, the I/O device signals that it needs wait states to prepare the data. |


### $\mathbf{T3}$: Data Setup and Synchronization (Waiting)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Output Data** | I/O Device | $\text{D0-D15}$ (Data Bus) | The I/O device **drives** the requested data onto the data lines. if data is ready |
| **Sample $\text{READY}$** | CPU | $\text{READY}$ (Input) | CPU **checks** if the I/O device has delivered the data. |
| **Insert Wait States** | CPU | $\mathbf{T_W}$ (States) | **If $\text{READY}$ is LOW**, the CPU pauses here, inserting $\mathbf{T_W}$ states. |

### $\mathbf{T_W}$: CPU Halt/Wait

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Drive $\text{READY}$ HIGH** | I/O Circuit | $\text{READY}$ (HIGH) | The I/O device signals that the data is stable and ready, causing the CPU to proceed to $\mathbf{T4}$. |


### $\mathbf{T4}$: Data Transfer and Cycle End (Receiving)

| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Read Data** | CPU | $\text{D0-D15}$ (Internal) | CPU **latches** the data from the Data Bus into the target register. |
| **Deassert $\mathbf{\text{RD}'}$** | CPU | $\text{RD}'$ (HIGH) | Terminates the read command. |
| **Deassert $\overline{\text{DEN}}$** | CPU | $\overline{\text{DEN}}$ (HIGH) | **Disables** the Data Transceivers. |
| **Cycle Complete** | All | Bus lines | The bus returns to an idle state. |


##  Key Differences for I/O Write (Output)

For an **I/O Write (Output)** operation, the differences are the same as the differences between a Memory Read and a Memory Write:

1.  **Command:** The CPU asserts **$\mathbf{\text{WR}'}$ (LOW)** instead of $\text{RD}'$.
2.  **Direction:** The CPU asserts **$\mathbf{\text{DT}/\overline{\text{R}}}$ (HIGH)** to set the transceivers for **Transmit**.
3.  **Data Flow:** The CPU **Output Data** in $\text{T1}$ and $\text{T2/T3}$, and the I/O device **receives** the data.
4.  **Termination:** The rising edge of **$\mathbf{\text{WR}'}$ (Deasserted HIGH)** in $\text{T4}$ signals the I/O port to internally **latch** the output data.

# MMIO
MMIO (Memory-Mapped I/O) is a technique where peripheral registers are addressed as if they were standard memory locations.
The CPU doesn't know it's talking to an I/O device; it just knows it's accessing a memory address.

## Bus Cycle

MMIO Bus Cycle: Same as Memory

The fundamental difference lies not in the CPU's pins, but in how the external hardware is wired to the address bus.

### 1. The CPU's Action (Identical to Memory Access)

The CPU executes a standard Memory Read (e.g., $\text{MOV AX, [Address]}$) or Memory Write (e.g., $\text{MOV [Address], AX}$) instruction.

* **T1:** The CPU outputs a **20-bit address** ($\text{A0-A19}$) and asserts $\mathbf{\text{M}/\overline{\text{IO}}}$ **HIGH** (Memory access).
* **T2:** The CPU asserts **$\mathbf{\text{RD}'}$ or $\mathbf{\text{WR}'}$** and sets the $\text{DT}/\overline{\text{R}}$ direction.
* **T3/T4:** The data transfer happens, controlled by $\text{READY}$.

### 2. The External Hardware's Role (The Difference)

The distinction happens in the **Address Decoding Logic**:

| Cycle Phase | Action | Purpose in MMIO |
| :--- | :--- | :--- |
| **Address Decoding** | The decoding circuit monitors the 20-bit address ($\text{A0-A19}$). | If the address falls within a predetermined range reserved for a peripheral (e.g., addresses $\text{F0000H}$ to $\text{FFFFFH}$), the decoder activates the peripheral instead of the main RAM. |
| **$\text{M}/\overline{\text{IO}}$ Signal** | The $\mathbf{\text{M}/\overline{\text{IO}}}$ pin is $\mathbf{HIGH}$ (Memory). | Because the address decoder handles the selection, the peripheral must be configured to respond *only* when $\text{M}/\overline{\text{IO}}$ is **HIGH**. |
| **Control Signals** | The decoder routes the $\text{RD}'$ and $\text{WR}'$ signals directly to the peripheral's internal registers. | The peripheral's registers treat $\text{RD}'$ as a command to output data (Input) and $\text{WR}'$ as a command to accept data (Output). |






https://ece-research.unm.edu/jimp/310/slides/8086_chipset.html

T1

(I/0)           A0-3        = 0 
(I/0)           A4-A15      = 1   
(O)             A16-A19     = 1    = FFF0
(I)     17      NMI         = 0 (grd)(static)
(I)     18      INTR        = 0 (grd)(static)
(O)     34      BHEB        = 0                         Active
(I)     33      MN/MXB      = 5v (static)
(O)     32      RDB         = 1
(I)     31      HOLD        = grd(static)
(O)     30      HOLDA       = 0
(O)     29      WRB         = 1
(O)     28      M/IOB       = 1                         Memory
(O)     27      DT/RB       = 0                         Receive
(O)     26      DENB        = 1
(O)     25      ALE         = 1                         Active
(O)     24      INTAB       = 1                         
(I)     23      TEST        = grd(static)
(I)     22      READY       = 5v(static)

ALE is active treat the bus data as address
Address is active output FFF0, Bus High Enable is active, Memory is selected, Address is active
Address is 20 bit long so it need BHE actie
Output's address and it is for memory

external device must take the address

T2

(I/0)           A0-1        = 0
(I/0)           A2          = 1
(I/0)           A4-A15      = 0   
(O)             A16-A19     = 0   

(I)     17      NMI         = 0 (grd)(static)
(I)     18      INTR        = 0 (grd)(static)
(O)     34      BHEB        = 0                         Active
(I)     33      MN/MXB      = 5v (static)
(O)     32      RDB         = 0                         Active
(I)     31      HOLD        = grd(static)
(O)     30      HOLDA       = 0
(O)     29      WRB         = 1
(O)     28      M/IOB       = 1                         Memory
(O)     27      DT/RB       = 0                         Receive
(O)     26      DENB        = 1
(O)     25      ALE         = 0
(O)     24      INTA        = 1
(I)     23      TEST        = grd(static)
(I)     22      READY       = 5v(static)

ALE goes of, means Bus is not holding address also Data enable (DENB) is not active so it is not an data in bus
Bus neigther have data/address

Read is enabled,  it is preparing for Receive operation

in DT/RB is enabled, it is preparing for Receive operation

external device must get to know about the operation


T3

(I/0)           A0-1        = 0
(I/0)           A2          = 1
(I/0)           A4-A15      = 0   
(O)             A16-A19     = 0   

(I)     17      NMI         = 0 (grd)(static)
(I)     18      INTR        = 0 (grd)(static)
(O)     34      BHEB        = 0                         Active
(I)     33      MN/MXB      = 5v (static)
(O)     32      RDB         = 0                         Active
(I)     31      HOLD        = grd(static)
(O)     30      HOLDA       = 0
(O)     29      WRB         = 1
(O)     28      M/IOB       = 1                         Memory
(O)     27      DT/RB       = 0                         Receive
(O)     26      DENB        = 0                         Active
(O)     25      ALE         = 0
(O)     24      INTA        = 1
(I)     23      TEST        = grd(static)
(I)     22      READY       = 5v(static)

Now  Data enable (DENB) is active means it is enabled the bus for data, now BUS treat as data
Now it is performing data transfer
DTRB is active which means it is receiving the data

T4

(I/0)           A0-1        = 0
(I/0)           A2          = 1
(I/0)           A4-A15      = 0   
(O)             A16-A19     = 0   

(I)     17      NMI         = 0 (grd)(static)
(I)     18      INTR        = 0 (grd)(static)
(O)     34      BHEB        = 0                         Active
(I)     33      MN/MXB      = 5v (static)
(O)     32      RDB         = 1                         
(I)     31      HOLD        = grd(static)
(O)     30      HOLDA       = 0
(O)     29      WRB         = 1
(O)     28      M/IOB       = 1                         Memory
(O)     27      DT/RB       = 0                         Receive
(O)     26      DENB        = 1                         
(O)     25      ALE         = 0
(O)     24      INTA        = 1
(I)     23      TEST        = grd(static)
(I)     22      READY       = 5v(static)

Now RDB and DENB is disabled which mean data operation is completed, 
8086 is no longer access the bus, but it is doing the internal operations during this cycle