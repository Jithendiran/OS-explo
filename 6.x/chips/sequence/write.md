# UART Data Write (Transmission) Flow
```
                      +----------------------------------+
                      |   1. Local System Checks Status  |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |   2. Check Flow Control (MSR CTS)|  (optional for ftable device)
                      +----------------+-----------------+
                                       |
                                       v                                       
                      +----------------------------------+
                      |    3. Write Data to THR/FIFO     |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |  4. Transfer to Shift Register   |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |  5. Serialization & Generation   |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |  6. Physical Line Transmission   |
                      +----------------+-----------------+
```

## Detailed Step-by-Step Breakdown
### Step 1: Local System Checks Transmitter Status
* What it needs to do: The central processing unit (CPU) or Direct Memory Access (DMA) controller reads the Line Status Register (LSR) to verify if the UART hardware is ready to accept new transmission data.
* Why it exists: Writing data into the transmit buffer when it is already full causes data overwriting and corruption. Checking the status register prevents buffer overflows.
* Registers: Line Status Register (LSR)
  * Register Offset/Address: Base Address + 5
  * Value to Check: Bit 5 (Transmitter Holding Register Empty - THRE) or Bit 6 (Transmitter Empty - TEMT).
  * Bit Details:
    * Bit 5 = 1 indicates that the Transmitter Holding Register (THR) or FIFO is empty and ready for the next data byte.
    * Bit 6 = 1 indicates that both the holding register and the internal shift register have completed transmission and the physical wire is completely idle.

### Step 2: Check Flow Control Status (MSR CTS)
* What it needs to do: Before proceeding with the write operation, the local system reads the Modem Status Register (MSR) to verify the state of the Clear to Send (CTS) input line from the remote receiving device.
* Why it exists: Even if the local UART transmit buffer is empty, the remote device's receive buffer might be full. Checking CTS ensures that data is only sent when the remote receiver is ready, preventing data loss across the physical wire.
* Registers: Modem Status Register (MSR)
  * Register Offset/Address: Base Address + 6
  * Value to Check: Bit 4 (Clear to Send - CTS).
  * Bit Details: Bit 4 = 1 indicates that CTS is asserted (active low/high depending on transceiver configuration, meaning remote device is ready). Bit 4 = 0 indicates that CTS is deasserted, requiring the local system to pause the write sequence until the remote device clears its buffers.
