## Privilege

[Refer](https://pdos.csail.mit.edu/6.828/2014/readings/i386/s06_03.htm)

The CPU does not keep a separate "global variable" for the privilege level. Instead, the privilege is baked into the Selector currently loaded in the `CS` register.

- When a code is switched to protected mode and started running
- It will load the code segment selector address into `CS`, Data segment into `DS` register
- Each segment register will have a invisible cahe part, This is a hidden cache inside the CPU. When you load a value into the visible part (CS, DS,..), the CPU automatically goes to the Descriptor Table in RAM, fetches the details for that segment, and save them in this invisible portion.
- Invisible part store the descriptor Base Address, Limit, Type and DPL

* Descriptors contain a field called the descriptor privilege level (DPL).
* Selectors contain a field called the requestor's privilege level (RPL)
* The current privilege level (CPL). Normally the CPL is equal to the DPL of the segment that the processor is currently executing (`CS`). CPL changes as control is transferred to segments with differing DPLs.

**Order of privilege**
1. 00 - most privilege  (can access 00, 01, 10 and 11)
2. 01 - high privilege  (can access 01, 10 and 11)
3. 10 - low privilege   (can access 10 and 11)
4. 11 - least privilege (can access 11)
Each level of has it's own stack

**How the CPL  change?**
The CPL is not something a programmer can change by simply "writing" to the CS register with a MOV instruction. The CPU only allows the CPL to change during specific "Control Transfers":
1. Far Jumps or Calls: When jumping to a different code segment defined in the GDT.
2. Interrupts/Exceptions: Interrupt can force a transition to a Ring 0 descriptor.
3. Syscalls: Modern methods for jumping from User Mode to Kernel Mode.

When one of these events happens, the CPU loads a new Selector into the CS register. The bottom two bits of that new selector become the new CPL.

## Access data

### Restricting Access to Data segment

`mov ds, 0x7000`

When loading the selector (`0x7000` is selector not address in 386) of data segment into a data-segment register (DS, ES, FS, GS, SS).The processor automatically evaluates access to a data segment by comparing privilege levels. Evaluation is performed at the time a selector for the descriptor of the target segment is loaded into the data-segment register

- CPL: current code segment's privilege level, inside hidden cache from the GDT or LDT table (`CS` register's bit index `0 and 1` or say as last 2 bits) : `Who am I?`
- RPL: Selector that is being targeted (`0x7000` -> last 2 bit `0 0`) : `Who am I pretending to be?`
- DLP: Permission inside descriptor table of the target segment that selector is indexing : `Who is allowed in?`

- RPL and DLP may looks like redudant , RPL is from the selector that is the index of the table, that table's entry also have a permission DPL. RPL is dynamic value, it will not exceed callers privilege level

**Dynamic RPL**

Reference - Intel combined manual Vol 3: 5.10.4 (`Checking Caller Access Privileges (ARPL Instruction)`)

I call this as dynamic because OS will override the target segment registers's last 2 bit (RPL) (`0x7000` stored in `ds`) permission bit
- if CPL is `01` and RPL is `00` OS will set RPL to `01`
- if CPL is `01` and RPL is `11` (`0x7003`), OS will keep the `11` as it is
    > The `ARPL` (Adjust Requested Privilege Level) instruction in x86 assembly (286+ protected mode) is used by operating systems to ensure a segment selector's RPL does not exceed the caller's privilege. It compares two 16-bit selectors and increases the destination's RPL to match the source if it is less
    > Purpose: Prevents lower-privileged code from using higher-privileged selectors passed to the OS.
    > Operation: If Dest[RPL] < Source[RPL], then Dest[RPL] = Source[RPL] and ZF is set. Otherwise, ZF is cleared. It decreases the privilege level
    > The OS usually uses the Caller’s CS (Code Segment) Selector as the Src. Since the CS selector’s RPL always matches the CPL of the program that was running, it is the "Truth" about how powerful the user actually is.
    > CS is not set by mov or other manual, must use far jump, interrupt call or syscall
    > Compatibility: Supported in Protected Mode and Virtual-8086 mode; not available in 64-bit mode. 
    ```
    When an OS starts a new process:
    1. The OS allocates memory for the program.
    2. It manually constructs a "fake" stack frame or TSS.
    3. It writes the value 0x001B (or similar) into the CS slot.
        * `Binary: 0000 0000 0001 1011`
        * The last two bits (11) are 3.
    4. It executes IRET. The CPU "returns" into the new program, loading that RPL 3 into CS.
    ```

    *RPL of the selector is dynamic*

    When a high-privilege program (like the OS Kernel) performs a task for a low-privilege program.
    1. Your App ($CPL=3$) wants the Kernel ($CPL=0$) to write some data into a buffer.
    2. You give the Kernel a Selector (a pointer).
    3. The Risk: If you are malicious, you might give the Kernel a selector that points to the Kernel's own private password memory ($DPL=0$).
    4. Without RPL: The Kernel ($CPL=0$) would try to write to that memory. The CPU would check $CPL(0) \le DPL(0)$. It would pass! The Kernel just accidentally overrode its own security because you gave it a "bad" pointer.
    5. With RPL: The Kernel takes your selector and it with $RPL=3$, current $CPL=0$ since RPL is alaready greater than CPL it remains the same (else using the ARPL instruction it will change). Now, when the Kernel tries to use that pointer, the CPU checks:$$max(CPL=0, RPL=3) = 3$$
    The CPU then compares 3 against the memory's DPL=0.
        $$3 \le 0 \text{ is FALSE.}$$
    Access Denied. The CPU stops the Kernel from being "tricked" into using its high $CPL$ to access data that the original requester (the App) shouldn't see.

