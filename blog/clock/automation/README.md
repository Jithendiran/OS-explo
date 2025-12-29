How Clocks Turn Manual Logic into Automated Calculation?

We have a task to add serious of number eg: `24 + 34 + 77 = 135`

How humans will perform addition? As a human we will add all the 1's place, then 10s and so on, to keep simple i will explain for sequence addition

24+34 = 58, 58 is not our final result, so will keep in our memory or write it some where

then 58 + 77 = 135, 135 is our result

Here 58 is the intermidiate result , then add the final number with intermediate result

Lets design a simple circuit to do perform this operation

![circult diagram](./image-1.png)

Circuit explaination:
    1. 8 bit adder with 2 inputs
    2. 8 bit latch
    3. 8 bit adder and latch is connected with 8bit switch, imagine when we press the switch all the 8 bit switch circuit will close

why we need 8 switch?
    8 switch are included to decide when it should perform the addition

> What is Latch?
Latch is a memory circuit which will store 1 bit data, to save 8 bit data we will arrange 8 latches

Our sequence is 

1. **Start:** Latch is `0`. Input is `24`. Adder calculates $0 + 24 = 24$. We store `24` in the Latch by closing add circuit with latch (pressing the switch).
2. **Next:** Latch is `24`. Input is `34`. Adder calculates $24 + 34 = 58$. We store `58` in the Latch.
3. **Next:** Latch is `58`. Input is `77`. Adder calculates  $58 + 77 = 135$. We store `135` in the Latch.

The above steps may sound promising but unfortunately circuit won't work like that. 

**How wrong could it go?**

We all know electricity travell very fast,  When you press it, the gate stays open as long as your finger is on the button. If you press the button for even 0.1 seconds, the CPU sees that as a "High" signal for thousands of nanoseconds.

* **Time 0:** You press the button. Result = $0 (\text{memory}) + 24 (\text{input}) = 24$.
* **Time 1 (Still pressing):** The Latch sees the "High" signal is still there. It takes the new `24` from memory and adds the `24` from the input again. Result =  $24 + 24 = 48$.
* **Time 2:** It happens again! Result = $48 + 24 = 72$.

In a split second, your answer is `72` (or much higher) instead of `24`. This is a **feedback loop error**.

How to solve this?
Here problem is cicuit stays open for long duration, if the circuit open only once we will get our desire solution

We need some circut to open only once for each click, even if we press for couple of seconds, It should allow the electricity only one time

Scenerios
1st time you press teh button exactly for 1 sec and not pressed for 2 sec then you press for 3 sec and leave it open for 1 sec again you press for 0.5 sec

Lets plot a graph
![time graph](./btnclicks.png)

The high stage of the graph indicate the moment you press the button and low state indicate the open state of the switch

in our case the addition is happened on the high state, so latch keep on storing the data and feeding the data as input to the adder so it is contonously adding till the button is open

![stage graph](./Stagesofwave.png)

In graph we have four level of states
1. Rise state: At the moment we press the button
2. high state: As long as we press
3. fall state: At the moment we stoped pressing the button
4. low state: Button in open state 

Rise state and fall state happend only once in the button cycle, so if our circuit is opened at any one of these state we will get the desire result

Also it our button click cycle is matching with the square wave clock cycle, In square wave clock cycle we have same four stages  Rise, high, fall and low
Some circuits are only active during the Rise stage, like flip flop

> Flip flop is a extension of latch, Gates of flip flop open only at the time of rise edge, Flip flop have clock input

> Latches are high level trigger meaning as long you keep press the button it will accept the input


Let's redesign our cicuit 
![Adder](./8bitflipflopadder.png)

In our new design we replace the latch with flip flop, directly connect the output of adder to the input of the flip flop
connect the button with flip flop's clk pin

Now we if we follow our same sequence and observe the output

Our sequence is 

1. **Start:** Flip Flop is `0`. Input is `24`. Adder calculates $0 + 24 = 24$. We store `24` in the Flip Flop by closing add circuit with Flip Flop (pressing the switch).
2. **Next:** Flip Flop is `24`. Input is `34`. Adder calculates $24 + 34 = 58$. We store `58` in the Flip Flop.
3. **Next:** Flip Flop is `58`. Input is `77`. Adder calculates  $58 + 77 = 135$. We store `135` in the Flip Flop.

Since flip flop allow store the input only at the time of rise edge, we will get the desire output now

Most of the circuits like counters are made of flipflops



### Automating the Process

