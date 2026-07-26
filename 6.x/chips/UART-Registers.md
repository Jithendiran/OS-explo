
# Register
To control and communicate with the 8250/16550 UART hardware, the system processor uses a set of 8 primary byte-wide locations (registers) accessed via offsets (+0 to +7) from a base address(A0, A1, A2 the hardware address bus lines $2^3 = 8$).

Because 8 memory addresses are not enough to cover every single function of the chip, the UART uses an internal switch called the Divisor Latch Access Bit (DLAB)—which lives inside the Line Control Register (LCR, Offset +3)—to change what Offsets +0 and +1 point to.

## Why DLAB Exists
* Speed configuration registers (Divisor Latch Low and High) are only written once when the system boots up or when the baud rate changes.
* Conversely, data movement registers (Receiver Buffer and Transmitter Holding) are accessed constantly during active communication.

To prevent wasting scarce I/O address space on configuration registers that are rarely modified, the chip architecture shares the memory addresses 0x3F8 and 0x3F9 between data movement and speed configuration. The DLAB switch dictates which function owns those addresses at any given moment.

## Offset and Register

### DLAB 0

|Binary (A2 A1 A0)|Offset (Hex)|Read Operation|Write Operation|
|-----------------|------------|--------------|---------------|
|000|+0x00|Receiver Buffer Register (RBR)*|Transmitter Holding Register (THR)*|
|001|+0x01|Interrupt Enable Register (IER)*|Interrupt Enable Register (IER)*|
|010|+0x02|Interrupt Identification Register (IIR)|FIFO Control Register (FCR)|
|011|+0x03|Line Control Register (LCR)|Line Control Register (LCR)|
|100|+0x04|Modem Control Register (MCR)|Modem Control Register (MCR)|
|101|+0x05|Line Status Register (LSR)|Factory Test / Reserved|
|110|+0x06|Modem Status Register (MSR)|Reserved|
|111|+0x07|Scratch Register (SCR)|Scratch Register (SCR)|

### DLAB 1
Note on Registers: offsets `+0x00` and `+0x01` multiplex with the Baud Rate Divisor Latch registers (DLL and DLM) when the Divisor Latch Access Bit (`DLAB`) in the Line Control Register (`+0x03`) is set to `1`.

|Binary (A2 A1 A0)|Offset (Hex)|Read Operation|Write Operation|
|-----------------|------------|--------------|---------------|
|000|+0x00|Divisor Latch Low (DLL)|Divisor Latch Low (DLL)|
|001|+0x01|Divisor Latch High (DLM)|Divisor Latch High (DLM)|
|010|+0x02|Interrupt Identification Register (IIR)|FIFO Control Register (FCR)|
|011|+0x03|Line Control Register (LCR) (DLAB lives here)|Line Control Register (LCR) (DLAB lives here)|
|100|+0x04|Modem Control Register (MCR)|Modem Control Register (MCR)|
|101|+0x05|Line Status Register (LSR)|Factory Test / Reserved|
|110|+0x06|Modem Status Register (MSR)|Reserved|
|111|+0x07|Scratch Register (SCR)|Scratch Register (SCR)|

### A Real-World Example (x86 COM Ports)
On traditional PC architecture, COM1(`intr 4` pin) is mapped to I/O base address `0x3F8`:
* `0x3F8` (`0x3F8` + `0`): `A2 A1 A0` = `000` $\rightarrow$ Accesses Data Register (RBR/THR)
* `0x3F9` (`0x3F8` + `1`): `A2 A1 A0` = `001` $\rightarrow$ Accesses Interrupt Enable Register (IER)
* `0x3FD` (`0x3F8` + `5`): `A2 A1 A0` = `101` $\rightarrow$ Accesses Line Status Register (LSR)

### 16550 FIFO Hardware Capacity Allocation
The 16550 UART contains two completely separate 16-byte FIFO memory buffers. They do not share memory space.
* Receive FIFO: Dedicated entirely to receiving data coming from the serial wire. Capacity = 16 bytes.
* Transmit FIFO: Dedicated entirely to staging data queued to be sent out over the serial wire. Capacity = 16 bytes.

