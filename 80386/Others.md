## IDT

[refer](https://www.scs.stanford.edu/05au-cs240c/lab/i386/s09_05.htm)

In 8086 used Interrupt Vector Table (IVT). It is just a list of 4-byte pointers (Segment:Offset) located at the very start of memory (0000:0000).

The 80386 replaced this with the Interrupt Descriptor Table (IDT). The 8086 was "open." Any program could change the IVT, which often led to system crashes. The 80386 introduces Protection. The IDT allows the operating system to define not just where the code is, but who is allowed to trigger it and how the processor should behave when it happens.

The IDT is an array of 256 "Gate Descriptors each 8-byte descriptors (Gates). While  8086 IVT was fixed at address 0, the IDT can live anywhere in the 4GB memory space. The CPU finds it using a special register called the IDTR (Interrupt Descriptor Table Register), which stores the table's base address and size.

When a hardware interrupt or a software exception occurs, the CPU uses an index to find the correct entry in this table. Each entry in the IDT is called a Gate

**Here is how those 8 bytes are broken down:**

* Offset (32 bits): Divided into two 16-bit chunks (the low bits at the start, the high bits at the end). This is the actual memory address of the Interrupt Service Routine (ISR).
* Segment Selector (16 bits): Unlike the 8086, which used a segment address, this points to an entry in the GDT (Global Descriptor Table). It tells the CPU which code segment to use.
    **Why the IDT must look for the GDT?**
    In the 8086, an interrupt vector simply contained a segment and an offset (CS:IP). However, the 80386 introduces Privilege Levels (Rings 0 through 3).

* Reserved (5 bits): Always set to zero.
* Gate Type (5 bits): Defines what kind of gate this is (Task Gate, Interrupt Gate, or Trap Gate).
* DPL (2 bits): The Descriptor Privilege Level. This is the security guard. It defines which "Ring" (0 through 3) is allowed to access this interrupt.
* P (1 bit): The Present bit. If this is 0, the CPU triggers an error because the code isn't currently in memory.

IDT contains any of these Task gates, Interrupt gates and Trap gates


![IDT](./res/IDT_DES.png)

**Why is it required? (What it solved)**
1. Security : On an 8086, any program could jump into an interrupt handler or overwrite the IVT. In the 386+, a program can only trigger an interrupt if it has the right Privilege Level (DPL). It ensures that code running in a restricted mode (Ring 3) cannot execute sensitive instructions unless the IDT explicitly allows a path to the kernel (Ring 0).
2. State Management: When an interrupt happens on an 8086, the CPU just pushes Flags, CS, and IP, It has single stack were user program and interrupt service handler will be working. On a 386+, the IDT works with the TSS to automatically switch to a secure "Kernel Stack," ensuring a user-mode crash doesn't break the interrupt handler.
3. Flexibility: It allows for different types of entries (Task, Interrupt, and Trap gates), each behaving differently regarding hardware interrupts and task switching.

**How it work?**
1. The CPU receives the interrupt vector (e.g., 13 for General Protection Fault). It multiplies this by 8 (the size of a descriptor) and adds it to the base address stored in the IDTR register.
    - Segment Selector: Extracted from the IDT entry.
    - Offset: Extracted from the IDT entry.
    - TI Bit: The CPU checks Bit 2 of the Selector. If 0, it uses GDTR; if 1, it uses LDTR.

2. The CPU treats the Segment Selector from the IDT as a pointer into the chosen table (GDT or LDT).
    - It retrieves the Segment Descriptor from that table.
    - This descriptor contains the Base Address and the Limit (size) of the code segment where the handler lives.

3. The CPU performs two specific checks:
    - Gate Check: The CPL (the privilege of the code that was running) must be numerically less than or equal to the DPL of the IDT Gate. This prevents user-mode programs (Ring 3) from manually triggering sensitive hardware interrupts via the INT n instruction unless permitted.
    - Target Check: The CPL must be numerically greater than or equal to the DPL of the Target Code Segment (found in the GDT/LDT). This ensures the interrupt is "elevating" privilege (e.g., moving from Ring 3 to Ring 0).

4. The final linear address is calculated as: $$\text{Linear Address} = \text{Segment Base (from GDT/LDT)} + \text{Offset (from IDT)}$$

**The Gate Descriptors**

1. Interrupt Gate : This is used for hardware (like the system clock or keyboard).
2. Trap Gate    : This is used for software exceptions
3. Task Gate : Hardware Multitasking


## TSS
[Refer](https://www.scs.stanford.edu/05au-cs240c/lab/i386/s07_01.htm)

In the 8086 era, if a program crashed or went into an infinite loop, the whole system froze. There was no "clean" way for the hardware to save exactly what one program was doing and instantly switch to another.

The TSS was created to solve Hardware Task Switching. It allowed the CPU to treat a "task" (a running program) as an object that could be paused and resumed.

Think of the TSS as a data structure in memory that acts as a snapshot. When the Operating System wants to switch from Task A to Task B, the CPU automatically "dumps" all the current register values into Task A's TSS and "loads" the values from Task B's TSS.

A TSS is a 104-byte block of memory


**What it solved:**
* Isolation: It prevented one program from accidentally using the registers or stack of another.
* Multitasking: It provided a hardware-level "save game" slot for the CPU's state.
* Privilege Levels: It helped the CPU manage the jump between "User Mode" (apps) and "Kernel Mode" (the OS) securely.

Modern linux almost stopped using TSS, only for kernel stack switch it uses 

When a User (Ring 3) program triggers an Interrupt Gate to enter the Kernel (Ring 0), the CPU refuses to use the user's stack (it might be full or malicious). The CPU looks inside the TSS to find the ESP0 (the "Known Good" Kernel Stack pointer). Without a TSS, the CPU would have nowhere to store data when moving from a low privilege to a high privilege, causing a "Triple Fault" (instant reboot).

## Gates

Gates are the "controlled entry points" that allow a program to pass from one level of privilege to another in a safe, synchronized way.

Technically, a Gate is a special type of Descriptor. While a standard descriptor describes a block of memory (like data or code), a Gate describes an entry point to a function or a task.

If a User Application in Ring 3 needs to talk to the Hard Drive (which is a Ring 0 task), it cannot simply jump into the Kernel's code. If it did, it might crash the system. Gates solve this by providing a specific, pre-defined "window" where the switch is allowed to happen.

**Why do they exist?**
The 8086 had no "Rings." Every program was essentially a "Superuser." The 80386 introduced Ring 0 (The Kernel/OS) and Ring 3 (The User Applications).

**How a Gate Works**
When the 80386 encounters a CALL or INT instruction pointing to a Gate, it doesn't just jump. It performs a multi-step "Handshake":
1. Privilege Check: The CPU compares the requester's privilege (CPL) against the Gate’s privilege (DPL). If you aren't "cleared" to use this gate, the CPU triggers a General Protection Fault.
2. The Switch: If cleared, the CPU automatically switches the Stack. Since Ring 3 and Ring 0 shouldn't share a stack for security reasons, the Gate tells the CPU where the "secure stack" is located.
3. The Jump: Finally, the CPU loads the new Code Segment (CS) and Instruction Pointer (EIP) from the Gate and begins execution.

### Task gate
A Task Gate is an entry in a descriptor table (the GDT, LDT, or IDT) that points directly to a TSS.

On 8086, if wanted to switch tasks, had to manually save all registers to memory, swap stack pointers, and jump to the new code. A Task Gate tells the CPU: "When someone calls this gate, pause everything and perform a full hardware context switch to the task defined in this TSS."

**Why is it required?**
1. Automated Switching: It triggers the hardware to save the current CPU state and load a new one in a single instruction (CALL or JMP).
2. Handling "Total Meltdowns": This is the most important use today. If the system has a "Double Fault" (a crash so bad the CPU can't even run the error handler), a Task Gate can point to a "Safe Task" with its own clean stack to try and recover the system.
3. Isolation: It allows an interrupt (like a keyboard press) to trigger a specific, isolated task without interfering with whatever the user is currently doing.

Modern linux stopped using TSS gate

**How it Works?**
When the CPU hits a Task Gate (via a CALL instruction or an Interrupt), the following happens automatically in hardware:
1. The Pause: The CPU stops the current code.
2. The Save: It takes all current registers ($EAX, EIP, ESP, etc.$) and writes them into the current TSS.
3. The Load: It goes to the Task Gate, finds the new TSS, and sucks all those values into the CPU registers.
4. The Link: It sets a "Busy" bit so the task can't re-enter itself, and optionally links the new task to the old one (the "Backlink").
5. The Resume: The CPU starts executing at the new $EIP$.

### Call gate

A Call Gate is a specialized Descriptor in a system table (the GDT or LDT). Instead of a program calling a memory address directly, it calls the "Gate."

Think of it as a controlled entry point. On the 8086, a program could walk through any door in the house. With a Call Gate, all the doors are locked, and the program must go through a specific hallway where its "ID" is checked before it can enter the room.

in call gate CPU ignore the EIP given in instruction and take from descriptor table, to make sure call only enter in entry on the code not in middle 

**Structure**
* **call gate descriptor**
- Selector - 16 bit (Points to the the executable code index in descriptor table)
- Count    - 5 bit (No of parameter)
- zero     - 3 bit (not used)
- Type     - 5 bit (says call gate)
- DPL      - 2 bit (determine what privilege levels can use the gate)
- P        - 1 bit (is present in memory)
- Offset   - 32 bit 

![call gate descriptor](./res/callgate.png)


**Why is it required?**
1. Privilege Transition: **It allows a low-privilege application (Ring 3) to execute code in the high-privilege Kernel (Ring 0) without giving the application full control over the CPU**.
2. Hiding the Address: The application doesn't need to know where the Kernel code is located in memory. It only needs to know the "Selector" for the Gate.
3. Parameter Validation: The hardware can automatically copy parameters from the user’s stack to the kernel’s stack to prevent memory corruption.

**How it Works?**
In a system using Call Gates, the process changes:
1. The program issues a CALL to a Selector (e.g., CALL 0x0040:0x0).
2. The CPU sees that 0x40 points to a Call Gate, not a code segment.
3. The CPU checks the CPL (Current Privilege Level). If the program is allowed to use this gate, the CPU proceeds.
4. The CPU automatically switches to the Kernel Stack
5. The CPU jumps to the actual address stored inside the Gate.

Linux does not use call gates

### Interrupts
Both the Interrupt and Trap gates share the same 8-byte format, but their "Type" bits differ.
It stored only in IDT

Offset (0-15):	The lower 16 bits of the handler's address.
Selector :	The 16-bit Code Segment.
DPL :	Descriptor Privilege Level (Who can trigger this?).
Offset (16-31):	The upper 16 bits of the handler's address.

#### The Interrupt Gate
The Interrupt Gate is designed primarily for Hardware Interrupts (like your Keyboard or System Clock).
When a hardware device pulls the "Interrupt" pin on the CPU, the CPU looks up the Interrupt Gate. Its special "superpower" is that it automatically clears the IF (Interrupt Flag).

While the interrupt can happen at any privilege level, the handler (the code that fixers the interrupt) almost always runs in Ring 0.

When a hardware interrupt occurs, the CPU performs an automatic "Privilege Level Transition":
1. The Interrupted State: The CPU might be running a web browser in Ring 3.
2. The Trigger: A hardware signal arrives at the CPU's pins.
3. The Lookup: The CPU consults the IDT
4. The Promotion: The IDT entry points to a Code Segment in the GDT that is marked as DPL 0 (Kernel Mode).
5. The Switch: The CPU automatically switches from Ring 3 to Ring 0 to execute the Interrupt Service Routine (ISR).

**Hardware Interrupts Ignore the DPL of the Gate**
- Software Interrupt: If a Ring 3 program tries to call a Ring 0 gate, the CPU checks the IDT Gate's DPL. If they don't match, it triggers a General Protection Fault.
- Hardware Interrupt: The CPU ignores the DPL of the IDT gate. Because hardware is "impartial," it is allowed to redirect the CPU to a Ring 0 handler regardless of what code was running at the time.
    If the CPU is in Ring 3 and a hardware interrupt moves it to Ring 0, the CPU cannot use the Ring 3 stack (it is untrusted and might overflow).
    - The CPU automatically looks into a special structure called the TSS (Task State Segment).
    - It finds the Ring 0 Stack Pointer (ESP0).
    - It switches to the Kernel Stack before saving the registers.

#### Trap gate
A Trap Gate is a descriptor that tells the CPU how to handle a "software-initiated" event, like an exception (division by zero) or a specific program request.

The biggest difference between a Trap Gate and an Interrupt Gate  is how they handle the "Interrupt Flag" ($IF$):
* Interrupt Gate: Automatically disables interrupts (clears $IF$) so no other hardware can bother the CPU while it's working.
* Trap Gate: Leaves the Interrupt Flag alone. Other hardware interrupts can still fire while the trap handler is running. If a program crashes (Trap), the kernel needs to handle it, but the system clock and keyboard should keep running in the background.


**How the CPU uses** 
1. The Event: An event happens (Hardware fires or Code crashes).
2. The Index: The CPU multiplies the interrupt number by 8 (because each gate is 8 bytes) to find the entry in the IDT.
3. The Check: The CPU checks the DPL. If a User program tries to trigger a "Kernel Only" gate, the CPU generates a General Protection Fault.
4. The Stack Switch: The CPU looks at the TSS to find the Kernel's Stack. It pushes the old CS, EIP, and EFLAGS onto the new stack.
5. The IF Flip: If it's an Interrupt Gate, the CPU sets $IF = 0$. If it's a Trap Gate, it does nothing.
6. The Jump: The CPU loads the Selector and Offset from the Gate and starts running the handler.
