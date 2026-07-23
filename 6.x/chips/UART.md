# Comprehensive Architecture: From Boot Configuration to Runtime Operation
## 1. Hardware Fundamentals
    
### The Purpose of UART

Universal Asynchronous Receiver-Transmitter (UART) is a hardware peripheral used for serial communication. It translates parallel data from the system bus into serial data (a stream of individual bits) for the transmission line, and vice versa for received data. It is "asynchronous" because it does not use a shared clock signal to synchronize the sender and receiver. Instead, both devices must be pre-configured to the same communication speed, known as the baud rate.

* The Challenge: Without a shared clock, the receiving UART does not know exactly when the transmitting UART will send data, or how fast the bits are traveling.
* The Solution (Baud Rate and Framing):
  * Both UARTs must be manually configured to the same Baud Rate (the speed of transmission, measured in bits per second) before communication begins.
  * The UART wraps every data byte in a strict physical frame:
  * Start Bit: The transmission wire rests at a high voltage state (Logical 1) when idle. To signal the start of a byte, the transmitting UART pulls the wire to a low voltage state (Logical 0) for exactly one bit-period. This wakes up the receiver.
  * Data Bits: The 5 to 8 bits of actual data are sent.
  * Parity Bit (Optional): A primitive error-checking bit.
  * Stop Bit: The wire is driven back to a high voltage state (Logical 1) for one or two bit-periods to signal the end of the frame and reset the line for the next start bit.

## 2. The 8250 UART Chip Architecture
The 8250 UART is a specific, historic silicon chip designed in late 1970s. It became the foundational standard for serial ports in IBM-compatible personal computers. Modern serial hardware still emulates the architecture of the 8250 family.

### Why the 8250 Architecture Matters
Before the 8250, developers had to write unique code for every proprietary serial hardware layout. The 8250 standardized a specific set of internal Hardware Registers (memory locations inside the chip) that the CPU uses to control serial communication.

Key registers established by this architecture include:
* Receiver Buffer / Transmitter Holding Register: The entry and exit points for data bytes.
* Interrupt Enable Register (IER): Allows the chip to request CPU attention when data arrives.
* Interrupt Identification Register (IIR): A register the CPU reads to discover exactly why the chip triggered an interrupt (e.g., "data received" vs. "ready to transmit").
* Line Control Register (LCR): Sets the frame parameters (baud rate, parity, stop bits).

### Evolution to the 16550
The original 8250 had a severe hardware flaw: it could only hold one byte of received data at a time. If the CPU did not read that byte before the next serial byte arriving, the original byte was permanently overwritten (Overrun Error).

To solve this, the 16550 UART was designed. It maintains exact backward compatibility with the 8250 register layout but adds a FIFO (First-In, First-Out) Buffer. The 16550 can hold up to 16 bytes of incoming data in hardware memory, giving the CPU more time to respond.

## 3. Multi-Port Serial Controllers and Interrupt Sharing
A standard computer architecture allocates specific resource channels to communicate with hardware components. One key channel is the Interrupt Request (IRQ) Line, a physical wire that a device uses to scream for the CPU's immediate attention.

### Single-Port Hardware
In a basic configuration, one UART chip controls one physical serial connector (port) on the outside of the machine. This single chip is connected to its own dedicated IRQ line.

### Multi-Port Hardware
A Multi-Port Serial Controller is a single integrated circuit board containing multiple independent UART units (for example, 4 or 8 individual ports on a single PCI card).
```
MULTI-PORT PCI CARD
+-----------------------------------------------+
|  [Port 1 / UART 1] ---\                       |
|                        \                      |
|  [Port 2 / UART 2] ----+--->[COMBINING logic] | =====> SINGLE CPU IRQ LINE
|                        /                      |
|  [Port 3 / UART 3] ---/                       |
+-----------------------------------------------+
```
* The Problem: CPU interrupt lines are physically limited. A computer cannot spare four separate IRQ lines for a single 4-port serial expansion card.
* The Solution (Interrupt Sharing): The multi-port card is physically wired so that all of its internal UART chips share a single, combined IRQ line leading to the CPU.
* The Operational Consequence: When any of the ports receive data, the shared IRQ wire is activated. The CPU knows that the card needs attention, but the hardware wiring cannot specify which exact port received the data. The system software must step in to read the internal registers of each port sequentially to locate the source of the data.

