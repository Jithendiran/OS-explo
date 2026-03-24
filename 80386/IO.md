## I/O
The 80386 maintains this separation but adds a protection layer called the I/O Permission Bit Map. This map is located within the Task State Segment (TSS).

The 80386 processor supports a 64 KB I/O address space. This space contains $2^{16}$ (65,536) 8-bit ports.

### I/O Protection Levels
Unlike the 8086, the 80386 restricts I/O access based on the I/O Privilege Level (IOPL).
- IOPL Bits: These are bits 12 and 13 in the EFLAGS register.
- The Rule: If the Current Privilege Level (CPL) is numerically less than or equal to the IOPL, the processor allows all IN and OUT instructions. (00 - Highest privilege,  11 - least privilege)  CPL $\le$ IOPL
- The Conflict: If the CPL is greater than the IOPL (meaning the program has less privilege), the processor does not immediately crash. It instead checks the I/O Permission Bit Map. CPL $>$ IOPL, the processor locates the TSS using the Task Register (TR).

**The I/O Permission Bit Map**
The I/O Permission Bit Map is a table of bits located at the end of the Task State Segment (TSS). Each bit in this map represents one I/O port address.
* Bit Value 0: Access to the corresponding port is permitted.
* Bit Value 1: Access to the corresponding port is prohibited.
If a program in User Mode (Ring 3) attempts an OUT instruction to port 20H, the processor looks at the 32nd bit (20H) in the bit map. If that bit is 1, a General Protection Fault (#GP) occurs.

**TSS and the I/O Map Base Address**
The TSS contains a 16-bit field called the I/O Map Base Address. This field acts as an offset from the start of the TSS to the beginning of the Bit Map.
* Placement: The I/O map must be at the end of the TSS.
* Size: The map can be up to 8 KB in size to cover all 65,536 ports (since 8 bits per byte $\times$ 8,192 bytes = 65,536 bits).
* The Last Byte: The processor requires an extra byte of all 1s (FFH) at the very end of the map to signify the end of the table.