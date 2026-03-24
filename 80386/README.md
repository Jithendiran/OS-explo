
## 80386 or i386 or x86_32
The 8086 architecture faced significant limitations regarding memory management and security. The transition to the 80386 processor introduced hardware-level multitasking, resolving these core issues.

**Limitations of the 8086 Architecture**
* **Memory Fragmentation**: Fixed memory splitting prevents any single program from utilizing the total available capacity. if we have two process A 600KB space divided into two 300KB segments restricts individual process growth.
* **Scalability Issues**: Increasing the number of multitasking processes further reduces the memory available to each individual program.
* **Lack of Isolation**: Program A can unintentionally overwrite or corrupt the memory space belonging to Program B.
* **Security Vulnerabilities**: Any user-level program maintains the ability to modify the Interrupt Vector Table (IVT), risking system stability.

**Advancements in the 80386 Architecture**
* **Virtual Memory Space**: Each program operates within its own dedicated view of the entire memory resource. Hardware handles the swapping or replacement of content during process switches.
* **Privilege Levels**: Memory modification is restricted to authenticated processes. Only high-privilege code can alter critical system segments.
* **Process Protection**: Memory isolation ensures that two processes with equal privilege levels cannot interfere with each other’s data unless shared memory is explicitly defined.

## Contents
1. [Memory](./Memory.md)
    - Registers, Segments 
2. [Modes](./Modes.md)
    - Real mode
    - protected mode
    - virtual mode
3. [Protected mode](./Protected_mode.md)
    - GDT
    - LDT
    - IDT
    - TSS
4. [Protection](./Protection.md)
    - CPL, RPL, DPL
    - Control transfer with in a task
5. [Paging](./paging.md) 
6. [IO](./IO.md)
    - IOPL
    - TSS I/O map


Ensuring the Same Reset Vector

The physical address where the CPU fetches its first instruction after reset is called the **Reset Vector**. Both processors were designed to start at the last 16 bytes of the 1MB Real Mode address space: **$\text{FFFF0h}$**.

* **8086 Address Calculation (CS $\times$ 10h + IP):**
    $$\text{FFFFh} \times \text{10h} + \text{0000h} = \text{FFFF0h}$$

* **80286 Address Calculation (CS $\times$ 10h + IP):**
    $$\text{F000h} \times \text{10h} + \text{FFF0h} = \text{F0000h} + \text{FFF0h} = \text{FFFF0h}$$

Since the **calculated physical address remains the same** ($\text{FFFF0h}$), compatibility with the existing BIOS ROM location is maintained.

[Refer](https://css.csail.mit.edu/6.858/2014/readings/i386.pdf)


