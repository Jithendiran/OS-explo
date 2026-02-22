## Detailed Flow: Memory Read Operation ($\mathbf{T1 - T4}$)

This sequence details the actions taken by the **CPU** (Initiator) and the **Memory/External Circuits** (Recipient) during the minimum mode four T-states to fetch data from RAM.


### $\mathbf{T1}$: The Address Strobe (Labeling)

| Pin Num | Mnemonic | I/O Type | State | Note / Function |
| --- | --- | --- | --- | --- |
| **-** | A0​−A3 | I/O | `0` | Lower Address Bits |
| **-** | A4​−A15  | I/O | `1` | Middle Address Bits |
| **-** | A16​−A19 | O | `1` | High Address (`FFF0H`) |
| **17** | NMI | I | `0` (GND) |  |
| **18** | INTR  | I | `0` (GND) | I |
| **34** | BHEB | O | `0` | **Active**: Bus High Enable |
| **33** | MN/MXB | I | `5V` | **Minimum Mode** (Static power) |
| **32** | RDB | O | `1` | |
| **31** | HOLD | I | `GND` |  |
| **30** | HOLDA| O | `0` | |
| **29** | WRB | O | `1` |  |
| **28** | M/IOB | O | `1` | **Memory** Access Mode |
| **27** | DT/RB  | O | `0` | **Receive** Data Direction |
| **26** | DENB | O | `1` |  |
| **25** | ALE | O | `1` | **Active**: Address Latch Enable |
| **24** | INTAB | O | `1` |  |
| **23** | TEST | I | `GND` | Test Pin (Static power) |
| **22** | READY | I | `5V` | Processor Ready (Static power) |

- ALE is active treat the bus data as address
- Address is active output FFF0, Bus High Enable is active, Memory is selected, Address is active
- Address is 20 bit long so it need BHE actie
- Output's address and it is for memory
- External device must take the address

The $\mathbf{\text{S7}}$ status bit is always HIGH (Logic 1) during the $\text{T2-T4}$ phases when the CPU is operating in Minimum Mode.

By dropping $\text{ALE}$ at the end of $\text{T1}$, the CPU achieves its goal: it separates the address (latched externally) from the data/status information that will follow on the same pins in $\text{T2, T3, T4}$.


### $\mathbf{T2}$: The Command and Direction (Ordering)

| Pin Num | Mnemonic | Type | State | Note / Function |
| --- | --- | --- | --- | --- |
| **-** |  A0-1  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A2 | I/O | `1` | Address/Data Bus (Tri-state/Floating) |
| **-** |   A4-A15  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A16-A19 | O | `0` | Status bits ($S_3 - S_6$) being output |
| **17** | NMI | I | `0` |  |
| **18** | INTR | I | `0` |  |
| **34** | BHEB | O | `0` | **Active**: High bank access |
| **33** | MN/MXB  | I | `5V` | **Minimum Mode** (Static) |
| **32** | RDB | O | `0` | **Active**: Memory Read initiated |
| **31** | HOLD | I | `GND` |  |
| **30** | HOLDA | O | `0` |  |
| **29** | WRB | O | `1` |  |
| **28** | M/IOB | O | `1` | **Memory** Access Mode |
| **27** |  DT/RB  | O | `0` | **Receive** Data Direction |
| **26** | DENB | O | `1` |  |
| **25** | ALE | O | `0` | |
| **24** | INTA | O | `1` |  |
| **23** | TEST | I | `GND` | Test Pin (Static) |
| **22** | READY | I | `5V` | Processor Ready (Static) |

- ALE goes off, means Bus is not holding address also Data enable (DENB) is not active so it is not an data in bus
- Bus neigther have data/address
- Read is enabled,  it is preparing for Receive operation
- DT/RB is enabled, it is preparing for Receive operation
- External device must get to know about the operation


### $\mathbf{T3}$: Data Setup and Synchronization 

