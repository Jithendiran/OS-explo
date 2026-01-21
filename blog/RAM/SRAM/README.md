## The Nanosecond Handshake: A Timing Analysis of MPU and SRAM

In low-level programming, we treat memory access like a simple `Load` or `Store` instruction. But underneath that abstraction lies a high-speed Handshake. If the signals arrive even 10 nanoseconds late, the entire system collapses into metastability and crashes.

This analysis looks at the timing budget between a [W65C02S](https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf) MPU (2 MHz) and an [HM62256B-8](https://web.mit.edu/6.115/www/document/62256.pdf) SRAM (85ns).

## Analysis
![Analysis](./timing-diagram-6502.jpg)

### 1. The Clock: Our 500ns Budget

1. Convert Megahertz to Hertz: $$2\text{ MHz} = 2 \times 10^6\text{ Hz} = 2,000,000\text{ Hz}$$
2. Calculate the period in seconds: $$T = \frac{1}{2,000,000\text{ Hz}} = 0.0000005\text{ seconds}$$
$$T = 5 \times 10^{-7}\text{ s}$$
3. Convert seconds to nanoseconds: Since $1\text{ second} = 10^9\text{ nanoseconds}$:
    $$T = (5 \times 10^{-7}) \times 10^9\text{ ns}$$
    $$T = 500\text{ ns}$$

At 2MHz, one clock cycle is exactly 500ns. We use the Falling Edge (0ns) as our starting gun.

### 2. The Read Cycle
* MPU need 150ns to drive valid address on address BUS
* RAM chip need 85 from the valid address to drive correct data over data BUS
* MPU needs data to be stable for 60ns before capturing data

Timing budget for read is 440ns–150ns=290ns

**The time line**
1. 0 - 150ns : Address is Driving. Data is invalid.
2. 235ns     : RAM successfully drives the Data Bus.
3. 440ns     : The "Setup Window" begins. Data must not move.
4. 500ns     : MPU latches the data. Success.

Verdict: Data arrives at 235ns, and the deadline is 440ns. We have a massive safety margin, Even if the chip gets hot and slows down, it will still work.

### 3. The Write Cycle
Writing is more dangerous. If address is not stable before start writing it could lead to hard to debug the issues. unlike read, write has to start and stop at clock signal for synchrnous

**The time line**
1. 0 – 150ns: Address is Driving. 
2. 250ns: The "Gate" Opens. WE and CS pins go active; RAM prepares to receive data.
3. 390ns: MPU successfully drives the Data Bus (tMDS).
4. 465ns: The "Setup Window" begins. Data must be stable for the RAM (tDW).
5. 500ns: WE goes disable. The Gate closes and Data is "burned" into memory.

Verdict: The MPU provides stable data at 390ns. The gate closes at 500ns. That is 110ns of stability—triple what the RAM requires (35ns).

### 4. The Hold Time
Notice that tAH (Address Hold) and tDHW (Data Hold) are both 10ns. When the clock falls at 500ns, the MPU doesn't instantly stop driving the bus. It holds for 10ns while the next address is preparing.

This "anchor" ensures that the RAM doesn't see the address change while it is still trying to finish the write. Without this 10ns grace period, data could bleed into the wrong memory address.

**What if the Memory is too slow?**
If you used an old 400ns RAM, the data wouldn't be ready until 150ns + 400ns = 550ns. The MPU would have already sampled the bus at 500ns and read "garbage."

To fix this, we use the RDY Pin. Pulling RDY low tells the MPU to "freeze" for one clock cycle—giving the slow RAM an extra 500ns to finish its job. This is the hardware origin of the "Wait State" in software.

### Deep Dive Further

I have documented the full pin-by-pin breakdown on my GitHub: [Jithendiran](https://github.com/Jithendiran/OS-explo/blob/master/electronics/timing-diagram.md)