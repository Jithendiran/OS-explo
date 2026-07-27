## External Device Architecture and Buffering
An external device (such as a microcontroller, sensor module, or terminal) operates as an independent hardware unit. This device contains its own internal processing components and memory storage.
* Presence of Memory: The external device typically includes a hardware FIFO (First-In, First-Out) buffer or a RAM-based software queue, functioning similarly to a UART receiver FIFO. It does not rely solely on a single present-time data register; it maintains a temporary holding queue to manage incoming signals before processing or transmission.
* Location of the Buffer: The "internal buffer" resides completely inside the external hardware unit, separate from the local receiving system's UART chip.

### The Flow Control Barrier and Data Movement
When a system deasserts a flow control line (such as Request-to-Send - RTS), it establishes an active physical barrier.
* Absence of Transmission: The physical serial wire connecting the two devices carries no electrical data signals during deassertion.
* Isolation from Local UART: Because no signals travel across the wire, the local UART receiver shift register and local UART FIFO remain completely empty of new data. The data does not enter the local UART FIFO because the transmission path is closed.

### Timeline of Buffer Saturation and Data Loss
When flow control is deasserted for an extended duration while an input source continuously supplies data to the external device, a specific sequence occurs:
1. Internal Accumulation: The external device accepts the continuous input data from its local source (such as a sensor or keyboard) and stores those bytes inside its own internal buffer queue, because the paused serial wire prevents transmission to the local system.
2. Buffer Exhaustion: The internal buffer of the external device fills up progressively until it reaches maximum hardware capacity.
3. Data Loss Manifestation: Once the external device buffer is full, any subsequent incoming data causes an overflow.
   * What Data is Lost: The specific bytes lost depend entirely on the internal programming of the external device. The device either discards newly arriving inputs or overwrites older untransmitted data with new entries. 
   * Location of Loss: Data loss occurs exclusively inside the external device. The local system experiences zero data loss because the local system never received the data across the paused serial line.

### External Device Overrun Detection Capabilities
Detection of buffer overflows on the external device side depends entirely on the specific hardware architecture and firmware implementation of that device. It is not universally impossible, but capabilities vary significantly across different hardware types.
* Software Buffer Tracking (Pointer Collision): Many devices use firmware to manage internal RAM buffers through circular queues or FIFO pointers. When continuous input forces the write pointer to catch up to an unread read pointer, the firmware logic detects the collision and records a software-level buffer overflow flag.
* Hardware Status Registers: Advanced microcontrollers and peripheral chips feature dedicated hardware status registers. These registers can assert an internal error flag or trigger an internal exception when a peripheral or memory buffer exhausts its capacity.
* Silent Data Loss in Simple Hardware: Basic or legacy hardware often lacks memory management logic or error-reporting flags. Such devices drop incoming data silently without registering or communicating the error condition.

UART is a blind, asynchronous protocol—it doesn't have a built-in "are you ready?" handshake built into every bit. If the computer's UART receiver is disabled, locked, or its FIFO is full, it simply stops reading the pins. It drops incoming bits or triggers an overrun flag on its end, but it has no mechanism to care about or look back at the external device's internal state. So no way to know if error happened in device side if UART is locked the door for device


## Interrupts, Flow Control, and Overrun Conditions
### 1. Interrupt Masking and Unmasking Mechanics
**Definition and Purpose**
* Masking: The process of disabling specific interrupt notification channels within a configuration register (such as the Interrupt Enable Register - IER) to prevent the UART hardware from alerting the central processing unit (CPU) when particular events occur.
* Unmasking: The process of enabling those notification channels to permit hardware alert signals to reach the CPU.
* Underlying Logic: Software systems require selective control over hardware notifications to manage system workloads efficiently, preventing the processor from processing low-priority events during critical execution phases.

