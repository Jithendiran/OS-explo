## Task

[Refer](https://pdos.csail.mit.edu/6.828/2014/readings/i386/c07.htm)

80836 uses hardware stack switch using the task data structure and register (Task state segment, Task state segment descriptor, Task register and Task gate descriptor).  80386 offers two other task-management features:
1. Interrupts and exceptions
    When interrupt or exeception occurs 80386 automatically switch to task that handles then it will switch back to the interrupted task 
2. With each task switch, the 80386 can also switch to respective LDT and to another page directory. 

## Task State Segment
- All the information the processor needs in order to manage a task is stored in a special type of segment, a task state segment
- Task state segments may reside anywhere in the linear space.
**Anatomy**
1. A dynamic set that the processor updates with each switch from the task. This set includes the fields that store:
    * The general registers (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI)(32bit).
    * The segment registers (ES, CS, SS, DS, FS, GS)(16bit).
    * The flags register (EFLAGS)(32bit).
    * The instruction pointer (EIP)(32bit).
    * The selector of the TSS of the previously executing task (updated only when a return is expected)(16bit).
2. A static set that the processor reads but does not change. This set includes the fields that store:
    * The selector of the task's LDT. (16bit)
    * The register (PDBR) that contains the base address of the task's page directory (read only when paging is enabled) (32bit).
    * Pointers to the stacks for privilege levels 0-2(ss-16, ESP 32).
    * The T-bit
    * The I/O map

## TSS Descriptor
- It is similar to other descriptor the difference is only in `Type`'s 2nd bit it is known as busy bit. When the processor starts executing a task, it sets this bit to 1. If the processor attempts to switch to a task and sees the Busy bit is already 1, it triggers a General Protection Fault.
- It is available only in GDT, GDT points to TSS, that TSS holds the selectors (CS, DS,...), those selectors can point to LDT
- The LIMIT field, however, must have a value equal to or greater than 103
- The larger limit is used when TSS has 
    1. The I/O Permission Bit Map
    2. OS-Specific Data : Thread Local Storage or task-specific metadata.
        CPU only care about 1st 104 bytes, remaining for software use
- A procedure that has access to a TSS descriptor can cause a task switch
- TSS Descriptors are "Execute-Only": You can use a TSS descriptor to start a task , but the CPU will trigger an error if you try to use it to read or write the data inside.
- To change a task's settings, the OS must create a separate Data Segment descriptor that points to the same memory address. You use the "Data" version to edit the task and the "TSS" version to run it.

## Task Register
- The task register (TR) identifies the currently executing task by pointing to the TSS.
- TR has 16 bit visible register, it has the selector to the TSS in GDT.
- The processor uses the invisible portion to cache the base and limit values from the TSS descriptor.

## Task Gate Descriptor
- Task Gate Descriptor in GDT points to TSS
- lives in IDT and LDT
- RPL = Task Gate selector's bit 0 and 1
- DPL controls rights to use the descriptor to cause a task switch, permission MAX(RPL, CPL) <= DPL
- A procedure that has access to a **task gate has the power to cause a task switch**, just as a procedure that has access to a TSS descriptor. If task gate permission is passed the DPL of the TSS descriptor is ignored.
    - CPL=3, Gate DPL=3, TSS DPL=0 : Success : Gate DPL is the only "lock" the caller needs to open.
    - CPL=3, Gate DPL=0, TSS DPL=3 : Failure : Caller fails the check at the Gate; TSS DPL is never checked.
    - CPL=0, Gate DPL=3, TSS DPL=0 : Success : Kernel always has higher privilege than the gate.
    - Attempt to access a TSS Descriptor directly withoutout Task gate, then regular check against DLP is mandatory
- why the Task Gate is present?
    1. TSS Descriptor only present in GDT, but when a interrupt or exception happen there should be a entry in IDT which will cause the task switch
    2. Some times low privilege process may need to switch task but since TSS descriptor only lives in GDT, there can be a task gate in LDT which will point to GDT it can cause task switch. System software can limit the right
    3. Each task should have only one TSS descriptor, There may, however, be several task gates that select the single TSS descriptor.

## Task Switching
Possibilities
1. The current task executes a JMP or CALL that refers to a TSS descriptor.
2. The current task executes a JMP or CALL that refers to a task gate.
3. An interrupt or exception vectors to a task gate in the IDT.
4. The current task executes an IRET when the NT flag is set.

1. The Descriptor Type (For CALL and JMP)
    When you use a CALL or JMP instruction, you provide a selector. The CPU looks up that selector in the GDT (Global Descriptor Table). The Type field in that descriptor tells the CPU what to do:
    * Standard Mechanism: If the descriptor is a "Code Segment," the CPU just jumps to a new address in the current task.
    * Task Switch Variant: If the descriptor is a Task Gate or a TSS, the CPU stops everything, saves all current registers to the current TSS, and loads the new task's state.
    
    To cause a task switch, a JMP or CALL instruction can refer either to a TSS descriptor or to a task gate. The effect is the same in either case: the 80386 switches to the indicated task.
2. The NT (Nested Task) Bit (For IRET)
    The IRET (Interrupt Return) instruction is usually used to exit an interrupt. However, it behaves differently depending on the NT bit in the EFLAGS register:
    * Standard Mechanism (NT = 0): The CPU assumes it’s just returning from a simple function or interrupt. It pops the stack and continues.
    * Task Switch Variant (NT = 1): The CPU realizes the current task was "called" by another task. Instead of a simple return, it performs a task switch back to the previous task (using the "Back Link" pointer in the TSS).

    An exception or interrupt causes a task switch when it vectors to a task gate in the IDT and interrupt or trap gate in the IDT does not cause task switch

A task switching operation involves these steps:

1. Permission check
    - JMP or CALL treats as regular descriptor check.  DPL of TSS or task Gate >= max(CPL, RPL of selector). 
    - Exceptions (divide-by-zero,.. error), interrupts (keyboard press,..), and IRET (returning from an interrupt) are permitted to switch tasks regardless of the DPL of the target task gate or TSS descriptor.
2. TSS descriptor check
    - Is present and had a valid limit(greater than 103 bytes).
3. Saving current state
    - Get the current TSS from TR invisible cache
    - It copies the registers into the current TSS (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI, ES, CS, SS, DS, FS, GS, and the flag register). The EIP field of the TSS points to the instruction after the one that caused the task switch.
4. TR register
    - The selector is either the operand of a control transfer instruction or is taken from a task gate.
        - JMP (Far Jump): JMP selector:offset. If the selector points to a TSS descriptor or Task Gate, the CPU ignores the offset and performs a task switch.
        - CALL (Far Call): CALL selector:offset. Similar to JMP, but this version treats the tasks as "nested," setting the "Back Link" field in the new TSS so you can return to the original task.
        - INT n (Software Interrupt): If the Interrupt Descriptor Table (IDT) entry for vector n is a Task Gate, the CPU performs a task switch to the handler task.
        - IRET (Interrupt Return): If the NT (Nested Task) bit in the EFLAGS register is set, IRET doesn't just return from a function; it performs a task switch back to the task pointed to by the "Back Link" in the current TSS.

    - TR loads with TSS descriptor selector, then mark this TSS as busy, then set TS (task switched) bit of the MSW.
        - Selector Loading: The TR (Task Register) is updated with the new 16-bit selector.Selector Loading: The TR (Task Register) is updated with the new 16-bit selector.
        - Descriptor Loading: The CPU automatically loads the "hidden" part of the TR with the base address and limit from the GDT (Global Descriptor Table).
        - Marking Busy: The "Type" field in the TSS descriptor in the GDT is changed from 9 (Available 386 TSS) to 11 (Busy 386 TSS). This prevents a task from recursively calling itself.
5. Loading new state
    - Based on the new TSS load the states
    -  The registers loaded are the LDT register; the flag register; the general registers EIP, EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI; the segment registers ES, CS, SS, DS, FS, and GS; and PDBR
6. Complete the flow
    - execution of that task is resumed, it starts after the instruction that caused the task switch. 
    - The registers are restored to the values they held when the task stopped executing.
    - Setting TS Bit: The TS (Task Switched) bit in Machine Status Word (CR0) is set to 1. This is a flag for the FPU (Floating Point Unit) to let the OS know it might need to save/restore math registers.
    
Because a task has its own TSS (which saves its registers) and its own Address Space (its own page tables), it is essentially a separate universe. The CPU doesn't care if the "Old Task" was a lowly User program and the "New Task" is a high-privilege Kernel task. Since they don't share memory or registers, the Old Task cannot "leak" its influence into the New Task.

Unlike a standard CALL instruction—where your privilege level is checked against the target—a task switch resets the privilege level entirely.

The new task begins executing at the privilege level indicated by the RPL of the CS selector value that is loaded from the TSS.