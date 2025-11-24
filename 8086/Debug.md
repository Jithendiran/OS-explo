## How to debug

1. Compile: `nasm -f bin boot.asm -o /tmp/boot.img`
2. Execute: `qemu-system-i386 -fda /tmp/boot.img -S -s`

    -fda <boot_image_file>: Loads your bootable image (e.g., a 512-byte boot sector) as a floppy disk. You could also use -hda for a hard disk image.

    -S: Do not start CPU at boot. QEMU will wait for a debugger connection before executing the first instruction.

    -s: Start a GDB server on localhost:1234 (the default port).

    Once these commad is executed qemu will wait for debugger

3. Debugger

    1. $ gdb
    2. (gdb) target remote localhost:1234
    3. (gdb) set architecture i8086
    4. (gdb) break *0x7c00 // code start
    5. continue

    list command won't work as like debug c program, to list a code we have to examine the memory

    6. x/10i $pc
        This command is used to examine the current instruction, display from ccurrent instruction till next 10 instructions
        10 indicates the num of instructions to display
        $pc refers program counter, which points to current instruction

        To diplay specific address : `x/10i 0x7c00`

        To display data source index: `x/s $ds:$si`
    7. stepi // move next


> [!CRITICAL]  
> GDB making a wrong assumption about the address, because of modern host system


1. $ nasm -f bin simple_print.asm -o /tmp/boot.img
2. gdb 
3. (gdb) target remote :1234
4. 
// start up inits
(gdb) info registers cs eip ds ss esp es eflags
```gdb
cs             0xf000              61440
ip             0xfff0              0xfff0
ds             0x0                 0
ss             0x0                 0
sp             0x0                 0x0
es             0x0                 0
flags          0x2                 [ IOPL=0 ]
(gdb) 
```

(gdb) x/i $pc
```
=> 0xfff0:	add %al,(%eax)
```
The register \$pc is an alias for the Instruction Pointer (IP) register (or EIP in a 32-bit context). At the reset vector, this register is set to $\mathbf{0xFFF0}$.

Hidden CS Base $\mathbf{0xFFFF0000}$ The actual $32\text{-bit}$ base address.

Visible IP (Offset) $\mathbf{0xFFF0}$ The $16\text{-bit}$ offset ($pc$).

When you tell GDB to look at \$pc, GDB, by default, assumes the value $\mathbf{0xFFF0}$ is a 32-bit linear address (i.e., the physical memory location). It completely ignores the segment registers ($\mathbf{CS}$) and their hidden bases.

$$\text{GDB's Assumed Address} = \mathbf{0x0000FFF0}$$

Physical address $\mathbf{0x0000FFF0}$ is in the first $1$ MB of memory. This area is usually used by the BIOS Data Area or Interrupt Vector Table, or sometimes contains a copy of the BIOS (depending on the system).

The instruction add %al,(%eax) is just the random junk data that happens to be at that location, which GDB attempts to decode as an instruction. It is not the first instruction of the system startup.

5. The correct address is $0xFFFFFFF0$

```
(gdb) x/i 0xFFFFFFF0
0xfffffff0:	ljmp   $0x3630,$0xf000e05b
```

even here \$0xf000e05b is wrong, it still see as 32-bit, but ljmp statement is correct

## How to indetify the correct line at run time
`x/i $cs*0x10+$pc`
```
(gdb) x/i $cs*0x10+$pc
   0xffff0:	ljmp   $0x3630,$0xf000e05b
```

GDB see it as 32-bit system