```
                   +----------------------------------+
                   |          SYSTEM BUS              |
                   +--------+----------------+--------+
                            |                ^
             Write Data     |                | Read Data
             to THR (+0)    v                | from RBR (+0)
                  +-------------------+    +-------------------+
                  |   TRANSMIT FIFO   |    |   RECEIVE FIFO    |
                  |     (16 Bytes)    |    |    (16 Bytes)     |
                  +---------+---------+    +---------+---------+
                            |                        ^
             Parallel to    |                        | Serial to
             Serial Output  v                        | Parallel Input
                   +-------------------+    +-------------------+
                   | Transmitter Shift |    |  Receiver Shift   |
                   |     Register      |    |     Register      |
                   +--------+----------+    +--------+----------+
                            |                        ^
                            v                        |
                     TX Physical Line         RX Physical Line
```
The register offsets RBR (+0) and THR (+0) remain the access windows for these hardware memory structures:
* Writing to Offset +0 (THR): Appends 1 byte into the Transmit FIFO. Up to 16 sequential bytes can be written before the buffer becomes full.
* Reading from Offset +0 (RBR): Removes (dequeue) the oldest byte out of the Receive FIFO. Up to 16 bytes can accumulate in this buffer before an overrun error occurs.

### Core Purpose of Each Register
1. Receiver Buffer Register (RBR)
    * Purpose: Holds incoming serial data that the chip has converted into a parallel byte. Reading this register retrieves the oldest byte received from the FIFO buffer serial line.
    * Size: 8 bits Read-Only
    * Bits 7–0: Contains the actual 8-bit data byte received. (If configured for 5, 6, or 7 data bits, the unused upper bits are set to zero).
2. Transmitter Holding Register (THR)
    * Purpose: Accepts outgoing parallel data bytes written by software. The chip takes this byte, converts it into a serial bit stream, and transmits it over the wire. 
    * Size: 8 bits Write-Only
    * Bits 7–0: The 8-bit data byte written by software to be serialized and sent out over the transmission line.
3. Divisor Latch Low Byte (DLL)
    * Purpose: Stores the lower 8 bits of the 16-bit clock divisor value used to calculate the communication baud rate. 
    * Size: 8 bits Read/Write
    * Bits 7–0: The lower byte ($B_7$ to $B_0$) of the 16-bit divisor value calculated from the baud rate formula.
4. Divisor Latch High Byte (DLM)
    * Purpose: Stores the upper 8 bits of the 16-bit clock divisor value used to calculate the communication baud rate.
    * Size: 8 bits Read/Write
    * Bits 7–0: The upper byte ($B_{15}$ to $B_8$) of the 16-bit divisor value calculated from the baud rate formula.
5. Interrupt Enable Register (IER)
    * Purpose: Controls which specific hardware events—such as data arrival, transmit buffer readiness, or line errors—are permitted to   trigger an interrupt signal to the CPU.
    * Size: 8 bits Read/Write
    * Bit-by-Bit Breakdown:
      1. Bit 0 (Received Data Available Interrupt): When set to 1, enables an interrupt whenever new data arrives in the receive buffer or FIFO.
      2. Bit 1 (Transmitter Holding Register Empty Interrupt): When set to 1, enables an interrupt whenever the transmitter register or FIFO is empty and ready for more outgoing data.
      3. Bit 2 (Receiver Line Status Interrupt): When set to 1, enables an interrupt whenever a hardware error occurs (Overrun, Parity, Framing, or Break).
      4. Bit 3 (Modem Status Interrupt): When set to 1, enables an interrupt whenever a hardware handshake line (like CTS or DSR) changes state.
      5. Bits 7–4: Reserved / Unused (typically hardwired to 0).
6. Interrupt Identification Register (IIR)
    * Purpose: Read by the CPU during an interrupt service routine to identify the highest-priority pending event that triggered the interrupt request.
    * Size: 8 bits Read-Only
    * Bit-by-Bit Breakdown:
       1. Bit 0: Interrupt Pending Flag. If 0, an interrupt is pending and needs servicing. If 1, no interrupts are pending.
       2. Bits 2–1: Interrupt Source Code. Binary codes indicating the highest-priority event that triggered the interrupt. (e.g., Line Status, Received Data Available, Character Timeout, Transmitter Empty, or Modem Status).
       3. Bit 3: (16550 specific) Part of the interrupt source code encoding for FIFO timeout events.
       4. Bits 5–4: Reserved / Unused.
       5. Bits 7–6: FIFO Status. Reflects whether the FIFO buffers are enabled or disabled (11 means FIFOs are active).
    * Priority: Fixed priority ranking from highest to lowest is:
       1. Receiver Line Status (Highest: Overrun, Parity, Framing Error, or Break Interrupt)
       2. Received Data Available or Receiver FIFO Time-out (Data ready in buffer / FIFO trigger level reached)
       3. Transmitter Holding Register Empty (THR is ready for more data) 
       4. Modem Status (Lowest: Changes on CTS, DSR, RI, or CD lines)  
