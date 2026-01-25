## Understanding the CPU

At its simplest, a Central Processing Unit (CPU) is a manager. It contains an ALU (Arithmetic Logic Unit) for math, Registers for temporary storage, Flags to track status, and a Control Unit to act as the conductor of the orchestra.
 

### 1. How the CPU Talks to the World
The CPU uses three main "highways" called buses:
* Address Bus: Where the CPU "yells" the location it wants to talk to.
* Data Bus: Where the actual information travels.
* Control Bus: Where signals like "Read," "Write," or "Interrupt" are sent.

The CPU doesn't actually care what is connected to a specific address. It simply puts an address on the bus and expects the device assigned to that address to respond within a guaranteed timeframe. CPU will enable the read/write signal depends on the operation, using this signal device do the operation

The CPU does not wait for a confirmation signal; instead, it assumes the device will be ready to send or receive data at a strictly defined moment. This data exchange occurs within a fixed time window. If a device fails to respond fast enough or if the timing is slightly off, the CPU will likely capture incorrect data or write information to the wrong location, as there is no built-in mechanism to verify the success of the transfer.

### 2. Memory mapping and Devices
Apart from the CPU, everything else is a "device." To keep things organized, we use Memory Mapping. We split the available address space (e.g., 65,536 addresses for a 16-bit CPU) among different hardware for example memory mapping:

```
Device                      Address
RAM	                        0000 - 3FFF
I/O (Mouse/Keyboard,..)	    4000 - 7FFF
ROM (System BIOS)           8000 - FFFF
```

When multiple devices share the same bus, the system needs a way to prevent them from talking over each other. This is handled by two main components:

* Decoding Logic: Since all devices "hear" the CPU yelling an address, the decoding logic acts as a filter. It looks at the address and sends an "Enable" signal only to the specific device meant for that task. This ensures only one device is active at a time.
* Latches: Because the CPU only sends or expects data during a very narrow window of time, devices use a latch. A latch acts like a temporary storage box that "catches" and holds the data so it stays stable while the CPU is reading it, or holds onto data the CPU just wrote until the device is ready to process it.

While RAM and ROM only respond when the CPU reaches out to them, I/O devices are special. They have the interrupt ability to grab the CPU's attention. When interrupt occur CPU will stop the current execution, save the address of next instruction and start executing from Interrupt vector address, once it completed it will release the interrupt which is held by device and resume the old flow by take back the saved address

