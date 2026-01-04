## Timing in electronics
    Goal of this docs is to get the overview of how fast the electronics will work
    Timing are classified based on the logical things, Most of the discussions is about semiconductors

| Unit | Symbol | Value in Seconds | Common Example |
| --- | --- | --- | --- |
| **1 Second** | s | 1 sec | A human heartbeat. |
| **1 Millisecond** | ms | 1/1,000 sec | The blink of an eye (~300 ms). |
| **1 Microsecond** | μs | 1/1,000,000 sec | A high-speed camera flash. |
| **1 Nanosecond** | ns | 1/1,000,000,000 sec | Speed of light traveling 30cm (1 foot). |
| **1 Picosecond** | ps | 1/1,000,000,000,000 sec | Laser pulses used in eye surgery. |
| **1 Femtosecond** | fs | 1/1,000,000,000,000,000 sec | The motion of atoms in a molecule. |

```
1000 fs == 1 ps  
1000 ps == 1 ns  
1000 μs == 1 ms  
1000 ms == 1 sec  
60   s  == 1 min 
60  min == 1 hr  
24  hr  == 1 day  
```

### Physics

Physics deals with the properties of the signal

#### Speed of electricity

When you flick a light switch, the light turns on almost instantly because the electromagnetic wave travels through the wire at nearly the speed of light.

**In a Copper Wire**: Roughly 50% to 99% of the speed of light, depending on the insulation and the surrounding material.

Speed of electricity is depends on two things **Wave** and **Drift Velocity**

1. **The Wave (The "Push")**

    Think of a long garden hose already full of water, When you turn the faucet on, water comes out the far end of the hose instantly. You didn't wait for a new water molecule to travel from the faucet to the end. Instead, you pushed the first drop by opening the faucet, which pushed the second, which pushed the third.

    * It is a "push" or "electric field" a signal that travels almost at the speed of light. This is why your light turns on the moment you flip the switch.

    * Electrons can travel through a vacuum in $300,000 \text{ km/s}$
 

2. **Drift Velocity (The "crawl")**

    Electron can travel faster in vaccum, but in the medium like copper wire/steel,.. it will slow down. Electrons are constantly crashing into copper atoms, which slows them down to a few millimeters per second.

    Electron speed is also dpends on the medium of the conductor, how fast it will push the electron, Medium have drift velocity

    The drift velocity $v_d$ depends on how crowded the material is with electrons and how many "obstacles" (atoms) are in their way.
    
    1. Electron Density ($n$): 

        How many free electrons are available to carry charge. The more free electron, better it is

    2. Cross-Sectional Area ($A$):
        - Thin Wire: The electrons are squeezed into a narrow space. To maintain the same current, they have to move faster (like water in a narrow nozzle).
        - Thick Wire: The electrons have plenty of room. They can move much slower and still deliver the same amount of electricity.
    
    3. Temperature
        - Cold Wire: The metal atoms stay relatively still, making it easier for electrons to slide through.
        - Hot Wire: The atoms vibrate violently. The electrons "bump" into these vibrating atoms more often, which slows down their forward progress. This is why resistance increases as things get hot!

    Drift velocity in vaccum is 0

    | Material | Electron Density  | Drift Speed  |
    | --- | --- | --- |
    | **Silver** | Very High | **Lowest** (Most efficient) |
    | **Copper** | High | **low** |
    | **Aluminum** | Medium | **Highest** (Needs more "effort") |

    **Silver** is very fast

    The electron from the wire would take 1 second to travell 1 millimeter
    
    due to electrics field or domino effect or push it feels like instant

####  Capacitance and Resistance ($RC$ Delay)

In electronics, "speed" isn't just about how fast electrons move; it's about how fast voltage can change. 
- When we apply 5 V to a copper wire, it would take few nano seconds to get 5 V, also the voltage is not 5V after few nano seconds it will be ramp up
- In Semiconductors, The Threshold Voltage ($V_{th}$) is the most common use of the term in engineering. It is the minimum voltage that must be applied to the Gate terminal to allow electricity to flow between the Source and the Drain. If the $V$ is less than  ($V_{th}$) semiconductors are insulators, $V_{th}$ will vary for each components

This is where Capacitance ($C$) and Resistance ($R$) come in.

To visualize an RC circuit, imagine a Water Bucket (Capacitor) being filled by a Water Pipe (Resistor).

> why pipe is marked as resistor? because it speaks about how fast it can conduct, wider the pipe better the speed


