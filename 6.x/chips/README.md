## The IDT: The CPU's Interrupt Jump Table

### Why It Exists
The CPU must know *which code to run* when an interrupt arrives. There are 256 possible interrupt numbers (called **vectors**, numbered 0–255). The IDT maps each vector number to a handler function address.

**Intel permanently reserves vectors 0–31** for CPU-internal exceptions (e.g., vector 0 = Divide by Zero, vector 13 = General Protection Fault). These are triggered by the CPU itself, not by hardware pins. **Vectors 32–255 are available for hardware device interrupts.** By convention, vector 32 (0x20) is used as the first hardware interrupt slot.

### Physical Structure of the IDT
The IDT is a contiguous array in memory. Each entry is exactly **8 bytes wide**. The array holds 256 entries, so the total size is 256 × 8 = **2048 bytes**.

```
Bits 63–48  : base_high   — Upper 16 bits of the handler function address
Bits 47–40  : flags       — Gate type, privilege level, present bit
Bits 39–32  : always0     — Reserved, must be zero
Bits 31–16  : selector    — Code Segment selector from GDT (determines privilege context)
Bits 15–0   : base_low    — Lower 16 bits of the handler function address
```
The `flags` byte `0x8E` decodes as:
- Bit 7 (0x80): **Present** — entry is valid
- Bits 6–5 (0x00): **DPL = 0** — Ring 0 (kernel-level) only
- Bit 4 (0x00): Storage segment = 0 (this is a gate, not a data segment)
- Bits 3–0 (0x0E): Gate Type = 32-bit Interrupt Gate
The selector value `0x08` means: use entry 1 from the Global Descriptor Table (GDT), which in a standard Protected Mode setup points to the kernel code segment.

### Loading the IDT into the CPU
The CPU does not automatically know where the IDT is in memory. Software must inform the CPU by loading a 48-bit structure called the **IDTR (IDT Register)** using the `LIDT` instruction.
 
The IDTR structure:
```
Bits 47–16 : base  — Physical memory address where the IDT array starts
Bits 15–0  : limit — Size of the IDT minus 1 (for 256 entries: 2047 = 0x07FF)
```
 
Once `LIDT` executes, the CPU knows where to look every time a vector number arrives.

[UART](./UART.md)