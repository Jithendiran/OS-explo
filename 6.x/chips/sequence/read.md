# THE COMPLETE RECEPTION EVENT CYCLE
 
After initialization completes, the system enters the idle state. The following sequence describes every event that occurs from data arrival through ISR exit.

## Phase A: Idle State
 
**Hardware State:**
- The UART's RX line is monitored continuously by the shift register logic. The line sits at a high voltage state (Logic 1), the idle mark state. No data is arriving.
- The Receive FIFO contains zero bytes.
- MCR.DTR (Bit 0) = 1, MCR.RTS (Bit 1) = 1. Both handshake output lines are asserted.
- IER Bit 0 = 1. The received-data interrupt source is enabled.
- MCR.Out2 (Bit 3) = 1. Interrupt routing to the PIC is active.
- The CPU is executing other tasks.
**What "asserted RTS in idle" means:** The remote device monitors the local system's RTS line. Seeing RTS asserted, the remote device knows the local system is ready to receive. The remote device may begin transmitting at any time.

## Phase B: Serial Data Arrival and FIFO Accumulation
 
**B-1: Start Bit Detection**
 
The remote device pulls the serial TX wire from high (idle mark) to low (space) for exactly one bit period. This low pulse is the **Start Bit**. The local UART's shift register logic detects this falling edge and begins sampling the incoming bit stream.
 
**B-2: Bit Sampling and Assembly**
 
The UART samples each incoming bit 16 times (using the clock divisor configured in Steps I-2 through I-4) and determines the stable bit value near the center of each bit period. After all data bits, the optional parity bit, and the stop bit are received, the shift register holds one complete parallel byte.
 
**B-3: Transfer to Receive FIFO**
 
The assembled parallel byte is transferred from the shift register into the next available slot in the Receive FIFO. The byte is now stored in hardware memory. The shift register is immediately available to begin capturing the next incoming byte.
 
**B-4: FIFO Occupancy Check**
 
After each byte is deposited into the FIFO, the hardware checks whether the number of bytes now in the FIFO meets or exceeds the configured trigger level (set in FCR Bits 7-6 during initialization).
 
- **If FIFO count < trigger level AND the 4-character timeout has not elapsed:** No interrupt is generated yet. The UART continues waiting for more data.
- **If FIFO count ≥ trigger level:** The UART immediately asserts the interrupt signal. This is the **Received Data Available** interrupt.
- **If FIFO count < trigger level AND no new byte arrives for 4 character-frame periods:** The UART asserts the interrupt signal. This is the **Character Timeout** interrupt.
Both the Received Data Available interrupt and the Character Timeout interrupt use the same ISR entry path. The distinction is visible in the IIR register when the ISR reads it.

## Phase C: CPU Interrupt Handling Entry
 
**C-1: PIC Signals the CPU**
 
The UART's interrupt output line (routed to the PIC via MCR.Out2) causes the PIC to assert the CPU's INT pin.
 
**C-2: CPU Finishes Current Instruction**
 
The CPU completes the machine instruction currently in execution before responding to the interrupt. Interrupts are not handled mid-instruction.
 
**C-3: CPU Automatically Saves Context**
 
The CPU hardware automatically pushes the following onto the system stack in RAM:
- **FLAGS register** (including the current state of the Interrupt Flag, IF)
- **Code Segment register (CS)**
- **Instruction Pointer (IP/EIP/RIP)** — the address of the next instruction that would have executed if the interrupt had not occurred
This saved state is called the **interrupt context**. It allows the CPU to resume normal execution exactly where it was interrupted, after the ISR completes.
 
**C-4: CPU Clears the Interrupt Flag (IF)**
 
As part of the automatic interrupt entry mechanism, the CPU clears IF in the FLAGS register. This disables further hardware interrupt signals at the CPU level while the ISR is running.
 
