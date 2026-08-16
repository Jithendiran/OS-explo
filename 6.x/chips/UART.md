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
  
### Functionality of UART
* Baud Rate Configuration:
  * Requires setting the internal communication speed so both sender and receiver agree on how fast individual bits travel.
* Interrupt Enable and Disable Control:
  * Allows software to turn individual hardware notification signals on or off depending on the needs of the operating system.
* Interrupt Events:
  * Data Arrival: Notifies the system when new incoming bytes are sitting in the receive buffer ready to be read.
  * Transmission Completed: Notifies the system when the transmitter holding register or FIFO is empty and ready to accept the next outgoing byte.
  * Hardware Errors:
    * Overrun Error: Occurs when new data arrives faster than the system can read the old data, resulting in a lost byte.
    * Parity Error: Occurs when the calculated parity bit does not match the data received, indicating corruption in transit.
    * Framing Error: Occurs when the expected stop bit is missing, which typically happens when the sender and receiver are configured to different baud rates.
    * Break Interrupt: Occurs when the transmission line is held continuously in a low voltage state for longer than the transmission time of a single frame.
  * Character Timeout (FIFO): 
    * Behavior: When the receiver FIFO reaches the pre-configured trigger level (set by bits 5–4 of the FCR), the UART asserts a Received Data Available interrupt.
    * Character Timeout Exception: If bytes accumulate in the receive FIFO below the trigger threshold, but no new data arrives for a duration equivalent to the time it takes to transmit four character frames, the UART triggers a Character Timeout Interrupt. This ensures that lingering bytes are processed by the CPU without waiting indefinitely for the buffer to fill.
* Selective CPU Interruption:
  * Restricts hardware interrupt signals only to specifically permitted events, preventing the processor from being overwhelmed by unneeded alerts.
* External Device Flow Control:
  * Manages hardware handshake lines to coordinate communication pacing between the local system (computer) and connected external equipment (Printer, mice,..), preventing buffer overflows.

## 2. The 8250 UART Chip Architecture
The 8250 UART is a specific, historic silicon chip designed in late 1970s. It became the foundational standard for serial ports in IBM-compatible personal computers. Modern serial hardware still emulates the architecture of the 8250 family.

```
+---------+                              +----------+
|         |  serial +--------+  parallel |          |
| Printer,| <-----> |  UART  | <=======> | Computer |
| mice,.. |         +--------+           |   (CPU)  |
+---------+                              +----------+
```

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

## Flow Control 

### Problem
Two connected devices rarely process data at identical speeds. A fast transmitting device can easily overwhelm a slower receiving device, filling up its internal buffer and causing incoming data bytes to be permanently lost.

### The Purpose of Flow Control:
Flow control is a hardware or software mechanism that allows the receiving device to temporarily pause the transmitting device when the receiver's buffer is getting full, and resume transmission once it has caught up.

### Hardware Flow Control (RTS/CTS Handshaking):
The 8250/16550 architecture uses dedicated physical wires and control registers to manage communication pacing without consuming data bandwidth.
* Request-to-Send (RTS):
  * An output signal controlled by the local system via the Modem Control Register (MCR).
  * The local system sets this line to tell the external device that the local system is ready to receive data. If the local buffer fills up, the software drops the RTS signal to tell the external device to stop sending.
* Clear-to-Send (CTS):
  * An input signal monitored by the local system via the Modem Status Register (MSR).
  * The external device uses this line to tell the local system whether it is safe to transmit data. If the external device drops the CTS line, the local system pauses its own transmission until the line goes high again.

## Baud Rate calculation
$$\text{Baud Rate} = \frac{\text{Input Clock Frequency}}{16 \times \text{Divisor}}$$
* Input Clock Frequency: The baseline frequency of the crystal oscillator connected to the UART chip (commonly $1.8432\text{ MHz}$ in classic systems, or other standard frequencies depending on the hardware architecture).
* $16$: The standard oversampling factor used by UART receivers to safely sample incoming bits near their center.
* Divisor: The combined 16-bit value formed by concatenating the Divisor Latch High (DLM) and Divisor Latch Low (DLL) registers.  