* Capacitance ($C$): This is the size of the bucket. A huge bucket takes a long time to fill. / The wire and its surroundings act like a tiny battery that must be "charged" to the new voltage level before it stabilizes.
* Resistance ($R$): This is the narrowness of the pipe. A very thin pipe limits how much water flows, slowing down the filling process.
* Inductance($L$): The wire resists changes in current. It takes a tiny amount of time for the magnetic field around the wire to build up.

Even if the "push" (voltage) is instant, the bucket cannot be "full" (reach the target voltage) until enough charge has physically flowed through the resistance.

$$\tau = R \times C$$

$$\tau = \frac{L}{R}$$

Conductors/semicondutors don't charge in a straight line; they charge on a curve. As the capacitor fills up, it "pushes back," making it harder for more charge to enter. This is called Exponential Decay/Growth.

In practical engineering, a capacitor is never 100% full (the curve flattens out forever), so we use a rule of thumb:

$1\tau$: 63% Charged

$3\tau$: 95% Charged (Often considered "stable" for many signals)

$5\tau$: 99.3% Charged (Considered "Fully Charged")

Speed of the electron, Capacitance and Resistance are combined to cause Propagation Delay ($t_{pd}$). It is the time elapsed between an input change and the resulting output change. 

For conductors and semiconductors ($t_{pd}$) calculation will change

The timing of ($t_{pd}$) will be discussed in Combinational Logic section. 


#### Timings

Every medium will have rise, fall, Settling and Slew time eg: copper wire, capacitor,..
These timings are measured in output only

* Rise Time ($t_r$): The time a signal takes to transition from a low voltage (10% of $V_{cc}$) to a high voltage (90% of $V_{cc}$).
* Fall Time ($t_f$): The time to transition from high (90%) back to low (10%).
* Settling Time: After a signal "jumps" to a new level, it often oscillates slightly. Settling time is how long it takes to stay within a specific error margin (e.g., 2% of the final value).
* Slew Rate: "speed limit" for how fast the voltage of a signal can change.

Settling Time > Rise Time

Settling time is always longer than rise time because it includes the rise time plus any time spent "ringing" (oscillating) at the top.

### Combinational Logic

*From here Only for semiconductors*

Combinational Logic deals with the relationship between an Input and an Output (the "delay") based on the gates

Now we move to gates (AND, OR, NOT). Since these are made of transistors, they have their own internal propagation delays.

Inside a logic gate (like a NOT, AND,.. gate), transistors act like the Water Pipe (Resistor) and the Bucket (Capacitor)
- Resistance ($R$): When a transistor turns "ON," it isn't a perfect wire. It has internal resistance (the "pipe width").
- Capacitance ($C$): The "Gate" of the next transistor is a physical layer of insulation. It behaves exactly like a capacitor (the "bucket").
- The Logic Delay: To turn the next gate ON, the current transistor must "fill the bucket" of the next gate through its own "internal pipe."


If you have an AND gate ($5\text{ns}$ delay) feeding into an OR gate ($5\text{ns}$ delay), the total time for a signal to "ripple" through is $10\text{ns}$.

Engineers don't wait for $5\tau$ (99.3%). Instead, we usually measure $t_{pd}$ at the 50% mark. Why? Because at 50% voltage, the next transistor is already halfway to switching. 0% Input and 0% Output has no way to differentiate, 10% input - 90% output calculation has to be symmetric value to get correct value, 100% input - 100% output hard to reach, 90% input - 90% output take long time
-  The 50% measurement is an industry convention for consistency, but the physical switching 'event' occurs when the voltage crosses $V_{th}$. Therefore, $t_{pd}$ is a 'system-level' measurement that may or may not includes the time spent waiting for $V$ to reach $V_{th}$. $V_{th}$ may be at 80% of the $V$, but $t_{pd}$ is only calculated at 50% this is standard


#### Timings 

This is where $t_{PLH}$ and $t_{PHL}$ live. These terms require two points: an Input and an Output. Measured from Input to the output
* $t_{PLH}$ (Propagation Delay Low-to-High): The time from the Input crossing 50% to the Output crossing 50% as the output rises. Time required for output to reach 50% from the input change at 50%
* $t_{PHL}$ (Propagation Delay High-to-Low): The same, but for when the output falls.
* $t_{pd}$ (Propagation Delay): Usually defined as the average: $\frac{t_{PLH} + t_{PHL}}{2}$. This is the "Total Processing Time" of a gate.
* Contamination Delay ($t_{cd}$): This is the minimum time it takes for an output to start changing. While $t_{pd}$ is the "Max" time we wait for a valid result

