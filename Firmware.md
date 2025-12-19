## Memory (hardware) 

This is physical chip, which store the startup program (BIOS/UEFI)

* **EEPROM:** This is the "Physical Filing Cabinet." It is non-volatile memory (keeps data without power) that can be erased and rewritten electrically.
* **NOR Flash:** This is the modern version of EEPROM used in computers today. It is much faster and allows the CPU to read instructions directly from it.

**The Chip:** On your motherboard, this is usually a small 8-pin chip (often called the **SPI Flash Chip**).

* Originally: BIOS was stored on ROM (Read-Only) chips that couldn't be changed.
* Later: They used EPROM, which had to be erased using UV light.

## Protocol 

Once we have a chip, we need a way to move that data to the brain (CPU).

* **SPI (Serial Peripheral Interface):** This is the high-speed "Highway." It uses 4 wires to send and receive data at the same time. It is used for the BIOS because it is fast enough to handle boot instructions.
* **The "Middleman" (Chipset/PCH):** The BIOS chip is physically wired to the Chipset, not the CPU. The Chipset acts as a manager, fetching the data from the SPI chip and passing it to the CPU.
* **I2C (Inter-Integrated Circuit):** This is a slower "Side Street" using only 2 wires. It’s used for tiny tasks, like checking a temperature sensor or reading RAM speeds (SPD), where speed doesn't matter.

## Program 

This is the code living inside the EEPROM/NOR memory

**BIOS / UEFI:** 
* This is the first program that runs.
* **UEFI:** The modern version of BIOS. It is more secure and supports larger disks and a Mouse/GUI.

* **What it was:** A collection of low-level routines. This code is functionally equivalent to the "Internal (On the Chip) Low-Level Firmware" in modern Wi-Fi cards,devices, as it's the **first code executed** by the CPU.

* **Its Function:**
    * It performed the **P.O.S.T.** (Power-On Self-Test).
    * It initialized the core components (memory, keyboard, disk controller).
    * It provided a set of standardized **interrupt services** (the functional precursor to modern kernel drivers) that the operating system (like MS-DOS) used to interact with the hardware.

Even though the BIOS is on a separate SPI chip, the system "maps" that chip into the CPU's memory address space. To the CPU, it doesn't look like a file on a disk; it looks like a specific location in its memory (usually at the very top of the addressable range, like 0xFFFFFFF0).

----

## Firmware

Firmware is a specific type of software that provides low-level control for a device's specific hardware. It is often called "software for hardware" because it acts as the bridge between the physical electrical circuits (hardware) and the high-level code (Operating System/Software).

* **Fixed Logic**: Unlike regular software, firmware is usually semi-permanent. It is stored in non-volatile memory (like the EEPROM/NOR Flash you mentioned) inside the device so it isn't erased when the power is cut.

* **Purpose**: It translates general instructions from the OS into specific electrical signals the hardware understands. For example, when you click "print," the printer's firmware tells the motors exactly how many millimeters to move the paper.

**BIOS is a firmware**

All the complex hardware require firmware `eg: CPU, mouse, keyboard, remote,..`, device like simple fans won't have firmware

All the device have ROM/EEPROM which will contain the firmware 

8086 has firmware, it is stored on a ROM which is inside the 8086, This instruction know how to do add, mov,.. This firmware not write able again

**Does RAM have firmware?**
For most of computer history, the answer was No. RAM was "dumb" memory. However, every RAM stick has a tiny 8-pin chip called the SPD (Serial Presence Detect).

#### The SPD Chip (The "ID Badge")

The SPD is a small **EEPROM** chip on the side of the RAM stick.

* **What it contains:** It doesn't hold "programs." Instead, it holds **data** (tables) about the RAM's speed, voltage, and timings (e.g., "I am 16GB, I run at 3200MHz, and I need 1.35V").
* **How it works:** When you press the power button, the **BIOS/UEFI** reads the SPD chip using the **I2C/SMBus** protocol to know how to talk to that specific stick of RAM.

#### DDR5: The Game Changer

In modern **DDR5** RAM, the sticks have become much more "intelligent." They now include a **PMIC (Power Management Integrated Circuit)**.

* **Why:** In older RAM (DDR4), the motherboard controlled the power. In DDR5, the RAM stick controls its own power to be more efficient.
* **Real Firmware:** Because the PMIC and the new SPD hubs are complex, they **do** have firmware.

##### The Simple Controllers (8259 PIC, 8253 Timer)

**They do not have firmware.**
In the 8086 era, these were "Fixed-Function" chips. They were made entirely of **Logic Gates** (AND, OR, NOT gates) etched into the silicon.

