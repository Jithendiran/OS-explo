## Memory Alignment: Why Your CPU Loves Even Numbers

At the lowest level, a CPU doesn’t just "grab" a piece of data from a single long line of memory. It interacts with memory through a system of banks and channels. Understanding how this works explains why "misaligned" data can cut your program’s performance in half.

1. The 8-Bit Era: The Simple Start

   In the 8-bit era, CPUs were built with 8-bit internal registers and an 8-bit data bus. This meant that the hardware was physically wired to process one byte (8 bits) at a time. Memory chips were manufactured to match this architecture, designed to provide exactly 8 bits of data for every unique address.

   The total memory a CPU could "see" depended entirely on the number of address lines available:

    * 8-Bit Address Lines: With 8 bits of addressing, the CPU could access $2^8$ (256) unique locations. Since each location held 8 bits, the total capacity was 256 bytes ($256 \times 8 = 2,048$ bits or 256 bytes).
    * 16-Bit Address Lines: A 16-bit address bus allowed the CPU to access $2^{16}$ (65,536) unique locations. This resulted in a total memory capacity of 64 KB (65,536 bytes or 524,288 bits or 64KB).

   **Handling Larger Data**
   Even though the registers were 8-bit, programs often needed to work with 16-bit values (such as memory pointers or large integers). Because the data bus was physically limited to 8 bits, the CPU had to perform two separate read cycles.
   1. Cycle 1: Fetch the first 8 bits from memory.
   2. Cycle 2: Fetch the next 8 bits from the subsequent address.
   3. Conjunction: The CPU would then manually combine these two bytes within its registers to form a single 16-bit value.

2. The 16-Bit Era: The Birth of Banks

    As CPUs evolved to 16-bit architectures (like the Intel 8086), they were designed to handle 16-bit data natively. To maintain versatility, they remained backward compatible, meaning they could still read and write individual 8-bit bytes.

    A 16-bit register (such as AX) consists of two 8-bit halves: the High Byte (AH) and the Low Byte (AL). To support this, the memory architecture changed from a single block into two parallel Banks.

    **The Dual-Bank Trick**
    To read 16 bits in a single cycle, the CPU uses two separate memory chips organized side-by-side:
    * Even Bank: Stores data for addresses $0, 2, 4, 6 \dots$
    * Odd Bank: Stores data for addresses $1, 3, 5, 7 \dots$
    Each bank provide 8 bit of data
    The CPU is hardwired so that the Even Bank connects to the lower half of the data bus and the Odd Bank connects to the upper half.

    **How Parallel Access Works (The Common Address)**
    How does the CPU address two different chips at once? It uses a mathematical trick involving binary logic. Let’s look at two consecutive addresses:
    Let's take Single data `feab` 
    * Address 2: 0010 (Binary) = `fe`
    * Address 3: 0011 (Binary) = `ab`

    The only difference is the Least Significant Bit (LSB). If you "ignore" the LSB (effectively right-shifting the address by 1 bit), both 0010 and 0011 become 001. This is the Common Address.

    By sending the common address 001 to both chips simultaneously:
    1. The Even Bank provides the data at its location 001 `fe`(which corresponds to system address 2).
    2. The Odd Bank provides the data at its location 001 `ab`(which corresponds to system address 3).
    
    Single data is splitted between two banks (0-7 in one bank an 8 - 15 in another). From chip prespective both are stored in 1st address of memory
    This allows the CPU to fill a 16-bit register in one clock cycle.

    **Single Byte or 8 - bit data access**
    When a 16-bit CPU reads a single 8-bit byte, it still utilizes the banking system, but with a specific control mechanism to ignore the bank it doesn't need.

    Even though the CPU has two banks, it can choose to activate only one. This is handled by hardware signals (typically called Bus High Enable or BHE and the A0 address bit).
    1. Reading 8-bit from an Even Address
    When you request 1 byte from an even address (e.g., 0002):
    * The Process: The CPU generates the common address (001).
    * The Selection: It activates the Even Bank and deactivates the Odd Bank.
    * The Path: The data travels from the Even Bank directly into the Low Byte of the register (e.g., AL).
    * Cycles: 1 Cycle.

    2. Reading 8-bit from an Odd Address
    When you request 1 byte from an odd address (e.g., 0003):
    * The Process: The CPU generates the common address (001).
    * The Selection: It activates the Odd Bank and deactivates the Even Bank.
    * The Path: Even though the data is in the Odd Bank (which is physically wired to the high-byte bus lines), the CPU internal logic "swaps" or routes this data into the Low Byte of your target register (AL).
    * Cycles: 1 Cycle.

    We can read even/odd address in AL or AH for single bit 
    ```
        MEMORY BANKS          DATA BUS            REGISTERS
        [ Odd Bank  ] <---- [ High Bus ] <---+---> [ AH ]
                                            |
                    (Internal Swapper/Bridge Logic)
                                            |
        [ Even Bank ] <---- [ Low Bus  ] <---+---> [ AL ]
    ```

    **Aligned vs. Misaligned Access**
    The speed of the CPU now depends on where your data starts.
    * Aligned Access (Even Start)
    When data starts at an Even Address, the Low Byte and High Byte share the same "row" (common address).
    * Target: Address 0002 (16-bit data)
    * Step: CPU sends common address 001 to both banks.
    * Result: 1 Cycle.

    ```
    Address Space:
    Row (Common Addr) | Even Bank (0) | Odd Bank (1)
    ------------------------------------------------
    Row 0000          | [ Addr 0 ]    | [ Addr 1 ]
    Row 0001          | [ Addr 2 ]    | [ Addr 3 ]  <-- READ BOTH IN 1 CYCLE
    Row 0010          | [ Addr 4 ]    | [ Addr 5 ]
    ```

    **Misaligned Access (Odd Start)**
    If you try to read 16-bit data starting from an Odd Address, the data spans across two different rows.
    * Target: Address 0003 (16-bit data requires 0003 and 0004)
    * The Problem: Address 0003 is in Row 0001 (Odd Bank) and Address 0004 is in Row 0010 (Even Bank).
    Process:
        1. Cycle 1: The CPU accesses Row 0001 to grab the byte from the Odd Bank.
        2. Cycle 2: The CPU accesses Row 0010 to grab the byte from the Even Bank.
    * Result: 2 Cycles. The CPU is 50% slower because the data is "misaligned."

    ```
    Address Space:
    Row (Common Addr) | Even Bank (0) | Odd Bank (1)
    ------------------------------------------------
    Row 0001          | [        ]    | [ Addr 3 ]  <-- Cycle 1
    Row 0010          | [ Addr 4 ]    | [        ]  <-- Cycle 2
    ```