| Pin Num | Mnemonic | Type | State | Note / Function |
| --- | --- | --- | --- | --- |
| **-** |  A0-1  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A2 | I/O | `1` | Address/Data Bus (Tri-state/Floating) |
| **-** |   A4-A15  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A16-A19 | O | `0` | Status bits ($S_3 - S_6$) being output |
| **17** | NMI | I | `0` |  |
| **18** | INTR | I | `0` |  |
| **34** | BHEB | O | `0` | **Active**: High bank access |
| **33** | MN/MXB  | I | `5V` | **Minimum Mode** (Static) |
| **32** | RDB | O | `0` | **Active**: Memory Read initiated |
| **31** | HOLD | I | `GND` |  |
| **30** | HOLDA | O | `0` |  |
| **29** | WRB | O | `1` |  |
| **28** | M/IOB | O | `1` | **Memory** Access Mode |
| **27** |  DT/RB  | O | `0` | **Receive** Data Direction |
| **26** | DENB | O | `0` | **Active** |
| **25** | ALE | O | `0` | |
| **24** | INTA | O | `1` |  |
| **23** | TEST | I | `GND` | Test Pin (Static) |
| **22** | READY | I | `5V` | Processor Ready (Static) |

- Now  Data enable (DENB) is active means it is enabled the bus for data, now BUS treat as data
- Now it is performing data transfer
- DTRB is active which means it is receiving the data

### $\mathbf{T_w}$: CPU Halt/Wait
| Action | Doer | Pin Signal | Purpose |
| :--- | :--- | :--- | :--- |
| **Asserts $\text{READY}$** | Memory Device | $\text{READY}$ (HIGH) |  The Memory Device Drive $\text{READY}$ HIGH . When Data is ready|


### $\mathbf{T4}$: Data Transfer and Cycle End (Receiving)

| Pin Num | Mnemonic | Type | State | Note / Function |
| --- | --- | --- | --- | --- |
| **-** |  A0-1  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A2 | I/O | `1` | Address/Data Bus (Tri-state/Floating) |
| **-** |   A4-A15  | I/O | `0` | Address/Data Bus (Tri-state/Floating) |
| **-** |  A16-A19 | O | `0` | Status bits ($S_3 - S_6$) being output |
| **17** | NMI | I | `0` |  |
| **18** | INTR | I | `0` |  |
| **34** | BHEB | O | `0` | **Active**: High bank access |
| **33** | MN/MXB  | I | `5V` | **Minimum Mode** (Static) |
| **32** | RDB | O | `1` |  |
| **31** | HOLD | I | `GND` |  |
| **30** | HOLDA | O | `0` |  |
| **29** | WRB | O | `1` |  |
| **28** | M/IOB | O | `1` | **Memory** Access Mode |
| **27** |  DT/RB  | O | `0` | **Receive** Data Direction |
| **26** | DENB | O | `1` | |
| **25** | ALE | O | `0` | |
| **24** | INTA | O | `1` |  |
| **23** | TEST | I | `GND` | Test Pin (Static) |
| **22** | READY | I | `5V` | Processor Ready (Static) |

- Now RDB and DENB is disabled which mean data operation is completed, 
- 8086 is no longer access the bus, but it is doing the internal operations during this cycle

### Write flow

In write flow every thing remains same as read, only the $\text{RD}'$ and $\text{DT}/\overline{\text{R}}$ pins are swapped and the data is output by the CPU instead of the memory.


## I/O

The **I/O (Input/Output)** operation flow is nearly identical to the Memory flow, but with one critical change: the state of the $\mathbf{\text{M}/\overline{\text{IO}}}$ pin.


## MMIO
MMIO (Memory-Mapped I/O) is a technique where peripheral registers are addressed as if they were standard memory locations.
The CPU doesn't know it's talking to an I/O device; it just knows it's accessing a memory address.


https://ece-research.unm.edu/jimp/310/slides/8086_chipset.html
