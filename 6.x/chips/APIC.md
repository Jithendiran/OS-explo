# ACPI Kernel Internals: Foundation and Table Discovery

## Introduction to ACPI and the Firmware Interface
### The Definition and Purpose of ACPI
Advanced Configuration and Power Interface (ACPI) is an industry-standard specification defining how computer hardware and operating system software communicate regarding power management and system configuration.

#### The Underlying Problem and Why ACPI Exists
In early computing architectures, operating systems interacted directly with physical components through hardcoded memory addresses and port numbers compiled directly into the kernel code. This approach created significant engineering problems:
* **Hardware Fragility:** When motherboard layouts changed, the kernel failed to recognize components because physical addresses shifted.
* **Lack of Portability:** Every unique motherboard model required a custom-built kernel tailored specifically to its wiring.
* **Inefficient Power Management:** Operating systems lacked a standardized method to command hardware components to enter sleep states, shut down, or adjust power consumption dynamically.

ACPI solves these problems by separating **hardware description** from **operating system logic**. Instead of hardcoding hardware layouts into the kernel, motherboard manufacturers provide a set of data tables stored in non-volatile memory. When the operating system boots, it reads these tables dynamically to discover available hardware and its control mechanisms.

### Where ACPI Tables Are Stored
ACPI tables are **not stored inside individual hardware devices**. Instead, the motherboard manufacturer writes a central description manual (the ACPI tables) for the entire computer system. During early boot, the firmware copies these tables into central system **RAM** so the kernel can read them from a single, centralized location.

### What an ACPI Table Contains
An ACPI table is a structured file made of bytes containing two primary components:
1. **Signatures and Headers:** Metadata telling the kernel what kind of table it is and how large it is. Every ACPI table begins with a standard 36-byte header where the first four bytes contain an ASCII signature string identifying the table type (e.g., `FACP` for FADT, `APIC` for MADT).
2. **Data / Bytecode:** Specific values or instructions describing hardware resources.

## Finding the ACPI Tables in Memory
### The Root System Description Pointer (RSDP)
The Root System Description Pointer (RSDP) is a specific data structure stored in physical memory by system firmware during early boot.

#### The Underlying Problem and Why the RSDP Exists
When the kernel starts, it must read physical memory to discover system resources, but it does not initially know where ACPI tables reside. Because different computer models store these tables at varying memory locations, the kernel requires a reliable, standardized starting point. 

The RSDP acts as a **fixed navigation anchor**. Firmware places the RSDP into a standardized memory search area, providing the physical memory address needed to locate all subsequent ACPI tables.

### The RSDP Search Mechanism
Firmware places the RSDP into one of two specific memory regions:
* **The Extended BIOS Data Area (EBDA):** Low physical memory within the first megabyte, with its base address stored at physical memory vector `0x40E`.
* **The High Memory BIOS ROM Area:** A fixed memory block between physical addresses `0x000E0000` and `0x000FFFFF`.

#### The Scanning Process
1. The kernel reads the 16-bit pointer at physical memory address `0x40E` to find the EBDA starting address.
2. The kernel scans the first 1KB of the EBDA memory region, checking every 16-byte paragraph boundary.
3. If not found in the EBDA, the kernel scans the high memory BIOS area (`0x000E0000` to `0x000FFFFF`) at every 16-byte boundary.
4. At each boundary, the kernel inspects the first eight bytes for the ASCII signature `"RSD PTR "` (hexadecimal sequence `0x52 0x53 0x44 0x20 0x50 0x54 0x52 0x20`).
5. Upon detecting a matching sequence, the kernel calculates a checksum to verify integrity. Once validated, that memory address becomes the verified RSDP.

## System Description Tables (XSDT/RSDT Index Directory)
### The Purpose of Index Tables
Placing descriptions for every hardware component into a single massive file would create severe memory management and organization problems. Instead, ACPI divides hardware descriptions into modular, individual tables (e.g., FADT for core registers, MADT for interrupt controllers).

The **Root System Description Table (RSDT)** or **Extended System Description Table (XSDT)** acts as a master index directory containing a flat list of physical memory addresses pointing to each individual ACPI table loaded into system RAM.

### RSDT vs. XSDT
* **RSDT (Root System Description Table):** Used in older 32-bit architectures, containing an array of 32-bit physical memory addresses.
* **XSDT (Extended System Description Table):** Used in modern 64-bit architectures, replacing the RSDT with an array of 64-bit physical memory addresses to access memory beyond the 4GB limit.