3. The 32-Bit Era: The 4-Bank System

    In the 32-bit era (e.g., 80386 and beyond), the CPU grew to handle 32-bit registers like EAX. To keep up with this, the memory architecture was expanded into 4 parallel banks.

    **Bank Organization**
    Instead of just "Even" and "Odd," we now have four 8-bit banks. To find the "Common Address," the CPU now ignores the last two bits of the address (effectively a right shift by 2).
    1. Bank 0: Handles addresses $0, 4, 8, 12 \dots$
    2. Bank 1: Handles addresses $1, 5, 9, 13 \dots$
    3. Bank 2: Handles addresses $2, 6, 10, 14 \dots$
    4. Bank 3: Handles addresses $3, 7, 11, 15 \dots$

    **Bank to Register Mapping (Correction)**
    In a Little-Endian system, the wiring is sequential:
    1. Bank 0 is connected to the data bus bits 0–7 (Lower 8 bits).
    2. Bank 1 is connected to the data bus bits 8–15.
    3. Bank 2 is connected to the data bus bits 16–23.
    4. Bank 3 is connected to the data bus bits 24–31 (Higher 8 bits).

    **The 32-Bit Mapping and Reading Scenarios:**
    1. 8-bit Mapping (AL and AH)
        The CPU can route any of the 4 banks into AL or AH.
        * AL / AH: Can receive data from Bank 0, 1, 2, or 3.
        * Mechanism: The Internal Swapper (Bus Router) detects which bank is requested and maps it to the target register.
        * Performance: 1 Cycle regardless of which bank is used.

    2. 16-bit Mapping (AX)    
        For 16-bit operations, the CPU prefers to use bank pairs that share a logical "half-word" path:
        * Primary Path: Bank 0 + Bank 1 (Aligned at start address 0, 4, 8...).
        * Secondary Path: Bank 2 + Bank 3 (Aligned at start address 2, 6, 10...).
        * Both are 1 cycle (0, 2, 4, 8...): Because the CPU can pull these pairs in a single "row" fetch. The swapper just slides the Bank 2+3 data over to the AX position.

        **Reading Scenarios**
        * Start Address 0: (Banks 0 + 1). Same row. 1 Cycle.
        * Start Address 1: (Banks 1 + 2). Same row. 1 Cycle.
            These are in the same row. Even though it’s an odd address, the CPU grabs them in 1 Cycle because it doesn't cross a row boundary. It just shifts the data internally to align with the AX register.
        * Start Address 2: (Banks 2 + 3). Same row. 1 Cycle.
        * Start Address 3: (Bank 3 of Row 0 + Bank 0 of Row 1). 2 Cycles.
            * Cycle 1: Fetch Row 0 (grabs Bank 3).
            * Cycle 2: Fetch Row 1 (grabs Bank 0).

    3. 32-bit Mapping (EAX)
        * The Full Path: Bank 0 + Bank 1 + Bank 2 + Bank 3.
        * This uses the entire 32-bit data bus. It only works in 1 cycle if all four bytes are on the same "Common Address" (Row).

        **Reading Scenarios**
        * Start Address 0: (Banks 0, 1, 2, 3). Perfectly aligned. 1 Cycle.
        * Start Address 1: Data is at Address 1, 2, 3 (Row 0) and Address 4 (Row 1).. 2 Cycles.
            * cycle 1: Cycle 1: Read Row 0. The hardware shifts the data right 8 bits to discard Bank 0 and align Bank 1, 2, 3.
            * cycle 2: Read Row 1. The hardware grabs Bank 0 and "stitches" it to the end of the previous data.
        * Start Address 2: (Banks 2, 3 of Row 0 + Bank 0, 1 of Row 1). 2 Cycles.
            * Cycle 1: Read Row 0. Shift to keep Banks 2 and 3.
            * Cycle 2: Read Row 1. Shift to keep Banks 0 and 1.
        * Start Address 3: Data is at Address 3 (Row 0) and Address 4, 5, 6 (Row 1). 2 Cycles.
            * Cycle 1: Read Row 0. Keeps only Bank 3.
            * Cycle 2: Read Row 1. Keeps Banks 0, 1, 2.
        * Start Address 4: (Next row: Banks 0, 1, 2, 3). 1 Cycle.

