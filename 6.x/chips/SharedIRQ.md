# Shared Interrupt Request (IRQ) Line Architecture and Execution Flow

## IRQ Line Sharing
### Definition and Logic
IRQ Sharing is a configuration where multiple, completely different hardware devices register their signaling routines onto the exact same numeric IRQ line.
```
Shared IRQ Line
+--------------------+                   
| Dual UART Channel  | ------------------+
+--------------------+                   |
+--------------------+                   |
| USB Host Controller| ------------------+-------------> [ Interrupt Controller ]
+--------------------+                   |
+--------------------+                   |
| PCI Expansion Card | ------------------+
+--------------------+
```
eg: 2 USB controllet, 2 UART and 1 PCI can single IRQ line

### Why IRQ Sharing Exists
Limited Signal Lines: Historical system architectures had strict limits on available interrupt lines (e.g., 15 lines in legacy x86 PIC setups). As the number of expansion devices grew beyond available lines, hardware sharing became necessary.

```
IRQ 4 Execution Chain:
[ Kernel IRQ 4 Handler ]
          │
          ▼
[ Driver 1: UART 1 ] ──(returns IRQ_NONE if inactive)
          │
          ▼
[ Driver 2: UART 2 ] ──(returns IRQ_HANDLED if active)
          │
          ▼
[ Driver 3: USB 1 ]  ──(returns IRQ_NONE if inactive)
          │
          ▼
[ Driver 4: USB 2 ]  ──(returns IRQ_NONE if inactive)
          │
          ▼
[ Driver 5: PCI Card]──(returns IRQ_NONE if inactive)
```

When IRQ is shared device type might also registered to different irq-pin, will be using same device driver 
when pin-4's PCIe fired, CPU should not check Pin-5's PCIe hardware registers, to differentiate this when registering IRQ each has to register with device ID 

```
Hardware Pins              Interrupt Controller              CPU

Pin-4 (PCIe, USB, UART) ──► [ Line 4 / Vector A ] ──┐
                                                    ├──► Interrupt Vector Fire!
Pin-5 (PCIe, USB, UART) ──► [ Line 5 / Vector B ] ──┘

```
To manage multiple devices of the same type (using the exact same driver) on the same IRQ line, the operating system kernel uses a combination of Action Chains (Linked Lists) and Private Device Structures.

```
RQ 4 Line Descriptor (irq_desc[4])
       │
       ▼  Linked List of irqaction Structures
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ irqaction #1      │────►│ irqaction #2      │────►│ irqaction #3      │────►│ irqaction #4     │────►│ irqaction #5     │
├───────────────────┤     ├───────────────────┤     ├───────────────────┤     ├──────────────────┤     ├──────────────────┤
│ handler = uart_isr|     │ handler = pcie_isr|     │ handler = uart_isr|     │ handler = usb_isr|     │ handler = usb_isr│
│ dev_id  = &uart0  │     │ dev_id  = &pcie0  │     │ dev_id  = &uart1  │     │ dev_id  = &usb0  │     │ dev_id  = &usb1  │
└───────────────────┘     └───────────────────┘     └───────────────────┘     └──────────────────┘     └──────────────────┘
  (UART 0 Instance)             (PCIe Card)             (UART 1 Instance)       (USB Controller 0)      (USB Controller 1)
```

## Execution Flow and Signaling Mechanics
### Step-by-Step ISR Chain Execution
When a shared IRQ line fires, the kernel executes the following loop:
```
[ IRQ-4 Triggered ]
       │
       ▼
[ Fetch ISR-4 Handler List ]
       │
       ▼
[ Select First Handler in List ] <──────────────────────┐
       │                                                │
       ▼                                                │
[ Driver Checks Device Hardware Register ]              │
       │                                                │
       ├─── No Data Active ──> [ Return IRQ_NONE ] ─────┤
       │                                                │
       └─── Data Active ─────> [ Process Data ]         │
                                       │                │
                                       ▼                │
                               [ Clear Device Flag ]    │
                                       │                │
                                       ▼                │
                               [ Return IRQ_HANDLED ] ──┘
                                       │
                                       ▼ (Loop continues for all handlers)
                               [ Signal End Of Interrupt (EOI) ]
```
1. CPU Interrupt Pause: The CPU suspends standard instruction execution and calls the kernel function mapped to the triggered IRQ number.
2. List Retrieval: The kernel retrieves the chain of registered ISRs for that IRQ.
3. Sequential Polling: The kernel sequentially calls each driver's ISR in the order they were registered.
4. Hardware Status Verification: Each driver reads its specific device's internal status register over the bus (only device registered for this pin).
   1. If the hardware flag indicates no pending work, the driver immediately exits and returns IRQ_NONE.
   2. If the hardware flag indicates pending work, the driver clears the hardware (interrupt) flag, handles the data buffer, and returns IRQ_HANDLED.