**Why IF is cleared automatically:** A second interrupt arriving during ISR execution could cause the ISR to be interrupted itself (re-entrance). Re-entrant interrupt handling requires complex synchronization and is generally avoided in simple UART drivers. Clearing IF prevents this.
 
**Note on re-enabling IF during ISR:** In some advanced driver designs, the programmer explicitly re-enables IF at a certain point inside the ISR (using STI on x86) to allow other, higher-priority system interrupts to be handled while the UART ISR runs. This is a design choice, not a requirement.
 
**C-5: CPU Jumps to ISR**
 
The CPU uses the interrupt vector (IRQ4 for COM1) to look up the ISR address registered in Step I-8, and jumps to that address.

## Phase D: ISR Entry — IIR Read and Dispatch
 
This phase is the **most critical step missing from the original flow.** An ISR must always begin by identifying the cause of the interrupt before taking action.
 
### D-1: Read the Interrupt Identification Register (IIR)
 
**Register:** IIR at offset +2 (read-only)
 
The ISR's first action is to read the IIR. This register encodes the highest-priority pending interrupt source in Bits 3-0.
 
**Bit 0 — Interrupt Pending Flag:**
- Value `0`: An interrupt is pending and needs servicing.
- Value `1`: No interrupt is pending. All events have been serviced.
**Bits 3-1 — Interrupt Source Code:**
 
| Bits 3-1 | Source | Priority | Service Action |
|-----------|--------|----------|----------------|
| `011` | Receiver Line Status Error | 1 (Highest) | Read LSR, handle error, read RBR |
| `010` | Received Data Available | 2 | Drain FIFO (read LSR then RBR until DR=0) |
| `110` | Character Timeout | 2 | Drain FIFO (same as above) |
| `001` | Transmitter Holding Register Empty | 3 | Write next byte to THR |
| `000` | Modem Status Change | 4 (Lowest) | Read MSR to clear delta bits |
 
**Bits 7-6 — FIFO Status:**
- `11`: FIFOs are enabled (normal 16550 operation).
- `00`: FIFOs are disabled (8250-compatible mode).
### D-2: The IIR Service Loop
 
The ISR does not read IIR once and exit. The ISR executes a **service loop** that continues until all pending interrupt sources are cleared.
 
**Loop structure:**
```
LOOP START:
  Read IIR
  If IIR Bit 0 = 1 → No more pending interrupts → EXIT LOOP → proceed to Phase G
  Decode Bits 3-1 to identify source:
    Case: Line Status Error  → execute Phase E
    Case: Data Available     → execute Phase F
    Case: Character Timeout  → execute Phase F (identical handling)
    Case: Transmitter Empty  → execute transmit handler (separate, not covered here)
    Case: Modem Status       → execute Phase H
  Return to LOOP START
```
 
**Why the loop is mandatory:** Multiple interrupt events can occur and queue up before the ISR executes. The UART hardware records all pending events simultaneously. After servicing one event, the hardware may still have another event pending. If the ISR exits after servicing only one event, the remaining pending interrupt will immediately re-fire the ISR upon exit, causing redundant ISR entry. The correct approach is to drain all pending events in a single ISR invocation.
 
**Why IIR reports only the highest-priority source per read:** The UART hardware uses a priority encoder. If multiple events are pending simultaneously, IIR reports the highest-priority one. After that event is serviced (and its registers are read), IIR automatically reflects the next pending event. This is why re-reading IIR at the top of each loop iteration is required.

## Phase E: Line Status Error Handler
 
This phase executes when IIR Bits 3-1 = `011` (Receiver Line Status Error, highest priority).
 
### E-1: Read LSR First — Mandatory Rule
 
**Register:** LSR (Line Status Register) at offset +5 (read-only)
 
The ISR reads LSR immediately and stores the result in a local software variable before reading any data.
 