There are two types of interrupt maskable (cpu can ignore) and non-maskable (cpu can't ignore) 

**How an Interrupt Works**

When an external device like a mouse or keyboard needs to talk to the CPU, it follows a strict sequence to make sure no data is lost. Here is the flow in your style:
1. Capturing the Event: When you click a mouse or press a key, the device immediately captures that action. It saves the data in its own internal memory or a latch. It has to hold onto this data because the CPU is likely busy doing something else.
2. Signaling the CPU: The device pulls the Interrupt Pin high (or low, depending on the design) to tell the CPU, "I have something for you!"
3. The CPU Check: The CPU doesn't stop in the middle of a micro-instruction. It waits until it finishes the current full instruction (at the very end of the fetch-decode-execute cycle) to check the status of the interrupt pins.
4. Jumping to the Vector: If the interrupt is allowed (not masked), the CPU saves its current place and jumps to the Interrupt Vector Address. This is where the code lives that knows how to handle that specific device.
5. Clearing the Interrupt: This is a critical step. The CPU must "talk back" to the device to tell it the message was received. The device then releases the interrupt signal. If the CPU doesn't clear it, the device will keep yelling, the CPU will think it’s a brand new request, and the system will get stuck in "interrupt hell," never returning to normal work.
6. The Return: Once the device is quiet and the work is done, the CPU uses a "return" command to jump back to the exact address it was at before the interruption and resumes the old flow.

When the CPU has to move a massive amount of data (like loading a movie from a disk to RAM), doing it manually is a waste of time. The CPU would have to fetch and execute for every single byte. DMA (Direct Memory Access) is like hiring a specialized mover so the manager (CPU) can focus on other things.

**How DMA Works**

1. The Setup: When the CPU needs to move a large block of data, it doesn't do the heavy lifting. Instead, it tells the DMA Controller: "Take this much data from this Device address and put it into this RAM address."
2. Bus Request (Hold): The DMA Controller sends a signal to the CPU (usually called a HOLD request). It is basically asking, "Can I borrow the Address and Data buses for a moment?"
3. Bus Grant: The CPU finishes its current task and then releases control of the buses.
4. The Fast Transfer: Now, the DMA Controller is the boss of the buses. It moves the data directly from the device to RAM (or vice versa) without passing it through the CPU registers. This is much faster because there is no "Fetch-Decode-Execute" for every byte.
5. The Finish: Once the transfer is complete, the DMA Controller releases the HOLD signal to say, "The job is done." The CPU then takes back control of the buses and continues its work.

`It's important to remember that during a DMA transfer, the CPU is usually "stalled" from using the main buses. It can still work on things inside its own cache, but it cannot "yell" an address on the bus until the DMA controller is finished and gives the buses back.`

### 3. Instruction
Everything a human writes is eventually turned into an Opcode (what to do) and an Operand (data or location).

CPU instructions, are stored in memory in a continous order. To execute them, the CPU generates addresses to fetch these instructions one after another, automatically incrementing the address to move to the next step. However, certain "flow control" instructions—like jumps, loops, or conditions—can break this straight line. These special commands tell the CPU to skip ahead or go back to a different address, allowing the program to make decisions or repeat tasks instead of just running from start to finish.

When you run an instruction like `ADDA [address]`, the CPU’s Control Unit acts as the manager, breaking that one command into smaller "micro-steps" that happen over several clock cycles. The Control Unit knows exactly which hardware gates to open or close during each specific cycle to make the math happen.

**For the ADDA (Add to Register A) instruction, here is how those cycles work:**

* Cycle 1: The CPU puts the target address onto the Address Bus. During this time, only the address bus logic is enabled so the right memory location hears the call.

* Cycle 2: The CPU flips the "Read" switch. The data from the device travels from the Data Bus into a temporary register. Only the data bus and that specific internal register are enabled to receive the information.

* Cycle 3: The ALU (Adder) takes the value from Register A and the new value from the temporary register. Since the adder is hardwired to these registers, it performs the calculation immediately.

* Cycle 4: The result of the addition is saved back into Register A. The Control Unit enables the "Write" gate for Register A so it can store the final sum.

So, for this ADDA operation, it takes 4 cycles to finish. On every single tick of the clock, the Control Unit is responsible for enabling or disabling different components so the data moves exactly where it belongs without any collisions.

The Control Unit is the brains of the operation, but it needs a way to know exactly which "switches" to flip for every single instruction. Since every instruction (like ADDA or JUMP) needs a different number of cycles and different components, the Control Unit uses a Step Counter to keep track of which cycle it is currently on.

This counter usually resets after the instruction is finished. Its maximum count is determined by the longest, most complex instruction the CPU can handle.

To actually enable the components, there are two main ways the Control Unit makes decisions:
* Hardwired Control: This uses a massive, fixed web of logic gates (AND, OR, NOT) and decoders. When an opcode enters, it travels through these gates like a physical maze to trigger the correct components. It is extremely fast because signals move at the speed of electricity through the gates, but it is too complex to design and impossible to change once the chip is made.
* Microprogrammed (Internal ROM): In this version, the CPU has its own "mini-memory" or Control ROM. The binary opcode acts like an address that points to a location in this ROM. The data stored at that address is a bit-pattern (a Micro-instruction) that tells the CPU exactly which components to enable. While it is slower than hardwiring because it requires a memory lookup, it is extremely flexible. Engineers can even update the CPU's behavior by changing the code in this ROM.

Essentially, the Control Unit combines the Opcode and the Step Counter to decide which specific "control signals" to turn on at any given nanosecond.

### 4. Execution
When you first turn on a computer It follows a very strict "startup" routine and then enters a never-ending loop called the Instruction Cycle.

**The Power-On (The Reset Vector)**
At the exact moment of power-on, the CPU is hardwired to look at a specific, "special" address known as the Reset Vector Address. This address doesn't contain the program itself. Instead, it contains the starting address of the actual program (like the BIOS or Bootloader). The CPU grabs that address, puts it into its Program Counter, and the race begins.

**The Fetch-Decode-Execute Loop**
Once the CPU knows where to start, it repeats these three main steps for every single instruction:

1. Fetch
* Address Phase: The CPU puts the value from the Program Counter onto the Address Bus.
* Data Phase: It flips the "Read" switch. The instruction travels from memory across the Data Bus.
* Storage: The CPU catches this data and stores it in the Instruction Register (IR). Now it has the "map" for what to do next.

2. Decode
* The Control Unit takes the opcode from the Instruction Register.
* Using either Hardwired logic (gates) or Internal ROM (EPROM), it breaks the opcode down.
* It determines exactly how many cycles are needed and which components (like the ALU or specific registers) must be enabled.

3. Execute
* The Control Unit releases the signals to the hardware.
* If it's math, the ALU activates. If it's a move, the data buses move the bits.
* Once the work is done, the Program Counter is updated to the next address, and the cycle starts all over again at Step 1.

### Important concepts

#### Registers
* A (Accumulator): The primary register for the ALU; it holds one of the numbers during math operations and stores the final result.
* PC (Program Counter): The "bookmark" that holds the address of the next instruction to be fetched from memory.
* IR (Instruction Register): The "waiting room" that holds the current instruction while the Control Unit decodes it.
* SP (Stack Pointer): Tracks the "top" of the stack in RAM to manage function calls and interrupts.
* SB (Stack Base / Base Pointer): Points to the fixed "start" of a data block in the stack to help locate local variables.
* CS (Code Segment): Defines the specific block of memory where the executable program code is stored.
* DS (Data Segment): Points to the area of memory where global variables and static data are kept.
* Index Registers (SI/DI): Used for "pointing" to memory locations during string operations or when moving through arrays and lists.
* status registers: The Status Register (often called the FLAGS Register or PSW - Program Status Word) is the CPU's way of keeping track of "what just happened." Unlike other registers that hold data or addresses, this one is a collection of individual bits (flags) that act as yes/no switches.

#### Addressing
1. An **absolute address** is a fixed, specific location in memory
    eg: `MOV EAX, [0x00401000]` — This tells the CPU to go exactly to memory location 0x00401000 to find the data.

2. A **relative address** specifies a location based on a reference point, usually the Program Counter (PC) or Instruction Pointer (IP). It is offset
    eg: `JMP +12` — This tells the CPU to skip forward 12 bytes from the current instruction.
3. The **effective address (EA)** is the final memory address the CPU calculates for a specific instruction before it actually goes to fetch the data. It is the result of an addressing mode calculation.
    eg: `MOV EAX, [EBX + ESI*4 + 20]` 
4. The **Immediate Addressing**, data is not in memory or a register; it is part of the instruction itself.
    eg: `MOV EAX, 10` (The number 10 is "immediate data").
5. The **Register Addressing**, operand or data is stored in a CPU register. This is the fastest mode because it doesn't require any trips to RAM.
    eg: `MOV EAX, EBX` (Both the source and destination are registers).
6. **Indirect Addressing** the instruction doesn't contain the address of the data, but rather the address of the address
    eg: 
    1. `MOV EAX, [ [0x00401000] ]` — Look at 0x401000, find the value there, and treat that value as the final address.
    2. `MOV EAX, [EBX]` — The address is stored inside register EBX
7. **Indexed Addressing** The effective address is calculated by adding a constant "base" address to a value in an index register.
    eg: `MOV EAX, [EBX + ESI]` EBX holds the start of the array, and ESI acts as the counter (index) to move through the elements.
8. **Displacement (Base-Offset) Addressing** A variation of indexed addressing where you add a fixed numerical offset to a register.
    eg: `MOV EAX, [EBP + 8]`
9. **Implied (Inherent) Addressing**  The operand is hidden or "implied" by the command itself. There is no explicit address or register mentioned because the CPU already knows where to look.
    eg: `CLC` (Clear Carry Flag) or `PUSHFD` (Push Flags to Stack).