Why these are Combinational: They represent the "logic tax." In a perfect world (physics), a gate would flip the output the instant the input changes. In the real world, the gate has to "think" (process) for $t_{pd}$ nanoseconds.

### Sequential Logic

This is where the Clock comes in. To store data, we use Flip-Flops. These are "edge-triggered," meaning they only look at the input at the exact moment the clock pulse rises.

For a Flip-Flop to capture data correctly, the physics of the transistors requires the data to be stable.


For this discussion i take positive edge trigger flip flop, not D flip flop. D Flip flop is a negative edge trigger



#### Timings
Now we add the Clock. This level is about the "Agreement" between data and time.
* Clock-to-Q ($t_{pcq}$): The time for the output ($Q$) to change after the clock edge hits.
* Setup Time ($t_s$): The "deadline." Data must arrive and stable $t_s$ before the clock. Before this time data is not stable
* Hold Time ($t_h$): The "commitment." Data must stay for $t_h$ after the clock.
* Clock Skew ($t_{skew}$): The "latency" of the clock itself. If the clock wire is longer to one IC than another, one IC "wakes up" later.
* Clock Pulse Width High ($T_{high}$): The duration the clock signal remains at a logic High level ($V > V_{IH}$) during one cycle. The time the "Slave" latch has to drive the output $Q$.
* Clock Pulse Width Low ($T_{low}$) : The duration the clock signal remains at a logic Low level ($V < V_{IL}$) during one cycle. The time the "Master" latch has to "sample" the new data from the $D$ pin before the next edge.
* Minimum Pulse Width $(t_{w(min)})$: It is the absolute shortest time a pulse can exist (either high or low) for the internal transistors to respond. Clock must stay low / high for minimum of this time to capture

The exact moment filpflop start capture is Switching Threshold ($V_m$)  which is usually around $V_{DD}/2$, $V_{setup}$ must start before $V_m$



**Flip flop cycle**

We have positive edge trigger flip flop, Master's clock is inverted clock, salve has regular clock

1. During low level  ($\text{CLK } 0$)
    - Master Latch: The "front door" is open. The master is constantly watching and sampling the input data ($D$).
    - Slave Latch: The "back door" is locked. It ignores the master and keeps holding the previous output ($Q$).
    - Minimum $T_{low}$: The clock must stay low long enough to "power up" the master’s internal components so they can fully capture the data signal.
    - Setup Time ($t_s$): This is the final deadline at the very end of this phase. Data must stop changing here so the master can get a clear, stable "look" at the value before the door shuts.
2. During Edge ($\text{CLK }0 \implies 1$)
    - The Trigger: The clock hits the threshold voltage ($V_{th}$).
    - The Inversion Delay: Because the master’s clock is an inverted version of the main clock, it takes a few extra picoseconds for that signal to pass through the internal inverter.
    - The Overlap: During this tiny delay, the Master latch hasn't fully "locked" yet, even though the Slave latch has already started to "open." For a brief moment, both are sampling.
    - Hold Time ($t_h$): If the data changes during this overlap, the Master might capture the new, wrong value and pass it to the Slave, causing Metastability. To prevent this, data must remain stable for a short period after the $V_{th}$ hit until the Master's door is completely shut.
3. During High level ($\text{CLK } 1$)
    - Master Latch: The front door is now locked. It is "frozen" and ignores any new changes on the data pin.
    - Slave Latch: The back door opens. It takes the frozen value from the master and pushes it out to the output ($Q$).
    - Minimum $T_{high}$: The clock must stay high long enough for the slave to stabilize and successfully drive the new value to the output pins.
4. During low fall ($\text{CLK }1 \implies 0$)
    - During low edge, slave latch close the door quicker than master open it's door, during this time for few pico seconds both master and slave don't accept the data
    - Slave output the value catured during rise edge and high 
--- 
Next cycle

5. Now low level
    - Master latch sampling the new data.... $\text{again repeat}$

During  $T_{low}$ data can be change, but when $t_{su}$ is started data should not be latched

**If the data needs to be stable only for $t_{su}$, then why we need $T_{low}$ time?**

During the $T_{low}$ period master will open it's door and power up it's internal components (inverters and transmission gates) before the $t_{su}$, when it is $t_{su}$ internal components are warmed up it can capture the data quickly. 