### Example Calculation
If your UART has an input clock of $1.8432\text{ MHz}$ ($1,843,200\text{ Hz}$) and you want a target baud rate of $115,200$:

$$\text{Divisor} = \frac{1,843,200}{16 \times 115,200} = \frac{1,843,200}{1,843,200} = 1$$
You would split the 16-bit integer 1 into the two registers:
* Divisor Latch Low (DLL at offset +0, DLAB=1): `0x01`
* Divisor Latch High (DLM at offset +1, DLAB=1): `0x00`

The local computer's software configuration, the local UART hardware divisor, and the external connected device must all be configured to the exact same baud rate (such as 115,200).

## [Registers](./UART-Registers.md)

## [Sequence](./sequence/README.md)

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

## 5. Line Disciplines and Device Identification Architecture
### The Function of Line Disciplines
A line discipline is an intermediate software layer inside the operating system kernel. It sits directly between the low-level UART hardware driver and the high-level user applications.
* The Reason for Existence: Raw hardware UART drivers only move individual bytes of data back and forth across a physical copper wire. They do not know whether those bytes represent letters typed on a keyboard, packets of internet data, or coordinates from a pointing device. The line discipline interprets the raw byte stream and applies specific processing rules.
* Dynamic Inter-changeability: Multiple software modules exist within the kernel to handle different data formats. The operating system can swap these software modules dynamically on the same physical UART port depending on what type of external equipment is attached.

### Available Line Discipline Types
The operating system kernel includes several standard line discipline modules, each designed for a specific class of data transmission:
* n_tty (Standard Terminal Discipline):
       Function: Processes the byte stream as interactive text. It manages input buffering, line editing (such as processing the backspace key), character echoing back to a display, and special control character interpretation (such as translating specific key combinations into system process signals).
* n_ppp (Point-to-Point Protocol Discipline):
       Function: Packages raw serial bytes directly into network packets. It allows standard internet protocol traffic (such as TCP/IP) to travel across a serial communication link.
* n_mouse (Legacy Mouse Discipline):
       Function: Intercepts historical serial data streams sent by older external pointing devices and translates those raw bytes into standard graphical mouse movement and click events.
### Method of Identifying Attached External Devices
Raw UART hardware ports lack any plug-and-play electronic signaling protocol. An operating system cannot automatically detect whether a terminal, a modem, a network bridge, or a mouse is attached to the physical pins.

Device identification and line discipline selection occur through external configuration rather than automatic hardware discovery:
1. Manual System Configuration:
       * System administrators or initialization scripts explicitly inform the operating system kernel regarding what equipment is wired to a specific serial port.
2. User-Space Attachment Utilities:
       * System software uses specific control utilities (such as the `ldattach` program) to open a serial device file (such as `/dev/ttyS0`) - `ldattach slip /dev/ttyS0` and issue a kernel control command (`ioctl`).
       * This command forces the kernel to detach the default text terminal module (`n_tty`) and attach the required alternative module (such as `n_ppp` or `n_slip`).
3. Automated Daemons:
       * Background networking or communication services automate this process during system startup or connection requests, configuring the correct line discipline without requiring manual intervention for established configurations.

## 6. Memory-Mapped I/O (MMIO) vs. Port-Mapped I/O (PMIO)

The CPU interacts with the UART hardware via specific control registers. The operating system accesses these registers using one of two architectures depending on the processor type:

* Port-Mapped I/O (PMIO): Common in x86 architectures. Registers are accessed using specialized CPU instructions (such as `in` and `out`) through a separate I/O address space.
* Memory-Mapped I/O (MMIO): Common in ARM and modern x86 systems. The hardware registers are mapped directly into the physical memory address space of the system. The CPU accesses the UART registers using standard memory access instructions (such as pointers in C).

## 7. Boot Configuration and Driver Initialization
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
