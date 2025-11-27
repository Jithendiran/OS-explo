##  QEMU/GDB Guide for Boot Sector Debugging

### I. Setup and Launch QEMU

The first step is correct execution to enable remote debugging.

| Step | Command | Description |
| :--- | :--- | :--- |
| **1. Compile** | `nasm -f bin boot.asm -o /tmp/boot.img` | Assemble your $\text{16-bit}$ boot sector code into a raw binary file. |
| **2. Execute QEMU** | `qemu-system-i386 -fda /tmp/boot.img -S -s` | Starts the QEMU machine, loading your image as a floppy disk. |
| | **`-S`** | **Do not start the CPU.** QEMU waits for GDB to connect. |
| | **`-s`** | Start the **GDB server** on the default port: $\text{localhost:1234}$. |

After this, QEMU will pause, waiting for the debugger.

-----

### II. Connect and Configure GDB

Launch GDB and configure it for the $\text{16-bit}$ environment.

| Step | Command | Description |
| :--- | :--- | :--- |
| **1. Launch GDB** | `gdb` | Start the GDB program in a new terminal window. |
| **2. Connect** | `target remote localhost:1234` | Connect GDB to the QEMU GDB server. |
| **3. Set Architecture** | `set architecture i8086` | **Critical:** Forces GDB to use $\text{16-bit}$ Real Mode register names and addressing rules. |
| **4. Breakpoint** | `break *0x7c00` | Set a breakpoint at the standard boot sector loading address ($\text{0x7C00}$). |
| **5. Start Execution** | `continue` | Tell the CPU to start running. It will execute the initial BIOS code and then stop at your $\text{0x7C00}$ breakpoint. |

-----

`list` command won't work as like debugging c program, because there is no high level source code. To list a code we have to examine the memory

`x/10i $pc`

    This command is used to examine the current instruction, display from current instruction till next 10 instructions

    10 indicates the num of instructions to display

    i indicates instruction
    
    $pc refers program counter, which points to current instruction

    To diplay specific address : `x/10i 0x7c00`

    To display data source index: `x/s $ds:$si`

stepi // move next


----

// start up inits
(gdb) info registers cs eip ds ss esp es eflags
```gdb
cs             0xf000              61440
eip            0xfff0              0xfff0
ds             0x0                 0
ss             0x0                 0
esp            0x0                 0x0
es             0x0                 0
eflags         0x2                 [ IOPL=0 ]
(gdb) 
```

(gdb) x/i $pc
```
=> 0xfff0:	add %al,(%eax)
```

Modern x86 processors (from the $\text{80286}$ onward) handle the reset slightly differently when initializing to Real Mode, but they must point to the same physical location.

$\mathbf{CS} = \mathbf{0\text{xF000}}$  
$\mathbf{EIP} = \mathbf{0\text{xFFF0}}$  
(GDB uses $\text{EIP}$ for the $\text{16-bit IP}$)  
Linear Address: $(\text{CS} \times 16) + \text{IP} = (0\text{xF000} \times 10\text{H}) + 0\text{xFFF0} = 0\text{xF0000} + 0\text{xFFF0} = \mathbf{0\text{xFFFF0}}$

The correct address is $0xFFFFFFF0$

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

#### Common Debugging Commands

| Command | Shorthand | Description |
| :--- | :--- | :--- |
| **Step Instruction** | `stepi` (or `si`) | Executes the current instruction and steps to the next one. |
| **Next Instruction** | `nexti` (or `ni`) | Similar to `si`, but will execute an entire procedure call (`CALL`) without stepping into it. |
| **Examine Instructions** | `x/Ni $pc` | Examines (displays) the next $N$ instructions starting from the Program Counter ($\text{\$pc}$). |
| **Examine Data** | `x/Nx 0xADDR` | Examines $N$ bytes of data as hex (`x`) starting at address $\text{0xADDR}$. |
| **Examine String** | `x/s $ds:0xOFFSET` | Displays the null-terminated string pointed to by the Segment ($\text{\$ds}$) and Offset ($\text{0xOFFSET}$). |
| **View Registers** | `info registers` | Displays all general-purpose registers ($\text{AX}$, $\text{BX}$, $\text{CX}$, etc.) and segment registers ($\text{CS}$, $\text{DS}$, etc.). |
| **Set Register** | `set $ax = 0x1234` | Changes the value of the $\text{AX}$ register to $\text{0x1234}$. |
| **Clear screen** | `shell clear`      | Clear the gdb screen|