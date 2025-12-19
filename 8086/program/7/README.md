# The 8259A Programmable Interrupt Controller ($\text{PIC}$)

## What is the PIC?

* The $\text{8259A}$ is a dedicated chip designed by Intel to manage multiple external hardware interrupt requests $(\text{IRQ}s)$ and deliver them to the CPU as a single interrupt signal, prioritized and numbered.

* $\text{8259A}$ can be used as a single chip which can handle 0-7 $\text{IRQ}$ or i two chips can be used like (**Master** and **Slave**), The Slave $\text{PIC}$ is connected to the Master's $\text{IRQ2}$ line, expanding the total number of usable $\text{IRQ}$ lines to 15 $(\text{IRQ 0 to IRQ 15})$.

    - Here master is just an **multiplixer**, master can't read and write data to salve PIC, CPU must do the things. If slave has IRQ, master's IRQ2 is asserted so the CPU knows data has to read from slave chip 

* Modern systems have largely replaced the $\text{8259A}$ with the **APIC (Advanced PIC)** for handling PCI and other modern interrupts, the 8259A is still emulated in all modern $\text{x86}$ chips for backward compatibility

>[!NOTE]   
> `IR` is a pin from PIC which will connect to the device.  
> PIC has 8 `IR` pins `0-7` It is also called as `IRQ0-7`.  
> Id 8086 is connected with master and salve now master has `IR0-7` and slave has`IR0-7` pins total 16 IR's, salve is connected with master's `IR2` so `IRQ 0 - 15` is connected to device.  
> IRQ here refers total interrupt handelable (system-level interrupt numbers) and IR refer each device pins (hardware pins)

## Why it is needed?

The CPU (like the 8086) only has a few interrupt pins (INTR and NMI). The PIC solves two problems:

1. **Expansion:** It allows 8 (or 15) different hardware devices to signal the CPU.
2. **Prioritization:** It ensures that if multiple devices request service at the same time, only the highest-priority request is forwarded to the CPU.

## How CPU communicate with PIC

The CPU communicates with the PIC via IN and OUT instructions to specific I/O ports.

| PIC | Port (Hex) | Name | CPU Instruction to access |
| --- | --- | --- | --- |
| **Master** | $\text{0x20}$ | Command Port | $\text{OUT 0x20, AL}$ (Write) / $\text{IN AL, 0x20}$ (Read) |
| **Master** | $\text{0x21}$ | Data Port | $\text{OUT 0x21, AL}$ (Write) / $\text{IN AL, 0x21}$ (Read) |
| **Slave** | $\text{0xA0}$ | Command Port | $\text{OUT 0xA0, AL}$ (Write) / $\text{IN AL, 0xA0}$ (Read) |
| **Slave** | $\text{0xA1}$ | Data Port | $\text{OUT 0xA1, AL}$ (Write) / $\text{IN AL, 0xA1}$ (Read) |

## Internal Registers
8259A contains several internal registers that track the state of interrupts. The $\text{CPU}$ can read these via the Command Ports $(\text{0x20/0xA0})$ after sending an $\text{OCW3}$ to prepare the $\text{PIC}$.

$\text{8259A}$ has three 8-bit registers ($\text{IMR}$, $\text{IRR}$, $\text{ISR}$)
* Each bit corresponds to one of the $\text{8}$ Interrupt Request lines ($\text{IR0}$ to $\text{IR7}$) handled by a single $\text{8259A}$ chip.
* All data transfer between the $\text{CPU}$ and the $\text{8259A}$ (including all commands, masks, and status reads) occurs over the 8-bit data bus ($\text{D0-D7}$).

| Register | Full Name | Read/Write | Purpose & Function |
| :--- | :--- | :--- | :--- |
| **$\text{IRR}$** | **Interrupt Request Register** | Read-Only | **Tracks Pending Requests:** An 8-bit register where each bit corresponds to an $\text{IRQ}$ line ($\text{IR0}$ to $\text{IR7}$). The corresponding bit is set to $\text{1}$ whenever a device asserts its $\text{IRQ}$ input line. **It shows which devices are currently asking for service.** |
| **$\text{ISR}$** | **In-Service Register** | Read-Only | **Tracks Active Interrupts:** An 8-bit register where the corresponding bit is set to $\text{1}$ when an interrupt is accepted (during the $\text{INTA}$ pulse) and the $\text{CPU}$ begins servicing it. **It shows which interrupt is currently being handled by the $\text{CPU}$** (or is "in service"). The $\text{PIC}$ uses this to enforce priority rules. |
| **$\text{IMR}$** | **Interrupt Mask Register** | Read/Write | **Disables Interrupts:** An 8-bit register where each bit controls masking for an $\text{IRQ}$ line. Writing a $\text{1}$ to a bit **masks** (disables) that interrupt, causing the $\text{PIC}$ to ignore the request in the $\text{IRR}$. Writing a $\text{0}$ **unmasks** (enables) it. |