Instructions may load a data-segment register (and subsequently use the target segment) only if the DPL of the target segment is numerically greater than or equal to the maximum of the CPL and the selector's RPL. In other words, a procedure can only access data that is at the same or less privileged level. $$\text{max(CPL, RPL)} \le \text{DPL}$$

### Restricting Access to Code segment
> Conforming (c = 1) : It can be executed by a lower-privileged program (e.g., Ring 3 calling Ring 0). Conforming code segment continue to run on CPL, no stack switch happen
> Non-conforming ( C = 0 ): Code can only be executed by a caller with the same privilege level
> Higher privilege (Ring 0) can generally access lower privilege (Ring 3) data, but they usually cannot "jump" into lower-privilege code for execution unless they specifically lower their own CPL

`MOV AX, CS   ; MOV DS, AX`

Code segments may legally hold constants values; it is not possible to write to a segment described as a code segment. The following methods of accessing data in code segments are possible:
1. Load a data-segment register with a selector of a nonconforming, readable, executable segment.
   - $$\text{max(CPL, RPL)} \le \text{DPL}$$
   - A Ring 3 program cannot load a Ring 0 non-conforming code segment into DS to read its bytes.
2. Load a data-segment register with a selector of a conforming, readable, executable segment
    - Since conforming is set, Lower ring programs can read the data stored in higher ring, DPL is no use here, always allowed
3. Use a CS override prefix to read a readable, executable segment whose selector is already loaded in the CS register.
    - `mov al, cs:[my_constant]`
    - always valid because the DPL of the code segment in CS is, by definition, equal to CPL.

## Control Transfers

Operation in far `jmp` and `call` will refer to other segments, therefore processor performs privilege checking.

