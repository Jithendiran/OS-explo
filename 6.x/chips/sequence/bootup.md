# UART Startup and Initialization Phase
At power-on, the UART hardware powers up in an unconfigured, default state. The central processing unit (CPU) must execute a precise initialization sequence to prepare the UART for communication.

```
                      +----------------------------------+
                      |     1. Power-On Reset State      |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |   2. Disable All Interrupts      |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |   3. Set DLAB Bit in LCR         |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      | 4. Write Baud Rate Divisor Latch |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |  5. Configure Line Parameters    |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |   6. Reset and Enable FIFOs      |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |  7. Configure Modem Control      |
                      +----------------+-----------------+
                                       |
                                       v
                      +----------------------------------+
                      |   8. Re-enable Desired Interrupts|
                      +----------------+-----------------+
```

## Detailed Step-by-Step Breakdown
### Step 1: Power-On Reset State
* What it needs to do: The hardware initializes with random or default register states due to the sudden application of electrical power. The baud rate, data format, and interrupt lines are completely uncoordinated.
* Why it exists: Silicon circuits require a defined startup condition. Until software configures the registers, the UART cannot reliably send or receive data.

### Step 2: Disable All Interrupts
* What it needs to do: Software writes a zero value to the Interrupt Enable Register (IER).
* Why it exists: Configuring baud rates and line parameters changes register mappings and clock dividers. If interrupts remain active during this setup process, random hardware states could trigger false interrupts, crashing the CPU interrupt handler before the system is ready.
* Registers: Interrupt Enable Register (IER)
  * Register Offset/Address: Base Address + 1 (when LCR DLAB = 0)
  * Value to Write: 0x00 (hexadecimal) or 00000000 (binary)
  * Bit Details: Setting all bits (0 through 7) to 0 disables every interrupt source (Received Data Available, Transmitter Holding Register Empty, Receiver Line Status, and Modem Status).

### Step 3: Set the DLAB Bit in the Line Control Register (LCR)
* What it needs to do: Software writes a value to set the Divisor Latch Access Bit (DLAB) to 1 inside the Line Control Register (LCR).
* Why it exists: The UART chip has a limited number of physical address lines. To save space inside the chip, the register addresses for the baud rate divisors share the exact same memory addresses as the Receiver Buffer Register (RBR) and Transmitter Holding Register (THR). Setting DLAB to 1 acts as a hardware switch that redirects those register addresses to point to the baud rate configuration registers instead.
* Registers: Line Control Register (LCR)
  * Register Offset/Address: Base Address + 3
  * Value to Write: Retain existing line settings while setting bit 7 to 1 (e.g., 0x80 if configuring fresh).
  * Bit Details: Bit 7 is the Divisor Latch Access Bit (DLAB). Setting Bit 7 = 1 disconnects the RBR/THR data registers and connects the DLL/DLM baud rate registers to the memory map.

### Step 4: Program the Baud Rate Divisor (DLL and DLM)
* What it needs to do: Software writes values into the Divisor Latch Low (DLL) and Divisor Latch High (DLM) registers to define the communication speed (baud rate).
* Why it exists: Asynchronous serial communication requires both connected devices to agree on exact timing intervals for each bit. The divisor takes the system's master clock frequency and scales it down to match the target baud rate (such as 9600 or 115200 bits per second).
* Registers: Divisor Latch Low (DLL), Divisor Latch High (DLM)
  * Register Offsets/Addresses: DLL: Base Address + 0 (when LCR DLAB = 1), DLM: Base Address + 1 (when LCR DLAB = 1)
  * Value to Write: Example for 115200 Baud with a standard 1.8432 MHz crystal: Divisor equals 1.
    * DLL Value: Lower byte of the divisor (e.g., 0x01).
    * DLM Value: Upper byte of the divisor (e.g., 0x00).

### Step 5: Configure Line Parameters and Clear DLAB
* What it needs to do: Software writes a configuration byte to the Line Control Register (LCR) that sets the data bit length (e.g., 8 bits), stop bits (e.g., 1 bit), parity checking options, and explicitly sets DLAB to 0.
* Why it exists: Setting DLAB back to 0 restores the normal register map, allowing the addresses to point back to the data holding registers (RBR/THR). The framing parameters configure the electronic boundaries of every individual character packet transmitted across the wire.
* Registers: Line Control Register (LCR)
  * Register Offset/Address: Base Address + 3
  * Value to Write: 0x03 (for 8 data bits, 1 stop bit, no parity, and DLAB = 0).
  * Bit Details:
    * Bits [1:0] = 11 (Sets 8-bit word length).
    * Bit 2 = 0 (Sets 1 stop bit).
    * Bits [5:3] = 000 (Disables parity).
    * Bit 7 = 0 (Clears DLAB, returning memory map to RBR/THR).

### Step 6: Reset and Enable FIFOs (FCR)
* What it needs to do: Software writes to the FIFO Control Register (FCR) to enable the hardware FIFOs and trigger a reset command that clears out any old garbage data sitting inside the receive and transmit buffers.
* Why it exists: Enabling the FIFO shifts the UART from single-byte mode to multi-byte buffering, preventing data loss during high-speed traffic. Clearing the buffers ensures a clean slate before any real communication begins.
* Register: FIFO Control Register (FCR)
  * Register Offset/Address: Base Address + 2 (Write-only)
  * Value to Write: 0x07 (Hexadecimal) or 00000111 (Binary)
  * Bit Details:
    * Bit 0 = 1 (Enables the FIFOs).
    * Bit 1 = 1 (Clears/resets the Receiver FIFO).
    * Bit 2 = 1 (Clears/resets the Transmitter FIFO).
    * Bits [7:6] = Trigger level configuration (e.g., 00 for 1-byte trigger).

### Step 7: Configure Modem Control Lines (MCR)
* What it needs to do: Software sets bits in the Modem Control Register (MCR) to control physical output lines like Request-to-Send (RTS) and Data Terminal Ready (DTR).
* Why it exists: This prepares the hardware signaling lines to tell external devices that the local system is powered up, initialized, and ready to accept physical connections or data flow.
* Register: Modem Control Register (MCR)
  * Register Offset/Address: Base Address + 4
  * Value to Write: 0x03 (Hexadecimal) or 00000011 (Binary)
  * Bit Details:
    * Bit 0 = 1 (Asserts DTR - Data Terminal Ready). Signals to the remote device that the local system is initialized and present.
    * Bit 1 = 1 (Asserts RTS - Request to Send, indicating readiness to receive data). Signals to the remote device that the local system's receive buffer is empty and ready to accept data.
    * Bit 3 = 1 (Enables OUT2, a required master interrupt gate on standard PC-compatible UART architectures). If left 0 UART's internal circuitry will block all hardware interrupts from reaching the system's interrupt controller (like the PIC or APIC), cpu will never receive serial interrupts (such as data-ready or transmitter-empty alerts).

### Step 8: Re-enable Desired Interrupts (IER)
* What it needs to do: Software writes back to the Interrupt Enable Register (IER) to unmask specific interrupt channels, such as the Received Data Available interrupt.
* Why it exists: With the hardware completely configured, structured, and cleared, the system is now ready to safely listen for incoming data events without risking crashes or invalid data processing.
* Register: Interrupt Enable Register (IER)
  * Register Offset/Address: Base Address + 1 (when LCR DLAB = 0)
  * Value to Write: 0x01 (Hexadecimal) or 00000001 (Binary)
  * Bit Details:
    * Bit 0 = 1 (Enables the Received Data Available Interrupt).
    * Other bits remain 0 unless transmit or line status interrupts are explicitly required by the system design.