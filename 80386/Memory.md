## Registers

All the general registers are capable of 32bit

[Refer](https://www.eeeguide.com/registers-of-80386-microprocessor/)

### Segment registers
Segment registers are 16bit, New segment registers were introduced `FS & GS (Additional Data Segment)`

### Control Registers
These are 32-bit registers used to define the operating mode of the CPU and manage paging.
- CR0
    * PE (Bit 0): Protection Enable. Set this to 1 to switch from Real Mode to Protected Mode.
    * PG (Bit 31): Paging. Set this to 1 to enable Virtual Memory.
- CR1: Reserved for future processors (not used in the 386).
- CR2: Page Fault Linear Address. If the CPU hits a memory error (Page Fault), it stores the address that caused the error here.
- CR3: Page Directory Base Register (PDBR). This holds the physical address of the very first table used in Paging.

### Debug and Test Registers
The 386 introduced hardware-level debugging
- DR0–DR3: Debug Address Registers. You can store 4 memory addresses here, and the CPU will automatically trigger a "Breakpoint" if the program tries to access them.
- DR4-DR5: are reserved by Intel.
- DR6: Debug Status Register.
- DR7: Debug Control Register.
- TR6–TR7: This is for caching, TR6 is known as test control and TR7 is called a test status register.

### System Address Registers
The Three big table registers 

- GDTR: Global Descriptor Table Register (48 bits).
- IDTR: Interrupt Descriptor Table Register (48 bits).
- LDTR: Local Descriptor Table Register (Holds a "Selector" to the LDT).
- TR: Task Register. Points to the current TSS (Task State Segment) for multitasking.

### Invisible Registers
Each segment register actually consists of two parts:
1. The Visible Part (Selector): The 16-bit register you can see and modify (e.g., MOV AX, DS).
2. The Invisible Part (Descriptor Cache): A "hidden" 64-bit (approx.) register that the CPU uses to store information about the segment.

In the 8086, the CPU just did a simple bit-shift: $Segment \times 16 + Offset$. 

In the 80386 Protected Mode, every time you access memory, the CPU has to check:
- What is the Base Address?
- What is the Limit (size)?
- Do you have Permission (Read/Write/Execute)?
- What is the Privilege Level (Ring 0-3)?

If the CPU had to go to RAM and look up the GDT (Global Descriptor Table) for every single instruction, the computer would slow down

When you execute an instruction like MOV DS, AX:
1. The CPU takes the value in AX (the Selector).
2. It uses that selector as an index to find an entry in the GDT or LDT in RAM.
3. It fetches the Segment Descriptor (8 bytes of data) from RAM.
4. It "caches" that data into the Invisible/Hidden part of the DS register.

The cache stores the processed version of the Segment Descriptor:
- Base Address: The 32-bit starting point of the segment.
- Limit: How big the segment is (to prevent "buffer overflow" style crashes at the hardware level).
- Attributes: 
    * Type: Is it code or data?
    * DPL: Descriptor Privilege Level (Which "Ring" owns this?).
    * Presence: Is this segment actually in RAM right now?


### EFLAGS
The 8086 had a 16-bit FLAGS register. The 80386 extended this to a 32-bit EFLAGS register.
Most of the new bits are used for managing Protected Mode and multitasking. Key new flags include:
- VM (Virtual 8086 Mode): Bit 17. If this is set, the 386 creates a "sandbox" that acts exactly like an 8086 while still running inside Protected Mode. This is how old DOS programs could run inside Windows.
- RF (Resume Flag): Bit 16. Used with debug registers to prevent the CPU from getting stuck in an infinite loop on a breakpoint.
- NT (Nested Task): Bit 14. Used for hardware multitasking. It tells the CPU if the current task was "called" by another task (linked via the TSS).
- IOPL (I/O Privilege Level): Bits 12-13. Defines which "Ring" is allowed to perform I/O instructions like IN and OUT. If a program in Ring 3 tries to touch hardware without permission, the CPU triggers a fault.

## Address calculation
In Real Mode, the 80386 behaves exactly like a very fast 8086
$$Physical\ Address = (Segment \times 16) + Offset$$

1. Real Mode
    If you are using standard 16-bit instructions, the math is identical to the 8086:
    Max Address: $0xFFFF \times 16 + 0xFFFF = 0x10FFEF$ (just over 1MB).

2. Protected Mode: Segmentation
    In Protected Mode, the value in a Segment Register (CS, DS, SS, etc.) is no longer a base address. It is now a Selector. This selector acts as an index into a table called the Global Descriptor Table (GDT).
    $$\text{Linear Address} = \text{Segment Base (from GDT)} + \text{32-bit Offset}$$

3. Paging
    If paging is enabled (via the CR0 register), the Linear Address is not the final physical address. It is broken down into three parts to navigate a hierarchy of tables.

   **The 10-10-12 Split:**
   A 32-bit Linear Address is divided as follows:
   - Directory Index (10 bits): Selects an entry in the Page Directory.
   - Table Index (10 bits): Selects an entry in a Page Table.
   - Offset (12 bits): The specific byte within the 4 KB physical page.

4. The A20 Gate (The "Wrap" Problem)
    On the original 8086, if you calculated an address like 0x100010, it would "wrap around" and actually access 0x00010 because there were only 20 physical wires (address lines) on the chip.

    On the 80386, To maintain backward compatibility, IBM added a physical logic gate to the 21st address line (A20).
    - A20 Disabled (Default): The A20 line is forced to 0. Memory wraps around just like the 8086.
    - A20 Enabled: The A20 line functions normally, allowing you to access all 4 GB of memory on your 386.