7. Line Status Register (LSR)
    * Purpose: Reports communication status and error conditions, letting software know if data is ready to be read, if the transmitter is empty, or if framing and overrun errors occurred.
    * Size: 8 bits Read-Only
    * Bit-by-Bit Breakdown:
      1. Bit 0 (Data Ready - DR): Set to 1 when data has been received and saved in the RBR or FIFO. Cleared when the CPU reads all data.
      2. Bit 1 (Overrun Error - OE): Set to 1 when a new incoming character arrives before the previous character has been read from the RBR, causing the old data to be overwritten.
      3. Bit 2 (Parity Error - PE): Set to 1 when the received character does not have the correct parity as specified by the LCR.
      4. Bit 3 (Framing Error - FE): Set to 1 when the received character does not have a valid stop bit (usually indicates a baud rate mismatch or line noise).
      5. Bit 4 (Break Interrupt - BI): Set to 1 when the serial input line is held in a logic 0 state for longer than the transmission time of a full character.
      6. Bit 5 (Transmitter Holding Register Empty - THRE): Set to 1 when the THR or FIFO is empty and ready to accept the next character to transmit.
      7. Bit 6 (Transmitter Empty - TEMT): Set to 1 when both the THR and the internal shift register are completely empty and no data is currently being transmitted on the wire.
      8. Bit 7 (Error in FIFO / Receiver FIFO Error): Set to 1 when there is at least one parity error, framing error, or break indication in the FIFO.
8. FIFO Control Register (FCR)
    * Purpose: Enables or disables the hardware FIFO buffers, clears queue contents, and sets trigger thresholds for when the buffer should warn the CPU.
    * Size: 8 bits Write-Only
    * Bit-by-Bit Breakdown:
      1. Bit 0 (FIFO Enable): When set to 1, enables both the transmitter and receiver FIFOs. When cleared to 0, disables the FIFOs (reverting to 1-byte buffer mode). Note: This bit must be toggled to clear FIFO contents.
      2. Bit 1 (RXRST - Receiver FIFO Reset): Writing a 1 clears all bytes in the receiver FIFO and resets its counter logic to zero (automatically clears itself afterward).
      3. Bit 2 (TXRST - Transmitter FIFO Reset): Writing a 1 clears all bytes in the transmitter FIFO and resets its counter logic to zero (automatically clears itself afterward).
      4. Bit 3 (DMA Mode Select): Selects the DMA signaling mode for receiver data transfers (usually 0 for Mode 0, 1 for Mode 1).
      5. Bits 5–4 (Receiver Trigger Level): Sets the number of bytes in the receiver FIFO required to trigger a Received Data Available interrupt (e.g., 00 for 1 byte, 01 for 4 bytes, 10 for 8 bytes, 11 for 14 bytes).
      6. Bits 7–6 (Reserved / Trigger Select): Used in conjunction with other settings to define trigger depths depending on the UART variant.
9. Line Control Register (LCR)
    * Purpose: Configures the physical framing of characters, including data bit length, stop bits, and parity generation. Bit 7 of this register acts as the DLAB switch to toggle access to the divisor latches.
    * Size: 8 bits Read/Write
    * Bit-by-Bit Breakdown:
      1. Bits 1–0 (Word Length Select): Specifies the number of data bits per character (00 = 5 bits, 01 = 6 bits, 10 = 7 bits, 11 = 8 bits).
      2. Bit 2 (Stop Bit Select): Specifies the number of stop bits transmitted (0 = 1 stop bit, 1 = 1.5 stop bits for 5-bit data or 2 stop bits for 6/7/8-bit data).
      3. Bit 3 (Parity Enable): When set to 1, parity generation and checking are enabled.
      4. Bit 4 (Even Parity Select): When set to 1, selects Even parity (if Bit 3 is enabled). When 0, selects Odd parity.
      5. Bit 5 (Stick Parity): When set to 1, forces the parity bit to a fixed state (high if Bit 4 is 0, low if Bit 4 is 1).
      6. Bit 6 (Break Control): When set to 1, forces the serial output (TX) to a constant spacing state (logic 0) to alert the receiving end of a break condition.
      7. Bit 7 (Divisor Latch Access Bit - DLAB): When set to 1, enables access to the DLL and DLM registers through the base I/O addresses normally used by RBR/THR and IER. Must be cleared to 0 for normal operation.