**$\text{IRQ}$ refers to the physical input lines or signals coming into the PIC from various hardware**

#### Register interaction
Each device connected with PIC's dedicated IRQ line 

Let's say the Hard Disk is connected to Slave $\text{PIC}$'s $\text{IR6}$ pin, which corresponds to $\text{IRQ14}$ in the system.

1. The hard disk device asserts salve's IRQ line (IR6)
2. slave PIC detect the IRQ assert and set It's IRR bit value to 1

| $\text{IRR7}$ ($\text{IRQ15}$) | $\text{IRR6}$ ($\text{IRQ14}$) | $\text{IRR5}$ ($\text{IRQ13}$) | $\text{IRR4}$ ($\text{IRQ12}$) | $\text{IRR3}$ ($\text{IRQ11}$) | $\text{IRR2}$ ($\text{IRQ10}$) | $\text{IRR1}$ ($\text{IRQ9}$) | $\text{IRR0}$ ($\text{IRQ8}$) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| $\text{0}$ | **$\text{1}$** | $\text{0}$ | $\text{0}$ | $\text{0}$ | $\text{0}$ | $\text{0}$ | $\text{0}$ |

3. The Slave $\text{PIC}$ then asserts the Master $\text{PIC}$'s $\text{IRQ2}$ line. The Master $\text{PIC}$'s $\text{IRR}$ bit $\text{2}$ is set to $\text{1}$.

4. The $\text{PIC}$'s internal Priority Resolver logic constantly checks all active requests against the Interrupt Mask Register ($\text{IMR}$)(CPU decides which Interrupt is enabled or not by manupulating IMR) . The $\text{CPU}$ usually initializes the $\text{IMR}$ to only allow specific interrupts. Let's assume the $\text{IMR}$ is set to $\text{0}$ (enabled) for $\text{IRQ14}$ and $\text{IRQ2}$. The $\text{PIC}$ sees the $\text{IR6}$ bit in the $\text{IRR}$ is $\text{1}$ and the corresponding bit in the $\text{IMR}$ is $\text{0}$.

5. The $\text{PIC}$ determines the request is valid and asserts its $\text{INT}$ (Interrupt) pin, which is wired to the $\text{CPU}$'s $\text{INTR}$ pin. The $\text{CPU}$ pauses its current task.

6. The $\text{CPU}$ sends out a special signal called $\text{INTA}$ (Interrupt Acknowledge). This is the moment the interrupt becomes "In Service."

7. The $\text{PIC}$ puts the $\text{IRQ}$ number on the data bus for the $\text{CPU}$ to read (this is the $\text{Interrupt Vector}$).

8. The Slave $\text{PIC}$'s $\text{IRR}$ bit $\text{6}$ is cleared ($\text{0}$) because the request has been processed.

9. The Slave $\text{PIC}$'s $\text{ISR}$ bit $\text{6}$ is set ($\text{1}$).

10. The Master $\text{PIC}$'s $\text{ISR}$ bit $\text{2}$ is also set ($\text{1}$), master $\text{PIC}$'s $\text{IRR}$ bit $\text{2}$ is cleared.

**While $\text{IR6}$ is set in the $\text{ISR}$, the $\text{PIC}$ will not allow any new, lower-priority requests (like $\text{IRQ15}$ or $\text{IRQ13}$) to interrupt the $\text{CPU}$.**

11. The $\text{CPU}$ executes the Hard Disk $\text{ISR}$. When it's finished, it sends an $\text{EOI}$ (End of Interrupt) command. (The $\text{CPU}$ must send an $\text{EOI}$ to both the Slave $\text{PIC}$ (via $\text{OCW2}$ to $\text{0xA0}$) and the Master $\text{PIC}$ (via $\text{OCW2}$ to $\text{0x20}$).)

## Configurations

In the world of computer hardware, "firmware" usually refers to permanent software programmed into a chip's memory (like BIOS or UEFI). The 8259A is much simpler than that; it is a purely logic-based hardware controller that is "stateless" when it first powers up. **The 8259A does not have its own firmware.**

**Firmware will handle the device from power till OS takeover. In 8259 there is no firmware then how things handled?**

