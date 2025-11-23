# IN

## How Keyboard works?

### Generation

1. Keystroke  

    `A` key is physically pressed. Key Switch Closure

    Component : Keyboard

2. Scan code

    The keyboard's internal controller generates a unique code for the key.

    Component :  Keyboard Controller

3. Data deposite

    The Scan Code is sent to and stored in the dedicated Keyboard I/O Port on the motherboard. Scan Code stored at $\text{I/O}$ address $\mathbf{60\text{H}}$

    Component :  I/O Controller

### Signaling

4. IRQ

    The Keyboard $\text{I/O}$ port sends an $\text{IRQ}1$ signal to the $\mathbf{8259\text{A PIC}}$.

    Component: I/O Controller

5. INTR

    The $\text{PIC}$ raises the INTR (Interrupt Request) pin 18 on the 8086 CPU.

    Component: 8259A PIC

6. Acknowledge

    The CPU stops what it's doing and sends an $\overline{INTA}$  (Interrupt Acknowledge) signal back to the $\text{PIC}$. Over Pin 24

    Component: 8086 CPU

7.  Type Number

    In response, the $\text{PIC}$ sends the Interrupt Type Number to the CPU. Type 9 (for keyboard)

    Component: 8259A PIC

### Reading and Interpretation

8.  Find Code

    The CPU uses Type 9 to find the address of the Keyboard Interrupt Service Routine (ISR) in the Interrupt Vector Table. (This identifies the device as the keyboard.)

    Component: 8086 CPU

9.  Read Data

    The $\text{ISR}$ executes the $\mathbf{IN}$ instruction ($\text{IN AL, 60H}$), causing the CPU to read the stored Scan Code from the $\text{I/O}$ Port $\mathbf{60\text{H}}$. This will empty the buffer

    Component: 8086 CPU

10. End of Interrupt  (EOI)

    The $\text{ISR}$ sends a command to the $\text{8259A PIC}$ to clear the interrupt in its registers, preparing it to handle the next request.

    Component: 8259A PIC

11. Translate

    The $\text{ISR}$ checks the Scan Code and translates the Scan Code into a final ASCII/Unicode character (e.g., 'a' or 'A').

    Component: OS/Application

# OUT
## CPU Writing Data to a Peripheral

### Initiation and Readiness Check

1.  Status Read

    The OS executes an $\mathbf{IN}$ instruction to read the peripheral's Status Port address.

    Component: CPU, Peripheral Controller

2.  Polling/Wait

    The CPU checks the status data to see if the device's $\overline{BUSY}$ flag is clear (meaning the device is ready). If busy, the CPU waits or loops.

    Component: CPU

### Execution

3.  Write Command

    The CPU executes the $\mathbf{OUT}$ instruction, commanding the transfer of data from the register to the peripheral's Data Port address.

    Component: CPU

4.  Address Setup

    The CPU places the $\text{I/O}$ Port address (e.g., $\mathbf{378\text{H}}$) onto the Address Bus.

    Component: CPU

5.  Data Setup

    The CPU places the data byte onto the Data Bus.

    Component: CPU

6.  Control Signal

    The CPU asserts the control signals to indicate a write to an I/O location.

    Component: CPU

7.  Peripheral Latch

    The peripheral's controller detects its address and the $\mathbf{\overline{WR}}$ signal Pin: 29, and reads (latches) the data byte from the Data Bus.
    
    Component: Peripheral Controller

### Completion

8.  Data Processing

    The peripheral starts executing the command with the new data (e.g., a printer moves the print head and applies ink).

    Component: Peripheral Device

9.  Status Update

    The peripheral changes its status flag (e.g., sets $\text{BUSY}$) to indicate it is now occupied, preparing for the next status check by the CPU.

    Component: Peripheral Controller