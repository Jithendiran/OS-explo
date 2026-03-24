## 1. GDT (Global Descriptor Table)
The GDT is the most important table. It defines the characteristics of the various memory segments used during program execution.
- What it does: It tells the CPU where memory segments start, how big they are, and who is allowed to access them (the Rings).
- Contents: It contains Descriptors. Each descriptor is 8 bytes long and defines a "window" of memory.
- The Register: You load the address of this table into the CPU using the LGDT instruction, which fills the GDTR register.
- OS Usage: Even if you use Paging, you must have a basic GDT to define at least one Code Segment and one Data Segment to enter Protected Mode.

- [GDT](./GDT.md)

## 2. IDT (Interrupt Descriptor Table)
The IDT is the Protected Mode version of the 8086's Interrupt Vector Table. It tells the CPU what to do when an "event" happens.
- What it does: It maps interrupts (like a timer tick, a keyboard press, or a divide-by-zero error) to specific functions in your kernel code.
- Contents: It contains Gate Descriptors (Task Gates, Interrupt Gates, or Trap Gates).
- The Register: Loaded via the LIDT instruction into the IDTR register.
- OS Usage: This is how you handle system calls and hardware. If an interrupt occurs and you haven't set up an IDT, the CPU will "Triple Fault" and reset the computer.
- [IDT](./Interrupts.md)
- [Exeception](./Exeception.md)

## 3. LDT (Local Descriptor Table)
The LDT is like a "private GDT" for a specific program.
- What it does: While the GDT is system-wide, each task (process) can have its own LDT. This allows processes to have their own private segments that other processes can't see.
- The Register: The address of the current LDT is stored in the LDTR (Local Descriptor Table Register).
- OS Usage: Most modern OSs (Linux/Windows) don't use the LDT. They prefer to use Paging to isolate processes because it's more flexible and faster.
- [LDT](./LDT.md)

## 4. TSS (Task State Segment)
The TSS is a special structure that holds information about a task. On the 80386, it was originally intended for hardware-accelerated multitasking.
- What it does: It stores the state of all registers ($EAX, EBX, ESP, EIP$, etc.) so the CPU can switch from one program to another in a single instruction.
- The Most Important Job: Even if you don't use hardware multitasking, you still need one TSS. Why? Because when a Ring 3 (User) program triggers an interrupt, the CPU needs to switch to a Ring 0 (Kernel) stack. The CPU looks inside the TSS to find the ESP0 value (the Kernel's stack pointer).
- The Register: Loaded via the LTR (Load Task Register) instruction.
- [TSS](./TaskSwitch.md)

## Control Registers
1. CR0: The System Control Register
    CR0 contains various "flags" that enable or disable major CPU features.
    * PE (Protection Enable, Bit 0):Setting this to 1 switches the CPU from Real Mode to Protected Mode.
    * MP (Monitor Coprocessor - Bit 1): This bit works closely with the TS (Task Switched) bit to handle multitasking.
    * EM (Emulation - Bit 2): This is the "Emergency" bit for computers that don't have a math chip at all.
    * TS (Task Switched, Bit 3): The CPU sets this automatically during a hardware task switch.
    * ET ET (Extension Type - Bit 4):This bit tells the CPU what kind of math chip is plugged into the motherboard.
    * WP (Write Protect, Bit 16): (Introduced in 486) Allows the kernel to prevent even Ring 0 from writing to Read-Only pages.
    * PG (Paging, Bit 31): Setting this to 1 enables the Paging mechanism. If this is 0, the CPU only uses Segmentation.

2. CR1: The Reserved Register
3. CR2: The Page Fault Linear Address Register
    * This is a "read-only" register for the programmer, used strictly for debugging Page Faults (Vector 14).
    * When a Page Fault occurs, the CPU automatically stores the 32-bit linear address that the program was trying to access into CR2.
4. CR3: The Page Directory Base Register (PDBR)
    * It holds the Physical Address of the Page Directory for the currently running task.
    * When the CPU needs to translate a virtual address, it looks at CR3 to find where the "Table of Contents" (Page Directory) starts in RAM.