**Critical Rule:** LSR must always be read before RBR. The act of reading LSR clears (resets to 0) the error flag bits. If RBR were read first, the error information would still be in LSR, but the ordering discipline matters for code correctness: the saved LSR value is the proof that an error occurred for the byte about to be retrieved.
 
**LSR Bit-by-Bit:**
 
| Bit | Name | Meaning When Set to 1 |
|-----|------|----------------------|
| 0 | DR (Data Ready) | At least one byte is in the Receive FIFO waiting to be read |
| 1 | OE (Overrun Error) | A byte was destroyed because the FIFO was full when it arrived |
| 2 | PE (Parity Error) | The received byte's parity did not match the expected parity |
| 3 | FE (Framing Error) | The expected stop bit was absent |
| 4 | BI (Break Interrupt) | The RX line was held low for more than one full character frame duration |
| 5 | THRE (Transmitter Empty) | THR is empty and ready for outgoing data |
| 6 | TEMT (Transmitter Shift Empty) | Both THR and the transmitter shift register are empty |
| 7 | RXFE (Receiver FIFO Error) | At least one byte currently in the FIFO has an error flag attached |
 
### E-2: Evaluate Error Flags
 
The saved LSR value is checked bit by bit. More than one error bit can be set simultaneously.
 
**Bit 1 — Overrun Error (OE):**
- **Meaning:** A byte was permanently destroyed at the UART hardware level. The FIFO was at 16-byte capacity and a new byte arrived before the CPU read any bytes out.
- **Root cause:** The CPU failed to service the FIFO fast enough, or MCR.RTS was not deasserted in time to stop the remote device.
- **Response:** Log the overrun event in the driver's error counter. Immediately deassert MCR.RTS (write Bit 1 = 0 to MCR at offset +4) to command the remote device to stop sending. The previously valid bytes in the FIFO are preserved; only the overflowing byte was lost.
**Bit 2 — Parity Error (PE):**
- **Meaning:** The number of logic-1 bits in the received byte did not match the expected parity (even or odd, as configured in LCR).
- **Root cause:** Electrical noise on the physical wire flipped one or more bits during transmission.
- **Response:** The byte must still be read from RBR to remove it from the FIFO. Depending on the protocol: either discard the byte, or pass it to the upper application layer with an error flag attached so the application can request retransmission.
**Bit 3 — Framing Error (FE):**
- **Meaning:** The stop bit position contained a 0 (space) instead of a 1 (mark).
- **Root cause:** Severe line noise, a disconnected wire, or a baud rate mismatch between the two devices.
- **Response:** Read the byte from RBR to remove it from the FIFO and discard it. If framing errors occur repeatedly, set a driver-level flag reporting a probable physical line failure or baud rate misconfiguration.
**Bit 4 — Break Interrupt (BI):**
- **Meaning:** The RX line was held at logic 0 continuously for longer than a full character frame duration.
- **Root cause:** The remote device deliberately sent a break signal (used as a special control condition in some protocols), or a cable physically disconnected.
- **Response:** Read and discard the zero byte from RBR. Report the break condition to the upper application layer.
**Bit 7 — Receiver FIFO Error (RXFE):**
- **Meaning:** At least one byte currently inside the FIFO has a parity error, framing error, or break condition attached to it. This is a summary indicator.
- **Important property:** Bit 7 does not identify which byte in the FIFO is corrupted. The error flags are attached to individual bytes, not to the FIFO as a whole.
- **How error flags advance:** When the CPU reads RBR, the UART hardware removes the oldest byte and simultaneously advances the error status for the next byte to the LSR-visible position. Therefore, the only way to find out which byte has an error is to read LSR and RBR alternately in a loop, checking error bits after each RBR read, until the FIFO is empty (LSR Bit 0 = 0).
**Example:** A FIFO contains 12 bytes. The 6th byte has a parity error.
- Reading RBR 5 times (bytes 1–5): LSR Bit 2 = 0 during all 5 reads. No error shown.
- Reading LSR before the 6th RBR read: LSR Bit 2 = 1. Parity error visible.
- Reading RBR (6th byte): Error byte removed from FIFO.
- Reading LSR before the 7th RBR read: Bit 2 = 0. No more errors.

