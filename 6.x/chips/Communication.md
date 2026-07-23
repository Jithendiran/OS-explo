# Hardware Communication Reference: Serial Interfaces and UART

## 1. Fundamentals of Data Transmission: Parallel vs. Serial
Computer processors process data in groups of bits simultaneously. The method used to move these bits determines the complexity and cost of the physical hardware.

### Parallel Transmission
* Definition: A method where multiple bits of data are sent at the exact same time over multiple separate physical wires running side-by-side. For example, an 8-bit system requires eight distinct data wires, plus additional control wires.
* The "Why": This method exists because it matches the internal design of early computer processors. It allows high-speed data transfer over very short distances within a circuit board, as an entire byte can move in a single clock cycle.
* Limitation: As physical distance increases, parallel transmission fails due to crosstalk (electrical interference between adjacent wires) and wire skew (bits arriving at slightly different times due to tiny variations in wire length). It also requires bulky, expensive cables.

### Serial Transmission
* Definition: A method where data bits are sent sequentially, one bit at a time, over a single physical wire.
* The "Why": This method was engineered to overcome the distance and cost limitations of parallel transmission. By reducing the data path to a single wire, it eliminates wire skew and drastically reduces the physical space and cost required for cabling.
* The Problem Introduced: Because processors think in parallel but cables transmit in serial, a hardware translation mechanism is required at both ends of the communication line.