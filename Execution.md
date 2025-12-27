## How cpu execute instruction 
Goal is just to understand how assembly concerted to micro code and it control the control lines

For simplisity consider it is a 8 bit computer, This computer can only do addtion of 8 bit number max

### clk
- Every component are connected with common clock BUS (single wire)
- CU's clock is inverted clock

### memory
A, B, SUM, IP, Memory Address Rregister, SUM, FLAGS, IP, PC , RAM all  are `D-type flip-flops`
- These are rise edge triggers

RAM is level trigger

### Connection
[Detailed View](https://eater.net/8bit/schematics)

| Component | Input From | Output To | Note |
| --- | --- | --- | --- |
| **PC** | Internal Logic | **Data Bus** | Only puts addresses *onto* the bus to be moved to MAR. |
| **MAR** | **Data Bus** | RAM Address Pins | A 4-bit latch that "points" at a memory location. |
| **RAM** | **Data Bus** (if RI) | **Data Bus** (if RO) | Uses the address currently held by the MAR. |
| **IR** | **Data Bus** | CU & **Data Bus** | Top 4 bits = OpCode (to CU); Bottom 4 bits = Operand. |
| **A Reg** | **Data Bus** | ALU & **Data Bus** | One side of the math equation; can also output to Bus. |
| **B Reg** | **Data Bus** | ALU | The other side of the math equation. |
| **ALU** | A & B Regs | **Sum Register** | Purely combinational logic; does not store anything. |
| **Sum Reg** | **ALU** | **Data Bus** | Latches the ALU result so it can be safely moved to A or Out. |
| **Flags** | ALU (Z/C) | Control Unit | Stores if the last math result was Zero or had a Carry. |
| **CU** | IR & Flags | All Module Pins | The EEPROM that turns "commands" into "voltages." |
| **OP** | **Data Bus** | LED/Monitor,.. | When the content is written to it's register, LED will start light up based on the values |

### OP

Output register get the data from BUS, output register is connected to 8 LED, if LED's `1010 1001` is written to OP resigter, where ever 1 is prent that particular LED will light up 

### ALU unit

ALU unit is a 8 bit addres which has 8 bit output and 1 carry flag, 8 bit output is connected with SUM register
- SUM register's input is connected with ALU's output 
- SUM's output is connected with BUS

SUM can only write to DATA BUS

ALU is level trigger

### BUS

BUS is a bundle of wire which is connected to many components, this the way each components talk to each other, System has 3 types of BUS

Since BUS are wire these are consider as Level trigger

In the explaination we will have 2 BUS
* Common BUS: This is were data and address will travel, all the components Input/Output (ALU's output is only connected to the BUS, input from A and B register) connected to this BUS, This is a common 8 wire attached to registers, RAM, PC, IR

* Control BUS: It has bunch of wired 
    - Enable: This is a unique wire for each component to control the enable pin
    - Load: This is a unique wire for each component to control the load pin

But in real world computer we will be having 4 BUSES

**What is the advantage of haveing 4 BUS?**

    In common BUS architecture we can only move data /address at a time, but in real world, registers can put/get data from data BUS and PC, MAR can use Address BUS at the same clock, It will speed up the process

**Real world BUS**

#### Address BUS
This BUS carries the address

Wire count depends on the maximum supported memory size, for 16 Bytes memory capacity 4 wires needed, address range 0000 - 1111 (0-15)

Components connected with Address BUS
* (Program Counter)PC: Points to the next address
* (Stack Pointer) SP: Pints to the top of the stack
* Memory Address Register (MAR): Ponits to the address to get data from RAM

Here the Address Bus was wired directly to the RAM but In a PC real PC, the Address Bus is connected to a System Controller (or Northbridge/Chipset). This controller is like a traffic cop with a map.


#### Data BUS
This BUS carries actual data

It is a 8 copper wire 

Components connected are
* A
* B
* SUM
* IR (Instruction Register): Connected to the Data Bus to "catch" the instruction coming in from memory so the Control Unit can decode it.

#### Control BUS
This BUS is used to control the flow, so this is not a common BUS, each component needs a dedicated wire

Each component has `Enable` pin and `Load` pin, this is connected with control unit

In real world computers this is the BUS which handle **Read/Write Signals**, **Interrupt Request**, **RESET**

#### Clock BUS
This is a single common wire for every component, CU's clock is inverted clock
So 2 wires used  1 common wire for every component and 1 dedicated wire for CU unit

**Why control unit has inverted clock?**

    Most components (Registers, PC) load data on the Rising Edge. If the Control Unit also changed its signals on the rising edge, there would be a "race condition"—the A-Register might try to load data at the exact same nanosecond the CU is still deciding whether to turn the "Load" pin on or off.

    By using an Inverted Clock (or the Falling Edge), the Control Unit sets up all the Enable/Load pins half a cycle early.

    Simply inverted clock is for CU has to start before, because it is doing the operation

When a enable/load pin is active for particular component (By CU) and when the component got the desire clock content is written to/get from the desire BUS(Address/Data) 


### Control unit
There is counter in the control unit which indicate the current stage of execution

Step Counter is a Rising Edge trigger

#### EEPROM 
It is level trigger

Let's say our computer only support 3 instructions 
1. LOD addr
2. ADD addr
3. OP

* **LOD**
    LOD has to take the content of RAM at the address that LOD is pointing to and load it into the `A` register

* **ADD**
ADD has to take the content of RAM at the address that it is pointing to and load it into the `B` register, then it has to add the content of A and B register and move the result to the `A` register

* **OP**
OP has to take the content from `A` register and power the LED based on the 1's in the digit or input it have

#### RAM layout

16 Byte memory storage

|Address in decimal|Value      |
|------------------|-----------|
|0                 | LOD 14    |
|1                 | ADD 15    |
|2                 | OP        |



#### Execution

> enable pin is associated with output, load pin is associated with input
> if the module's input is connected to bus and output is connected to BUS means when enable pin is active it will put the data to the BUS, if load pin is active it will get the data from BUS

Our instructions are already in the RAM and all the registers, components are at the reset position/stage (A=0, B=0, PC=0,...)

1. LOD 14

    --------------------Stage 1
    1. PC  (enable pin has to enabled)
    2. MAR (load pin has to enabled)
    3. clk pulse 
        At the clock pulse content from the PC is placed on the common bus, at the very moment content from the common bus will go into the MAR register 

    ----------------- Stage 2 

    RAM's input is MAR so RAM now knows which content it has to take, MAR is a pointer for RAM

    1. RAM (enable pin has to enabled)
    2. IR (load pin has to enabled)
    3. program counter has to incremented (BUS not used)
    4. clk pulse
        At the clock pulse content from the RAM is placed on the common bus, at the very moment content from the common bus will go into the IR register 

    --------------------- Stage 3

    Now IR got the instruction, PC points to the next instruction address

    Control unit has to know what that instruction means, IR will contain the binary of the instruction for now consider LOD -> 0001 and 14 -> 1110, so IR contains `0001 1110`

    Control unit get it's desire enable pins based on the instruction here it is LOD, so IR onlt interested on opcode LOD

    1. IR (enable pin has to enabled) (only 1st four bits/ operand / opcode is enabled)
    2. EEPROM (load pin has to enabled)
    3. clk
        IR's opcode is passed to EEPROM's input 

    > How EEPROM is working? 
    > EEPROM is same as RAM, but it can store data even power is down, when we input the address EEPROM will return the content on the address 
    > so here address is `0001` when we feed this as input, EEPROM will return the content stored in that location

    > What is the data stored in EEPROM?
    > Every address is the instruction, for each instruction it will have the active and deactive control pins (enable and load) for each module

    ------------------ Stage 4

    EEPROM's output is connected to the control pins for each module

    For `LOD 14` instruction (IR enable(operand), MAR , RAM , A register )

    1. IR (enable pin has to enabled)
    2. MAR (load pin has to enabled)
    3. clk

    --------------------- Stage 5

    Now MAR is pointed to address 14

    1. RAM (enable pin has to enabled)
    2. A (load pin has to enabled)
    3. clk

    ------------------

    At the end of 5 th stage `A reg` have the value

2. ADD 15

    PC is already pointing to second instruction

    --------------------Stage 1

    1. PC  enable pin
    2. MAR load pin 
    3. clk pulse 

    ----------------- Stage 2 

    1. RAM enable pin
    2. IR load pin 
    3. program counter ++
    4. clk pulse

    --------------------- Stage 3

    1. IR (opcode 1st 4 bit) enable pin
    2. EEPROM load pin 
    3. clk

    ------------------ Stage 4

    For `ADD 15` instruction (IR enable(operand), MAR in, RAM enable, B register load pin has to enable, ALU, SUM register )
    1. IR enable pin
    2. MAR load pin 
    3. clk
    MAR received 15

    ------------------ Stage 5

    1. RAM enable pin
    2. B load pin 
    3. clk
    Now B has the the content from 15, This ALU always do the operation based on the A and B register on every cycle, so far addition no need of seperate cycle, Moder chips have seperate enable pin for ALU to save the energy that time it require couple of cycles to do the opration

    ------------------ Stage 6

    ALU out is connected with SUM register, Now SUM has the result

    1. SUM enable pin (This is also ALU writting to the BUS )
    2. A load pin
    3. clk

    ------------------- 

    At the end of stage 6 we will have the add result in the A register

3. OP

    PC is already pointing to Third instruction

    --------------------Stage 1

    1. PC  enable pin
    2. MAR load pin 
    3. clk pulse 

    ----------------- Stage 2 

    1. RAM enable pin
    2. IR load pin 
    3. program counter ++
    4. clk pulse

    --------------------- Stage 3

    1. IR (opcode 1st 4 bit) enable pin
    2. EEPROM load pin 
    3. clk

    ------------------ Stage 4

    For `OP` instruction (A register and OP register)
    1. A enable pin 
    2. OP load pin
    3. clk
    At the clock pulse content from A register is written to BUS, at the very moment OP register get that data, Once the OP got the data the LED started litght up

    ----------


> We might have a doubt why single instruction is splitted into multiple stages and also some stages operation counts are high some stage operation count is less  
> Answer: Main rule is per clock cycle only one module can write into the common BUS, if more than one modules attempted to write, data written to BUS will be corrupted (if module 1 write `1010 1010` and module 2 write `0101 0101` at the clock pulse we not sure which one is written to the BUS or it might collide), so per clock cycle only one module has to write into the bus, there is no restriction on reading from the BUS, also no restriction on not using the BUS, so the stages are splitted only based on common medium usage, if we have seperate bus for data and address then in a single clock we might complete more steps

Here LOD take  5 clock cycles, ADD take 6 cycles and OP take 4 cycles to complete the operation 

LOD is the assembly code, this is break down into several stages based on the BUS usages, each stage have many instructions like RAM enable, IR load,.. these are called as micro code, This micro code we get from the EEPROM, if we not interested in using EEPROM, we can achive the same result by using logical gates (it is complex and require many gates, EEPROM is highly flexible easily add new instructions) 

We might see a pattern what ever the instruction initial 3 stages are common

* 1st 2 stages are knows as `Fetch` stage, it is taking the instruction from RAM
* 3 rd stage is `Decode` stage, it is finding the meaning of the address
* rest of the stages are `execution` stage, it is doing the job


### How EEPROM data is stored?
Lets say LOD is `0001`, ADD is `0010`, OP is `0011`
each instruction has max of 6 stages we will assign a number for that stage 1 is `0000`, 2 is `0001`, 3 is `0010`, 4 is `0011`, 5 is `0100`, 6 is `0101`

* **LOD**

|stage|EEPROM address|
|---|--------|
|1 |0001 0000| 
|2 |0001 0001|
|3 |0001 0010|
|4 |0001 0011|
|5 |0001 0100|
|6 |0001 0101| 

Now we have to fill up the content part (for simplisity i just included only minimal data)

For load stage 1 we have enable pc enable pin and MAR load pin, rest are disabled
(enable pin == O, load pin == I) 

A I = 0, A O = 0 (A register's enable and load pin is disabled)  

B I = 0, B O = 0  

$\vdots$

PC I = 0, PC O = 1 (PC's enable is active and load is unactive)

MAR I = 1, MAR O = 0 (MAR load is active and MAR enable is unactive)

This is the content of stage 1 for LOD

|A I|A O|B I|B O|$\cdots$|PC I| PC O| MAR I|MAR O|
|---|---|---|---|--------|----|-----|------|-----|
| 0 | 0 | 0 | 0 |$\cdots$| 0  |  1  |  1   |  0  |

|stage|EEPROM address|Content|
|---|--------|----|
|1 |0001 0000| 0000 $\cdots$ 0110

like wise for each instruction we will be fill up the 6 stage content

for 3 instruction we need 3 x 6 = 18 address, 

for LOD stage 6's content is all `0` like wise OP's stahe 5 and 6's content is all `0`, this indicate no opeartion

**Why we have to maintain 6 stages for each instruction?**

This is because ADD is the most complex instruction in this set, it required 6 stages, to keep sync we make ever instruction will have 6 stages

Control unit will keep track for each stages, so it will have a couter of 0 - 5, when it reaches to 5 on the next clock it will do reset so it will start from 0 again

This behaviour can be optmized, for simplisity we keep this way


## Simulation softwares
* [Logism](https://sourceforge.net/projects/circuit/)
* [Logisim-evolution](https://github.com/logisim-evolution/logisim-evolution)
* [Digital](https://github.com/hneemann/Digital)

## Refer
https://eater.net/8bit
* [Logic](https://youtu.be/dXdoim96v5A)(Manual operation)
* [CU](https://youtu.be/X7rCxs1ppyY) (Fetch cycle)
* [Code](https://youtu.be/dHWFpkGsxOs) (Micro code, assembly creation)
