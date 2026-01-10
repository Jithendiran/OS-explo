https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf

Let's take 2MHz

Min = This is the shortest time the CPU needs to stay "still" for things to work.
Max = This is the slowest the CPU will be.
Usually ignore $Typ$ if given in the datasheet for calculation

## Mem read

Address start flowing in the address BUS from fall edge, Data read from the memory at fall edge 

$t_{ADS}$ (max) = Cpu need 150 ns to put the stable address in address bus, after 150ns address is stable

$t_{ACC}$ (min) = from the clock rise edge, MPU expect data within 290ns

$t_{AH}$ (min) = Data read from memory happen at fall edge, so address must hold for atleast 10ns

Data must be stable before the next fall edge

$t_{DSR}$ (min) = Before fall clock edge arrive data must be stable for atleast 60ns

$t_{DHR}$ (min) = Data must be hold for atleast 10ns after the fall edge, for MPU to access latch the data properly

Both address and data operations are happen at the fall edge, address actually start setup after previous cycle data read exactly after 10ns


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

Clock cycle start
* t = 0 - 5 (fall edge)
    - Start Data read operation (MPU $\leftarrow$ Memory)
* t = 10ns (Hold time ends)
    - Now previous Data is guarenteed to be readed by MPU

---------------------------- start

* t = 10 + 150ns = 160ns (Actual start)
    - tADS completed
    - MPU puts the address to be read on the BUS
    - It will take 150 ns for stabilization 
* t = 161 - 249ns 
    - Address is driving
    - 90 ns waiting time for MPU, but RAM can utilize
    - Tacc 90 ns completed (ROM/RAM working)

* t = 250 (Rise edge)
    - Address is driving
    - Tacc 91 ns completed (ROM/RAM working)
    - put the data to the data bus 
* t = 250 + (tacc 290 - 91 = 199) = 449ns
    - Tacc completed
    - Memory chip (ROM/RAM working) start driving the data
* t = 450 
    - TDSR time start (t = 440 - 500 = 60 ns)
* t = 500ns (fall edge)
    - MPU start capturing the data

(Next cycle)
* t = 510ns
    - Data read completed

### Calc

* Address should be valid for 161 - 510 ns
* Memory unit available time = (start of DSR)440 - (start of Tacc)160 = 280ns 
approximately Memory unit have 290ns time, with in this time period it has to provide the data
    - If memory unit need more time disable `RDY` pin

here i have one doubt
RAM get the actual address in middle of low level
same data started  writing in the middle of high level
how it know that previous operation is completed it can start from ths time?

for modern DRAM
- Look up "SRAM vs DRAM": Learn why modern RAM needs to be "Refreshed" every few milliseconds.
- Look up "SDRAM State Machine": See how a "Command" (Activate, Read, Precharge) replaces a simple "Address."
- Explore the 65816 or 68000: These are "next step" CPUs that use Bus Multiplexing (sharing wires), which is a bridge to modern tech.