### E-3: Read RBR to Remove the Byte
 
**Register:** RBR (Receiver Buffer Register) at offset +0 (DLAB=0)
 
After the LSR has been saved, read RBR to extract the byte from the FIFO. Reading RBR automatically clears the parity and framing error flags associated specifically with that byte.
 
### E-4: Return to IIR Loop
 
After handling the error byte, return to Phase D, Step D-2 (re-read IIR) to check for any remaining pending events.

## Phase F: Received Data Available / Character Timeout Handler
 
This phase executes when IIR Bits 3-1 = `010` (Data Available) or `110` (Character Timeout). Both cases are handled identically — the FIFO must be drained completely.
 
### F-1: The Inner FIFO Drain Loop
 
The ISR does not read a single byte and return to the IIR loop. The ISR drains the entire FIFO in one pass using an inner loop.
 
**Why complete draining is required:**
 
The UART's received-data interrupt is level-triggered with respect to the FIFO trigger threshold. Once the FIFO drops below the trigger level, the UART deasserts the data-available interrupt. If the ISR reads only one byte and returns to the IIR loop, the IIR may show "no interrupt pending" even though 13 bytes remain in the FIFO — because the FIFO is now below the trigger level. Those 13 bytes will sit unread until either more bytes arrive and the threshold is crossed again, or the 4-character timeout fires. Complete draining avoids this ambiguity and maximizes throughput.
 
**Inner Drain Loop Structure:**
```
DRAIN LOOP START:
  Step F-2: Read LSR
  Step F-3: Check LSR Bit 0 (DR)
    If DR = 0 → FIFO is empty → EXIT DRAIN LOOP → return to IIR loop (Phase D-2)
  Step F-4: Check LSR error bits (Bits 1, 2, 3, 4, 7)
    If any error bit = 1 → handle per error type (see Phase E error descriptions)
  Step F-5: Read RBR → extract byte from FIFO
  Step F-6: Write byte to software ring buffer
  Step F-7: Check software buffer high-water mark
    If buffer occupancy ≥ high-water mark → execute Phase F-8 (deassert RTS)
  Return to DRAIN LOOP START
```
 
### F-2: Read LSR
 
Read LSR at offset +5. Save the entire byte value in a local variable.
 
### F-3: Check Data Ready Bit (LSR Bit 0)
 
If LSR Bit 0 (DR) = 0, the Receive FIFO is completely empty. No more bytes are available. Exit the inner drain loop and return to the IIR service loop (Phase D-2).
 
If LSR Bit 0 (DR) = 1, at least one byte is available. Continue to the next step.
 
### F-4: Check LSR Error Bits (This is for safety net)
 
Before touching RBR, evaluate LSR Bits 1, 2, 3, and 4 for error conditions. Handle each error type as described in Phase E. Even if an error is present, the byte must be read from RBR to advance the FIFO. The decision of whether to keep or discard the byte depends on the error type and protocol requirements.
 
### F-5: Read RBR to Extract One Byte
 
Read RBR at offset +0 (DLAB must be 0). This action:
1. Removes (dequeues) the oldest byte from the Receive FIFO.
2. Automatically clears the parity and framing error flags associated with that specific byte.
3. Decrements the FIFO occupancy by 1.
### F-6: Write to Software Ring Buffer
 
Write the extracted byte into the software ring buffer in RAM. Advance the ring buffer write pointer by 1.
 
### F-7: High-Water Mark Check and RTS Deassertion
 
After writing the byte into the software buffer, check the software buffer's current occupancy.
 
**If occupancy ≥ high-water mark:**
 