10. Modem Control Register (MCR)
    * Purpose: 
      * Drives external hardware (printer, mice,..) control lines 
        * Data-Terminal-Ready: An output signal controlled by bit 0 of this register. The local system uses this line to indicate that it is fully operational, prepared for communication, and has established a valid connection session.
        * Request-to-Send: An output signal controlled by bit 1 of this register. The local (computer) system uses this line to inform an external connected device (printer, mice) that the local system is powered on, ready, and able to receive incoming data.
      * Activates internal Loopback Mode for diagnostic testing without sending signals to physical pins.
          Controlled by bit 4 of this register. When enabled, the internal hardware logically disconnects the transmitter output from the physical transmission wire and loops it directly back into the receiver input. This allows software to write data to the chip and read it back internally to verify that the UART driver logic functions correctly without needing an actual external cable or connected device.
    * Size: 8 bits Read/Write
    * Bit-by-Bit Breakdown:
      1. Bit 0 (DTR - Data Terminal Ready): Controls the physical DTR output pin. Setting to 1 asserts the line active, indicating the system is ready for communication.
      2. Bit 1 (RTS - Request to Send): Controls the physical RTS output pin. Setting to 1 asserts the line active, signaling that the system is ready to receive data.
      3. Bit 2 (Out 1 / Auxiliary Output 1): User-defined general-purpose output pin (often unused or utilized for custom hardware functions).
      4. Bit 3 (Out 2 / Auxiliary Output 2): General-purpose output pin; in standard PC architectures, setting this to 1 enables the routing of UART hardware interrupts to the system interrupt controller.
      5. Bit 4 (Loopback Mode): When set to 1, activates internal diagnostic loopback mode, disconnecting external pins and looping transmitter outputs directly into receiver inputs.
      6. Bits 7–5: Reserved / Unused (typically hardwired to 0). 
11. Modem Status Register (MSR)
    * Purpose: Monitors the real-time physical states of incoming hardware handshake lines driven by external connected equipment.
      * The Concept of Handshaking: When two devices communicate over a serial cable, one device might send data faster than the other device can process it. To prevent data loss, physical wires are dedicated to flow control (handshaking). The external device uses these wires to tell the local system whether it is safe to send more data.
      * Real-Time Physical States: This register directly reads the electrical voltage currently present on specific input pins coming from the external device.
      * Clear-to-Send (CTS): Monitored by a specific bit in this register. It tells the local system whether the external device is ready to accept outgoing data. If the external device's internal buffer is full, it drops the voltage on this line, and the MSR reflects that change so the local system pauses transmission.
      * Data-Set-Ready (DSR): Monitored by another bit in this register. It indicates whether the external equipment is powered on, connected, and ready to establish communication.
    * Size: 8 bits Read-Only (Lower 4 bits indicate state changes, upper 4 bits indicate real-time pin levels)
    * Bit-by-Bit Breakdown:
      1. Bit 0 (Delta CTS - DCTS): Set to 1 if the physical CTS input pin has changed state since the CPU last read the MSR.
      2. Bit 1 (Delta DSR - DDSR): Set to 1 if the physical DSR input pin has changed state since the CPU last read the MSR.
      3. Bit 2 (Trailing Edge of Ring Indicator - TERI): Set to 1 if the RI input pin has transitioned from an active low state to an inactive high state.
      4. Bit 3 (Delta Data Carrier Detect - DDCD): Set to 1 if the physical DCD input pin has changed state since the CPU last read the MSR.
      5. Bit 4 (Clear to Send - CTS): Reflects the real-time complementary logic state of the physical CTS input pin (mirrors active status when high).
      6. Bit 5 (Data Set Ready - DSR): Reflects the real-time logic state of the physical DSR input pin.
      7. Bit 6 (Ring Indicator - RI): Reflects the real-time logic state of the physical RI input pin.
      8. Bit 7 (Data Carrier Detect - DCD): Reflects the real-time logic state of the physical DCD input pin.
12. Scratchpad Register (SCR)
    * Purpose: Contains no internal hardware control logic. Used exclusively as temporary storage by software device drivers to write a byte and read it back to verify that a valid UART chip is present at the expected memory address.
    * Bit-by-Bit Breakdown: Bits 7–0: General-purpose temporary data storage bits. Software drivers write an arbitrary pattern (e.g., 0x5A) to this register and read it back to confirm that a valid 16550 UART hardware chip is present and functioning at the designated memory or I/O address.

## The Problem without IIR
The UART chip can trigger a hardware interrupt for multiple distinct reasons:
* Data arrived and is waiting to be read.
* Transmit buffer is empty and ready for new data.
* A communication error occurred (e.g., framing error or parity error).
* A modem signal status line changed state.

