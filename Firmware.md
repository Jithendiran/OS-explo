## Low-Level Code in the 8086 Era (Firmware Predecessors)

The concept of firmware—essential, low-level code for hardware operation—was absolutely critical in the 8086 era, though the common term was typically ROM code or BIOS.

### 1. The Motherboard / PC System (The BIOS)

On systems built around the **Intel 8086** (or 8088), the core system firmware was the **BIOS** (Basic Input/Output System). 

* **What it was:** A collection of low-level routines. This code is functionally equivalent to the "Internal (On the Chip) Low-Level Firmware" in modern Wi-Fi cards,devices, as it's the **first code executed** by the CPU.

* **Where it was stored:** It was stored in a large, dedicated **Non-Volatile Memory** chip on the motherboard, such as **EPROM** (Erasable Programmable ROM) or **EEPROM**.

* **Its Function:**
    * It performed the **P.O.S.T.** (Power-On Self-Test).
    * It initialized the core components (memory, keyboard, disk controller).
    * It provided a set of standardized **interrupt services** (the functional precursor to modern kernel drivers) that the operating system (like MS-DOS) used to interact with the hardware.

### 2. Peripheral Cards (Option ROMs)

In the 8086 era (the original IBM PC and PC XT), there was effectively no Plug and Play. Devices were almost entirely fixed or required manual configuration.

Similar to how modern Wi-Fi cards need an "Operational Firmware," older expansion cards (graphics, early network, hard drive controllers) often needed extra code.

* These cards housed a smaller ROM chip called an **Option ROM** or **Extension ROM**.
* This ROM contained the **device-specific operational code** (firmware) for that card. The main BIOS would load and execute this code during startup, effectively initializing the peripheral and adding its capabilities to the system before the OS took over.

#### Are Option ROM Firmware Loaded into Main Memory (RAM)?
Short Answer: Yes, the firmware from Option ROMs was often copied (or "shadowed") into the system's main RAM during startup for faster execution.

### 3. Dedicated Hardware (e.g., PIC)

Simple, dedicated chips like the **PIC** (Programmable Interrupt Controller, e.g., Intel 8259) were common.

* **Does it have firmware?** **No.** These devices are built from fixed digital logic gates and contain no internal non-volatile memory (ROM or Flash) to store a program.
* **Its Operation:** The main 8086 CPU "configures" these chips at startup by writing specific operational values to their internal registers, but the chip itself does not execute its own program.


## 8086 BIOS Initialization (POST Sequence)

### Phase 1: CPU Startup and Initial Control

1.  **Reset Vector:** When power is first applied (cold boot) or the reset button is pressed, the CPU enters **Real Mode** (the 8086's native 16-bit mode). The CPU's hardware logic forces the **Code Segment (CS)** register to `0xF000` and the **Instruction Pointer (IP)** to `0xFFF0`.
2.  **First Instruction:** The resulting physical address is $CS \times 16 + IP = 0xF0000h + 0xFFF0h = \mathbf{0xFFFF0h}$. This address, the **Reset Vector**, is hard-wired by the chipset to point directly to the very end of the BIOS ROM chip.
3.  **Initial Jump:** The instruction at $\mathbf{0xFFFF0h}$ is typically a jump instruction (`JMP`) that directs the CPU to the main, complete starting code of the BIOS, which is located in a lower, more accessible part of the BIOS ROM.

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