Execute Phase F-8 to deassert MCR.RTS. The DRAIN LOOP continues after this — the CPU does not stop reading bytes from the hardware FIFO simply because the software buffer is full. Stopping the loop would leave bytes in the hardware FIFO. Instead:
- The hardware FIFO continues to be drained into the software buffer.
- RTS deassertion commands the remote device to stop sending new bytes across the wire.
- The remote device will stop transmitting after it observes the RTS change, but bytes already in transit may still arrive and fill the FIFO. The drain loop handles them.
**If occupancy < high-water mark:** Continue the drain loop without changing RTS state.
 
### F-8: Deassert MCR.RTS (Stop Remote Device)
 
**Register:** MCR at offset +4
**Action:** Read the current MCR value, clear **Bit 1 (RTS) to 0**, write back to MCR.
 
**Effect:** The physical RTS output line transitions to its inactive electrical state. The remote device monitors this line and halts further data transmission when it detects the change.
 
**What the remote device does during the pause:** The remote device's own sensors or input sources may continue producing data. The remote device stores those bytes in its own internal buffer. If that internal buffer fills completely, the remote device loses data internally — but the local system has no visibility into this condition. This is why the high-water mark must be set conservatively enough to give the remote device time to stop before the local buffer overflows.
 
### F-9: Return to Drain Loop Top
 
Return to Step F-2 (read LSR again) and continue processing the remaining FIFO bytes.

## Phase G: Post-Drain Buffer Check and RTS Re-assertion
 
This phase executes after the IIR service loop in Phase D determines that no more interrupt sources are pending (IIR Bit 0 = 1).
 
### G-1: Check Software Buffer Low-Water Mark
 
Evaluate the current software ring buffer occupancy.
 
**If occupancy ≤ low-water mark AND MCR.RTS is currently deasserted:**
 
Execute Step G-2 to re-assert MCR.RTS.
 
**If occupancy > low-water mark:** MCR.RTS remains deasserted. The CPU will handle data from the software buffer through a separate mechanism (application read calls). RTS will be re-asserted at a future point when the application drains the software buffer below the low-water mark.
 
**If MCR.RTS was never deasserted during this ISR invocation:** No action needed. RTS remains asserted.
 
### G-2: Assert MCR.RTS (Resume Remote Device)
 
**Register:** MCR at offset +4
**Action:** Read the current MCR value, set **Bit 1 (RTS) to 1**, write back to MCR.
 
**Effect:** The physical RTS output line transitions back to its active electrical state. The remote device resumes transmission.
 
**Why this step is mandatory:** If RTS is never re-asserted after deassertion, the remote device remains permanently paused. Communication is permanently halted. The entire serial link deadlocks.

## Phase H: Modem Status Handler
 
This phase executes when IIR Bits 3-1 = `000` (Modem Status Change, lowest priority).
 
**Register:** MSR (Modem Status Register) at offset +6 (read-only)
 
### H-1: Read MSR
 
Reading the MSR clears the **Delta bits** (Bits 3-0), which are set whenever the corresponding input line changed state since the last MSR read. Reading MSR acknowledges that the CPU has seen these state changes.
 
**Key MSR bits for reception flow:**
 
| Bit | Name | Meaning |
|-----|------|---------|
| 0 | DCTS (Delta CTS) | CTS line changed state since last MSR read |
| 4 | CTS | Current real-time state of the CTS input line |
| 5 | DSR | Current real-time state of the DSR input line |
 
### H-2: Evaluate CTS State
 
If the remote device has deasserted CTS (MSR Bit 4 = 0), the remote device is signaling that it cannot currently receive outgoing data from the local system. The driver records this and pauses any pending local transmissions. This does not directly affect the receive path.
 
### H-3: Return to IIR Loop
 
After reading MSR and saving relevant state, return to Phase D-2 to re-check IIR.

## Phase I: Interrupt Acknowledgment
 
Before exiting the ISR, two separate acknowledgment actions must be completed.
 