Because it has no permanent memory (like ROM or Flash), it "forgets" everything every time you turn off the computer. This is why the CPU must initialize it every time the system boots up. The CPU sends a specific sequence of Initialization Command Words (ICWs) to set its personality:

* ICW1: Are we using one chip or two?

* ICW2: What are the "Vector Numbers" (the ID numbers the CPU uses to find the right code)?

* ICW3: How are the Master and Slave wired together?

* ICW4: Is this an 8086 system or an older 8085?

The ICWs must be sent in a strict order: **$ICW1 \rightarrow ICW2 \rightarrow ICW3 \rightarrow ICW4$**.

### **The Initialization Flow**

| Command Word | Necessity | Purpose |
| --- | --- | --- |
| **ICW1** | **Compulsory** | Starts the setup. Defines the basic hardware environment (Edge/Level trigger, Single/master-salve(cascade)). |
| **ICW2** | **Compulsory** | Defines the **Vector Offset**. Tells the CPU which interrupt number corresponds to IR0. |
| **ICW3** | **Optional** | Only sent if **Cascade Mode** is enabled in ICW1. Defines how Master and Slave are wired. |
| **ICW4** | **Optional** | Only sent if "ICW4 needed" is checked in ICW1. Sets the CPU mode (8086 vs 8085) and EOI behavior. |


ICW (Initialization Command Word): Used only once when the computer starts to "format" the PIC.

#### **ICW1: The "Wake Up" Call**

*Sent to Port 0x20 (Master) or 0xA0 (Slave).*

| Bit | Name | Function |
| --- | --- | --- |
| **0** | **IC4** | 1 = Will send ICW4 later; 0 = No ICW4 needed. |
| **1** | **SNGL** | 1 = Single PIC mode; 0 = Cascade (Master/Slave) mode. |
| **2** | **ADI** | Call address interval (1 = interval of 4; 0 = interval of 8). Usually ignored in x86. |
| **3** | **LTIM** | 1 = Level Triggered Mode; 0 = Edge Triggered Mode. |
| **4** | **Init** | **Must be 1** to identify this as ICW1. |
| **5** | **A5** | Vector address bits for MCS-80/85 mode. (Set to 0 for x86). |
| **6** | **A6** | Vector address bits for MCS-80/85 mode. (Set to 0 for x86). |
| **7** | **A7** | Vector address bits for MCS-80/85 mode. (Set to 0 for x86). |

#### **ICW2: The "ID Card" Generator**

*Sent to Port 0x21 (Master) or 0xA1 (Slave).*
The CPU needs to know which interrupt number to look up in its table.

* **In 8086 systems:** You send a "Base Address."
* **Example:** If you send **0x20** (32) as ICW2, then:
* IR0 becomes Interrupt 0x20
* IR1 becomes Interrupt 0x21
* ...and so on.

| Bit | Name | Function |
| --- | --- | --- |
| **0-2** | **ID** | In 8086 mode, these are usually 0 (the PIC fills these based on which IRQ fired). |
| **3-7** | **Address** | **The Base Address.** If you want IR0 to be Int 0x08, you write 00001000b (0x08). |

#### **ICW3: The "Wiring Map"**

*Only used if you have a Master and Slave.*

* **For Master:** Each bit represents one of its IR pins. You set the bit where the Slave is connected. (Usually Bit 2 is 1 because Slave is on IR2). 00000100

    The Master needs to know which of its pins have slaves attached. It uses one bit per pin because you could theoretically have a slave on $IR1$, another on $IR2$, and another on $IR5$.
    
    - To say "There is a slave on $IR2$", you set Bit 2 to $1$.
    - Binary: 00000100 ($0x04$)

* **For Slave:** You send a binary number representing which Master pin it is connected to (e.g., 00000010 for Pin 2).

    The Slave PIC is a single device. It only needs to know which "Identity" (0-7) it has on the Master's board so it can listen for its "turn" on the cascade bus. It doesn't use a mask; it uses the actual number of the pin.

    - To say "I am connected to Master's Pin 2", you send the number 2.
    - Binary: 00000010 ($0x02$)

if master decide to use 5th pin for slave then master's config `00100000 ($0x20$)` and salve's config `00000101 ($0x05$)`


#### **ICW4: The "Environment" Settings**

Without ICW4, the PIC wouldn't know two critical things:

1. **Processor Architecture:** Whether it is talking to an old **8085** (8-bit) or a "modern" **8086/x86** (16/32/64-bit). The way they acknowledge interrupts is slightly different.
2. **Termination Policy:** Whether the PIC should automatically mark an interrupt as "done" or wait for a specific "All Clear" signal (EOI) from the programmer.