Instead of a human pressing a button, we use a **Clock Signal** (a continuous square wave) to automate the process


**Imagine we have 3 registers (A, B, C) holding our numbers:**

1.  Adder stage (cycle 1)
    1. **Rising Edge:(Starter)** Push the Inputs to the adder.
    2. **High Level:** The Adder receives the new numbers. started doing the math
    3. **Falling Edge:** The Adder is still working due to propogation delay
    4. **Low Level:** Doing nothing, just give enough time that adder has 100% 
    At the end of the cycle adder done with the operation

2. Capture and move stage(cycle 2)
    1. **Rise:** capture the reult and move to next register (increment the address)
    2. **High Level:** Do nothing
    3. **Falling Edge:** Do nothing
    4. **Low Level:** Do nothing
    At the end of the second cycle, Control Unit select the second register

In CPU, these is a seperate unit called `Control unit`, it will take care of the controling the circuits as per clock and stage, it will have internal counter it will keep track of the cycle counts

>**Adder circuit is not a edge\level trigger**   
>    Unlike latches or Flip-Flops, an adder does not have a "Clock" or "Enable" pin. It doesn't wait for a signal to tell it to start adding. It is always on
>    - How it works: As soon as you change the inputs ($input$ or $flipflop$), the output ($Sum$) starts changing immediately.
>    - The Delay: The only reason the output isn't "instant" is because of Propagation Delay (the physical time it takes electricity to travel through all the transistors inside add logic). 
> We should give enough time for output to settle down in the adder


#### Cycle process
1. 0 + 24
    1. Cycle 1
        1. Rise edge:
            - flipflop currently it is 0
            - Push the flipflop data and A register to Adder (24)
        2. High level:
            - Adder receives the number
            - Due to propogation delay it would take some time
        3. Falling edge:
            - Adder is working, due to complex logics and propogation delay
        4. Low Level:
            - At the end of the low level adder should have the stable result of sum (24)
    2. Cycle 2
        1. Rise edge:
            - flipflop capture the data from Adder (24)
            - Control unit select the B reister
        2. High level:
        3. Falling edge:
        4. Low Level:
            - do nothing
    
2. 24+34
    1. Cycle 1
        1. Rise edge:
            - 24 captured in flipflop
            - Push flipflop (24) and B register to Adder(34)
        2. High level:
            - adding
        3. Falling edge:
            - adding
        4.  Low Level:
            - At the end of low level adder have result (58)
    2. Cycle 2
        1. Rise edge:
            - flipflop capture the data from Adder (58)
            - Control unit select the C reister
        2. High level:
        3. Falling edge:
        4. Low Level:
            - do nothing

3. 58+77
    1. Cycle 1
        1. Rise edge:
            - 58 captured in flipflop
            - Push flipflop (58) and B register to Adder(77)
        2. High level:
            - adding
        3. Falling edge:
            - adding
        4.  Low Level:
            - At the end of low level adder have result (135)
    
    2. Cycle 2
        1. Rise edge:
        2. High level:
        3. Falling edge:
        4. Low Level:
            - do nothing

At the end of 5 th cycle we will get the result


By the end of 5th  cycle, addition is perfectly finished. This is **Controlled Automation**. Because each step has its own "moment" on the wave, the operations don't collide. This is use of the clock, It will sync the operation


We should choose our clock based on our longest taking time circuit, in our example adder is more complex circuit, so before moving to next cycle we should guarenteed that the proper output of adder is captured

There are some option in choosing the clock
**1. Duty Cycle Adjustments**
During High level electricity flow into the circuit like adder but the results are not stable (Based on the carry bit electricity flow may change), think of this stage is only to pass the electricity, in low level stage it will get enough time to settle the result
- in high stage electricity is flow into the circuit, but result are not stabe
- in the end low level result will be stage

for some circuits flow of electricity is faster but stable will take time, in this case we should choose clock like high stage is lower than the low stage like (10% duty cycle, high stage only have 10% time of cycle, low stage will have 90% time)
if flow and stable take same amout of time then it is 50% duty cycle
high stage hev 50% of the cycle and low stahe have 50% of the cycle

**2. Frequency Divisor**
If the whole system is too fast, we use a frequency divisor to slow down the "heartbeat" of the CPU so every component can keep up.

**3. The "Wait" State**
What if the component is *really* slow (like external RAM)?
In this case, the component sends a "Wait" signal to the CPU. The CPU will stop and "idle" on a specific part of the clock cycle until the component says, "I am done!" Then, the CPU continues to the next stage.