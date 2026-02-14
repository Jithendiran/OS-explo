## Jump

### Short Jump

`eb`: This is the "Opcode" for a Short JMP, It is used in same section or with offset maximum 1 byte long (-128 to 127)

```asm
start:
    nop
    jmp end
    nop
    jmp start
    nop 
    nop
    jmp $
    nop
    nop
end:
    nop
    jmp start
```

```sh 
$ objdump
file.o:     file format elf32-i386


Disassembly of section .text:

00000000 <start>:                                       # our Note, 
0:   90                      nop                        # offset in decimal signed number       PC calculation
1:   eb 09                   jmp    c <end>             #09 == 09                               3 + 9  = 12 (c) 
3:   90                      nop
4:   eb fa                   jmp    0 <start>           #fa == -6                               6 + (-6) = 0
6:   90                      nop
7:   90                      nop
8:   eb fe                   jmp    8 <start+0x8>       #fe == -2                               a + (-2) = 8
a:   90                      nop
b:   90                      nop

0000000c <end>:
c:   90                      nop
d:   eb f1                   jmp    0 <start>           #f1 == -15                              15 + (-15) = 0
```

Don't look the notes in code now

In the machine code we can see some strange number like `09, fa, fe, f1`. These are offset to reach that location, it is not the final address. They store a relative offset. This offset tells the CPU how many bytes to move forward or backward from its current position.