**Operational Timeline and Data Capture State**
When an interrupt channel is masked, the internal physical operation of the UART receiver remains active:
1. Physical Reception: The UART shift register continues to sample incoming electrical voltages from the serial wire and convert serial bit streams into parallel data bytes.
2. FIFO Storage: Converted bytes transfer directly into the hardware Receiver FIFO buffer. Data capture does not stop because masking affects only the output notification line leading to the CPU, not the input shift logic.

**Overrun Trigger Conditions**
If the receive interrupt remains masked, the CPU receives no notifications to read incoming data.
1. Buffer Saturation: The Receiver FIFO accumulates bytes until it reaches its maximum hardware capacity of 16 bytes.
2. Arrival of Subsequent Data: When a seventeenth byte arrives and finishes converting in the shift register, no empty storage slot exists within the FIFO.
3. Data Discard and Error Flagging: The newly arrived byte cannot transfer into memory and is permanently destroyed. The UART hardware immediately asserts the Overrun Error (OE) bit inside the Line Status Register (LSR) to record the data loss.

### 2. Hardware Assert and Deassert Control Signaling
**Definition and Purpose**
* Asserting: Driving a control line or register bit to its active electrical state to signify a condition of readiness, permission, or execution.
* Deasserting: Returning a control line or register bit to its inactive or idle state to signify a pause, prohibition, or termination.
* Underlying Logic: Asynchronous serial communication involves independent clock domains and processing speeds between connected devices. Physical control lines provide a mechanism to coordinate pacing and prevent memory overflows without consuming data communication bandwidth.

**Operational Timeline During Deassertion**
When the local system deasserts a flow control output line (such as Request-to-Send - RTS):
1. Transmitter Response: The external connected device monitors the state change through its input line and halts its own data transmission.
2. External Input Handling: The external device continues to accept inputs from its local users or sensors, but temporarily holds those bytes inside its own internal memory buffer.
3. Local UART State: The local receiving UART hardware remains fully powered and capable of capturing signals if data is forced across the wire, but proper flow control protocols prevent transmission during the deasserted state.
   During this time if device's own internal buffer is filled and UART is not listening subsequent data will be lost and UART don't know that data are lost

### 3. Interrupt Acknowledgment (Ack) Mechanics
Interrupt is the way UART tells cpu that it got data, ack is the way cpu tells the UART that it handled the interrupt

**Definition and Purpose**
* Acknowledgment: An acknowledgment is a mandatory action taken by software to tell a hardware peripheral that the processor has noticed and finished handling an active interrupt request.
* Why it is Necessary: Hardware interrupt signals do not turn off by themselves. They remain active and continuously alert the processor until software directly interacts with the peripheral's registers to clear them.
* Underlying Logic: If software fails to execute this acknowledgment step, the interrupt line stays stuck in the active state. The processor will finish the interrupt service routine, return to normal execution, and immediately get interrupted again by the exact same unresolved signal, trapping the system in an endless, locked execution loop.

#### 16550 UART Acknowledgment Protocol
A 16550 UART does not use a dedicated "clear interrupt" button or register bit. Instead, the hardware clears its interrupt request lines automatically as a direct physical reaction to normal data register operations.

##### Receive Interrupt Acknowledgment
* The Trigger: The UART asserts a receive interrupt to tell the processor that new data bytes are waiting in the Receiver FIFO.
* The Action: Software responds by reading those bytes out of the Receiver Buffer Register (RBR).
* The Acknowledgment Mechanism: The physical act of reading the bytes reduces the amount of waiting data inside the FIFO. Once the FIFO drops below its pre-configured trigger threshold (or becomes completely empty), the UART hardware automatically drops its internal interrupt request line.

##### Transmit Interrupt Acknowledgment
* The Trigger: The UART asserts a transmit interrupt to tell the processor that its Transmitter Holding Register (THR) is empty and ready to accept new data to send.
* The Action: Software responds by writing new data bytes into the Transmitter Holding Register (THR).
* The Acknowledgment Mechanism: The physical act of filling the holding register with new data tells the hardware that the transmission queue is no longer empty, causing the UART hardware to automatically drop the transmit interrupt request line.