(If data is written to external device without checking the flow control and external device is already busy in writing it's buffer is full, newly written data might lost or corrupt the existing data)
  
### Step 3: Write Data to the Transmitter Holding Register (THR) or FIFO
* What it needs to do: The local system writes an 8-bit data byte directly into the Transmitter Holding Register (THR) memory address.
* Why it exists: This provides the bridge for data to move from the local system data bus into the UART peripheral hardware storage.
* Registers: Transmitter Holding Register (THR)
  * Register Offset/Address: Base Address + 0 (when LCR DLAB = 0)
  * Value to Write: The raw data byte (e.g., an ASCII character code like 0x41 for 'A').
  * Bit Details: Bits [7:0] hold the parallel data byte awaiting internal hardware movement. Writing to this address clears the THRE status flag in the LSR until the byte moves into the internal shift stage.

### Step 4: Transfer from Holding Register to Shift Register
* What it needs to do: The internal UART hardware automatically copies the data byte from the THR or transmit FIFO into the Transmit Shift Register (TSR).
* Why it exists: The holding register only stores parallel data temporarily. The shift register is specialized hardware that can physically shift bits out one by one. This hardware handoff frees the holding register to accept the next byte from the local system while the current byte is still being sent.
* Mechanism: Triggered automatically by internal hardware logic as soon as the TSR becomes idle and a new byte is present in the THR/FIFO.
* Error Handling Context: If the local system attempts to force data into the transmit path while the hardware is faulted or uninitialized, or if transmission line parameters conflict, status flags in the LSR are monitored to ensure the shift register clears properly without stalling.
  * Standard UART architectures do not possess dedicated hardware "error flags" for transmission in the way they do for reception.

### Step 5: Serialization and Packet Framing
* What it needs to do: The Transmit Shift Register breaks the parallel 8-bit byte down into individual sequential bits and wraps them inside an asynchronous communication packet frame.
* Why it exists: Serial communication lines require a strict temporal structure so the remote receiver can distinguish where individual characters begin and end.  
* Packet Construction Sequence:
  1. Start Bit: The internal logic forces the output transmission line (TX) from a logical high state to a logical low state for exactly one clock cycle defined by the baud rate.  
  2. Data Bits: The shift register outputs each data bit sequentially, starting strictly with the Least Significant Bit (LSB, Bit 0) up to the Most Significant Bit (MSB, Bit 7).
  3. Parity Bit (Optional): If enabled during initialization, the hardware calculates an even or odd parity bit based on the total number of high bits in the data frame and appends it.  
  4. Stop Bit(s): The hardware pulls the line back to a logical high state for one or two bit-durations to mark the conclusion of the packet frame.

### Step 6: Physical Line Transmission
* What it needs to do: The serialized electrical voltage transitions generated by the shift register pass through an external line driver (such as an RS-232, RS-485, or TTL transceiver) and travel across the physical wire to the remote device.  
* Why it exists: Internal microcontroller logic voltages cannot travel long distances or withstand electrical noise without proper physical layer conversion. The line driver adapts the digital pulses into robust electrical signals for the destination hardware.


## Transmit Event Breakdown: Scenarios, Resolutions, and Consequences
During the transition from the THR to the Transmit Shift Register (TSR), several failure states can occur.
### Event A: Transmit Buffer Overwrite (Software Overrun)
* What Happens: The local system writes a new byte to the THR while the previous byte is still waiting to be transferred to the TSR.
* Flag Monitored: Line Status Register (LSR) Bit 5: Transmitter Holding Register Empty (THRE).
* Resolution: The software must continuously poll the LSR or rely on a Transmit Interrupt to confirm THRE = 1 before pushing the next byte to the THR address.
* Consequence if Unresolved: The previous data byte is permanently destroyed before it ever reaches the physical wire. The remote device will receive a corrupted packet stream missing sequential bytes, leading to application-level protocol failures.

### Event B: Hardware Flow Control Stall (CTS Timeout)
* What Happens: The local system has a byte ready in the THR, but the internal hardware logic refuses to move it to the Shift Register because the remote device has deasserted the Clear to Send (CTS) line.
* Flag Monitored: Modem Status Register (MSR) Bit 4: Clear to Send (CTS).
* Resolution: The local system must implement a software-based timeout timer. If the CTS line remains low (deasserted) for a duration exceeding the expected timeout limit, the software must abort the transmission loop, flush the transmit buffers, and alert the application layer of a connection failure.
* Consequence if Unresolved: If the remote device crashes, powers off, or the physical cable is severed, the CTS line will never assert. Without a software timeout, the local CPU will enter an infinite polling loop waiting for CTS to go high, causing the local system thread to hang indefinitely.

### Event C: Shift Register Stall (Premature Line Disconnect)
* What Happens: The local system writes the final data byte of a message to the THR. The byte moves to the Shift Register, and THRE becomes 1. Assuming the transmission is finished, the local system immediately disables the UART hardware or alters the baud rate divisors.
* Flag Monitored: Line Status Register (LSR) Bit 6: Transmitter Empty (TEMT).
  * `THRE` only means the holding register is empty.
  * `TEMT` means both the holding register and the Shift Register are completely empty, and the physical line is idle.
* Resolution: When finishing a transmission sequence (especially before power-down or changing line directions in half-duplex RS-485 systems), the software must wait for TEMT = 1 rather than just THRE = 1.
* Consequence if Unresolved: Disabling the UART or changing clocks while the Shift Register is still pushing bits onto the wire will instantly sever the electrical pulse generation. The final byte will be truncated mid-transmission, causing a Framing Error on the remote receiver's side.