Without a central reporting register, an Interrupt Service Routine (ISR) executing on the main CPU must perform polling across multiple status registers (LSR, MSR, RBR) using individual input/output read instructions to identify the cause of the interrupt.

**The Mechanism of IIR**
The UART hardware tracks internal events and encodes the highest-priority pending condition directly into bits 0 through 3 of IIR (Offset +2).

When the hardware fires an interrupt signal line to the processor, the CPU executes a single read instruction to Offset +2. The value returned in IIR instantly identifies the exact source of the event without querying individual status registers.

* Reading IIR and receiving value 0x04 (Bit pattern 0000 0100) directly indicates: "Received Data Available".
* Reading IIR and receiving value 0x02 (Bit pattern 0000 0010) directly indicates: "Transmitter Holding Register Empty".

### Priority working
When an Overrun Error (OE), Parity Error (PE), and Data Ready (DR) all happen at the exact same time, the UART hardware handles it through a specific sequence of priority evaluation and register status updates.

1. Priority Resolution in the UART
    Even though all three events occurred together, the UART's internal priority encoder evaluates them using its hardwired rules.
    * Line Status errors (which include Overrun and Parity errors) sit at the highest priority level.
    * Data Ready (Received Data Available) sits at a lower priority level.
    Therefore, the UART will generate an Interrupt Identification Register (IIR) code specifically signaling a Receiver Line Status interrupt, effectively masking the "Data Ready" interrupt temporarily. 
2. What the Registers Show
    When the CPU responds to the interrupt and reads the registers:
    * Line Status Register (LSR): Both Bit 1 (Overrun Error) and Bit 2 (Parity Error) will be set to 1, along with Bit 0 (Data Ready / DR) which is typically set whenever valid data is waiting in the receiver buffer. The LSR captures the cumulative state of the hardware.
    * Receiver Buffer / FIFO: The corrupted byte that triggered the Parity Error sits at the top of the FIFO/buffer. However, because an Overrun Error also occurred, it means a previous byte was lost because the buffer was already full.
3. How the CPU Handles It
   To properly resolve this, the CPU's Interrupt Service Routine (ISR) must follow a strict order of operations:
   1. Read the IIR: Sees that a Line Status interrupt is pending.
   2. Read the LSR First: The CPU reads the LSR before reading the data. Seeing both OE and PE bits set, the software logs that a data corruption occurred (Parity) and a data loss occurred (Overrun).
   3. Read the Data Byte: The CPU then reads the Receiver Buffer (+0x00). Reading the LSR and then the data buffer is usually what clears the error flags in the UART hardware.
   4. Loop / Re-check: Because Data Ready was masked by the higher-priority error, good UART driver software will loop and check if any other flags or data remain in the queue before exiting the interrupt handler.

* Priorities 1, 2, and 3 (Receiver Line Status, Data Available/Timeout, and Transmitter Empty) are all monitored, tracked, and reported through the Line Status Register (LSR) at offset +0x05.
* Priority 4 (Modem Status changes) is monitored, tracked, and reported through the Modem Status Register (MSR) at offset +0x06.

When an interrupt fires, the CPU reads the Interrupt Identification Register (IIR) to find out which of these four priority levels triggered the interrupt, and then goes directly to the appropriate register (LSR or MSR) to read the specific details.

## Critical Driver Implementation Note: Clearing LSR Error Flags
### What actually happens in the hardware?
1. The Error Flags Live in the LSR: When a data corruption error happens (like a parity or framing error), the UART chip stores that warning flag inside the Line Status Register (LSR).
2. Reading LSR Resets It: The moment your code reads the LSR register, the chip assumes you have seen the error and clears (wipes) those error flags back to zero.
3. Reading RBR Does NOT Clear the Error: Reading the Receiver Buffer Register (RBR) only pulls the actual data byte out of the hardware queue. It leaves the LSR error flags alone.

### Why is there a "Driver Warning" then?
The warning is about the order in which you write your code, because developers often make a mistake that hides errors.

If a programmer writes an interrupt handler that processes data haphazardly—or if they read registers out of sequence—they might look at the data buffer before saving a copy of the LSR error flags. Once the error flags in the LSR are wiped or ignored, the software loses its proof of why the data was corrupted.

### The Rule for Writing Code:
* Step 1: Read the LSR first to check for errors and save that status. (This read clears the error flags, which is fine because you just saved them).
* Step 2: Read the RBR next to grab the incoming data bytes.