| Bit | Name | Function | Why it matters |
| --- | --- | --- | --- |
| **0** | **$\mu$ PM** | **Microprocessor Mode** | **1 = 8086/x86 mode.** **0 = 8080/8085 mode.** (Crucial: x86 handles interrupt vectors differently). |
| **1** | **AEOI** | **Auto End of Interrupt** | **1 = Auto.** The PIC clears the In-Service bit itself. **0 = Normal.** You must manually send an EOI code in your assembly. |
| **2** | **M/S** | **Master/Slave** | Only used if "Buffered Mode" (Bit 3) is on. Tells the chip if it's the boss or the subordinate. |
| **3** | **BUF** | **Buffered Mode** | Used in large systems with bus drivers to prevent electrical "noise." Usually **0** for PCs. |
| **4** | **SFNM** | **Special Fully Nested Mode** | Used in very complex cascaded systems to allow a higher priority interrupt from the same slave to break through. Usually **0**. |
| **5-7** | **0** | **Reserved** | Must always be **0**. |

**When is it skipped?**

ICW4 is only sent if you set Bit 0 (IC4) to 1 in your very first command (ICW1). If you set that bit to 0, the PIC assumes you are using an ancient 8085 system and defaults to the simplest settings.

**What the BIOS specifically does:**

When you turn on the computer, the BIOS executes its own startup code which includes:

1. **Initializing the Master and Slave PICs:** It sends the ICW sequence to set them up in Cascaded mode.
2. **Mapping the Vectors:**
    * **Master PIC:** Usually mapped to Interrupt Offset **0x08** (IR0 becomes Int 8, IR1 becomes Int 9, etc.).
    * **Slave PIC:** Usually mapped to Interrupt Offset **0x70** (IR0 becomes Int 0x70).
3. **Unmasking Essential IRQs:** It unmasks IRQ0 (Timer) and IRQ1 (Keyboard) in the **IMR (Interrupt Mask Register)** so the system can track time and accept user input immediately.

### How to distinguish the congif stage

To write these, you must use specific ports:

| Step | Register | Port (Master) | Port (Slave) |
| --- | --- | --- | --- |
| 1 | **ICW1** | 0x20 | 0xA0 |
| 2 | **ICW2** | 0x21 | 0xA1 |
| 3 | **ICW3** | 0x21 | 0xA1 |
| 4 | **ICW4** | 0x21 | 0xA1 |

> **Note:** Even though ICW2, 3, and 4 use the same port, the PIC knows which one is which because of the **internal state machine** triggered by ICW1. It "locks" the port until the sequence is finished.

The 8259A uses a combination of Physical Pins and an Internal State Machine to keep track of which ICW is being received. It doesn’t just "know"; it follows a very strict hardware logic sequence.

#### 1. The Entry Point: How it knows it is ICW1

The PIC knows you are starting the initialization sequence by looking at the **Command Port** (0x20 for Master) and checking a specific bit.

* **Port Check:** ICW1 must be sent to the **Command Port** (A0 pin on the chip is `0`).
* **The "Magic" Bit:** The PIC looks at **Bit 4** of the data you sent. If Bit 4 is **1**, the PIC's internal logic says: *"Stop everything! This is ICW1. Reset the state machine and prepare for the next words."*

#### 2. The Internal State Machine: ICW2, 3, and 4

Once ICW1 is received, the PIC enters a "Setup Mode." It uses an internal counter (a state machine) to determine what the next bytes sent to the **Data Port** (0x21) represent.

The sequence follows this logic:

1. **After ICW1:** The PIC "locks" itself and waits for the next byte at the Data Port. It **knows** this next byte must be **ICW2**.
2. **Checking ICW1 Bits:** The PIC looks back at the bits you sent in ICW1 to decide what happens next:
* **Is it Cascaded?** If ICW1 Bit 1 (SNGL) was `0`, the PIC waits for **ICW3**.
* **Is ICW4 needed?** If ICW1 Bit 0 (IC4) was `1`, the PIC waits for **ICW4**.

| If ICW1 says... | Step 2 | Step 3 | Step 4 |
| --- | --- | --- | --- |
| **Single, No ICW4** | ICW2 | *Done* | *Done* |
| **Single, With ICW4** | ICW2 | - | **ICW4** |
| **Cascade, No ICW4** | ICW2 | **ICW3** | *Done* |
| **Cascade, With ICW4** | ICW2 | **ICW3** | **ICW4** |

