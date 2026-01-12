## Timing diagram analysis
Timing diagram analysis explaination


Min = This is the shortest time the CPU needs to stay "still" for things to work.

Max = This is the slowest the CPU will be.

Usually ignore $Typ$ if given in the datasheet for calculation

### MPU W65C02S
[w65c02s](https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf)

![6502](./res/timing-diagram-6502.png)

![6502-timing](./res/6502-timing.png)

Let's take 2MHz for sample calculation
* BE pin is enabled for all operation

* $t_{BVD}$ (max) = Once data is started diving in BUS, BUS need maximum of 30 ns to give the correct value 

* $t_{ADS}$ (max) = Cpu need 150 ns to put the stable address in address bus, after 150ns address is stable

* $t_{ACC}$ (min) = After address stabled, MPU expect data operation within 290ns

* $t_{AH}$ (min) = Data read/write from/to memory happen at fall edge, so address must hold for atleast 10ns

* $t_{ADS}$ (new address) and $t_{AH}$ (old address) has a overlapping period for 10ns at starting of the clock cycle

#### Read timing

* $t_{DSR}$ (min) = Before fall clock edge arrive, data must be stable for atleast 60ns

* $t_{DHR}$ (min) = Data must be hold for atleast 10ns after the fall edge, for MPU to access latch the data properly

#### Write timing

* $t_{MDS}$ (max) = MPU takes 140ns to write the data on the data bus

* $t_{DHW}$ (min) = MPU must hold the data after the fall clock edge for 10ns