5. Chain Completion: The kernel proceeds through every driver in the chain to ensure all devices that raised an interrupt during that cycle are checked.
6. End of Interrupt (EOI): The kernel notifies the Interrupt Controller that processing for the cycle is complete.

```
[ IRQ Triggered ]
       │
       ▼
Driver 1: Checked ──> Returns IRQ_NONE
Driver 2: Checked ──> Clears Dev 2 hardware flag, handles data, returns IRQ_HANDLED
Driver 3: Checked ──> Returns IRQ_NONE
Driver 4: Checked ──> Clears Dev 4 hardware flag, handles data, returns IRQ_HANDLED
Driver 5: Checked ──> Returns IRQ_NONE
       │
       ▼
 Both devices cleared ──> Physical line goes HIGH (Inactive)
       │
       ▼
 [ Signal EOI ] ──> Done! (Total passes: 1)
```

### A device fires DURING the loop
Now imagine a race condition where a device fires after its driver was already checked:
1. Pass 1 starts: The kernel calls Driver 1. Device 1 has no data, so Driver 1 returns IRQ_NONE.
2. Race Condition: While the kernel is currently executing Driver 3, Device 1 suddenly receives new data and pulls the IRQ line low.
3. Pass 1 completes: The kernel finishes checking Driver 4 and Driver 5, then signals End Of Interrupt (EOI) to the Interrupt Controller.
4. Hardware Re-trigger: Because Device 1 is still holding the level-triggered line low, the physical line is still active. The Interrupt Controller sees this immediately and fires a brand-new hardware interrupt to the CPU.
5. Pass 2 starts: The kernel starts the loop from the beginning again. Driver 1 is called, sees the new data, handles it, and clears the hardware line.

Writing an EOI does not force the interrupt line to turn off. EOI simply tells the controller's internal logic to drop the current priority level and re-check the physical wire. If the wire is still pulled low ($0\text{V}$), the controller simply sets the interrupt back to PENDING and alerts the CPU again immediately.

## Signal Prevention Mechanism: Level-Triggered Interrupts vs. Edge-Triggered Interrupts

A critical hardware requirement for IRQ sharing is the signaling method used on the physical trace line.


### Edge-Triggered Interrupts (Legacy)

```
Clock Line (CLK):      ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
                      ─┘ └─┴─┘ └─┴─┘ └─┴─┘ └─┴─┘ └─┴─┘─┘ └─     
                                EDGE!
                                  │
Edge IRQ Line:        ────────────┐                       
 (Rising-Edge)                    └───────────────────────
                                  ▲
                         The trigger event happens 
                         ONLY on this 0V -> 5V jump.
```
* Mechanism: Fires an interrupt signal only at the moment the electrical signal changes state (e.g., transitioning from Low voltage to High voltage/high to low).
* Limitation: If Device A holds the line low, and Device B receives data while the line is already low, no new edge transition occurs. Device B's interrupt is completely missed.
* Result: Incompatible with IRQ sharing.

### Level-Triggered Interrupts (Modern PCI Standard)

An interrupt line is completely separate from the system clock line.

It does not reset or drop when the clock changes state. The hardware device actively drives the physical voltage on the interrupt line independent of clock cycles, keeping it held until the driver explicitly clears the status register.

```
Clock Line (CLK):      ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
                      ─┘ └─┴─┘ └─┴─┘ └─┴─┘ └─┴─┘ └─┴─┴─┘ └─
                       
Level IRQ Line:       ─────────┐                       ┌────
 (Active Low)                  └───────────────────────┘
                                <--- Stays LOW across --->
                                     thousands of clock
                                           cycles
```

* Mechanism: The interrupt signal remains active (e.g., pulled to continuous Low voltage) as long as at least one hardware device has uncleared data in its status register.
* Resolution of Race Conditions:
  * Assume the kernel checks Device 1 (no data) and moves to Device 2 (data present).
  * While Device 2 is being handled, Device 1 receives new data and activates its interrupt line.
  * The kernel finishes checking Device 2, Device 3, and Device 4, then signals End-Of-Interrupt (EOI).
  * Because Device 1 is actively pulling the level-triggered line low, the Interrupt Controller immediately detects that the line is still active.
  * The Interrupt Controller instantly triggers a new IRQ execution cycle, causing the kernel to restart the loop from Device 1.
* Result: No data is lost, regardless of when devices receive data during an execution loop.