### I-1: UART Self-Clearing (Automatic)
 
The 16550 UART does not have a dedicated "clear interrupt" register bit. The UART automatically deasserts its interrupt signal line when the condition that caused the interrupt is resolved:
 
- **Received Data Available interrupt:** Automatically clears when the FIFO drops below the trigger level. The drain loop in Phase F accomplishes this.
- **Character Timeout interrupt:** Automatically clears when the FIFO is emptied (LSR Bit 0 = 0). The drain loop accomplishes this.
- **Line Status Error interrupt:** Automatically clears when the LSR is read and the error conditions are resolved.
- **Modem Status interrupt:** Automatically clears when the MSR is read (delta bits are cleared).
**Consequence of not reading the correct registers:** If the ISR exits without reading LSR (in an error case) or without draining the FIFO below the trigger level, the UART continues asserting its interrupt signal. The PIC will signal the CPU again immediately after IRET. The CPU will enter the ISR again without pause, creating an endless interrupt loop that locks the system.
 
### I-2: System Interrupt Controller Acknowledgment (x86-specific)
 
On x86 PC hardware using the 8259 PIC, the ISR must send an **End of Interrupt (EOI)** command to the PIC before executing IRET. The EOI command tells the PIC that the CPU has finished handling this IRQ and the PIC may now accept and forward the next interrupt of equal or lower priority.
 
**EOI mechanism:** Write the value `0x20` to the PIC command port (`0x20` for the master PIC, and both `0xA0` and `0x20` for IRQs on the slave PIC).
 
**Why EOI is required:** The PIC holds the interrupt signal to the CPU asserted until EOI is received. If EOI is not sent, the PIC will not forward any further interrupts of equal or lower priority after the ISR exits, causing the system to miss future UART and other hardware events.

## Phase J: ISR Exit and CPU Context Restoration
 
**Action:** The ISR executes the return-from-interrupt instruction (`IRET` on x86).
 
**CPU automatic actions upon IRET:**
1. Pops the saved Instruction Pointer (IP) from the stack — restores the program counter to where it was before the interrupt.
2. Pops the saved Code Segment (CS) from the stack.
3. Pops the saved FLAGS register from the stack — restores all flags to their pre-interrupt state, including the Interrupt Flag (IF = 1). This re-enables hardware interrupts at the CPU level.
The CPU resumes execution of the interrupted program at exactly the instruction it would have executed if the interrupt had never occurred. The interrupt is invisible to the interrupted program.

## Phase K: Steady-State Await
 
The CPU returns to executing its normal tasks (operating system scheduling, application processing, etc.). The UART hardware continues monitoring the RX line. When the next data byte arrives and the FIFO trigger condition is met, Phase B through Phase J repeat.

# ERROR SCENARIOS IN DETAIL
 
## Simultaneous Overrun and Parity Error
 
**Scenario:** The FIFO is full (16 bytes). A new byte arrives with a parity error. The overrun destroys the incoming byte; the parity error flag is set because the incoming byte itself was corrupt.
 
**IIR Report:** Line Status Error (highest priority). The Data Ready interrupt is masked by the higher-priority error.
 
**LSR State:** OE = 1, PE = 1, DR = 1 (valid bytes from before the overrun are still in the FIFO).
 
**ISR Response:**
1. Read IIR → sees Line Status Error.
2. Read LSR → saves OE=1, PE=1, DR=1.
3. Log overrun (data was lost). Log parity error.
4. Deassert MCR.RTS immediately.
5. Read RBR → the byte at the top of the FIFO was the last byte before the destroyed byte. Process it.
6. Re-read IIR → if DR is still 1 and no new error, handle remaining valid bytes in Phase F drain loop.

## Character Timeout with Error in Last Byte
 
**Scenario:** 3 bytes arrive. The trigger level is 14 bytes. After 4 character-frame periods, Character Timeout fires. The 3rd byte has a framing error.
 
