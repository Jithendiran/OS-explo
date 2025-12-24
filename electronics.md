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
* Outputs: Q (the stored bit) and 6$\bar{Q}$ (the "Not Q" or complement).7 In a healthy state, if 8$Q$ is 1, 9$\bar{Q}$ must be 0.

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

* This allows the 8086 to follow a sequence (like the **Bus Cycle**). For example:
* **Clock 1:** Put the address on the bus.
* **Clock 2:** Wait for the memory to respond.
* **Clock 3:** Capture the data.

#### 4. Deterministic Calculation

Because of the clock, we can calculate exactly how long a program will take to run. If an instruction requires $20$ clock cycles and your 8086 is running at $5\text{ MHz}$, you can use the formula:

$$Time = \frac{\text{Number of Cycles}}{\text{Clock Frequency}}$$

Without a clock, the speed of the computer would change depending on the temperature of the room or the length of the wires, making it impossible to write software that relies on timing.


[How flip flop used to reduce hz](https://youtu.be/_2By2ane2I4)

[How CPU use clock](https://youtu.be/PVNAPWUxZ0g)

[Additional](https://youtu.be/kRlSFm519Bo?list=PLowKtXNTBypGqImE405J2565dvjafglHU)


## Detector

In electronics, a Detector is a circuit that looks for a specific pattern or "event" in a signal.

* It doesn't care about the signal most of the time.

* It only "fires" or activates when it sees its specific target (like a certain voltage level or a sudden change).

### Level vs. Edge 

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
