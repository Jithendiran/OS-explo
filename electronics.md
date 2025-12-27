# The Physical Switch

The Transistor as a Switch. At the lowest level, a transistor (specifically a MOSFET) is just a gatekeeper. It has three pins: Source, Drain, and Gate.
Source will have input connected, Drain is the output. We will control the switch by GATE 

[Refer the water flow](https://youtu.be/AwRJsze_9m4?t=434)

## Propagation Delay

Electricity moves at nearly the speed of light, but transistors take time to "charge up" and flip. This tiny pause—often just a few nanoseconds ($10^{-9}$ seconds) is called Propagation Delay.

Why it matters: If you have 100 gates in a row, the delay adds up. You cannot ask for the answer until the electricity has had enough time to "propagate" through all 100 gates.

## SR Latch (NOR)
This is used to store 1 bit of value

The most common way to build an SR Latch is by using two NOR gates in a "cross-coupled" configuration. This means the output of the first gate is fed back into the input of the second, and vice versa.

* Inputs: S (Set) and R (Reset).
* Outputs: Q (the stored bit) and $\bar{Q}$ (the "Not Q" or complement). In a healthy state, if 8$Q$ is 1, 9$\bar{Q}$ must be 0.

### How It Works (The 4 States)

| State | S (Set) | R (Reset) | Q (Output) | Description |
| --- | --- | --- | --- | --- |
| **Hold** | 0 | 0 | Previous | No change. It "remembers" the last value. |
| **Reset** | 0 | 1 | **0** | Forces the output to 0. |
| **Set** | 1 | 0 | **1** | Forces the output to 1. |
| **Invalid** | 1 | 1 | 0 (both) | **Forbidden.** Both gates try to force 0, breaking the  rule. |

[SR Latch](https://youtu.be/KM0DdEaY5sY)  

[D Latch](https://youtu.be/peCh_859q7Q)

## Clock
A clock signal is a voltage that oscillates between 0 (Low) and 1 (High) at a constant frequency. 

### Why we need clock?

#### 1. Managing Propagation Delay (The "Settling" Time)

Electricity takes time to travel through transistors. When an input changes, the output doesn't update instantly. It "flickers" or "oscillates" for a few nanoseconds before settling on the correct value.

* **The Problem:** If the CPU tries to read that value while it is still flickering, it will read "garbage" data.
* **The Solution:** The Clock acts as a waiting period. We set the clock speed so that the time between "ticks" is slightly longer than the worst-case propagation delay. This ensures the electrical signals have fully "settled" before the CPU moves to the next step.

#### 2. Synchronization and Sequencing

A CPU is made of many different units (the ALU, registers, and memory). Some units are fast, while others are slow.

* Without a clock, the fast units would finish their work and move on before the slow units were ready, causing a total collapse of logic.
* The clock acts as a Global Conductor. It ensures that every single transistor in the system is synchronized to the same heartbeat. No part of the CPU can "get ahead" of another.

#### 3. Creating Discrete "Steps" (State Machines)

Modern computing is based on State. A CPU needs to know: "I am finished with Step A, now I am starting Step B." Because the clock has a Rising Edge (the moment it jumps from 0V to 5V), it provides a definitive "Now!" command.

* This allows the CPU to follow a sequence (like the **Bus Cycle**). For example:
* **Clock 1:** Put the address on the bus.
* **Clock 2:** Wait for the memory to respond.
* **Clock 3:** Capture the data.

![clock](./res/wave-time.jpg)

#### 4. Deterministic Calculation

Because of the clock, we can calculate exactly how long a program will take to run. If an instruction requires $20$ clock cycles and your CPU is running at $5\text{ MHz}$, you can use the formula:

$$Time = \frac{\text{Number of Cycles}}{\text{Clock Frequency}}$$

Without a clock, the speed of the computer would change depending on the temperature of the room or the length of the wires, making it impossible to write software that relies on timing.


[How flip flop used to reduce hz](https://youtu.be/_2By2ane2I4)

[Frequency divisior](https://youtu.be/nL8u0YBhyWg)

[How CPU use clock](https://youtu.be/PVNAPWUxZ0g)

[Additional](https://youtu.be/kRlSFm519Bo?list=PLowKtXNTBypGqImE405J2565dvjafglHU)


## Detector

In electronics, a Detector is a circuit that looks for a specific pattern or "event" in a signal.

* It doesn't care about the signal most of the time.

* It only "fires" or activates when it sees its specific target (like a certain voltage level or a sudden change).

### Level vs. Edge 

![Wave](./res/digital-wave.png)

This describes how long the gate stays open.

* **Level Triggering (The Duration)**
    The circuit is active for the entire time the signal is at a specific logic level. If you hold the button down for 5 seconds, the circuit is "listening" for 5 seconds.

    If you are using Level Triggering, you have two choices for when the circuit is "active":
    - Active High: The circuit works when the signal is at Logic 1 (e.g., 5V).
    - Active Low: The circuit works when the signal is at Logic 0 (e.g., 0V).

* **Edge Triggering (The Moment)**

    The circuit is active only at the exact instant the signal changes state.
    It doesn't matter how long you hold the button; the circuit only reacts once—at the very start (or end).

    If you are using Edge Triggering, you have two choices for the exact "moment" of activation:
    - Rising Edge (Positive Edge): start of pulse
    - Falling Edge (Negative Edge): end of the pulse


[D Flip flop](https://youtu.be/YW-_GkUguMM?t=239) [Only see D flip flop section]

## Clock explained

To understand why we need a clock, let's look at a simple math problem:

`24 + 34 + 77 = 135`

To do this in a circuit, we need an **8-bit Adder** and an **8-bit Latch** (to store the running total).

![circult diagram](./res/adder-latch.png)

Since it has internal memory we no need to note down the result in each step and feed with next input

There is a `clk` in the latch, latch will accept the input from adder when we close the `add` circuit

**The Sequence:**

1. **Start:** Latch is `0`. Input is `24`. Adder calculates $0 + 24 = 24$. We store `24` in the Latch by closing add circuit (pressing the button kind of).
2. **Next:** Latch is `24`. Input is `34`. Adder calculates $24 + 34 = 58$. We store `58` in the Latch.
3. **Next:** Latch is `58`. Input is `77`. Adder calculates  $58 + 77 = 135$. We store `135` in the Latch.

### Why can't we just use a simple "Level Trigger" (Switch)?

Imagine the "Add" button is a **Level Trigger**. When you press it, the gate stays open as long as your finger is on the button.

**The Problem:** Humans are slow, and electricity is fast.
If you press the button for even 0.1 seconds, the CPU sees that as a "High" signal for thousands of nanoseconds.

**How wrong could it go?**

* **Time 0:** You press the button. Result = $0 (\text{memory}) + 24 (\text{input}) = 24$.
* **Time 1 (Still pressing):** The Latch sees the "High" signal is still there. It takes the new `24` from memory and adds the `24` from the input again. Result =  $24 + 24 = 48$.
* **Time 2:** It happens again! Result = $48 + 24 = 72$.

In a split second, your answer is `72` (or much higher) instead of `24`. This is a **feedback loop error**.

#### The Solution: Edge Triggering

An **Edge Trigger** only activates at the exact moment the signal jumps from 0 to 1 (the Rising Edge). Even if you hold the button for an hour, the Latch only "captures" the value **once**. This guarantees that $0 + 24$ stays $24$.


### Automating the Process

Instead of a human pressing a button, we use a **Clock Signal** (a continuous square wave). We can divide one "Clock Cycle" into four stages to handle different tasks.


**Imagine we have 3 registers (A, B, C) holding our numbers:**

1. **Rising Edge:** Read the number from the register (A).
2. **High Level:** Give the Adder time to perform the math.
3. **Falling Edge:** Save (Latch) the new result into memory.
4. **Low Level:** Move to the next register (B).

why latch operation and registers opeartions are in edge because, it won't take so long
ALU oprations like add and increment may take some more time, so these are in level trigger

see we have a pattern `edge -> level -> edge -> level`, our square wave also have pattern of rise` Rise edge -> high level -> fall edge -> low level`

By the end of one full cycle, one addition is perfectly finished. This is **Controlled Automation**. Because each step has its own "moment" on the wave, the operations don't collide.

our only job is to put the value in A, B, C address and start the machine at the end of 3 cycle assume machine will stop because we don't have any more address, our result is stored in latch

By the end of 3rd cycle, we get the result. we got the result in automated and controlled way, The controlled way i mean here is only one operation will happen at a stage, so the result is guaranteed


### What if one task takes longer than another?

**1. Duty Cycle Adjustments**
If "Addition" takes more time than "Incrementing the Address," we can use a **67% Duty Cycle**. This makes the "High" part of the wave longer and the "Low" part shorter, giving the Adder more time to settle.

**2. Frequency Divisor**
If the whole system is too fast, we use a frequency divisor to slow down the "heartbeat" of the CPU so every component can keep up.

**3. The "Wait" State**
What if the component is *really* slow (like external RAM)?
In this case, the component sends a "Wait" signal to the CPU. The CPU will stop and "idle" on a specific part of the clock cycle until the component says, "I am done!" Then, the CPU continues to the next stage.


The clock frequency is chosen based on the **worst-case scenario** (the slowest task). This ensures that every operation has enough time to finish before the next "Rising Edge" starts a new cycle.

#### Note
* Latches are level triggered
* D Flip-Flop is edge-triggered

## What is BUS?
Bus is a common connector, like registers, memory, ALU are linked with BUS
So BUS is a single (1bit) or bundle (8, 16, 32,.. bit) of wires connecting all the components, One module (ALU, memory,..) can put the data in the bus other module can get the data from BUS (register, ALU, memory,..)

Since every modules are connected to the BUS, we need a way to select the each module, so there are couple of control signals are used for each modules for selecting the module



### How modules are connected?

Each modules can have input and output wires (8,16,32,... based on the bits), then Load signal, clock and enable signal wires (single wire for each)
* when a module has load signal with desire clock signal, module will capture the data from bus.
* when a module has enable signal with desire clock signal, module will put the data to the bus.

The really important about BUS is no more than 1 module has to put the data in same cycle, let say module a put data 1010 1010 to the bus, module b put 0101 0101 to the bus, here there is no certinity what the value of bus, so we want to make sure only one module will interact with a bus at a specific time

To keep the bus safe, we use a special electronic "switch" called a Tri-State Buffer.

In normal electronics, you have 0 and 1. But a Tri-State Buffer has a third state: High Impedance (Hi-Z)

* Hi-Z means the module is "completely disconnected" from the bus. It’s like the wire has been physically cut.

* Even though the metal wires are touching, no electricity can flow out of the module onto the bus unless the Enable signal is turned on.

**Control Unit** acts like a traffic cop. It makes sure that if it turns on the Enable for the AX register, the Enable for all other registers (BX, CX, etc.) is strictly turned off (set to Hi-Z).

## Control Unit
In a car, the engine (ALU) does the hard work, but the driver (Control Unit) decides when to press the gas, when to shift gears, and when to brake. They are in the same car, but they have completely different roles.

The Control Unit is located inside the Execution Unit (EU). The Control Unit is connected to the Enable and Load pins of every single module/component

There are two main ways a Control Unit can be built. 
1. Hardwired Control (Fast & Fixed)
    * This is a massive web of logic gates (AND, OR, NOT) and Flip-Flops.
    * The Logic: If the instruction is 1011 0000 (Move data to AL), the "hardwired" path immediately sends an Enable signal to the memory and a Load signal to the AL register.
    * Pros: Extremely fast because the signal just travels through wires.
    * Cons: If you want to add a new instruction, you have to redesign the entire chip.

2. Microprogrammed Control (Flexible & "Software-like")
    * Instead of only using gates, it has a tiny "mini-memory" inside called Control ROM.
    * The Logic: When an instruction comes in, it acts like an address. The Control Unit looks up that address in its Control ROM, which contains a list of Micro-instructions (tiny steps like: 1. Open Bus, 2. Pulse Register AX, 3. Close Bus).
    * Pros: Easier to design complex instructions.
    * Cons: Slower than hardwired because it has to "read" from its internal ROM.

### ALU
ALU may have enable pin or may not, it depends on the CHIP

1. Standard ALU ICs (e.g., 74LS181)
    - It does not have an enable pin.
    - It is a combinational circuit, meaning as soon as you change the inputs (operands $A$ and $B$) or the function select pins ($S0$–$S3$), the output ($F$) changes after a short propagation delay.
    - The chip is "always on" as long as it has power.
    - It should not connect to BUS directly
    - when done with the operation it will have result  in the sum pins, we have to move the values to A register, from A register we have to move to BUS

2. Microprocessor Architecture
    - It does not have an enable pin.
    - It connected to the BUS 
    - It will do the ALU operation based on the $A$ and $B$ register, but it won't write it into memory until output enable pin enabled 
    - The chip is "always on" as long as it has power.

3. Modern design
    - ALU has enable pin to save power
    - It connected to BUS

### RESET

There is a single RESET pin on for every module in the chips (registers, CU,..). This pin is connected to a "Reset Bus" that travels to every module:

* To the Registers: "Set your value to 0."

* To the Control Unit: "Go back to the first step of the cycle."

* To the Bus Interface: "Stop all current memory reads/writes."

**Does the ALU have a reset?** 
Not usually. The ALU is just a bunch of gates (combinational logic). It doesn't "store" anything, so there is nothing to reset. It just reacts to whatever inputs the registers give it

**Why does it take a few clock cycles to reset?**
This ensures the "Reset electricity" has enough time to propagate through all the tiny transistors in every module to clear them properly.

### HLT

When the Control Unit decodes the HLT instruction, it enters a special Halt State.

* It stops sending Enable or Load signals to the registers.

* It stops the EU (CU, ALU).

* The CPU basically sits in a "Wait Loop," doing nothing but checking one specific thing: The Interrupt pins.

* To "wake up" a halted CPU, you need an Interrupt (an electrical signal on the INTR or NMI pins).

* It won't lose data stored in registers

## Refer

* [Code: The Hidden Language of Computer Hardware and Software](https://www.amazon.in/Code-Language-Computer-Hardware-Software/dp/0137909101)
    - Ch: 17 Feedback and Flip-Flops

* [BUS](https://youtu.be/QzWW-CBugZo)

* [ALU](https://youtu.be/mOVOS9AjgFs)

* [RAM](https://youtu.be/FnxPIZR1ybs)

* [PC](https://youtu.be/g_1HyxBzjl0)

* [EPROM](https://youtu.be/BA12Z7gQ4P0) Just look, it is just a bonus, if don't understand leave it and chill

* [Control](https://youtu.be/AwUirxi9eBg) (Just a connection, not much important)