During the $T_{high}$ slave power up it's component as well capture the data from master

$T_{low}$ started before $t_s$  $$T_{low}  \geq t_{w(min)} > t_{su}$$

**Sequence**
1. $T_{low}$ Starts: The Master latch opens. The internal nodes begin charging/discharging to match the current $D$ input. power up it's internal component
2. Data Changes: The Master latch tracks these changes. The internal "feedback loop" is being pushed back and forth. **Data changes are allowed**
3. $t_{su}$ Window Begins: The $D$ input must now remain constant. This gives the Master latch enough time to "settle" its internal feedback loop into a high-confidence state.  **Data changes are not allowed**
4. $V_{th}$ Reached (The Capture): 
    - The Master latch begins to disconnect from the $D$ pin.
    - The Slave latch begins to connect to the Master.
5. $t_h$ (Hold) Window: Because the Master's "disconnect" isn't instant (it's an analog process), the $D$ pin must stay stable for a few more picoseconds so no "garbage" noise leaks in while the door is closing.
6. $T_{high}$ Phase: The Slave latch is now transparent. It passes the Master's captured value to the output $Q$. It needs this time to drive the external load (wires and other gates).

**What is $t_{pcq}$ (Propagation Delay: Clock-to-Q) ?**
- The time it takes for the "snapshot" captured by the Master to physically appear at the Slave's output ($Q$). It is measured from the clock's $V_{th}$ to the output's $V_{th}$. This is the "output speed" of the flip-flop.
- $t_{pcq}$  does not include the setup. It is a separate measurement that happens after the clock edge.
- $t_{pcq}$ accounts for: 

    It is the propogational delay of the Flip flop after the clock edge
    1. The internal clock-path delay (Hold time is also in it)
    2. The time for the Slave latch to become transparent.
    3. The Slew Rate of the output $Q$ as it rises or falls.
    From rise edge $t_{pcq}$ covered every delay for the flipflop

### The System Loop (The "Logic")

Now we combine everything. Think of a circuit as a factory shift.

1. Start of Shift: The Clock ticks.
2. Work Begins: Data leaves the first Flip-Flop ($t_{pcq}$).
3. The Process: Data travels through all the "bricks" of combinational gates ($t_{pd}$).
4. The Deadline: Data must arrive at the next Flip-Flop and sit still for the setup time ($t_s$) before the next clock tick arrives.

- Speed of the clock should be choosen based on the combinational logic
- After the rise edge, after some pico seconds flip flop start driving the output to the combinational circuit  (The output data of the 1st Flip-Flop becomes stable after the $t_{pcq}$ (Clock-to-Q) delay, which usually happens long before the duty cycle (the "High" time) is over.)
- During High level 
    - Master is locked
    - Slave is driving the data
    - Combinationa circuit doing it's operation
- During low level
    - Master started sampling the new data
    - slave is driving the previous data 
    - Combinationa circuit doing it's operation
- At the end of the low level combinational will complete it's operation

#### Timings

The speed of that clock is actually dictated by the combinational circuits sitting between them.

* Sequential Circuits : These are the flip-flops that hold the data. They only  change state when the clock ticks.

* Combinational Circuits : This is the logic (adders, multipliers) that sits between the flip-flops. The data has to "run" through this logic before the next clock tick arrives.

$t_{pd}$ is taken based on the longest string of $t_{pd}$ values in your combinational circuit.

$$\text{T}_{clk} = \underbrace{t_{pcq}}_{\text{FF1 Delay}} + \underbrace{\sum t_{pd}}_{\text{Logic Math delay}} + \underbrace{t_{s}}_{\text{FF2 Buffer}} $$


$$f_{max} = 1 / \text{T}_{clk}$$

$$\text{T}_{clk}\text{ =  Total Minimum Clock Period}$$

### Duty Cycle and Pulse Width

Why Duty Cycle matters for Flip-Flops? 

Even though the "action" happens at the edge, a Flip-Flop is internally made of two parts: the Master Latch and the Slave Latch.

- When Clock is LOW ($T_{low}$ or $T_{off}$): The "Master" door is open. The data from the $D$ pin is flowing into the first chamber. If $T_{low}$ is too short, the data never reaches the back of the chamber.

- When Clock is HIGH ($T_{high}$ or $T_{on}$): The "Master" door slams shut, and the "Slave" door opens to push the data to the $Q$ output. If $T_{high}$ is too short, the data doesn't "lock" into the Slave latch properly.

The Duty Cycle is the ratio of "High" time to "Low" time in one clock period.

* The Physics Limit: Every IC has a Minimum Pulse Width. If your clock frequency is $100\text{MHz}$ ($10\text{ns}$ period), but you set a $10\%$ duty cycle, the "High" pulse is only $1\text{ns}$.
* The Failure: If that $1\text{ns}$ is shorter than the IC's internal physical switching limit, the transistors won't even finish turning on. The circuit will fail, even if the frequency "math" seems correct.

Most modern ICs use CMOS (Complementary Metal-Oxide-Semiconductor) technology, which uses two types of "switches" working together: NMOS and PMOS.
* NMOS Transistor: Closes the switch (conducts) when the Gate is High.
* PMOS Transistor: Closes the switch (conducts) when the Gate is Low.

**The Pulse Width Constraint**

- $T \times \text{Duty Cycle} > t_{w(min, high)}$
- $T \times (1 - \text{Duty Cycle}) > t_{w(min, low)}$

Imagine a 1 GHz clock ($T = 1000\text{ ps}$) with a 20% Duty Cycle.

Actual High Time: $1000 \times 0.20 = \mathbf{200\text{ ps}}$  
Actual Low Time: $1000 \times (1 - 0.20) = 1000 \times (0.80) = \mathbf{800\text{ ps}}$

If your flip-flop's datasheet says $t_{w(min, high)} = 250\text{ ps}$, your circuit will fail because 200ps is not enough time for the Slave to operate, even though the total 1GHz frequency might be fine.


#### Choosing the right Duty Cycle:

| Duty Cycle | When to go for it? | Why? |
| --- | --- | --- |
| **50% (Standard)** | **Almost all digital systems.** | Provides the most balanced time for the Master and Slave latches to settle. It is the "gold standard." |
| **10% (Short Pulse)** | **Low Power / Triggering.** | Useful if you only want to "strobe" (Flash on quickly and off) a circuit to save power. However, if $T_{on}$ is shorter than the internal switching time of the transistors, the FF will fail to capture. |
| **60% (Asymmetric)** | **Time Borrowing / Skew.** | Used in advanced designs (like high-performance CPUs) where the logic in one direction is much slower than the other. It "borrows" time from one phase to give to another. |

###  The Clock Skew

Clock Skew is a system-level result of your design, not a property of a single component.

A datasheet for a Flip-Flop tells you about the individual part: how fast it is ($t_{pcq}$) and what it requires ($t_{su}$, $t_h$). This has to be calculated by the designer

Clock Skew ($\delta$ or $t_{skew}$) is the difference in arrival time of the same clock edge at two different flip-flops.

It depends on 
- how long your wires/traces are 
- how far apart you will place the flip-flops on your PCB or chip.

We have to use specialized software to calculate the skew time

#### Calculation
Clock skew is defined as the mathematical difference between the arrival time at the "Destination" flip-flop and the "Source" flip-flop.

$$\text{Skew} = T_{\text{FF2 clock time}} - T_{\text{FF1 clock time}}$$

* Positive Skew: The clock arrives at the receiving (Capture) flop later than the sending (Launch) flop.
    - If data and clock flow in same direction, it will result positive clock skew, eg (left to right), from 1st flipflop to 2nd flip flop
    - Positive Skew helps your Setup Time (it gives the logic more time to finish) but hurts your Hold Time (it might let new data "race" in too early and change the data before hold time).

    $$\text{T}_{clk} + \text{T}_{skew} \geq t_{pcq} + t_{logic} + t_{su}$$
    $$\text{T}_{clk} \geq t_{pcq} + t_{logic} + t_{su} -  \text{T}_{skew} $$
    Hold time Safety check: If this condition satisfied good to go
    $$t_{pcq} + t_{logic} \geq t_{h} + t_{skew}$$

* Negative Skew: The clock arrives at the receiving flop earlier than the sending flop.
    - If data and clock flow in differet direction, it will result negative skew, eg data from from FF1 to FF2, clock signal is near FF2 and far from FF1
    - Negative Skew hurts your Setup Time (it cuts the cycle short).
    $$\text{T}_{clk} - \text{T}_{skew} \geq t_{pcq} + t_{logic} + t_{su}$$

    $$\text{T}_{clk} \geq t_{pcq} + t_{logic} + t_{su} + \text{T}_{skew} $$

    No hold time vilolation

    Hold time Safety check: If this condition satisfied good to go
    $$t_{pcq} + t_{logic} \geq t_{h} - t_{skew}$$


#### How to avoid clock skew?
If we provide a intentional delay of in the early clocks, we may avoid clock skew
If more cpomponents are present in the circuit, **clock tree** is a clock management circuit it will make sure every component get the clock at same time

### Clock jitter
Clock Jitter is a random, unpredictable variation in the timing of the clock edges from one cycle to the next.
$$T_{min} = t_{pcq} + t_{logic} + t_{su} +(- t_{skew} || +t_{skew}) + t_{jitter}$$


### Logic take more time

#### Option 1: Increase the Clock Timer (Slow down the Clock)

This is the "easiest" fix. If your adder takes  but your clock cycle is only , you just change the clock to .

* **Pros:** Very simple to implement. You don't have to change any logic or code.
* **Cons:** **It slows down everything.** Even the fast parts of your chip (like a simple gate that only takes ) are now forced to wait  for the next edge. Your overall "Megahertz" (MHz) rating drops.


#### Option 2: Give it an "Empty" Clock (Multi-Cycle Path)

In professional digital design, we call this a **Multi-Cycle Path**. You keep the clock fast (e.g., ), but you tell the system: *"Hey, this specific adder is slow; don't look at its output until the 2nd or 3rd clock edge."*

* **Pros:** You keep your high clock speed (MHz) for the rest of the chip.
* **Cons:** * **Complexity:** You must add "Enable" signals to your flip-flops so they don't capture the "garbage" data during the first clock edge.
* **Throughput:** You can't start a new addition every single cycle; you have to wait for the adder to finish before giving it new numbers.


#### Which one is better?

It depends on how often you use that adder:

| If the Adder is... | Best Solution | Why? |
| --- | --- | --- |
| **Used in every single step** (like the PC incrementer) | **Slower Clock** or **Pipeline it** | If everything depends on it, a fast clock doesn't help much if you're always waiting. |
| **A rare, heavy task** (like a complex 64-bit Multiply) | **Multi-Cycle Path** | Keep the CPU clock fast for simple tasks; only slow down when that specific heavy math is needed. |
| **Extremely slow** | **Pipelining** | Break the adder into two smaller adders with a flip-flop in the middle. This allows you to keep a fast clock *and* start a new addition every cycle. |

> **The "PC Overclocking" Fact:** When people "overclock" their computers, they are doing the opposite—they are making the clock faster and faster until the adders can't finish in time. Eventually, the math fails, and the computer blue-screens!


### The  Datasheet Shorthand

| Category | Shorthand | Simple English Explanation | Water Analogy |
| --- | --- | --- | --- |
| **Supplies** | **$V_{DD}$** | **Main Power (+)** for CMOS/MOSFETs. | The Water Tower height. |
|  | **$V_{SS}$** | **Ground (0V)** for CMOS/MOSFETs. | The ground/drain level. |
|  | **$V_{CC}$** | **Main Power (+)** for BJTs/Old Logic. | The Water Tower height. |
|  | **$V_{EE}$** | **Ground/Negative** for BJTs/Old Logic. | The ground/drain level. |
| **Thresholds** | **$V_{th}$** | **Internal switch point** of a transistor. | The height of the floodgate. |
|  | **$V_{IH}$** | Minimum voltage needed to **see a "1"**. | The "Full" bucket mark. |
|  | **$V_{IL}$** | Maximum voltage allowed to **see a "0"**. | The "Empty" bucket mark. |
| **Outputs** | **$V_{OH}$** | Minimum voltage the chip **sends for a "1"**. | Pressure the sender promises. |
|  | **$V_{OL}$** | Maximum voltage the chip **sends for a "0"**. | Pressure the sender drains to. |
||**$V_{hys}$**|Hysteresis Voltage: A small "buffer zone" that prevents a signal from flickering if it's noisy.|A spring on the floodgate that prevents it from rattling if the water level is exactly at the threshold.|
| **Timing** | **$t_{PLH}$** | Time for Output to go **Low-to-High**. | Time for water to start flowing. |
|  | **$t_{PHL}$** | Time for Output to go **High-to-Low**. | *ime for water to stop flowing. |
|  | **$t_{r}$** | **Rise time** (time to climb 10% to 90%). | Time for pipe to reach full pressure. |
|  | **$t_{f}$** | **Fall time** (time to drop 90% to 10%). | Time for pipe to empty out. |
||**$t_{sk}$**|Skew Time: The difference in delay between two different pins on the same chip.|Two faucets turned on at the same time, but one pipe is slightly longer so the water arrives later.|
| **Current** | **$I_{CC}$** | The total current the chip consumes to power its internal logic.(Just for alive) | The total amount of water the entire house system uses just to keep the pipes pressurized. |
||**$I_{OH}$**| Output High Current, How much current the pin can push out to power an LED/other gate. |How much water the pipe can spray out to fill another bucket or spin a wheel (LED).|
||**$I_{OL}$**|Output Low Current, How much current the pin can pull in (sink) to ground.|How much water the pipe can suck in and dump into the sewer (Ground) without overflowing.|
---

### Calculation

**FF1 -> Adder -> FF2**

### Flip flop 
[Data from Data sheet](https://www.ti.com/lit/ds/symlink/sn54hc273-sp.pdf)

$V_{CC} = 4.5\text{V}$ At 25&deg;C

1. DC Thresholds (Correct)
- $V_{IH} = 3.15\text{V}$
- $V_{IL} = 1.35\text{V}$
- $V_{OH} = 4.4\text{V}$ (at $I_{OH} = -20\mu\text{A}$)
-$V_{VOL} = 0.1\text{V}$ (at $I_{OL} = 20\mu\text{A}$).
2. Timing Requirements (The "Deadlines")
- Slew Rate ($\Delta t/\Delta v$) = $500\text{ ns}$
- $t_{w}$ (Pulse Width  high or low) = $24\text{ ns} $
- $t_{w}$ ($\overline{CLR}$ low) = $24\text{ ns} $
- $t_{su}$ (Setup Time) = $30\text{ ns}$
- $t_{su}$ ($\overline{CLR}$ inactive) = $30\text{ ns}$
- $t_{h}$ (Hold Time) = $0\text{ ns}$
3. Output
- $t_{pd} / t_{PHL} = 48\text{ ns}$
4. The Clock Frequency ($f_{max}$)
- $f_{clock}$ (Max) = $18\text{ MHz}$ rating is the fastest the chip can toggle internally.

### Adder

[Data from Data sheet](https://www.ti.com/lit/ds/symlink/cd74hc283.pdf)

$V_{CC} = 4.5\text{V}$ At 25&deg;C

HC type
This is a 4 bit adder we have to combine 2
1. DC Thresholds (Correct)
- $V_{IH} = 3.15\text{V}$
- $V_{IL} = 1.35\text{V}$
- $V_{OH} = 4.4\text{V}$ (at $I_{OH} = -20\mu\text{A}$)
- $V_{VOL} = 0.1\text{V}$ (at $I_{OL} = 20\mu\text{A}$)

2. Output (Propagation delay)
tPLH,tPHL at CL = 50 pF
- $C_{IN} \text{ to } S0 = 32$
- $C_{IN} \text{ to } S1 = 36$
- $C_{IN} \text{ to } S2, C_{IN} \text{ to } COUT = 39$
- $C_{IN} \text{ to } S3 = 46$
- $C_{IN} = 10$
- $A_n, B_n \text{ to } C_{OUT} = 39ns (\text{Carry delay})$
- $An, Bn \text{ to } Sn = 42ns (\text{Math delay})$
- $t_{TLH},t_{THL} = 15ns $


Calculation

FFP1 = ($t_{pd}$): $48\text{ ns}$

I think FFP1 duty cycle only for slave, bcz master sampled in last low cycle

Adder

FFP2 = ($t_{su}$): $30\text{ ns}$

$$f = 1 / 78\text{ns} = \mathbf{12.8\text{ MHz}}$$
This clr and clk has same frequency

check duty cycle

--

#### Phase 1: Preparing at Flip-Flop 1 (The Starting Line)

Before the clock even "ticks," the data must be ready.

1. $V_{IH}$ (Input High Voltage): The data at the input of FF1 must rise above the $V_{IH}$ threshold to be recognized as a "1".
2. $T_{setup}$ ($t_s$): The data must be stable at $V_{IH}$ for at least $t_s$ nanoseconds before the clock edge hits. If it changes during this window, the transistors inside won't settle, leading to Metastability.
3. Clock Arrival & $t_{skew}$: The clock signal travels through the wires. If the wire to FF1 is shorter than the wire to FF2, the difference in arrival time is Clock Skew.
4. $V_{th}$ (Threshold Voltage): As the clock signal rises, it hits the $V_{th}$ of the internal clock-buffer transistors. This is the exact "moment" the FF captures the data.

#### Phase 2: Processing (The Journey through the Adder)

The clock has hit. Now the signal "exits" FF1 and travels through the Adder.

5. $t_{pcq}$ (Clock-to-Q Propagation): The time from the clock's 50% point to the output $Q$ reaching its 50% point. This is the "Exit Fee" of the first flip-flop.
6. $t_{cd}$ (Contamination Delay): This is the "Best Case" speed. It's the absolute minimum time before the output starts to move. We use this to check for Hold violations.violations.
7. $t_{pd}$ (Logic Propagation): The signal now enters the Adder. It ripples through the gates. This is the "Processing Tax."
8. $t_r$ and $t_f$ (Rise and Fall): As the signal leaves the Adder, it doesn't "jump." It follows an RC curve. The Rise Time is measured from 10% to 90% of the voltage.
9. Settling Time: After the rise, the signal might "ring" (oscillate) slightly due to inductance. Settling time is how long it takes to stay stable within a small margin (e.g., 2%).


#### Phase 3: Arriving at Flip-Flop 2 (The Finish Line)

10. $T_{setup}$ at FF2: The data coming out of the Adder must arrive at FF2 and be stable for $t_s$ before the next clock edge hits.
* **Max Frequency Calculation:**  $T_{period} \geq t_{pcq} + t_{pd\_adder} + t_s$.


11. $T_{hold}$ ($t_h$): After the clock edge hits FF2, the data from the Adder must stay stable for $t_h$. If the Adder is "too fast" and sends the next bit of data before $t_h$ is over, you get a Hold Violation.

----


$$\text{Frequency } = \frac{1 \text{ Cycle}}{\text{"ON/High" time} + \text{"Off/Low" time}}$$

1. On Time = 10 ms, Off time = 10 ms

This is a 50% duty clock (ON and OFF time are same)

$$=\frac{1}{10\text{ms} + 10\text{ms}} = \frac{1}{20\text{ms}} = 0.05 Hz$$
1 cycle for every 0.05 seconds

$$0.05{ ms} \times 1000 \text{ ms per second}  = 50 Hz$$

Convert the time from milliseconds to seconds:
$$20 \text{ ms} = \frac{20}{1000} \text{ s} = 0.02 \text{ s}$$

Calculate the frequency:
$$f = \frac{1}{0.02 \text{ s}} = 50 \text{ Hz}$$

2. On Time 10ms , Off Time= 30ms

Find Duty cycle = ON + OFF = total period for 1 cycle
$$ \text{One cycle time Period} = 10 + 30 = 40$$
$$\text{Duty cycle } =\frac{ \text{ON time}}{\text{One cycle time Period}}$$
$$= \frac{10}{40} = \frac{1}{4} = 25%$$
It is 25% Duty cycle clock

$$\text{Clock Frequency}=\frac{1}{10\text{ms} + 30\text{ms}} = \frac{1}{40\text{ms}} = 0.025$$

Milli second to seconds 
$$40/1000 = 0.04 \text{ s}$$

$$f = \frac{1}{0.04 \text{ s}} = 25 \text{ Hz}$$


$$T_{clk} \geq T_{cq} + T_{\text{Propagation Delay}} + T_{\text{Setup Time}} + T_{\text{Hold Time}}$$



$T_{cq}$: 1 nanosecond (Time for Flip-Flop to "speak").

$T_{pd}$: 8 nanoseconds (Time for the Adder to calculate the sum).

$T_{su}$: 1 nanosecond (Safety buffer for the next Flip-Flop).

Total $T_{clk}$: $1 + 8 + 1 = \mathbf{10 \text{ nanoseconds}}$.

Max Clock Speed: 

1 nanosecond ($ns$) = $0.000000001$ seconds

$$f = \frac{1}{10 \text{ nanoseconds}} = \frac{1}{10 \times 10^{-9} \text{ seconds}}$$

$$f = \frac{1}{0.00000001} = 100,000,000 \text{ Hz}$$
$$\frac{100,000,000 \text{ Hz}} {1000\text{ Kilo}} = 100,000 \text{KHz}$$
$$\frac{100,000 \text{ KHz}} {1000\text{ Mega}} = 100 \text{MHz}$$


Important: If you try to run this at 200 MHz ($5 \text{ ns}$ period), the "Rise Edge" will hit while the Adder is still in the middle of calculating. The result? Corrupted data.