There are two ways it can refer to other segments
1. The operand selects the descriptor of another executable segment.
    - Usually CPL  is equal to the current code segment's DPL because CPL(cached) is copied from the DPL of the CS descriptor at the time of loading, if call is performing jump with same privilege level different segment in this is case it is allowed because CPL == DPL 
    - But when conforming is set there is a chance lower privilege (CPL = 3) may execute higher privilege code segment (DPL = 0) in this case CPL != DPL cached CPL is may not match with the DPL of code segment in the GDT/LDT

    The processor permits a JMP or CALL directly to another segment only if one of the following privilege rules is satisfied:
    1. DPL of the target is equal to CPL. (To execute same privilege code)
    2. The conforming bit of the target code-segment descriptor is set, and the DPL of the target is less than (0) or equal to CPL(3).
         conforming segment (higher privilege segment executed at the current CPL=3 privilege not with the target segment's privilege DPL=0)
    The JMP instruction may never transfer control to a nonconforming segment whose DPL does not equal CPL.
2. The operand selects a call gate descriptor. 
    - If conforming bit is not set but there is a need to execute higher privilege code, this can be achieved by  CALL instruction when used with call-gate descriptor
    - To provide protection for control transfers among executable segments at different privilege levels, the 80386 uses gate descriptors
    - Call gates
        ![call gate descriptor](./res/callgate.png)

        In same process need to execute (call or jmp) higher privilege code and that higher privilege code segment's conforming bit is not set in this case call gate will be used
        - Call gate resides in GDT or LDT, not in IDT. 
        - A call gate guarantees that all transitions to another segment go to a valid entry point, rather than possibly into the middle of a procedure, It will ignore the offset part (only for call gate) 
            - `call 0x8000:0x0100` here `0x8000` is segment, CPU treat that as normal segment. Then in GDT or LDT it find this is call gate
            - From the Descriptor table (GDT/LDT) it will take the base address then it will ignore the offset part (`0x0100`) because this might points to middle or any where
        - Call gate have 2 primary functions
            1. To give entry point for the high privilege code
            2. To specify what is the privilege used for that high privileged code
        

        Four different privilege levels are used to check the validity of a control transfer via a call gate:
        1. The CPL
        2. The RPL of the selector used to specify the call gate.
        3. The DPL of the gate descriptor.
            - It determine what privilege levels can use the gate, Single segment can contain many procedures that may be used by different different privilege level
        4. The DPL of the descriptor of the target executable segment. 

        Call gate can be used by `jup` instruction as well but when using jump instruction only same privileged level or conforming segment will work, When `call` control  transfers to smaller privilege levels or to the same privilege level 

        Permission checks
        1. Jump
            (MAX (CPL,RPL) <= gate DPL) && (target segment DPL == CPL)
        2. Call
            (MAX (CPL,RPL) <= gate DPL) && (target segment DPL <= CPL)
            - CPL = 2
            - RPL = 0
            - gate DPL = 2
            - target segment DPL = 3

            - max(2,0) <= 2 && 3 <= 2 = fail, because here higher privilege code transfer control to low privilege, call gate only designed for low to high, if high to low is desire `ret`, `Iret` is used
        
        **What happen to DS, ES, FS, and GS segment registers?**
        
        **Stack**
        - Since each level of privilege has own stack,  These stacks assure sufficient stack space to process calls from less privileged levels. Each stack must contain enough space to hold the old SS:ESP, the return address, and all parameters and local variables that may be required to process a call.
        - The processor locates these stacks via the task state segment. Systems software is responsible for creating TSSs and placing correct stack pointers in them. The initial stack pointers in the TSS are strictly read-only values. The processor never changes them during the course of execution.
        - The processor uses the DPL (The new CPL) of the target code segment to index the initial stack pointer for privilege level (0 or 1 or 2).
            Tss is not maintaining privilege level 3 because it is the least level, when a processor want to switch from low to high it will consult these TSS and take the Stack space pointer, when it want to return back to low previlege it will simply do return, so no need of storing privilege level 3 stack
        - stack pointer is a segment selector, the data descriptor pointing to the stack selector's DPL must be equal to the new CPL or target segment DPL 
        - To make privilege transitions transparent to the called procedure, the processor copies the parameters to the new stack. The count field of a call gate tells the processor how many doublewords (up to 31) to copy from the caller's stack to the new stack.

        **Steps in stack**
        1. when call transfer occurs the process check the new stack limit to assure large enough to hold all the values
        2. Old privilege SS:ESP is pushed on the new privilege stack
        3. The parameters are copied from old privilege to new privilege stack 
        4. Old privilege CS:EIP is pushed in new privilege stack 

        Do the work

        **Returning from callgate**
        - Under normal condition return pointer is valid, because of its relation to the prior CALL. But that higher privilege may alter the stack or not properly maintained the stack, so CPU will perform all the privilege checks
        - Return statement can transfer control only to the lower privilege 
        - When the RET instruction encounters a saved CS value whose RPL is numerically greater than (old CS's RPL priviledge is less) the CPL, an interlevel return occur

        1. Privilege Check
            - Pop the CS:EIP 
            - old cs's selectror has RPL , consult the descriptor table and take DPL $$\text{max(CPL, RPL)} \le \text{DPL}$$
            - when it will faile `3 <= 0` when DPL is less than CPL or RPL, meaning returning to high privilege code
        
        2. Adjust the stack
            - Then Pop the SS:ESP with stack privilege checks, then adjust the old SS:ESP by the number of bytes indicated in the RET 
        3. The contents of the DS, ES, FS, and GS segment registers are checked. If any of these registers refer to segments whose DPL is greater than the new CPL (excluding conforming code segments), the segment register is loaded with the null selector (INDEX = 0, TI = 0), next memory access to those segment will raise exeception
            

        **How the CPU Combines address and working**
        To find the final physical instruction, the CPU performs a "Double Lookup":
        1. Instruction: `CALL 0x50:0x12345678`
            - The CPU looks at GDT index `0x50`. It sees it's a Call Gate.
            - The CPU discards the `0x12345678` provided by the user.
        2. Inside the Call Gate descriptor:
            - It sees Selector `0x08` and Offset `0x00001000`.
            - Check DPL of gate is greater than or equal CPL and RPL (checks user can access call gate)
        3. Descriptor table look up
            - The CPU looks at GDT index `0x08`.
            - RPL in `0x08` is ignored 
            - It sees a Code Segment with Base `0x40000000`.
            - Check DPL of target executable code is less than or equal CPL
            - offset of target executable code segment is ignored
        4. Final Result:
            - The CPU jumps to: Base from target executable code segment (`0x40000000`) + Gate Offset (`0x00001000`) = `0x40001000`.
        
        
        [Complete working](./call_gate_complete_work.md)
        
    - [Trap gates](./Interrupts.md)
    - [Interrupt gates](./Interrupts.md)
    - [Task gates](TaskSwitch.md)
