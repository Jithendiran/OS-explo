## Root Dev

In the Linux 0.12 kernel, root_dev is a variable that stores a specific numerical identifier. This number represents the root device, which is the disk partition containing the root file system (the top-level directory denoted as /).

### What is stored in the root_dev?
Bootsect, Setup, and Head, These three components make up the Kernel Image. They are separate from the file system found in root_dev.
- bootsect.s: The first 512 bytes. Its only job is to load the rest of the kernel into memory.
- setup.s: Handles hardware initialization (like moving to Protected Mode).
- head.s + main.c: This is the actual "core" of the kernel. It stays in RAM to manage memory, tasks, and hardware.

The root_dev refers to a disk partition containing a file system (typically the Minix file system in version 0.12). It does not contain the kernel code itself. Instead, it contains:
- User-space programs: Examples include the shell (/bin/sh), the compiler (gcc), and basic commands like ls or cat.
- Configuration files: System settings located in the /etc directory.
- Library files: Code used by user programs, found in /lib.
- Device files: Special files in /dev that allow programs to talk to hardware.



### Why the Design Separates Kernel and root_dev
The kernel is not stored as a regular file inside the root_dev file system during the boot process of 0.12. There are several technical reasons for this design:

1. Loop problem
To read a file from a file system, the kernel must already be running and have a file system driver loaded.
- If the kernel were a file inside the root_dev partition, the computer would need a "mini-kernel" just to find and load the "actual kernel."
- By placing bootsect, setup, and the kernel image in raw disk sectors (at the very beginning of the disk), the BIOS can load them directly without needing to understand complex file system structures.

2. Physical vs. Logical Storage
- Kernel Image: Needs to be in a fixed, continuous location so the bootloader can find it easily at power-on.
- File System (root_dev): Designed for flexibility. Files are often scattered across the disk (fragmented). If user-space programs were stored in a "subsequent manner" without a file system, adding or deleting a single file would require shifting every other byte on the hard drive.

3. Memory Management
The kernel must reside in a specific area of RAM to manage the CPU. User-space programs in root_dev are loaded into memory only when they are executed and are removed when they finish. Keeping them separate allows the kernel to remain permanent in memory while swapping user programs in and out.

### Why not store everything "subsequently"?
If everything were stored as one long stream of data without a file system:
- No File Names: Finding a specific program would require knowing its exact byte offset (e.g., "Run the program at byte 5,000,200").
- No Updates: To update the shell, the entire disk would likely need to be rewritten.
- No Multi-tasking: A file system allows the kernel to track multiple files at once, which is essential for a Unix-like operating system.


## 8086 memory reading
- The 8086 CPU has 20 "pins" connecting it to the system RAM. To point to a specific byte of memory, it must send a 20-bit number (ranging from 0x00000 to 0xFFFFF).
- However, the CPU registers (like the Segment registers CS, DS, SS) are only 16 bits wide. A 16-bit register cannot hold a 20-bit number.
- To solve this, the CPU hardware takes a 16-bit Segment value and mathematically shifts it to the left by 4 bits before adding an Offset. Shifting a hexadecimal number to the left by one position is the same as multiplying it by 16.

- Because the hardware always adds that hexadecimal zero to the Segment value, a Segment can only start at addresses that end in 0.
    * If the Segment register is 0x1000, the base physical address is 0x10000.
    * If the Segment register is increased by the smallest possible amount (to 0x1001), the base physical address becomes 0x10010.
    **Difference**
    * 0x10010 - 0x10000 = 0x00010 == 0x10 (hex) == 16 (decimal)

Therefore, it is physically impossible for a Segment to start at address 0x10001 or 0x10008. The CPU "jumps" in blocks of 16 bytes every time the Segment value changes by 1. These 16-byte blocks are called paragraphs.

Since the kernel must be loaded into a specific Segment in memory, and Segments only move in 16-byte steps, measuring the kernel in bytes would be not clear for the CPU's segmentation logic. By using paragraphs, the code speaks the same "language" as the 8086 hardware.