### RAM HM62256B
We will use [HM62256B](https://web.mit.edu/6.115/www/document/62256.pdf) Asynchronous Static RAM (SRAM), it does not use a clock signal to synchronize its operations. 

Let's take -8 for sample calculation

![Read](./res/HM62256B-read-time.png)
![read-timeline](./res/HM62256B-read-time-line.png)

![write](./res/HM62256B-write-time.png)
![write-timeline](./res/HM62256B-write-cycle.png)

#### Read timing

* $\overline{WE}$ set to high
* $t_{RC}$ min = The total time a read operation must take, 85ns
* $t_{AA}$ (max)  = 85ns, From address stable till data become valid
* $t_{ACS}$ (max) = chip select time maximum of 85ns
* $t_{OE}$ (max)  = How long after OE goes Low until Data is valid, 45ns
* $t_{OH}$ (min)  = How long the data stays on the bus after the address changes 10ns

Address should be valid before $t_{AA}$ or $t_{OE}$ goes low and must valid till valid data available to databus till setup time, after address change, data is valid for minimim of 10 ns $t_{OH}$  

So the reading time required is which ever is greater in $t_{ACS}$ or $t_{OE}$ till address change, which is 85ns

From the stable address it need 85ns to provide the data

#### Write timing

> end of the write means it is the start time gates started closing, take some time to close completely

* Data will start write to RAM at time when  $\overline{CS}$ and $\overline{WE}$ both are in low state, during this period address must be valid and data should provide with in this time period, It is not expected to give the data for whole overlapping period, The data must be a valid one before RAM stops writing and it should be stable (achieve setup time) 
* Data write will stop when  $\overline{CS}$ or $\overline{WE}$ goes high, data must stable for hold time

* $\overline{OE}$ is set to high
* $t_{AS}$ (min) = Address setup delay with in RAM chip = 0ns
* $t_{WC}$ (min) = Total write cycle from address start driving till start change = 85ns
* $t_{AW}$ (min) = Address valid time till end of the write (gate started closing, address has to drive some time after this) = 75ns, $\overline{OE}$ is set high after few ns 
* $t_{CW}$ (min) = Duration for chip select from goes low till end of the write = 75ns
* $t_{WP}$ (min) = This is enabled after address is stable, the time duration is still end of the write = 0ns
* $t_{DW}$ (min) = This is the time data should be stable before the $\overline{CS}$ and $\overline{WE}$ goes high = 35ns
* $t_{DH}$ (min) = This is the time data should be hold after the end of the write = 0ns

Writing start at overlapping and end at 1st non overlapping, which time is greater in $(t_{CW}, t_{AW}, t_{WP})$ is the time required for write operation, which is 75ns. Data should be stable from 75 - $t_{DW}$ = 75-35 = 40ns

So the overlapping period is 0-75ns

0-40ns - don't care about what ever the data, but absolutely what ever is provided on the data-in is written to the memory, since actual correct data is followed by this, it will ensure correct data is written

40-75ns - data writing period, this time valid data should present in data-in pin

Data and address must hold for $t_{DH}$ (0ns) to ensure no data is not corrupted during closing window

## Analysis

| Time (ns) | Event / State | Logic Phase |
| --- | --- | --- |
| **0** | **50% of Falling Edge** | **Cycle Starts ($T_f$)** |
| 1 – 2 | Finish Falling to Low | Low edge ($T_f$). 3/5 sec in fall time| 
| 3 – 247 | **Low Level** | Low  level ($T_{PWL}$)|
| 248 | Start of Rising Edge | Transition, 2/5 sec in rise time (248, 249)|
| **250** | **50% of Rising Edge** | **Mid-cycle ($T_{r}$)** |
| 251 – 252 | Finish Rising to Low | High edge ($T_r$) 3/5 sec in rise time (250, 251, 252)|
| 253 – 498 | **High Level** | High level ($T_{PWH}$)|
| 499 | Start of Falling Edge | Transition |
| **500** | **50% of Falling Edge** | **Next Cycle Starts** |

### Memory read cycle

Address start flowing in the address BUS from fall edge, Data read from the memory at fall edge 

* MPU provides stable address by 150ns.
* The RAM starts working at 150ns. It needs $t_{AA}$ (85ns) to put data on the bus. $150\text{ns} + 85\text{ns} = 235\text{ns}$. Data is guaranteed stable on the bus at 235ns.
* The MPU doesn't need the data until the falling edge (500ns) minus its setup time $t_{DSR}$ (60ns), which is 440ns.

#### Clock cycle 
* t = 1 - 5 (fall edge)
    - Start Data read operation (old read) (MPU $\leftarrow$ Memory)
    - MPU started generating the next address

* t = 10ns (Hold time ends)
    - Now previous Data is guarenteed to be readed by MPU
    - We can believe it would take 10ns (0-10) for new address to change the state of internal transistor, before driving the next address to address bus, so old address is stable in bus during 0-10 ns

* t = 150 ns
    - new/current Address is stabilized on address BUS (tADS)
    - It will take 150 ns for stabilization 
    - Address is driving
    - RAM started working

* t = 150 + 85 = 235ns
    - RAM completed the working and start driving the data in the data bus
    - it will drive till the input address for RAM chip change

* t = 250 (Rise edge)
    - Address is driving from MPU
    - Data is driving from RAM

* t = 440 (440-150 (Address stable) = 290)
    - Tacc completed, now MPU Expect the data should be stable on the data bus 
    - Time for Data setup DSR(t = 440 - 500 = 60 ns)
    - MPU started latching

* t = 500ns (fall edge)
    - MPU start capturing the data

(Next cycle)
* t = 510ns (tDHR)
    - Data read completed
    - get new address
* t = 515ns 
    - Data from the data bus is back to high impendence state

#### Calc

* Address should be valid for 150 - 510 ns = 360ns
* Memory unit available time = (start of DSR)440 - (start of Tacc)150 = 290ns 
Memory unit have 290ns time, with in this time period it has to provide the data
$$t_{ACC} = t_{CYC} - (t_{ADS} + t_{DSR})$$
$$500\text{ns} - (150\text{ns} + 60\text{ns}) = 290\text{ns}$$

* RAM chip timing = 85ns, $85ns < 290ns $ so timing is with in the range

### Memory write cycle

* MPU provides stable address by 150ns.

Data write happen at fall edge, data should be available before the fall edge (35ns)

MPU need 140 ns to stabilize the write data

MPU can start write the data from 250ns high clock edge, 250 + 140 = 390 ns
from 390ns data is stable + 75ns for RAM write cycle = 465 ns at this time data is expected to written into RAM 

Atleast from 360 ns data should be stable

data must be available for 10ns after the clock hit 140 + 10 = 150 ns

**Things to note for RAM**


* Based on the timing diagram of MPU, we have address valid for some amount of time before clock goes high, valid for full high level and some tome after fall edge and MPU treating the fall edge as write data time, we must pick that spot

* $t_{AS}$ (min) = chip address setup time = 0
* $t_{CW}$ (min) = Chip select pin should be low minimum of 75 ns
* $t_{WP}$ (min) = Write pin should be low minimum of 55 ns
*  $t_{CW} - t_{WP} = 75-55 = 20ns$, $t_{CW}$ must goes low before 20ns of $t_{WP}$ goes low
*  Data writing time during overlapping 55ns, during this 55ns address must be stable, data must attain it's data setup time before any of the CW/WP pin goes high, $t_{DW} = 35ns$, 55 - 35 = 20, so during the last 20ns of overlap period data is written to RAM and address must valid after any of the pin goes high for $t_{WR} = 0ns$ time and data must valid for minimum of  $t_{DH} = 0ns$ after any of the the pin goes high


#### Clock cycle 
* t = 1 - 5 (fall edge)
    - Start Data write operation (MPU $\rightarrow$ Memory)
    - MPU started generating the next address
* t = 10ns (Hold time ends)
    - Now previous Data is guarenteed to be written by Memory
    - We can believe it would take 10ns for new address to change the state of internal transistor, before driving the next address to address bus, so old address is stable in bus

* t = 150ns
    - tADS completed
    - Address is stabilized on address BUS
    - It will take 150 ns for stabilization 
    - RAM chip $t_{AS}$ is 0 so RAM chip address get stablized from 150th ns

* t = 151 - 249ns 
    - Address is driving


* t = 250 (Rise edge)
    - Address is driving
    - CS pin and WE pin goes low
    - write data stabilization start

* t = 390ns (250+140 = 390ns)
    - Data is stable in Data bus.  ($t_{MDS}$).

* t = 465ns (500 - 35 = 465ns)
    - RAM Data Setup Deadline. For an 85ns RAM, $t_{DW}$ is 35ns. Data must be stable 35ns before $\overline{WE}$ goes High.

* t = 500ns (fall edge)
    - CS pin and WE pin goes high, which mean RAM chip is stop writing
    - DATA $t_{DH} = 0$ and Address $t_{WR} = 0$ should be valid for minimum amount of time

(Next cycle)
* t = 510ns (tDHW)
    - Data write completed
    - get new address

Since data is stable at 390ns and the write ends at 500ns. the data is stable for 110ns, which is much greater than the 35ns required.

### Slow memory 

**What if memory unit need more time?**

- If memory unit need more time disable `RDY` pin
- During fall edge depends on the `RDY` pin, MPU will wait for new data
- Hardware designer will design a Wait State Generator circuit, it will set the `RDY` pin low or high
- tPCS = 60 ns, before fall edge, `RDY` pin should be stabilized before 60ns
- tPCH = 10 ns, `RDY` pin has to be stable for atleast 10 ns, after fall edge

### Todo
for modern DRAM
- Look up "SRAM vs DRAM": Learn why modern RAM needs to be "Refreshed" every few milliseconds.
- Look up "SDRAM State Machine": See how a "Command" (Activate, Read, Precharge) replaces a simple "Address."
- Explore the 65816 or 68000: These are "next step" CPUs that use Bus Multiplexing (sharing wires), which is a bridge to modern tech.

## Refer
* [Youtube](https://www.youtube.com/watch?v=i_wrxBdXTgM)
* [Youtube](https://www.youtube.com/watch?v=Vq0x-ic9q04)