### How the Kernel Uses the XSDT/RSDT
1. **Locate Index:** The kernel reads the physical address stored in the verified RSDP structure to locate the XSDT in RAM.
2. **Determine Size:** The kernel reads the XSDT header's `Length` field to calculate the total number of entries contained within the table.
3. **Iterate Pointers:** The kernel iterates through the array of physical memory addresses, where each entry points directly to a specialized individual ACPI table in RAM.

```
┌─────────────────────────────────────────────────────────────┐
│                     System Physical RAM                     │
│                                                             │
│   [ RSDP Table ]                                            │
│         │                                                   │
│         ▼                                                   │
│   [ XSDT Index Table ]                                      │
│         ├─► Pointer ─► [ FADT Table (Power/Registers) ]     │
│         ├─► Pointer ─► [ MADT Table (Interrupts/CPUs) ]     │
│         └─► Pointer ─► [ DSDT Table (Motherboard Devices) ] │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Overview of Core ACPI Table Types, Formats, and Entries

### Introduction to Modular ACPI Table Types
The XSDT/RSDT acts as a master index pointing to various individual ACPI tables stored in RAM. Each table serves a distinct hardware subsystem.

While the DSDT contains executable AML bytecode for variable motherboard devices, other core tables use fixed, C-language binary structures to describe static hardware.

### The Common Table Header (The Format Foundation)
Every ACPI table (whether fixed or containing bytecode) begins with an identical standard header. This uniform format allows the operating system kernel to parse any table safely before reading its specific payload.

**Header Format Layout (36 Bytes Total)**
|Offset (Bytes)|Field Name|Length (Bytes)|Description|
|--------------|----------|--------------|-----------|
|0x00 - 0x03|Signature|4|"ASCII character sequence identifying the table type (e.g., FACP, APIC, DSDT)."|
|0x04 - 0x07|Length|4|Total length of the entire table in bytes (including the header).|
|0x08|Revision|1|Minor version number of the table structure specification.|
|0x09|Checksum|1|Entire table checksum byte (must sum to zero when added with all other table bytes).|
|0x0A - 0x0F|OEM ID|6|OEM manufacturer string identifier.|
|0x10 - 0x17|OEM Table ID|8|Model string defined by the OEM.|
|0x18 - 0x1B|OEM Revision|4|Revision number of the OEM table generation.|
|0x1C - 0x1F|Creator ID|4|Vendor ID of the utility that compiled the table.|
|0x20 - 0x23|Creator Revision|4|Revision number of the compiling utility.|

### Detailed Breakdown of Core Table Types
1. **FADT (Fixed ACPI Description Table)**
   * Signature: FACP
   * Purpose: The FADT describes fixed, low-level motherboard hardware registers (such as power management control blocks, sleep control registers, and system reset controls). It also acts as the vital bridge pointing directly to the DSDT.
   * Format & Entries:
     * Following the standard 36-byte header, the FADT contains fixed-size C-struct fields.
     * Key Entry: It contains physical memory pointers (specifically DSDT and X_DSDT) pointing to the location of the DSDT in RAM.
2. **MADT (Multiple APIC Description Table)**
    * Signature: APIC
    * Purpose: The MADT describes all interrupt controllers and processors in the system. It tells the kernel how CPU cores are identified and how the Advanced Programmable Interrupt Controller (APIC) network is wired.
    * Format & Entries:
        * Following its standard header, the MADT contains fixed global configuration fields (such as the physical address of the Local APIC).
        * Variable Sub-Entries: Unlike tables with fixed layouts, the MADT contains a variable array of modular sub-structures called Interrupt Controller Structures. Each sub-entry begins with a 1-byte Type and a 1-byte Length:
          * Type 0: Processor Local APIC (maps CPU core IDs).
          * Type 1: I/O APIC (describes external interrupt routing chips).
          * Type 2: Interrupt Source Override (re-routes legacy ISA interrupts like the keyboard or timer).
3. **DSDT (Differentiated System Description Table)**
    * Signature: DSDT
    * Purpose: Describes motherboard-specific peripheral devices (like embedded controllers, thermal zones, and serial ports) that cannot be described with rigid C-structs.
    * Format & Entries:
      * Following the standard 36-byte header, the DSDT contains no fixed C-struct fields.
      * The entire remaining payload consists of raw binary ACPI Machine Language (AML) bytecode. The kernel passes this block directly to the ACPICA interpreter to build the ACPI Namespace.
4. **SSDT (Secondary System Description Table)**
    * Signature: SSDT
    * Purpose: Operates as an extension to the DSDT. Motherboard firmware uses SSDTs to describe optional, add-on, or modular hardware components (such as dynamic device configurations or hot-plug devices) without modifying the primary DSDT.
    * Format & Entries:
        * Structurally identical to the DSDT: a standard 36-byte header followed entirely by raw AML bytecode. As noted in previous sections, a system can contain multiple SSDT instances, each registered independently via the XSDT.

## Traversing the ACPI Namespace and Discovering Devices

### The Transition from Global Tables to Hierarchical Namespace
Once the operating system kernel completes the steps covered in previous sections—locating the RSDP, reading the XSDT/RSDT index, parsing foundational tables like the FADT and MADT, and loading the AML bytecode from the DSDT and SSDTs into memory—the core initialization phase transitions into Namespace Traversal.

### The Underlying Problem and Why Traversal Exists
Global tables like the FADT and MADT provide fixed system configuration data, but they do not describe individual peripheral devices like motherboard serial ports (COM1).

Instead, individual devices are defined within the hierarchical ACPI Namespace built by the AML interpreter. The operating system kernel cannot simply scan physical memory or I/O ports to find these devices; it must navigate the virtual tree structure of the namespace to discover what hardware nodes exist and what resources they require.

### Device Nodes and Plug and Play IDs (`_HID`)
Within the hierarchical ACPI Namespace, motherboard devices are represented as named nodes containing properties and methods.

#### What is a Hardware ID (`_HID`)?

When the kernel traverses the namespace, it inspects individual device objects to determine what kind of physical hardware they represent.
* Every standardized device object contains a special control property named `_HID` (Hardware ID).
* The `_HID` returns a standardized string or EISA ID defined by industry specifications. For example, a standard 16550A-compatible serial port is designated with the `PNP0501` hardware ID string.

#### Why `_HID` Exists
Without a standardized naming convention, the operating system kernel would have no way of knowing whether a generic device node in the firmware namespace corresponds to a serial port, a parallel port, a floppy drive, or a power button. The `_HID` property provides a universally recognized label that allows the kernel driver to match itself to the correct firmware node.

### Evaluating Resource Methods (`_CRS`)
Discovering that a device exists via its `_HID` is only the first step. The operating system kernel also needs to know the physical operational parameters of that device (such as its assigned I/O port address and IRQ line).

#### What is `_CRS`?
Every device node in the namespace that requires hardware resources contains a special executable method named `_CRS` (Current Resource Settings).

#### The Underlying Problem and Why `_CRS` Exists
Hardware configurations vary across different computer models. A serial port might be assigned to I/O port address `0x3F8` on one motherboard, but assigned to `0x2F8` on another.
* Hardcoding these addresses into the operating system kernel is impossible.
* The `_CRS` method solves this problem by returning a dynamic data structure (a resource template) that tells the kernel the exact, current physical resources allocated to that specific device by the firmware.

#### How the Kernel Evaluates `_CRS`
1. Namespace Scan: The kernel walks the ACPI namespace tree searching for nodes containing a recognized hardware ID (e.g., `_HID` matching `PNP0501`).
2. Method Execution: When a matching node is found, the kernel instructs the internal AML interpreter (ACPICA) to execute the device's `_CRS` method.
3. Resource Extraction: The AML interpreter executes the bytecode inside `_CRS` and returns a raw buffer containing resource descriptors. The kernel parses this buffer to extract:
   * I/O Port Ranges (e.g., base port 0x3F8, length 8 bytes).
   * Interrupt Lines (e.g., IRQ line 4).

### Bridging ACPI to the Linux Driver Model
Once the kernel extracts the hardware resources from the `_CRS` method, it must instantiate the device within the standard Linux driver architecture.

#### Platform Devices and Drivers
Because ACPI-enumerated motherboard devices do not reside on physical discovery buses like PCI or USB, they cannot use standard bus-scanning routines.
* Platform Bus: The Linux kernel registers these devices on a virtual infrastructure bus called the Platform Bus.
* Platform Devices: The kernel wraps the ACPI device node and its extracted `_CRS` resources into a platform_device structure.
* Driver Matching: Serial device drivers (such as the 8250 serial driver) register an ACPI device match table containing compatible strings (e.g., `{ "PNP0501", 0 }`). When the platform device is registered, the kernel core matches the `PNP0501` ID with the driver, passes the extracted I/O port and IRQ configuration, and successfully initializes the hardware.