[Shared IRQ](./SharedIRQ.md)

```
[ Physical IRQ Line 4 (irq_desc[4]) ]
│
├──► [ irqaction #1 ] ── (Serial Driver / 8250 Subsystem)
│    │
│    ├──► handler = serial8250_interrupt()
│    │
│    └──► dev_id = &irq_info_struct_A
│                  │
│                  ├── (Inner Loop Walk) ──► [ Port 1 / ttyS0 ]
│                  │                         └── Base IO: 0x3F8
│                  │
│                  └── (Inner Loop Walk) ──► [ Port 2 / ttyS1 ]
│                                            └── Base IO: 0x2F8
│
└──► [ irqaction #2 ] ── (USB Host Controller Driver)
     │
     ├──► handler = usb_hcd_irq()
     │
     └──► dev_id = &usb_hcd_struct_B
                   │
                   └── (Direct Register Read) ──► [ USB Controller 0 ]
                                                  └── MMIO: 0xFE800000
```

## 4. Physical Ports vs. Teletypewriter (TTY) Concepts
It is necessary to decouple the physical hardware connection from the functional role it plays in computing history.

### The Physical Serial Port
This is the tangible hardware interface: the electrical pins, the UART chip, and the copper wires. It simply transmits raw high and low electrical voltages representing binary bits. It has no understanding of what those bits mean. User can connect a modem, a mouse or a printer to these wires.

### The Origin of TTY (Teletypewriter)
Historically, a Teletypewriter (TTY) was a physical, mechanical electromechanical typewriter connected to a communication line. Typing a key sent a serial sequence of signals down the wire; receiving a serial sequence of signals caused the mechanical parts to print letters on physical paper.
```
+------------------+     Serial Cable     +---------------------+
| Terminal (TTY)   |======================| Computer            |
| Keyboard & Paper |  (Raw text stream)   | Processes the text  |
+------------------+                      +---------------------+
```
Early computers did not have video monitors. They used these TTY machines as the sole interface for human interaction. The computer sent text streams out of its UART port, and the TTY printed them.

A TTY device specifically refers to virtual or physical serial interfaces meant for text-based terminal sessions (input/output of ASCII/UTF-8 characters).

### Why the Concept Persists
Even though physical paper teletypewriters are obsolete, the design concept remains. Computers treat any device that handles input characters (typing) and output characters (displaying text) as a TTY interface.
* The UART Hardware: The electronic engine moving bits over a wire.
* The TTY Abstraction: The functional agreement that the data passing through that UART consists of a text-based command stream used to interact with a system.

## 5. Memory-Mapped I/O (MMIO) vs. Port-Mapped I/O (PMIO)

The CPU interacts with the UART hardware via specific control registers. The operating system accesses these registers using one of two architectures depending on the processor type:

* Port-Mapped I/O (PMIO): Common in x86 architectures. Registers are accessed using specialized CPU instructions (such as `in` and `out`) through a separate I/O address space.
* Memory-Mapped I/O (MMIO): Common in ARM and modern x86 systems. The hardware registers are mapped directly into the physical memory address space of the system. The CPU accesses the UART registers using standard memory access instructions (such as pointers in C).

### Essential Hardware Registers
A standard 8250/16550 UART controller exposes a set of 1-byte registers. The primary registers required for operations are:

