## LDT
The LDT is a secondary table that holds segment descriptors. The LDT entry in the GDT follows the System Descriptor format. It uses the same 8-byte structure as your GDT entries. However, the CPU doesn't have a "LDTR Base Address" that points directly to RAM. Instead, the LDT is a resource described inside the GDT.

LDT follows the same structure as GDT, LDT usually stores only ring 3 Privilege.

When $S=0$, the 4-bit "Type" field defines the specific system object. In the LDT, only one primary type is functional. That is  Call Gates: This is the most common system descriptor found in an LDT. It allows a lower-privilege application to transition to a higher-privilege code segment (defined in the GDT).
- You cannot have a descriptor for an LDT inside another LDT.
- TSS cannot be inside LDT
- Task Gates: While technically possible in some edge cases for specific hardware interrupts, these are almost exclusively stored in the GDT or IDT (Interrupt Descriptor Table).

The Selector: This 16-bit value points to an entry inside the GDT.
The Logic: You are essentially telling the CPU, "Go look at GDT entry #5; that entry contains the base address and size of my current LDT."


**Why can't we deal only with GDT?**
When looking at how a computer manages memory, it is helpful to understand why designers use both a Global Descriptor Table (GDT) and Local Descriptor Tables (LDT).

While it is technically possible to use only a GDT, doing so creates several problems for a modern operating system. Here is why the LDT is used:
1. The Entry Limit
    The GDT has a hard limit of 8,192 entries. In a system with many active programs, this space fills up quickly. Each program needs its own "slots" for code, data, and stacks. If an operating system tries to fit every single program into one global table, it will eventually run out of room.
2. Security and Isolation
    Using an LDT helps keep programs private.
    With only a GDT: One program might be able to "guess" the address of another program's data because everything is in one big list.
3. Faster Task Switching
    When a computer switches from running Program A to Program B, it needs to change how it looks at memory.
    - It is very slow to rewrite thousands of lines in a single global table every time a switch happens.
    - It is much faster to simply tell the processor to point to a different LDT. This is done by changing a single piece of information called the LDTR (Local Descriptor Table Register).

**GDT vs. LDT: Who stores what?**

1. The GDT (Global Descriptor Table)
    The GDT stores "Global" information. This is data that the entire system or the Operating System (OS) needs to access.
    - Kernel Code and Data: These are the core instructions for the OS. Since the OS manages everything, its "map" must be in the global table.
    - TSS (Task State Segments): Think of these as "save files." They store the state of a task so the computer can pause it and come back to it later.
    - LDT Descriptors: The GDT actually holds the "address" or pointer to where each program's private LDT is located.
    - Call Gates: These act as security checkpoints. They allow a regular program to safely ask the OS to perform a high-level task.
2. The LDT (Local Descriptor Table)
    The LDT stores "Private" information. Each program usually has its own LDT that contains data specific to that one task.
    - User Program Code: This is the actual logic and instructions for a specific app (like a web browser or a game).
    - User Data and Stack: This is the private memory where the app stores its variables and temporary calculations.
    - Shared Libraries: If an app uses a specific set of tools or code shared with other parts of that process, those "maps" are kept here.


**How it works?**

1. The Setup: Giving the LDT a Home
    The CPU cannot find an LDT on its own. It needs the GDT to act as a map.
    - In the GDT: You create a special entry (a descriptor).
    - The Goal: This entry doesn't hold code or data; it holds the physical address of where the LDT starts in the memory (for example, at address 0x7000).

2. The Link: Loading the LDTR
    To tell the CPU which program is currently running, the Operating System uses a special command called LLDT.
    - Instead of giving the CPU a memory address, the OS gives it a Selector (like an index number) that points to the GDT.
    - The CPU looks at that index in the GDT, finds the address 0x7000, and saves it in a high-speed internal slot called the LDTR (LDT Register).
        1. OS finds the Selector: It knows Process B's LDT is at GDT Index 5.
        2. OS executes LLDT 0x28: (Index 5 * 8 = 40, or 0x28).
        3. CPU "Shadows" the Address: The CPU goes to GDT Index 5, grabs the Base Address (e.g., 0x9000), and stores it in a hidden "Shadow Register."
            * When the LLDT instruction loads a segment selector in the LDTR: the base address, limit, and descriptor attributes from the LDT descriptor are auto-matically loaded in the LDTR.

            * When a task switch occurs, the LDTR is automatically loaded with the segment selector and descriptor for the LDT for the new task. The contents of the LDTR are not automatically saved prior to writing the new LDT information into the register.

3. Execution: Finding Private Memory
    When a program wants to run its own private code, it uses a selector where the TI (Table Indicator) bit is set to 1.
   

    Imagine a program is currently running. The CPU needs to find the next instruction to execute. To do this, it looks at the CS (Code Segment) register.
    - CS Register Value: 0x000F
    - Instruction Pointer (EIP): 0x00002000

    1. Step 1: Breaking Down the CS Selector
        The CPU first looks at the binary version of 0x000F to understand what it means.
        - Binary: 0000 0000 0000 1 | 1 | 11
        - Index: 1 (The first three bits are ignored for the index).
        - TI Bit: 1 (This tells the CPU: "Look in the LDT!")
        - RPL: 3 (This means it is running in "User Mode").

    2. Step 2: Finding the LDT Base
        Because the TI Bit is 1, the CPU goes to its internal LDTR register.
        - The LDTR was already set up by the OS to point to the address 0x7000.
        - The CPU now knows the "Private Table" for this program starts at 0x7000.

    3. Step 3: Finding the Segment Descriptor
        The CPU needs to find Index 1 inside that LDT table.
        - Each entry (descriptor) is 8 bytes long.
        - Calculation: $Base + (Index \times 8) \rightarrow 0x7000 + (1 \times 8) = 0x7008$.
        - The CPU reads the data at 0x7008. It finds a "Base Address" stored there—let's say it is 0x50000000.

    4. Step 4: Calculating the Final Address
        Now the CPU has everything it needs to find the actual code in the RAM. It adds the "Base Address" from the LDT to the "Offset" in the EIP.
        - LDT Base Address: 0x50000000
        - EIP (Offset): + 0x00002000
        - Final Physical Address: 0x50002000
