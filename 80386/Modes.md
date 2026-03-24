## 1. Real Address Mode (Real Mode)
This is the "Legacy Mode." When you power on an 80386, it starts in Real Mode to act exactly like an 8086.
- Address Space: Limited to 1 MB.
- Registers: Default to 16-bit (though you can use 32-bit registers with special prefixes).
- Segmentation: Uses the fixed (Segment * 16) + Offset calculation.
- Protection: None. Any program can overwrite BIOS data or the OS.

## 2. Protected Virtual Address Mode (Protected Mode)
This is the "Native Mode" of the 80386 and where your OS kernel will spend most of its time. This mode unlocks the full power of the chip.
- Address Space: Full 4 GB (32-bit).
- Segmentation: Uses Selectors and Descriptors (GDT/LDT) instead of simple math.
- Paging: Allows for Virtual Memory—mapping a "fake" address to a "real" physical one.
- Privilege Levels: Introduces Rings (Ring 0 for Kernel, Ring 3 for Apps). This prevents an app from crashing the whole system.
- Multitasking: Hardware support for switching between different program tasks (though most modern OSs do this in software now).

* **Rings**
    When you switch the 80386 into Protected Mode, the CPU begins enforcing Privilege Levels (0-3). It does this by checking bits inside the Segment Selectors and Segment Descriptors.

    **How the CPU knows the Ring:**
    The Ring level is stored in the bottom 2 bits of the Code Segment register (CS). This is called the CPL (Current Privilege Level).
    00 = Ring 0 (Highest privilege/Kernel)
    11 = Ring 3 (Lowest privilege/User Applications)

    **While Virtual 8086 (V86) mode looks like Real Mode to the program running inside it, it actually runs at Ring 3. If the V86 program tries to do something privileged (like an I/O operation), the CPU traps the instruction and hands control to the Protected Mode kernel (Ring 0).**

    **What the Rings actually do:**
    1. Restricted Instructions: Certain "Privileged Instructions" (like lgdt to load a GDT, hlt to stop the CPU, or out to hardware ports) will cause a General Protection Fault if executed in Ring 3.
    2. Memory Access: A segment descriptor in the GDT has a DPL (Descriptor Privilege Level). If a Ring 3 program tries to access a Ring 0 data segment, the CPU hardware blocks the move.
    3. Paging Protection: In the Page Tables, there is a U/S (User/Supervisor) bit. If the bit is set to Supervisor, Ring 3 code cannot even see that memory.

    **Ring 0: The Kernel**
    - Capabilities: Can execute Privileged Instructions (like HLT to stop the CPU, LGDT to load the GDT, or modifying Control Registers like CR0 and CR3).
    - Memory Access: Has unrestricted access to all system memory and I/O ports.
    - Responsibility: Manages hardware, interrupts, and memory mapping for everyone else.

    **Ring 1: The Device Driver Layer**
    Intel designed Ring 1 to house the software that talks to hardware (drivers), but shouldn't have the power to destroy the core kernel.
    - Capabilities: Higher than Ring 3, but lower than Ring 0. It can execute most instructions but is barred from "Global" CPU management (like loading a new GDT or shutting down the processor).
    - Memory Access: Can access its own data and Ring 2/3 data. It cannot access Ring 0 memory (the Kernel's private variables or Page Directories) unless explicitly allowed by the GDT.
    - Responsibility: To act as the interface between the "Abstract OS" and the "Physical Hardware." This is where your video card, network, and disk drivers were supposed to live.
    - Restrictions: Cannot modify the Control Registers (CR0-CR4). If a driver in Ring 1 crashes, it might hang the hardware, but it theoretically shouldn't be able to corrupt the Kernel's memory tables.
    - Hardware Access: Access to I/O ports is controlled by the IOPL (I/O Privilege Level) bits in the EFLAGS register. Usually, Ring 1 is given permission to use IN and OUT instructions, whereas Ring 3 is not.

    **Ring 2: The System Services Layer**
    Ring 2 was intended for "Trusted Subsystems." Think of things that provide a service to the user but don't need to touch the metal of the hardware.
    - Capabilities: Very similar to Ring 3, but with the ability to call Ring 1 drivers more easily.
    - Memory Access: Can access Ring 2 and Ring 3 memory. It is blocked from Ring 0 and Ring 1 memory.
    - Responsibility: Historically intended for File Systems, Database Engines, or Network Stacks. For example, a File System needs to organize data (logic), but it doesn't need to know how the hard drive's motor spinning works (Ring 1).
    - Restrictions: Cannot execute any privileged instructions. It is strictly for "Logic" that is more trusted than a standard user app but less trusted than a driver.
    - Hardware Access: Usually denied. Ring 2 would have to make a "Call" to a Ring 1 driver to actually move data to a disk or screen.

    **Ring 3: User Land (Least Privileged)**
    This is where your applications like a web browser, a compiler, or a game—run.
    - Restrictions: Cannot execute privileged instructions. If a program tries to run CLI (Clear Interrupts) in Ring 3, the CPU will instantly trigger a General Protection Fault (#GP).
    - Memory Access: Can only see memory that the Kernel has specifically mapped for it via Paging. It cannot touch the Kernel's memory or another program's memory.
    - Hardware Access: Cannot talk to hardware directly. It must ask the Kernel to do it via a System Call.

## 3. Virtual 8086 Mode (V86 Mode)
This is a "sub-mode" of Protected Mode. It’s a stroke of genius that allowed the 386 to run old 16-bit Real Mode apps inside a protected 32-bit environment.
- How it works: The CPU creates a "Virtual Machine" that looks like an 8086 with a 1 MB limit.
- The Catch: It runs under the control of a Protected Mode monitor (the OS). If the 16-bit app tries to do something "illegal" (like touching hardware), the CPU triggers an exception and hands control back to your OS.
- Usage: This is how Windows 3.1 or OS/2 could run multiple DOS windows simultaneously without one crashing the others.