|Register Name|Abbreviation|Access Type|Purpose|
|-------------|------------|-----------|-------|
|Receive Buffer Register|`UART_RX`|Read-Only|Holds the incoming byte of data extracted from the serial line.|
|Transmit Holding Register|`UART_TX`|Write-Only|Accepts the byte of data that the CPU wants to transmit over the serial line.|
|Interrupt Enable Register|`UART_IER`|Read/Write|Enables or disables specific hardware interrupts (e.g., Data Ready, Transmit Register Empty).|
|Fifo Control Register|`UART_FCR`|Write-Only|Configures the 16-byte internal FIFO buffers and sets the interrupt trigger thresholds.|
|Line Status Register|`UART_LSR`|Read-Only|Provides the status of the data transfer, indicating if data is ready to be read (`UART_LSR_DR`) or if the transmit register is empty (`UART_LSR_THRE`).|
|Line Control Register|`UART_LCR`|Read/Write|"Configures data framing (word length, parity, stop bits) and hosts the DLAB switch (Bit 7) used to swap register mappings."|
|Divisor Latch Low (LSB)|`UART_DLL`|Read/Write|Accessible only when DLAB = 1. Holds the lower 8 bits of the 16-bit divisor value used to calculate the baud rate.|
|Divisor Latch High (MSB)|`UART_DLH`|Read/Write|Accessible only when DLAB = 1. Holds the upper 8 bits of the 16-bit divisor value used to calculate the baud rate.|
|Interrupt Identification Register|`UART_IIR`|Read-Only|Shares an address with UART_FCR. Allows the CPU to read and identify the highest priority pending interrupt when multiple interrupt sources are enabled.|
|Modem Control Register|`UART_MCR`|Read/Write|"Controls external modem interface signals like Data Terminal Ready (DTR) and Request to Send (RTS), and enables the internal diagnostic loopback mode."|
|Modem Status Register|`UART_MSR`|Read-Only|"Provides the real-time status and change-state indicators of the incoming modem control lines, such as Clear to Send (CTS) and Data Set Ready (DSR)."|
|Scratch Register|`UART_SCR`|Read/Write|A temporary 1-byte storage register that has no effect on the UART hardware. It is used purely by the programmer to test if the UART is present and responsive.|

## 6. Boot Configuration and Driver Initialization
Before the operating system can read or write to the UART, the kernel must locate the hardware, map its registers, configure the internal baud rate generators, and register the device with the subsystem.
```
[Firmware / Device Tree] 
       │
       ▼
[Kernel Boot / Setup] ────► Maps Physical Address to Virtual Address
       │
       ▼
[Driver Probe] ───────────► Configures Baud Rate, Word Length, and FIFOs
       │
       ▼
[Subsystem Registration] ─► Creates /dev/ttyS0 in User Space
```

### Step A: Hardware Discovery (Device Tree or ACPI)
During the early boot phase, the Linux kernel determines the physical address and the Interrupt Request (IRQ) number of the UART hardware.
* On x86 architectures, this information is retrieved from the ACPI (Advanced Configuration and Power Interface) tables or standard legacy I/O ports (like `0x3f8` for `ttyS0`).

**Kernel path**:
1. `arch/x86/kernel/acpi/boot.c:static int __init acpi_parse_ioapic(union acpi_subtable_headers * header, const unsigned long end)` and  `arch/x86/kernel/acpi/boot.c:static int __init acpi_parse_madt(struct acpi_table_header *table)`
2. `drivers/tty/serial/8250/8250_pnp.c:static int serial_pnp_probe(struct pnp_dev *dev, const struct pnp_device_id *dev_id)`

### Step B: Address Mapping (ioremap)
The physical address space allocated to the UART is not directly accessible by the kernel because the CPU operates in a virtual memory environment. The kernel calls `ioremap()` to map the physical MMIO address of the UART into the kernel's virtual address space. This returns a virtual pointer (`void __iomem *`) that the driver uses to read and write to the registers.

### Step C: Driver Probing (serial8250_probe)
The kernel matches the detected hardware with the corresponding driver (`drivers/tty/serial/8250/8250_core.c`). The probe function executes the following initialization steps:
1. Line Configuration: Sets the data word length (typically 8 bits), stop bits (typically 1), and parity (typically none) by writing to the Line Control Register (`UART_LCR`).
2. Baud Rate Calculation: Calculates the clock divisor. The UART has an internal crystal clock. To achieve a specific baud rate (e.g., 115200 bits per second), the driver divides the UART clock frequency by the target baud rate and writes this divisor into the Divisor Latch registers.
3. FIFO Allocation: Enables the 16-byte internal FIFO buffers by writing to the UART_FCR and configures the trigger threshold (e.g., fire an interrupt when the receive FIFO contains 8 bytes).

### Step D: TTY Core Registration
The 8250 driver registers the serial port with the Linux TTY (Teletype) core subsystem using `uart_add_one_port()`. This framework exposes the hardware to user space as a character device node, typically located at /dev/ttyS0.

## 7. Runtime Runtime Operation: Data Reception (Read Path)
When data arrives from an external source, it moves from the physical wire to user space application memory via Programmed I/O.