**ISR Response:**
1. Read IIR → sees Character Timeout.
2. Enter Phase F drain loop.
3. First LSR read: DR=1, FE=0. Read RBR: byte 1 is clean.
4. Second LSR read: DR=1, FE=0. Read RBR: byte 2 is clean.
5. Third LSR read: DR=1, FE=1. Handle framing error. Read RBR: byte 3 is extracted and discarded.
6. Fourth LSR read: DR=0. Exit drain loop.
7. Return to IIR loop. IIR Bit 0 = 1. Exit ISR.

## RTS Deasserted, Remote Device Buffer Overflows
 
**Scenario:** The local software buffer fills. RTS is deasserted. The remote device is a simple sensor that lacks buffer management firmware. The sensor continues producing data and its internal buffer overflows. Data is lost inside the sensor. When RTS is re-asserted, the sensor resumes transmitting, but the data produced during the pause was lost internally.
 
**Local system visibility:** The local system has no indication that data was lost inside the remote device. The local UART never saw those bytes — they never crossed the serial wire. The local LSR will not show an overrun error for bytes lost in the remote device. The data loss is silent from the local system's perspective.
 
**Prevention:** Use flow control response times that account for the remote device's internal buffer capacity. If the remote device has a 64-byte buffer, the local system must reassert RTS before the remote device receives 64 new bytes during the pause.
 