* **How they "learn" what to do:** They have **Internal Registers** (tiny storage slots). When the BIOS/CPU starts up, it sends a byte of data to a specific **I/O Port** (like `0x20` for the PIC).
* **The Result:** That byte physically flips "switches" (latches) inside the chip. Once those switches are flipped, the hardware is configured. There is no code running inside; it’s just electricity flowing through a specific path you've just "unlocked."

##### Modern Controllers (The "Integrated" Kind)

**They almost always have firmware.**
In modern PCs, the functions of the PIC, DMA, and Timer have been swallowed up by a massive chip called the **PCH (Platform Controller Hub)** or **Chipset**.

* **The Management Engine (ME) / PSP:** Inside your modern Intel or AMD chipset, there is actually a tiny, separate processor (often a RISC or ARM core).
* **Firmware:** This tiny processor runs its own firmware (e.g., Intel Management Engine firmware) which is stored in the same **SPI Flash Chip** as your BIOS.
* **Role:** This firmware handles things the main CPU shouldn't have to worry about, like deep-sleep power states, remote management, and security encryption keys.

##### Peripheral Controllers (USB, SATA, NVMe)

**They have firmware.**
When you connect a "Controller" as a device (like a dedicated RAID card or even the USB controller inside your laptop):

* **The Microcontroller:** The chip has its own "brain."
* **The Firmware:** It needs code to handle the complex protocols (like the USB 3.0 handshake).
* **Where it lives:** Sometimes it’s on a tiny dedicated EEPROM chip next to the controller, and sometimes the BIOS "injects" the firmware into the controller during the boot process.


### 1. Modern Firmware: The Two-Tier System

In modern computing, we distinguish between **Persistent Firmware** (lives on the chip) and **Runtime/Volatile Patches** (loaded by the OS).

#### 1. Persistent Firmware (The "Foundation")

* **Where:** Stored in the **EEPROM/NOR Flash** (the SPI chip on the motherboard).
* **Role:** This is the "Bare Minimum" code needed to turn the power on, initialize the memory controller, and start the CPU.
* **Static:** It stays there even when the power is off. It only changes if you manually "Flash" your BIOS.

#### 2. OS-Loaded Firmware (The "Update")

* **Where:** Stored on your **SSD/Hard Drive** as part of the Operating System or Driver files.
* **Role:** This is often called **Microcode** (for CPUs) or **Firmware Blobs** (for GPUs and Wi-Fi cards).
* **Dynamic:** Every time you boot up, the OS sends this newer code to the hardware’s internal RAM. 

> Every harware has it's internal RAM   
> Wifi card has RAM, Mouse has it's internal RAM,..

> **Why do we do this?** If a bug is found in the CPU or GPU, it is much safer and easier for vendor to fix it during every boot-up than to risk a physical BIOS flash that could "brick" (break) the motherboard.

### 2. Peripheral Cards (Option ROMs)

In the 8086 era (the original IBM PC and PC XT), there was effectively no Plug and Play. Devices were almost entirely fixed or required manual configuration.

Similar to how modern Wi-Fi cards need an "Operational Firmware," older expansion cards (graphics, early network, hard drive controllers) often needed extra code.

* These cards housed a smaller ROM chip called an **Option ROM** or **Extension ROM**.
* This ROM contained the **device-specific operational code** (firmware) for that card. The main BIOS would load and execute this code during startup, effectively initializing the peripheral and adding its capabilities to the system before the OS took over.

| Device | Does it have a BIOS? | Does it have Firmware? | What does that code do? |
| --- | --- | --- | --- |
| **Motherboard** | **Yes** (or UEFI) | Yes | Wakes up the CPU, checks RAM, starts Windows/Linux. |
| **Keyboard** | No | **Yes** | Scans the key matrix to see which button you pressed and sends a code to the PC. |
| **WiFi Card** | No | **Yes** | Manages radio frequencies, encryption (WPA3), and connecting to routers. |
| **Hard Drive** | No | **Yes** | Controls the physical spinning of disks and moving the read/write head. |
| **GPU (Video Card)** | **Yes** (Video BIOS) | Yes | Modern GPUs are so complex they actually have a "Video BIOS" to tell the motherboard how to display text before Windows starts. |

#### Are Option ROM Firmware Loaded into system Main Memory (RAM)?
Short Answer: Yes, the firmware from Option ROMs was often copied (or "shadowed") into the system's main RAM during startup for faster execution.

### 3. Dedicated Hardware (e.g., PIC)