```
[Serial RX Wire]
       │
       ▼
[16-Byte Hardware FIFO] ── (Reaches Threshold / Timeout)
       │
       ▼
[Interrupt Controller] ─── (Fires Hardware IRQ)
       │
       ▼
[CPU: serial8250_interrupt()]
       │
       ├─► Read UART_RX Register ──► Copy to System RAM (TTY Flip Buffer)
       └─► Check UART_LSR ─────────► Repeat if Data Ready (UART_LSR_DR)
```
1. Deserialization: The physical wire transitions electrical voltages representing high (1) and low (0) states. The UART receiver detects the start bit, samples the incoming stream according to the configured baud rate, assembles the bits into a single 8-bit byte, and pushes that byte into the internal 16-byte hardware FIFO.
2. Interrupt Trigger: The hardware FIFO continues to fill. Once the number of bytes hits the pre-configured threshold (or if bytes sit in the FIFO for longer than a specific time period without new data arriving, known as a character timeout), the UART hardware asserts its physical interrupt pin.
3. Kernel Routing: The Local Advanced Programmable Interrupt Controller (LAPIC) detects the interrupt signal on the bus and halts the current CPU execution thread. The kernel references its Interrupt Descriptor Table (IDT), executes `handle_edge_irq()`, and calls the registered handler for the serial line: `serial8250_interrupt()`.
4. The PIO Extraction Loop: The CPU executes the low-level processing function `serial8250_rx_chars()`. The CPU reads the `UART_RX` register using an I/O read operation (`serial_in`). This read operation physically pulls the oldest byte out of the hardware FIFO, clearing room in the hardware chip.
5. Software Buffering: The CPU copies this byte into system RAM, specifically into the TTY subsystem's temporary storage known as the TTY Flip Buffer, using the function `tty_insert_flip_char()`.
6. Loop Evaluation: The CPU reads the Line Status Register (UART_LSR). If the bitmask UART_LSR_DR (Data Ready) evaluates to true, it means more data remains in the hardware FIFO. The CPU loops back to Step 4. The CPU stays inside this loop until the hardware FIFO is completely empty, ensuring low hardware overhead.
7. Push to User Space: Once the interrupt handler finishes, the TTY framework schedules a deferred task (a workqueue or tasklet) called `tty_flip_buffer_push()`. This copies the accumulated data out of the raw TTY flip buffers into the line discipline buffer, where it becomes available for user applications calling the read() system call on `/dev/ttyS0`.

## 8. Runtime Runtime Operation: Data Transmission (Write Path)
When an application transmits data, the process moves in reverse, transforming memory-stored structures back into timed electrical pulses.
```
[User Application] ────► Calls write() System Call
       │
       ▼
[TTY Line Discipline] ──► Copies Data to TTY Write Buffer (System RAM)
       │
       ▼
[8250 Serial Driver] ───► Checks UART_LSR for Empty Transmit Register
       │
       ▼
[CPU: PIO Copy Loop] ───► Writes Byte to UART_TX Register
       │
       ▼
[16-Byte Hardware FIFO] ──► Serializes Data onto TX Wire
```
1. System Call Initialization: A user space application calls the `write()` system call, passing a memory buffer containing the string to be sent (e.g., `"OK\n"`) to the file descriptor corresponding to `/dev/ttyS0`.
2. Subsystem Buffering: The kernel transitions to kernel space. The TTY layer routes the characters through the configured line discipline, which processes special characters if required, and places the data into the TTY transmission buffer located in system RAM.
3. Driver Notification: The TTY core calls the driver's start transmission function (`serial8250_start_tx()`).
4. Status Verification: The CPU reads the Line Status Register (`UART_LSR`) of the UART chip to check if the Transmit Holding Register Empty (`UART_LSR_THRE`) bit is set. If this bit is `1`, the hardware is capable of accepting new data.
5. Programmed I/O Write: The CPU pulls the first character out of the system RAM write buffer and writes it directly to the mapped virtual address of the `UART_TX` register using the `serial_out()` function.
6. Hardware Serialization: The UART hardware takes the byte from `UART_TX`, places it into its transmission shift register, shifts out the start bit, followed by the data bits sequentially, and appends the stop bit onto the physical TX wire.
7. The Transmit Interrupt Loop: As soon as the UART hardware clears the `UART_TX` register by shifting the byte out, it generates a transmission hardware interrupt. The CPU services this interrupt by re-entering the driver, identifying that the source of the interrupt was an empty transmit register, loading the next byte from system RAM into `UART_TX`, and repeating this cycle until the entire software buffer is drained.