3. The 64-Bit Era: The 8-Bank Powerhouse

    In the 64-bit era (modern x64 and ARM64), the CPU has graduated to handling 64-bit registers like RAX. To feed this beast, the memory architecture is expanded into 8 parallel banks.

    Bank Organization To find the "Common Address," the CPU now ignores the last three bits of the address (effectively a right shift by 3). This creates a "Row" that is 8 bytes wide.

    Bank to Register Mapping The wiring follows the 64-bit data bus sequentially:
    * Bank 0 connects to bits 0–7.
    $\vdots$
    * Bank 7 connects to bits 56–63.
    The Swapper: Just like in the 32-bit era, the internal logic can route any bank to the lower part of a register, but it's most efficient when data is "naturally aligned."

    **Reading Scenarios (The 8-Byte Boundary)**

    The speed of your program now depends on whether your data fits within a single 8-byte row.
    1. 8 - bit (AL/AH)
    * Can address any location and perform in 1 cycle

    2. 16 bit (AX)
    * Start Address 0, 2, 4, 6: The 2 bytes sit in (Bank 0+1), (2+3), (4+5), or (6+7). They are all in the same row. 1 cycle
    * Start Address 1, 3, 5: The data is still in the same row, but the CPU must perform a "Read + Shift" to align the bytes to the register. Bit slower
    * Start Address 7: The data spans two rows (Bank 7 of Row 0 and Bank 0 of Row 1). 2 cycle

    3. 32 bit (EAX)
    * Start Address 0 or 4: The 4 bytes sit perfectly in the first half (Banks 0-3) or second half (Banks 4-7) of the row. 1 cycle
    * Start Address 1, 2, 3: The 4 bytes are all within the same row (e.g., Banks 1-4). The CPU reads the 8-byte row and shifts.  Bit slower
    * Start Address 5, 6, 7: The data spans two rows.  2 cycle
 
    4. 64-bit Mapping (RAX)
    * Start Address (Multiple of 8): Address 0, 8, 16... The data fills Banks 0 through 7 of a single row perfectly. 1 Cycle.
    * Start Address (Any other): If you start at Address 1 through 7, the data must span two different rows. (Read Row 0 + Read Row 1 + Stitching). 2 cycles


    **Cache Line Splitting**
    While 2 cycles for a misaligned read is bad, 64-bit systems introduced a bigger problem: The Cache Line (typically 64 bytes).

    ```
    Address Space (64-byte chunks):
    [ Row 0 (8 bytes) ]
    [ Row 1 (8 bytes) ]
    ...
    [ Row 7 (8 bytes) ]  <-- End of Cache Line 1
    ---------------------------------------------
    [ Row 8 (8 bytes) ]  <-- Start of Cache Line 2
    ```
    If your 64-bit data starts at Address 60, it requires:
    1. The last 4 bytes of Cache Line 1.
    2. The first 4 bytes of Cache Line 2.

    This isn't just a "bank swap" anymore. The CPU might have to wait for the memory controller to fetch an entirely different block of memory from the L3 cache or RAM. This can turn a 1-cycle read into a massive performance hit, far worse than the 50% slowdown of the 16-bit era.


**Data Structure Padding: The Cost of Clean Rows**
Since the CPU is physically wired to grab data in 8-byte chunks (on a 64-bit system), the compiler knows that misaligned data will tank your performance. To prevent this, it performs Padding: it inserts "useless" empty bytes between your variables to push them into the start of a new bank or row.

```c
struct Example {
    char a;     // 1 byte
    int b;      // 4 bytes
    char c;     // 1 byte
};
```

You might think this takes up 6 bytes ($1 + 4 + 1$). But the CPU sees a problem.

```
MEMORY ROW (8 Bytes)
[ a ] [pad] [pad] [pad] [  b (4 bytes)  ]  <-- Row 0
[ c ] [pad] [pad] [pad] [   Next Struct ]  <-- Row 1
```

Optimization Trick: Reordering

```c
struct Good {
    int b;    // 4 bytes
    char a;   // 1 byte
    char c;   // 1 byte
    // Only 2 bytes of padding needed at the end to round to 8!
};
```

* A 1-byte `char` should be at an address divisible by 1.
* A 2-byte `short` should be at an address divisible by 2.
* A 4-byte `int` should be at an address divisible by 4.
* An 8-byte `double` should be at an address divisible by 8.