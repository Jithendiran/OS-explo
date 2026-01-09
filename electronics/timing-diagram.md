To build the "building" of device communication from the "bricks" of timings, we have to move from a point-to-point connection (like your Adder) to a Shared Bus connection.

In your Adder example, the wire belonged only to the Adder. In a System, many devices share the same "hallway" (The Bus).

1. The Tri-State Buffer (The "Valve")
    We seen a wire is either 0 or 1. But if two devices are connected to one wire and Device A sends a '1' while Device B sends a '0', the circuit shorts out.
    * High-Z (High Impedance)
        - third state where the transistor "unplugs" itself from the wire.
        -  How long does it take for a pin to go from "Active" to "Disconnected"? (This is called $t_{HZ}$ and $t_{LZ}$).
2. The Bus Cycle (The "Handshake")
    Now that we have valves, how do two chips agree on who talks? We move from $T_{total} = t_{pcq} + t_{pd} + t_{su}$ to a Bus Read Cycle.
    Your next study goal: Look at a timing diagram for a Generic Asynchronous Read.
    - Address Valid: The CPU puts an address on the wires.
    - The Wait ($t_{AA}$): Address Access Time. The memory chip needs time to "find" the data in its internal grid.
    - Data Valid: The moment the memory chip finally pushes data onto the bus.

3. Synchronous vs. Asynchronous
    You calculated a clock speed of 6.13 MHz. This assumes the CPU and Adder are perfectly in sync. But what if the device you are talking to is slow or doesn't have a clock?
    * Synchronous (SPI/Memory): Uses your $t_{su}$ and $t_h$ logic.
    * Asynchronous (UART/RS232): There is no shared clock! How do they agree on speed? (This introduces the concept of Baud Rate and Sampling).

Start with The Memory Read Cycle. It is the most direct evolution of your 8-Bit Adder project.
The Experiment: Instead of FF1 -> Adder -> FF2, imagine: CPU -> Address Bus -> SRAM Chip -> Data Bus -> CPU


https://web.mit.edu/6.111/www/s2004/LECTURES/l7.pdf