# FLOW DIAGRAM 
```
┌──────────────────────────────────────────────────────────────────┐
│  PHASE A: IDLE STATE                                             │
│  • RX line = idle (high voltage)                                 │
│  • FIFO empty                                                    │
│  • MCR: DTR=1, RTS=1, Out2=1                                     │
│  • CPU executing other tasks                                     │
└──────────────────────────────┬───────────────────────────────────┘
                               │ Remote device transmits bytes
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE B: DATA ARRIVAL AND FIFO ACCUMULATION                     │
│  • UART shift register samples bits, assembles byte              │
│  • Byte transferred to Receive FIFO                              │
│  • Repeat per byte until trigger condition is met                │
└──────────────────────────────┬───────────────────────────────────┘
                               │
              ┌────────────────┴─────────────────┐
              │ FIFO ≥ trigger level             │ FIFO < trigger level
              │                                  │ AND no new byte for
              │                                  │ 4 character periods
              ▼                                  ▼
 [Data Available IRQ]              [Character Timeout IRQ]
              │                                  │
              └────────────────┬─────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE C: CPU INTERRUPT ENTRY                                    │
│  • CPU finishes current instruction                              │
│  • CPU auto-saves FLAGS, CS, IP to stack                         │
│  • CPU auto-clears IF (disables further hardware interrupts)     │
│  • CPU jumps to ISR                                              │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
┌══════════════════════════════════════════════════════════════════╗
║  PHASE D: IIR SERVICE LOOP (re-enter here after each service)    ║
║                                                                  ║
║  Read IIR (offset +2)                                            ║
║       │                                                          ║
║       ├── IIR Bit0 = 1 → NO PENDING INTERRUPTS ───────────────>G ║
║       │                  (exit loop → jump to Phase G)           ║
║       │                                                          ║
║       ├── Bits3-1 = 011 → LINE STATUS ERROR ──► Phase E          ║
║       ├── Bits3-1 = 010 → DATA AVAILABLE ────► Phase F           ║
║       ├── Bits3-1 = 110 → CHARACTER TIMEOUT ─► Phase F           ║
║       ├── Bits3-1 = 001 → TRANSMITTER EMPTY ─► (TX handler)      ║
║       └── Bits3-1 = 000 → MODEM STATUS ─────► Phase H            ║
╚══════════════════════════════════════════════════════════════════╝
 
─────────────────── PHASE E: LINE STATUS ERROR ───────────────────
│                                                                |
├─ E-1: Read LSR (offset +5), save to variable                   |
│        (this read clears error flags — MUST be done before RBR)|
├─ E-2: Evaluate saved LSR:                                      |
│         Bit1 OE=1 → log overrun, deassert MCR.RTS              |
│         Bit2 PE=1 → flag byte as corrupt (parity)              |
│         Bit3 FE=1 → flag byte as corrupt (framing)             |
│         Bit4 BI=1 → flag break condition                       |
├─ E-3: Read RBR (offset +0) → remove byte from FIFO             |
│         (discard or pass to app with error flag per protocol)  |
└─ Return to Phase D ◄────────────────────────────────────────────
 
 
 ─────────────────── PHASE F: DATA AVAILABLE / TIMEOUT ────────────
 │
 │  ╔══════════════════════════════════════════════════════╗
 │  ║  INNER FIFO DRAIN LOOP (repeat until FIFO empty)     ║
 │  ║                                                      ║
 │  ║  F-2: Read LSR (offset +5), save value               ║
 │  ║  F-3: Check LSR Bit0 (DR)                            ║
 │  ║         DR=0 → FIFO empty → EXIT drain loop          ║
 │  ║         DR=1 → continue                              ║
 │  ║  F-4: Check LSR error bits (1,2,3,4,7)               ║
 │  ║         If any error → handle per error type         ║
 │  ║  F-5: Read RBR (offset +0) → extract byte from FIFO  ║
 │  ║  F-6: Write byte to software ring buffer (RAM)       ║
 │  ║  F-7: Check software buffer occupancy                ║
 │  ║         ≥ high-water mark → F-8: Deassert MCR.RTS    ║
 │  ║         < high-water mark → continue                 ║
 │  ║  Return to top of DRAIN LOOP (F-2)                   ║
 │  ╚══════════════════════════════════════════════════════╝
 │
 └─ (after drain loop exits) Return to Phase D ◄────────────────────
 
 
 ─────────────────── PHASE H: MODEM STATUS ────────────────────────
 │
 ├─ H-1: Read MSR (offset +6) → clears delta bits (Bits 3-0)
 ├─ H-2: Check MSR Bit4 (CTS): if 0, remote device cannot receive
 │         → pause any pending local transmissions
 └─ Return to Phase D ◄─────────────────────────────────────────────
 
 
                               │
                               │ (IIR Bit0=1, loop exits)
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE G: POST-DRAIN BUFFER CHECK                                │
│                                                                  │
│  Check software ring buffer occupancy:                           │
│    ≤ low-water mark AND RTS is currently deasserted?             │
│      YES → Assert MCR.RTS (write Bit1=1 to MCR, offset +4)       │
│             Remote device resumes transmission                   │
│      NO  → Keep current RTS state                                │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE I: INTERRUPT ACKNOWLEDGMENT                               │
│                                                                  │
│  I-1: UART self-clear (automatic):                               │
│        Draining FIFO below trigger level cleared RX interrupt    │
│        Reading LSR cleared error interrupt                       │
│        Reading MSR cleared modem status interrupt                │
│        No explicit UART register write needed                    │
│                                                                  │
│  I-2: PIC EOI (x86-specific):                                    │
│        Write 0x20 to PIC command port (0x20 for master PIC)      │
│        Tells PIC this IRQ has been fully handled                 │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE J: ISR EXIT (IRET)                                        │
│                                                                  │
│  CPU executes IRET:                                              │
│    • Restores IP (program counter resumes where interrupted)     │
│    • Restores CS                                                 │
│    • Restores FLAGS (IF returns to 1 → hardware IRQs re-enabled) │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│  PHASE K: STEADY-STATE AWAIT                                     │
│  CPU resumes normal operation.                                   │
│  UART monitors RX line.                                          │
│  Cycle repeats from Phase B when next byte arrives.              │
└──────────────────────────────────────────────────────────────────┘
```