Simple, dedicated chips like the **PIC** (Programmable Interrupt Controller, e.g., Intel 8259) were common.

* **Does it have firmware?** **No.** These devices are built from fixed digital logic gates and contain no internal non-volatile memory (ROM or Flash) to store a program.
* **Its Operation:** The main 8086 CPU "configures" these chips at startup by writing specific operational values to their internal registers, but the chip itself does not execute its own program.


## 8086 BIOS Initialization (POST Sequence)

### Phase 1: CPU Startup and Initial Control

1.  **Reset Vector:** When power is first applied (cold boot) or the reset button is pressed, the CPU enters **Real Mode** (the 8086's native 16-bit mode). The CPU's hardware logic forces the **Code Segment (CS)** register to `0xF000` and the **Instruction Pointer (IP)** to `0xFFF0`.
2.  **First Instruction:** The resulting physical address is $CS \times 16 + IP = 0xF0000h + 0xFFF0h = \mathbf{0xFFFF0h}$. This address, the **Reset Vector**, is hard-wired by the chipset to point directly to the very end of the BIOS ROM chip.
3.  **Initial Jump:** The instruction at $\mathbf{0xFFFF0h}$ is typically a jump instruction (`JMP`) that directs the CPU to the main, complete starting code of the BIOS, which is located in a lower, more accessible part of the **BIOS ROM**.

### Phase 2: Core Hardware Check and Setup (POST)

4.  **CPU & Registers Test:** The BIOS verifies the CPU is operational and clears or initializes key internal registers.
5.  **Checksum Test:** The BIOS performs a checksum calculation on its own code in the ROM to ensure the firmware has not been corrupted.
6.  **Critical Components:** It initializes and tests the core, indispensable components required for the system to run:
    * **Interrupt Controller:** Initializes the **PIC** (e.g., 8259) chip.
    * **Timer/Clock:** Initializes the system timer (e.g., 8253).
    * **DMA Controller:** Initializes the **DMA** (Direct Memory Access) controller.
    * **Keyboard Controller:** Initializes the keyboard controller (e.g., 8042).
7.  **Memory Test:** The BIOS checks for the presence and capacity of the main system **RAM**. It often performs a quick read/write test on the base memory (the first 64 KB, where the **Interrupt Vector Table (IVT)** is located) and then a more thorough test on the remaining memory. Errors here are signaled via **beep codes**.

### Phase 3: Shadowing and Peripheral Discovery

8.  **Video Initialization:** The BIOS finds and initializes the primary video adapter (e.g., CGA/EGA/VGA). The video card's own onboard **Option ROM (Video BIOS)** is usually executed first to get the display running.
9.  **CMOS Check:** The BIOS loads the system configuration (date, time, boot order, drive types) from the small **CMOS** battery-backed memory.
10. **Shadowing (Optional):** The BIOS copies its own code and the code from the Video BIOS into a fast area of **RAM** (Shadow RAM) and switches execution to the RAM copy for a significant speed increase.
11. **Option ROM Scan:** The BIOS scans the reserved upper memory area (typically $C0000h$ to $E0000h$) looking for the characteristic `0x55AA` signature of third-party **Option ROMs** (e.g., for a hard drive controller or network card).
12. **Execute Option ROMs:** For every valid Option ROM found, the BIOS loads its code (often shadowing it) and transfers control to its entry point. The peripheral's firmware then initializes its device and typically patches the main BIOS's **Interrupt Vector Table** to add its services (e.g., using a new $\mathrm{INT}\ 13h$ for the hard drive).

### Phase 4: Boot Sequence

13. **Final Initializations:** The BIOS initializes remaining devices and constructs the **Interrupt Vector Table (IVT)** and **BIOS Data Area (BDA)** in low memory.
14. **Boot Device Check:** The BIOS reads the boot sequence from the CMOS and begins checking the specified storage devices (e.g., Floppy drive, Hard drive).
15. **Load Boot Sector:** When it finds a device, it attempts to read the first sector (512 bytes) of the disk into memory address **$\mathbf{0x7C00}$**. It checks the last two bytes for the boot signature **$\mathbf{0x55AA}$**.
16. **Transfer Control:** If the signature is valid, the BIOS completes its job and transfers control to the code at memory address **$\mathbf{0x7C00}$**. This is the first instruction of the **bootloader** (often the Master Boot Record or the start of the OS loader), which then takes over the process of loading the main operating system. 


When an 8086 starts up, there is no "transfer" or "copying" happening yet. The CPU interacts with the EEPROM just like it does with RAM.

### Memory Map

|Memory Address| Content|Device|
|--------------|--------|------|
|00000h - 9FFFFh| User Programs| RAM|
|A0000h - BFFFFh| Video Memory|Video Card|
|F0000h - FFFFFh|System BIOS|EEPROM|

#### Is the Memory Map "Hardwired"?
The addresses themselves (the numbers like 0xA0000) are logical definitions. However, the Motherboard Chipset is hardwired to know which physical wire to "electrify" when the CPU asks for a specific address.

#### Is Memory only 640KB? (The "RAM" vs "Address" distinction)
In the 8086 era, we might have had 1MB of physical RAM chips, but you couldn't use all of it for your programs.

* 00000h - 9FFFFh (640KB): This is connected to your Physical RAM chips.
* A0000h - FFFFFh (384KB): This is called the Upper Memory Area (UMA).

The Motherbaord chipset is wired so that when the CPU asks for 0xA0000, the chipset disables the RAM chips and enables the Video Card or the BIOS EEPROM.

Yes, you lose that RAM space. Even if you have 1MB of RAM installed, the 384KB "behind" those addresses is essentially invisible because the chipset never sends the "Read" signal to the RAM chips for those addresses; it sends it to the devices instead.

#### How does "Shadowing" work?

If the chipset usually points `0xF0000` to the **EEPROM**, how can we "Shadow" (copy) it to **RAM** and run it from there?

Modern chipsets (and later 80286/386 boards) have **Programmable Address Decoders**.

1. **At Startup:** The chipset is set to "Read from ROM." When the CPU asks for `0xF0000`, the data comes from the EEPROM.
2. **The Copy:** The BIOS code tells the chipset: "Open a temporary write-path to RAM at `0xF0000`." It then reads from the EEPROM and writes that data to the "hidden" RAM sitting at the same address.
3. **The Switch:** The BIOS sends a command to the chipset: **"Flip the switch."**
4. **Result:** From now on, whenever the CPU asks for `0xF0000`, the chipset ignores the EEPROM and pulls the data from the RAM chips. This is much faster because RAM has a wider data bus and faster access times than the serial SPI/EEPROM.

#### Is A0000h - BFFFFh enough for VRAM?

**No, it’s not enough for modern graphics, but it was enough for the 8086.**

* **In the 8086 era:** A standard VGA screen at  in 16 colors only needed about 150KB. The 128KB "hole" at `0xA0000` was plenty.
* **Modern GPUs:** Your GPU might have 8GB of VRAM. 128KB is like a single pixel in a modern game!

**How do we handle it now?**

1. **A0000h is still there:** For compatibility, the GPU still maps a tiny "Window" at `0xA0000` so the computer can show text before the OS starts.
2. **The "Aperture" (BAR):** Modern systems use **Base Address Registers (BAR)**. The GPU tells the CPU: "I am a giant device. Map 8GB of my memory to the very high address range (e.g., `0x400000000`)."
3. **Command vs. Data:** When the CPU writes to `0xA0000`, it is usually writing **pixel data** (the colors to show on screen). If it needs to send a **command** (like "Draw a Triangle"), it writes to a different specific "Command Port" address defined by the driver.


###  The Physical "Handshake" (How it takes data)

The CPU "takes" data through a series of electrical signals on its pins. It follows a 4-step cycle called a **Bus Cycle**:

1. **Address Phase:** The 8086 puts the address `FFFF0h` onto its 20 address pins (A_{0} - A_{19}). It also pulses the **ALE** (Address Latch Enable) pin to tell the motherboard "Hey, I'm sending an address now!"
2. **Memory Request:** The CPU sets the **M/IO** pin to HIGH (Memory mode) and the **RD** (Read) pin to LOW (Active).
3. **The EEPROM Responds:** The motherboard circuitry sees address `FFFF0h` and "enables" the EEPROM chip. The EEPROM looks at that address internally and puts the first byte of code (usually a `JMP` instruction) onto the 16 data pins (D_{0} - D_{15}).
4. **Data Capture:** The CPU "samples" (reads) the electrical voltages on the data pins and pulls that byte into its internal **Instruction Queue**.


###  How do they work together?

When you turn on your 8086 (or a modern PC):

1. **Motherboard BIOS** wakes up first.
2. (BIOS) walks around and knocks on every door. It asks the **Keyboard Firmware**: "Are you there?" and the **WiFi Card**: "Who are you?"
3. Each device responds using its own internal firmware to say "I'm a keyboard, here is my ID."
4. The BIOS then records all this and tells the CPU, "Okay, the system is ready, let's start the OS."