**Let's see how jump works in short jump**
For example take `1:   eb 09  `
- `eb` means short jump (with in section, it's offset length will be 1 byte)
- From the assembly we wrote as `jmp end`, end offset is location `0000000c` or `c`

To reach `c` from current instruction c (target offset) - 1 (current offset) = b (11 steps), it has to add offset of 11,  so `1 + (b)11 = (c)12`, offset for 11 is `b` but in code it is `09`
When CPU execution With offset `c` it will jump to `d (13)` instead, because `jump` will work based on the PC, not based on current instruction location

**PC content will be modified by adder only, it won't take direct values**

By the time the CPU executes a jump instruction at location `1`, it has already finished reading it `(01-02)`. Therefore, the PC is already pointing to the start of the next instruction (`03`).  So when executing `01` address instruction , pc is in `03`. Jump calculation has to be done based on pc register, not based on current instruction 

Target is `c (12)`, PC=`3` 

$$C = 3 + ? \text{ or } 12 = 3 + x$$
$$? = C-3 \text{ or } x = 12 - 3$$
$$? = 9 \text{ or } x = 9$$
`9` is the offset to reach location `c` from `3`, this is placed as offset of jump instruction

For short Jump the offset value is 1 byte

Now look the notes comment in code

The assembler do this calculation to find the offset

$$\text{Store offset} = \text{target offset} - \text{Next instruction start}$$

How to calculate Next instruction start from current instruction?

$$\text{Next instruction start} = \text{current instruction opcode length} + \text{length of operand offset} + \text{current instruction start}$$
short jump  offset is `e9`, it's length is `1 byte` and it's length is `1 byte` and curent instruction start is `1`

$$\text{Next instruction start} = 1 + 1 + 1 = 3$$

How object dump seen it, object dump decoded as `c <end>`
`C` is final target to reach and it's symbol name

Since all the short jump are in the same section no relocation record is created, all this calculation is done by assembler, linker not involved yet.

we already seen `eb 09` let' see other 2

> [!TIP]   
>  Execute the below in bash shell, This will convert little endian to big endian, Unsigned and Signed decimal
```sh
hex-reloc() {
    # Removes spaces and treats the input as little-endian
    local hex_input=$(echo "$*" | tr -d ' ')
    python3 -c "import struct; b = bytes.fromhex('$hex_input'); \
                u = struct.unpack('<I', b)[0]; \
                s = struct.unpack('<i', b)[0]; \
                print(f'Hex (Big Endian): {u:08x}'); \
                print(f'Unsigned Dec:     {u}'); \
                print(f'Signed Dec:       {s}')"
}
```
> `$  hex-reloc fc ff ff ff` execute like this to find the value

1.  eb fa 
    - fa == -6 
    - Next PC = 6, It needs to reach 0
    To reach 6, it will add -6 to pc

2.  eb f1
    - f1 == -15
    - Next PC = 15, It needs to reach 0
    To reach 6, it will add -6 to pc

3. eb fe                   
    - fe == -2  
    - Next PC = a, It needs to reach 8(current location)
    To reach 8, it will add -2 to pc

    It's decoding is strange `jmp    8 <start+0x8>`, this is because there is bo symbol at the location `8` so it taken it's own section's near symbol, own section is `.text`, near symbol to reach from section start is `start`, from start symbol it has to do `+8` to reach that address.


### Near Jump 
`e9` : Near Jump (a 32-bit relative jump).
Between sections

```asm
section .text
local_start:        
    nop
    jmp local_start 
local_st:
    nop


section .aaa

local_1:
    nop
    nop
local_2:
    mov ax, 1
    nop
    jmp local_start
```

```sh
$ objdump
Disassembly of section .text:

00000000 <local_start>:
   0:   90                      nop
   1:   eb fd                   jmp    0 <local_start>

00000003 <local_st>:
   3:   90                      nop

Disassembly of section .aaa:

00000000 <local_1>:
   0:   90                      nop
   1:   90                      nop

00000002 <local_2>:
   2:   66 b8 01 00             mov    $0x1,%ax
   6:   90                      nop
   7:   e9 fc ff ff ff          jmp    8 <local_2+0x6> #-4
   c:   90                      nop
```

In this example, `jmp local_start` in the `.aaa` section is jumping to a completely different section. At this stage, the **Assembler** doesn't know where the `.text` and `.aaa` sections will eventually be placed in memory. It only knows the internal offset of each position relative to the start of its own section:

* **local_start** is at offset `0` within `.text`.
* **local_st** is at offset `3` within `.text`.
* **local_1** is at offset `0` within `.aaa`.
* **local_2** is at offset `2` within `.aaa`.

It is the Linker’s job to assign these sections to real memory addresses and calculate the final value for the jump offset.

#### How does the Linker know which addresses need to be relocated?

The Assembler helps the Linker by flagging specific locations that require relocation.

1. **Identifying the Jump:** When processing byte `7` of the `.aaa` section, the Assembler sees the jump opcode and recognizes it as a **near jump**. It then creates a **relocation record** in the `.aaa` section's relocation table.

2. **Marking the Target:** The Linker must modify the placeholder address with the final address. The relocation table tells the Linker exactly which bytes to replace.
    * It won't touch byte `7` (the opcode); instead, it targets bytes `8` through `11` (the 4-byte offset). Therefore, the Assembler creates a record starting at offset `8`.

3. **Defining the Type:** The Linker needs to know what kind of value it is replacing (e.g., a 32-bit address, a 64-bit address, or a PC-relative offset). To communicate this, the Assembler adds a "Type" column.
    * In our case, it uses `R_386_PC32`.
    * **R**: Relocatable.
    * **386**: Intel x386 family.
    * **PC**: Program Counter relative offset.
    * **32**: 32 bits (4 bytes) long.

4. **Assigning the Destination:** Finally, the Linker needs to know which section the jump is targeting. The Assembler places the symbol's section (in this case, `.text`) in the "Value" column of the record.

**The Relocation Record for [.aaa] would look like this:**

| OFFSET | TYPE | VALUE |
| --- | --- | --- |
| 00000008 | R_386_PC32 | .text |

Each section maintains its own relocation table, acting as a "to-do list" for the Linker to finalize the jump logic once memory addresses are assigned.

#### The Offset and the Linker's Calculation

So far, the assembler has created a record of which bytes need relocation and which section they target. However, one piece of information is still missing from the relocation table: the specific offset of the symbol within that target section. This offset acts like a unique ID.

The assembler stores this offset directly inside the jump instruction. For example:

* `local_start` is at offset `00`.
* The assembler fills bytes 8 through 11 with `00 00 00 00`.
* In section `.aaa`, the instruction at byte 7 looks like this: `7: e9 00 00 00 00`.
*(Note: You might actually see `fc ff ff ff` there instead; we will explain why that happens shortly. For now, let’s assume it is all zeros.)*

##### 1. Linker Execution Starts

Let's use decimal numbers to make the math easier. Suppose the linker decides:

* `.text` starts at address `1001` (so `local_start` is at `1001`).
* `.aaa` starts at address `2000`.

The jump instruction at offset 7 in `.aaa` is now at memory address `2007` and `7:   e9 fc ff ff ff` become `2007:   e9 fc ff ff ff`

The linker looks at the relocation record: `00000008 R_386_PC32 .text`. This tells the linker that the 4 bytes starting at offset 8 (address `2008`) need to be updated to point to `.text`.  It will calculate the target address for local_start

* **Target Address:** `.text` (1001) + symbol offset (0) = `1001`.
* **Current Position:** The linker is looking at address `2008` (`2008-2011`).
* **Linker's Math:** To get to 1001 from 2008, you need `1001 - 2008 = -1007`.
The linker replaces the zeros with `-1007`.


##### 2. The CPU Execution Problem

Now the program runs. The CPU reaches address `2007` and sees `jump -1007`.

However, the CPU will jump to `1005`, not `1001`. **Why?** Because of the **Program Counter (PC)**. By the time the jump executes, the PC is already pointing to the *next* instruction. A near jump is 5 bytes long (1 byte opcode + 4 bytes offset).

* Jump starts at `2007`.
* Next instruction starts at `2012`.
* CPU Calculation: `2012 - 1007 = 1005`.

**The "Overshoot" Problem**

Our cpu needs to go to `1001` not `1005`, it is off by `1005-1001` = 4 bytes but why 4 bytes?

Our jump instruction starts at address **2007** and ends at **2011**. This means the next instruction starts at **2012**. The offset part of the jump itself is 4 bytes long. When the CPU executes this, it "overshoots" the target by 4 bytes. If our jump offset were only 2 bytes long, it would overshoot by 2 bytes. This happens because the calculation is based on where the **PC (Program Counter)** is pointing at that exact moment.

We calculated everything from the **linker's perspective**. The linker starts its calculation from the location of the offset itself (byte **2008**).

**Linker calculation:** 
This math (2008-1007 = 1001) is correct for the linker, but it fails during **CPU execution**.

##### 3. The Assembler's Solution: The Addend

We can't change how the CPU works, and we shouldn't change how the linker works (since the linker is a general tool). The fix must happen in the **Assembler**.

When the assembler fills the jump offset, it pre-calculates this "overshoot." It subtracts the length of the offset (4 bytes) from the initial value.

* `local_start` offset (0) - length of offset (4) = `-4`.
* The assembler puts `-4` in the jump instruction: `jmp -4`.

**-4 is because length of the jump offset is 4 byte**

**Let’s recalculate with the Assembler's fix:**

* **Linker's Math:**
    * Target is `.text` (1001) + the new offset (-4) = `997`.
    * To go from address 2008 to 997: `997 - 2008 = -1011`.
    * The linker writes `-1011` into the binary.

* **CPU Execution:**
    * The CPU is at `2007`. The PC points to the next instruction at `2012`.
    * CPU Math: `2012 - 1011 = 1001`.
    * **Success!** The flow correctly goes to `1001`.

This is why you see `e9 fc ff ff ff` in the object file. `fc ff ff ff` is the hex representation of `-4`. This -4 is called as addend.

##### 4. Final Linking and Verification

When we run the linker, it assigns real memory addresses to our sections and calculates the final jump offset.

```sh
$ ld -m elf_i386 file_1.o -o file_1.out
Disassembly of section .text:

08049000 <local_start>:
 8049000:       90                      nop
 8049001:       eb fd                   jmp    8049000 <local_start>

08049003 <local_st>:
 8049003:       90                      nop

Disassembly of section .aaa:

0804a027 <local_1>:
 804a027:       90                      nop
 804a028:       90                      nop

0804a029 <local_2>:
 804a029:       66 b8 01 00             mov    $0x1,%ax
 804a02d:       90                      nop
 804a02e:       e9 cd ef ff ff          jmp    8049000 <local_start>
 804a033:       90                      nop
```

**The Linker's Calculation**

The linker uses a specific "Relocation Formula" to find address, $S + A - P$
- $S$ (Symbol): The final address of section .text
- $A$ (Addend): The value already stored in those 4 bytes (e.g., -4).
- $P$ (Position): The final address where the relocation is being applied (Relocation table offset 00000008 points to 0x0804a02f).

$$\text{Result} = S + A - P$$
$$\text{Result} = 0x08049000 + (-4) - 0x0804a02f$$
$$0x08049000 - 4 = 8048FFC$$
$$8048FFC - 0x0804a02f =-1033 $$
$$\text{Result} = -0x1033 \quad (\text{which is } \mathbf{FFFFEFCD})$$

**Verifying from the CPU's Perspective**

- `.text` address is `0x08049000` and offset of `local_start` is `0` $0x08049000 + 0 = 0x08049000$
- `.aaa` address is `0x0804a029`
    - (jump instruction) $0x0804a029 + 7 = 0x804a02e$
    - (Next Instruction Address) $0x0804a029 + c  = 0x804a033$

$$\text{Jump offset} = \text{target} - \text{next instruction}$$
$$= (08049000 + 0) - (804a033) = \text{FF FF EF CD} == -4147$$

Verify

$$804a033 + \text{FF FF EF CD} = 8049000 $$

**64bit**

In modern 64-bit systems (ELF64), the addend is often stored explicitly in the relocation table itself (this is called RELA). In 32-bit systems, the addend is usually stored "implicitly" in the section data itself (called REL).

Assembler puts 00 00 00 00 and store the offset (addend) in relocation table it self, calculation remains same

```sh
$  nasm -f elf64 test.asm -o test.o
$ objdump -D test.o

Disassembly of section .text:

0000000000000000 <local_start>:
   0:   90                      nop
   1:   eb fd                   jmp    0 <local_start>

0000000000000003 <local_st>:
   3:   90                      nop

Disassembly of section .aaa:

0000000000000000 <local_1>:
   0:   90                      nop
   1:   90                      nop

0000000000000002 <local_2>:
   2:   66 b8 01 00             mov    $0x1,%ax
   6:   90                      nop
   7:   e9 00 00 00 00          jmp    c <local_2+0xa>
   c:   90                      nop
   d:   eb f1                   jmp    0 <local_1>
   f:   90                      nop
  10:   90                      nop
  11:   eb ef                   jmp    2 <local_2>
  13:   90                      nop
  14:   90                      nop
  15:   e9 00 00 00 00          jmp    1a <c0_2+0x15>

$ objdump -r test.o

RELOCATION RECORDS FOR [.aaa]:
OFFSET           TYPE              VALUE
0000000000000008 R_X86_64_PC32     .text-0x0000000000000004
0000000000000016 R_X86_64_PC32     .text-0x0000000000000001

$ ld -m elf_x86_64 file_1.o -o file_1.out
$ $ objdump -D file_1.out

Disassembly of section .text:

0000000000401000 <local_start>:
  401000:       90                      nop
  401001:       eb fd                   jmp    401000 <local_start>

0000000000401003 <local_st>:
  401003:       90                      nop

Disassembly of section .aaa:

0000000000402027 <local_1>:
  402027:       90                      nop
  402028:       90                      nop

0000000000402029 <local_2>:
  402029:       66 b8 01 00             mov    $0x1,%ax
  40202d:       90                      nop
  40202e:       e9 cd ef ff ff          jmp    401000 <local_start>
  402033:       90                      nop
  402034:       eb f1                   jmp    402027 <local_1>
  402036:       90                      nop
  402037:       90                      nop
  402038:       eb ef                   jmp    402029 <local_2>
  40203a:       90                      nop
  40203b:       90                      nop
  40203c:       e9 c2 ef ff ff          jmp    401003 <local_st>
```

**Linker calc**

- 401000 - 4 - 40202f = -1033 == FF FF EF CD
- 401000 - 1 - 40203d = -103E == FF FF EF C2 

### More

In x86 assembly, jumps are generally categorized by **how far** they can go and **how the target address is determined**.

Beyond the **Short** and **Near** relative jumps we just analyzed, there are three other major categories you should know:

---

#### 1. Far Jumps (Inter-segment Jumps)

While Short and Near jumps move within the same code segment, a **Far Jump** changes the Code Segment (`CS`) register itself. These are used in low-level OS development (like switching from Real Mode to Protected Mode).

* **Opcode:** `EA`
* **Target:** It uses a full 48-bit pointer (16-bit segment selector + 32-bit offset).
* **Behavior:** It doesn't use a relative offset. It tells the CPU: "Go to this specific segment and this specific absolute address."

---

#### 2. Indirect Jumps

In our previous examples, the target was "hardcoded" as a relative value in the instruction. In an **Indirect Jump**, the target address is stored in a register or a memory location.

* **Examples:**
* `jmp eax` (Jump to the address currently held in EAX).
* `jmp [ebx]` (Jump to the address stored at the memory location pointed to by EBX).


* **Why use them?** They are essential for **switch statements** (using jump tables) and **virtual function calls** in C++. Because the target isn't known until the program is running, the linker doesn't use the  formula here.

---

#### 3. Conditional Jumps (`Jcc`)

These jumps only happen if specific bits in the **EFLAGS** register (like the Zero Flag or Carry Flag) are set.

* **Opcodes:** `0x70` through `0x7F` (Short) or `0x0F 0x80` through `0x0F 0x8F` (Near).
* **Common types:**
* `je` / `jz`: Jump if Equal / Zero.
* `jne` / `jnz`: Jump if Not Equal / Not Zero.
* `jg` / `jl`: Jump if Greater / Less (Signed).
* `ja` / `jb`: Jump if Above / Below (Unsigned).


* **Note:** In modern x86, conditional jumps can be **Short** (1-byte offset) or **Near** (4-byte offset), but they are **never Far**.


#### jump bwtween 2 files

#### A Quick Tip on Optimization

The CPU is very good at predicting **Relative Jumps** because the target is static. **Indirect Jumps** are harder for the CPU to predict (look up "Branch Prediction"), which is why deep inheritance in C++ or massive switch statements can sometimes slow down a high-performance loop!