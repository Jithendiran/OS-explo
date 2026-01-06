# How to Calculate Clock Speed

> This blog provides a high-level overview. For the full deep-dive from electron physics to logic gates, check out my technical notes on [GitHub](https://github.com/Jithendiran/OS-explo/blob/master/electronics/timings.md)


## Introduction: Electricity Isn’t Instant

We often think electricity instantly, but in the world of high-speed computers, electricity crawls. It takes time to charge wires and push through transistors.

### The Time Scale

1000 fs == 1 ps  
1000 ps == 1 ns  
1000 μs == 1 ms  
1000 ms == 1 sec  
60   s  == 1 min   
60  min == 1 hr    
24  hr  == 1 day  

To understand hardware, you have to think small about the speed of ns(Nano seconds)

### Why Timing Matters

Transistors take time to switch. This delay between an input changing and the output responding is called **Propagation Delay ($t_{pd}$)**.

Flip-flops have special requirements called **Setup Time** and **Hold Time**. During these windows, the data must be steady:

* **Setup Time ($t_s$):** The time required **before** the clock edge.
* **Hold Time ($t_h$):** The time required **after** the clock edge.

If data moves during this tiny window, the "photo" is blurry. Engineers call this **Metastability**—the system doesn't know if it's a 0 or a 1, and it crashes.


## The Flip-Flop Cycle: How Bits are Captured

We use a **Positive Edge Triggered Flip-Flop**. Internally, it consists of a Master latch (with an inverted clock) and a Slave latch (with a regular clock). Master sample the data and slave feed the data to next circuit.

### 1. During Low Level (CLK 0 - low level)

* **Master Latch:** The "master door" is open. The master is constantly watching and sampling the input data ($D$).
* **Slave Latch:** The "slave door" is locked. It ignores the master and holds the previous output ($Q$).
* **Constraint:** During low clock, The "master door" is open.  The clock must stay low ($T_{low}$) time, long enough to "power up" the master’s components to capture the signal.
* **The Deadline ($t_s$):** Data must stop changing here so the master gets a stable look before the door shuts.

### 2. During the Edge (0 $\to$ 1 Transition - positive edge)

* **The Trigger:** The clock hits the threshold voltage ($V_{th}$). (which is usually around $V_{DD}/2$)
* **The Inversion Delay:** The master’s clock is an inverted version of the main clock. It takes a few picoseconds for that signal to pass through the internal inverter.
* **The Overlap:** For a brief moment, the Master isn't fully locked, but the Slave has started to open. some small period both doors are opened
* **Hold Time  ($t_h$):** To prevent the Master from capturing a "wrong" new value during this overlap, the data must stay stable for a short period after the  hit.

### 3. During High Level (CLK 1 - high level)

* **Master Latch:** The master door is now locked. It is "frozen" and ignores changes on the data pin.
* **Slave Latch:** The slave door opens. It takes the frozen value from the master and pushes it to the output  ($Q$).
* **Constraint:** The clock must stay high ($T_{high}$) long enough for the slave to drive the new value to the output pins.

### 4. During the Falling Edge (1  $\to$ 0 Transition - negative edge)

* The Slave latch closes the door slightly quicker than the Master opens its door. For a few picoseconds, both doors are closed.


## Case Study: Building an 8-Bit Adder

We are cascading two 4-bit adder chips ([CD74HC283](https://www.ti.com/lit/ds/symlink/cd74hc283.pdf)) between two Flip-Flops ([SN54HC273](https://www.ti.com/lit/ds/symlink/sn54hc273-sp.pdf)).

### Timing Budget (at 4.5V)

* **Flip-Flop  (Setup):** 30 ns
* **Flip-Flop  (hold):** 0 ns
* **Flip-Flop  (Propagation):** 48 ns
* **Flip-Flop  (Min Pulse Width low/high):** 24 ns
* **Flip-Flop  (Max frequency):** 18 Mhz
* **Adder 1 (Carry Delay):** 39 ns
* **Adder 2 (Math Delay from $C_{in}$):** 46 ns

### The Adder Timeline

1. **Start (0 ns):** The clock hits. Data must hold for hold time, in our case it is 0. It takes **48 ns** ($t_{pd}$) for the data to exit the first Flip-Flop and reach the Adder.
2. **Adder 1 (48 + 39 = 87 ns):** After 39 ns of processing, the first adder produces a "Carry Out."
3. **Adder 2 (87 + 46 = 133 ns):** The second adder receives that carry and takes 46 ns to produce the final 8-bit sum.
4. **Final Deadline (133 + 30 = 163 ns):** The data is now at the second Flip-Flop. But it must sit still for **30 ns** ($t_{su}$) before the next clock edge can happen.


## Calculating Maximum Performance

To find the fastest stable speed, we add all the delays:

$$T_{total} = t_{pd(FF1)} + t_{logic(Adder\text{ 1, 2})} + t_{su(FF2)}$$

$$T_{total} = 48\text{ ns} + 85\text{ ns} + 30\text{ ns} = 163\text{ ns}$$


**Maximum Frequency ($f_{max}$):**
$$f_{max} = \frac{1}{163\text{ ns}} \approx 6.13\text{ MHz}$$

### Checks and Balances

* **Frequency Check:** 6.13 MHz is well within the chip's 18 MHz internal limit.
* **Duty Cycle Check:** At 50% duty cycle, $T_{high}$ and $T_{low}$ are both 81.5 ns. Both are greater than the 24 ns requirement. (PASS)

* **Hold Time Check:**  
    $$\text{FFP1 } t_{pcq(min)} + \text{Adder } t_{logic(min)} \geq \text{FFP2 }t_{hold} $$

    - $t_{pcq}$ (Fastest): Let's assume the FF reacts at its fastest, maybe $20\text{ ns}$.
    - $t_{logic}$ (Fastest): The carry doesn't have to ripple for the first bit ($S_0$). The delay from $A_0 \to S_0$ is only $32\text{ ns}$.

    $$20\text{ ns} + 32\text{ ns} \geq 0\text{ ns} $$
    $$52\text{ ns} \geq 0\text{ ns} \implies \mathbf{PASS}$$

> **Conclusion:** Clock speed isn't a random number; it is a calculation dictated by the laws of physics. As temperatures rise or voltages drop, these nanoseconds grow longer, forcing us to slow down the "heartbeat" of the CPU to keep the math accurate.