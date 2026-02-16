## ELF (Executable and Linkable Format) relocation process

### Concepts
#### The ELF Section Header Table
The Section Header Table is the "map" of an object file. It tells the linker exactly where each block of data is located, what it contains, and how it should be treated during the transition from a relocatable file (.o) to a final executable.

**Identifying reloc and non reloc Sections**
Not every section in an object file ends up in the final program. The linker uses two primary columns to decide a section's fate:
1. The Flag Column: A (ALLOC)

    - Presence of A: This section is "Allocatable." It must be loaded into RAM when the program executes. These are the functional parts of your code (like .text, .data, or .rodata).
    - Absence of A: This section is merely "administrative paperwork" for the linker. It exists only within the .o file to help build the binary. Once the linker finishes, these sections (like .rel.text or .shstrtab) are usually discarded and do not occupy RAM at runtime.

2. The Type Column
    - PROGBITS (Program Bits): This is a "black box" to the linker. It tells the linker: "The contents of this section are defined by the user (code or data). Don't try to interpret the bits; just copy them into the final binary at the assigned address."
    - SYMTAB / STRTAB: These are internal ELF structures. The Symbol Table (SYMTAB) and String Table (STRTAB) are used by the linker to look up names like global_code_1. These are "consumed" during the linking process and are not part of the program's logic.
    - REL (Relocation): These are the "To-Do" lists. They tell the linker exactly which bytes in the PROGBITS sections need to be patched once the final memory addresses are known.

#### Symbol table 

1. Ndx Column
    Ndx column has the index of symbol's respective section index form section table 
    - UND : undefined (Not present in any of the this file sections)
    - ABS : It is hard coded value
    - <num>: section index

2. Bind column 
    Bind has the visiblility
    - if we define a symbol Global, it will be a  GLOBAL
    - if we define a symbol extern, Ndx become UND and bind become GLOBAL
    - other symbols are local to this file


**The assembler creates symbol records for things that need the linker's help.**

### Program Used
```asm
;file_1.asm
global global_code_1 
extern a;

section .text
nop
nop
global_code_1:          
    mov ax, 0x1111
    mov ax, [a]
    jmp global_code_1

local_code_1:          
    nop

section .data
    db 0x11, 0x11
    jmp global_code_1
```

```asm
;file_2.asm
global a
extern global_code_1
global b

section .cs
a:
    db 0x00

section .text
    jmp global_code_1

section .code
    jmp global_code_1
    mov ax, [loc]
    mov ax, [b]

section .ji
loc:
    db 0x0

b:
    db 0x0

```

### Archology

**file_1**

```sh
$ nasm -f elf32 file_1.asm -o file_1.o
$ readelf -a file_1.o 
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              REL (Relocatable file)
  Machine:                           Intel 80386
  Version:                           0x1
  Entry point address:               0x0
  Start of program headers:          0 (bytes into file)
  Start of section headers:          64 (bytes into file)
  Flags:                             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           40 (bytes)
  Number of section headers:         8
  Section header string table index: 3

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000180 00000f 00  AX  0   0 16
  [ 2] .data             PROGBITS        00000000 000190 000007 00  WA  0   0  4
  [ 3] .shstrtab         STRTAB          00000000 0001a0 00003b 00      0   0  1
  [ 4] .symtab           SYMTAB          00000000 0001e0 000070 10      5   5  4
  [ 5] .strtab           STRTAB          00000000 000250 000029 00      0   0  1
  [ 6] .rel.text         REL             00000000 000280 000008 08      4   1  4
  [ 7] .rel.data         REL             00000000 000290 000008 08      4   2  4
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rel.text' at offset 0x280 contains 1 entry:
 Offset     Info    Type            Sym.Value  Sym. Name
00000008  00000501 R_386_32          00000000   a

Relocation section '.rel.data' at offset 0x290 contains 1 entry:
 Offset     Info    Type            Sym.Value  Sym. Name
00000003  00000202 R_386_PC32        00000000   .text
No processor specific unwind information to decode

Symbol table '.symtab' contains 7 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS file_1.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .data
     4: 0000000e     0 NOTYPE  LOCAL  DEFAULT    1 local_code_1
     5: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND a
     6: 00000002     0 NOTYPE  GLOBAL DEFAULT    1 global_code_1

No version information found in this file.
```

#### Symbol table

1. Section

    The assembler creates symbol entries for .text and .data. Because the linker might merge .text from file_1.o with .text from file_2.o. To calculate the final address of anything inside those sections, the linker first needs to know where the start of the section landed. These act as the "base" for all internal offsets.

2. Symbols

    **Global**
    Symbols like global_code_1 (defined here) and a (extern/undefined) must be in the symbol table.
    - global_code_1: The assembler marks this as GLOBAL. It tells the linker: "If any other file needs this address, here is where it is relative to my .text section."
    - a: The assembler marks this as UND (Undefined). It tells the linker: "I don't know what this is. Please find a symbol named a in another file and plug its address in here."

    **Local**
    Symbols like local_code_1 are usually kept in the relocatable object file's symbol table to help with debugging and local relocations, but they are marked as LOCAL.

#### Relocation Tables

##### .text

In this section, we used two symbols: `global_code_1` and `a`. However, there is only **one** relocation entry (for `a`).

* **Why is `global_code_1` missing?** Because `global_code_1` is inside the same `.text` section. The assembler already knows its relative offset from the start of the section. Since the whole section moves as one block, the distance between the instruction and the symbol never changes. The assembler "pre-calculates" this, so the linker has no extra work to do.

* **Why is `a` there?** Because `a` is `extern`. The assembler has no idea where `a` lives or even which section it's in. It puts `00 00 00 00` as a placeholder in the code and creates a relocation entry.

    **Crucial Detail:** In the `Sym. Name` column for this relocation, you see the actual name **"a"**. This is because the assembler doesn't even know which section to point to yet.

#### .data

In the `.data` section, we reference `global_code_1`. This time, a relocation entry **is** created, but it looks different.

* **The "Cross-Section" Problem:** Even though `global_code_1` is in this file, it's in a **different section** (`.text` vs `.data`). The assembler knows the offset *within* `.text`, but it doesn't know where the linker will eventually place `.text` relative to `.data` in RAM.

* **The Reference Style:** Look at the `Sym. Name` for this entry: it says **`.text`**, not `global_code_1`.
    * Since the assembler knows `global_code_1` belongs to `.text`, it tells the linker: *"Find where the `.text` section ends up, and then add this specific offset to find the symbol."*
    * If you look at the raw bytes in `.data` (using `objdump`), you'll see a small value like `fe ff ff ff` (-2) already stored there. This is the "Addend" the internal offset within the target section.

```sh
$ objdump -D file_1.o

file_1.o:     file format elf32-i386


Disassembly of section .text:

00000000 <global_code_1-0x2>:
   0:   90                      nop
   1:   90                      nop

00000002 <global_code_1>:
   2:   66 b8 11 11             mov    $0x1111,%ax
   6:   66 a1 00 00 00 00       mov    0x0,%ax
   c:   eb f4                   jmp    2 <global_code_1>

0000000e <local_code_1>:
   e:   90                      nop

Disassembly of section .data:

00000000 <.data>:
   0:   11 11                   adc    %edx,(%ecx)
   2:   e9 fe ff ff ff          jmp    5 <.data+0x5>
```

When the assembler creates `file_1.o`, it leaves **placeholders** in the machine code. These values aren't random; they are specific clues for the linker.

##### 1. The `extern` Placeholder: `mov ax, [a]`

At offset **0x6** in the `.text` section:

* **The Code:** `66 a1 00 00 00 00`
* **The Observation:** The address for `a` is just zeros (`00 00 00 00`).
* **The Reason:** Because `a` is `extern`, the assembler is completely "blind." It doesn't know the address, the offset, or even which section `a` lives in. It leaves a blank slate (0) and creates a relocation entry telling the linker: *"Find the symbol 'a' and overwrite these zeros with its final address."*

##### 2. The Cross-Section Placeholder: `jmp global_code_1`

At offset **0x2** in the `.data` section (the `e9` instruction):

* **The Code:** `e9 fe ff ff ff`
* **The Observation:** The 4-byte value after the opcode is `fe ff ff ff`. In little-endian, this is **-2**.
* **The Reason:** The assembler knows `global_code_1` is at **offset 2** within the `.text` section. However, since the jump starts from the `.data` section, it doesn't know the final distance between `.data` and `.text`.
* **The Logic:** It uses a relative offset.
    * The relocation type here is `R_386_PC32` (Program Counter relative).
    * The jump is calculated from the end of the instruction (which is 4 bytes long).
    * The math: 
        $$-2\text{ (stored value)} + 4\text{ (instruction length)} = 2$$
    * This result (**2**) points exactly to the start of `global_code_1` within the target `.text` section.


**file_2**

```sh
$ nasm -f elf32 file_2.asm -o file_2.o
$ readelf -a file_2.o 
readelf -a file_2.o 
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              REL (Relocatable file)
  Machine:                           Intel 80386
  Version:                           0x1
  Entry point address:               0x0
  Start of program headers:          0 (bytes into file)
  Start of section headers:          64 (bytes into file)
  Flags:                             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           40 (bytes)
  Number of section headers:         10
  Section header string table index: 5

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .cs               PROGBITS        00000000 0001d0 000001 00   A  0   0  1
  [ 2] .text             PROGBITS        00000000 0001e0 000005 00  AX  0   0 16
  [ 3] .code             PROGBITS        00000000 0001f0 000011 00   A  0   0  1
  [ 4] .ji               PROGBITS        00000000 000210 000002 00   A  0   0  1
  [ 5] .shstrtab         STRTAB          00000000 000220 000043 00      0   0  1
  [ 6] .symtab           SYMTAB          00000000 000270 0000a0 10      7   7  4
  [ 7] .strtab           STRTAB          00000000 000310 000022 00      0   0  1
  [ 8] .rel.text         REL             00000000 000340 000008 08      6   2  4
  [ 9] .rel.code         REL             00000000 000350 000018 08      6   3  4
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rel.text' at offset 0x340 contains 1 entry:
 Offset     Info    Type            Sym.Value  Sym. Name
00000001  00000702 R_386_PC32        00000000   global_code_1

Relocation section '.rel.code' at offset 0x350 contains 3 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
00000001  00000702 R_386_PC32        00000000   global_code_1
00000007  00000501 R_386_32          00000000   .ji
0000000d  00000501 R_386_32          00000000   .ji
No processor specific unwind information to decode

Symbol table '.symtab' contains 10 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS file_2.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .cs
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .text
     4: 00000000     0 SECTION LOCAL  DEFAULT    3 .code
     5: 00000000     0 SECTION LOCAL  DEFAULT    4 .ji
     6: 00000000     0 NOTYPE  LOCAL  DEFAULT    4 loc
     7: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND global_code_1
     8: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 a
     9: 00000001     0 NOTYPE  GLOBAL DEFAULT    4 b

No version information found in this file.
```

#### Symbol table

* In the Symbol Table, the assembler created entries for `.cs`, `.text`, `.code`, and `.ji`.

    **Why?** Since these are custom sections, the linker needs to know where each one begins. Just like with `.text` in `file_1`, these section symbols have `A` flag.

* **`global_code_1` (The Outsider):** * Marked as `UND` (Undefined) and `GLOBAL`.
    *This tells the linker: *"I don't have this code here. Look for it in another file (like `file_1.o`) and give me its address later."*

* **`a` and `b` (The Exports):**
    * **`a`** is at `Ndx 1` (the `.cs` section).
    * **`b`** is at `Ndx 4` (the `.ji` section).
    * Since they are marked `GLOBAL`, they are "exported." Other files (like `file_1.o`) can now see and use them.

#### Relocation table

##### .text
The assembler knows we want to jump to `global_code_1`, but since that symbol is `UND` (Undefined), It don't know the final section so it leaves the `Sym. Name` as `global_code_1`

#### .code
- The assembler knows symbol `loc` and `b` are form `.ji` section because these symbols are part of this file so it kept `.ji` in `Sym. Name`
- The assembler don't knows the final section for symbol `global_code_1` so it kept the symbol name as it is

No relocation table created for `.cs` and `.ji` because these sections don't use any external section symbols internally 

```sh
$ objdump -D file_2.o

file_2.o:     file format elf32-i386


Disassembly of section .cs:

00000000 <a>:
        ...

Disassembly of section .text:

00000000 <.text>:
   0:   e9 fc ff ff ff          jmp    1 <.text+0x1>

Disassembly of section .code:

00000000 <.code>:
   0:   e9 fc ff ff ff          jmp    1 <.code+0x1>
   5:   66 a1 00 00 00 00       mov    0x0,%ax
   b:   66 a1 01 00 00 00       mov    0x1,%ax

Disassembly of section .ji:

00000000 <loc>:
        ...

00000001 <b>:
        ...
```

#### 1. The Undefined Jump: `jmp global_code_1`

In both `.text` and `.code`, you see the instruction: `e9 fc ff ff ff`.

* **The Bytes:** `e9` is the opcode for a 32-bit relative jump. The operand is `fc ff ff ff`, which is **-4** (32-bit two's complement).
* **The Math:** For `R_386_PC32` relocations, the formula the CPU uses is:

    $$\text{Target offset} = \text{legth of offset} + \text{Stored Offset}$$

    $$4 - 4 = 0$$

* **The Reason:** Because `global_code_1` is external, the assembler has no clue where it is. It sets the base to **0** (via the -4 value) and lets the linker add the actual distance later.


#### 2. The Internal Section Offsets: `loc` and `b`

Look at the `mov` instructions in the `.code` section:

* **For `loc`:** `66 a1 00 00 00 00` (Value = **0**)
* **For `b`:** `66 a1 01 00 00 00` (Value = **1**)
* **The Reason:** Both `loc` and `b` live in the `.ji` section.
    * The assembler knows `loc` is at the very beginning of `.ji` (**Offset 0**).
    * The assembler knows `b` is exactly one byte after `loc` (**Offset 1**).


> [!NOTE] `global_code_1`
> In file_1.o, the offset is 2 because the assembler knows the symbol's location within its own section, whereas in file_2.o, the offset is 0 because the symbol is external and the assembler has no local address information to provide.
    

#### Linking

```sh
$ ld -m elf_i386 file_1.o file_2.o --verbose -M --cref > program.map
```

```sh
ld: mode elf_i386
attempt to open file_1.o succeeded
file_1.o
attempt to open file_2.o succeeded
file_2.o
```

2. start section address assignment in ascending order

```sh
.rel.dyn        0x080480b4        0x0
.rel.got        0x080480b4        0x0 file_1.o
.rel.plt        0x080480b4        0x0
.rel.iplt       0x080480b4        0x0 file_1.o
.relr.dyn       0x08049000 
.plt            0x08049000        0x0
.iplt           0x08049000        0x0 file_1.o
.text           0x08049000        0x15

```

let's skip all other things look only needed 

read .text from file_1.o
```sh
 .text          0x08049000        0xf file_1.o
                0x08049002                global_code_1
```

For global_code_1 it asigns address

```sh
.text           0x08049010        0x5 file_2.o
.fini           0x0804a000
```

Then it read .text from file_2.o

3. then read other sectiosn 

```sh
.cs             0x0804a000        0x1
 .cs            0x0804a000        0x1 file_2.o
                0x0804a000                a

.code           0x0804a001       0x11
 .code          0x0804a001       0x11 file_2.o

.ji             0x0804a012        0x2
 .ji            0x0804a012        0x2 file_2.o
                0x0804a013                b
```

Till this our all global memory got address, Linker assign pull out each sections and global symbols in each file assign address  

4. Other sections base memory 

```sh
.exception_ranges    0x0804b014  
.tdata          0x0804b014        0x0
.preinit_array  0x0804b014        0x0
.init_array     0x0804b014        0x0
.fini_array     0x0804b014        0x0
.got            0x0804b014        0x0
.got            0x0804b014        0x0 file_1.o

.got.plt        0x0804b014        0x0
 *(.got.plt)
 .got.plt       0x0804b014        0x0 file_1.o
 *(.igot.plt)
 .igot.plt      0x0804b014        0x0 file_1.o

.data           0x0804b014        0x7
 *(.data .data.* .gnu.linkonce.d.*)
 .data          0x0804b014        0x7 file_1.o

.data1
 *(.data1)
                0x0804b01b                        _edata = .
                [!provide]                        PROVIDE (edata = .)
                0x0804b01c                        . = ALIGN (ALIGNOF (NEXT_SECTION))
                0x0804b01b                        __bss_start = .

.bss            0x0804b01b        0x0
 *(.dynbss)
 *(.bss .bss.* .gnu.linkonce.b.*)
 *(COMMON)
                0x0804b01b                        . = ALIGN ((. != 0x0)?0x4:0x1)
                0x0804b01c                        . = ALIGN (0x4)
                0x0804b01c                        . = SEGMENT_START ("ldata-segment", .)
                0x0804b01c                        . = ALIGN (0x4)
                0x0804b01c                        _end = .
                [!provide]                        PROVIDE (end = .)
                0x0804b01c                        . = DATA_SEGMENT_END (.)

```
5. Look the cross ref table, it tells which file has which global symbol
```sh
OUTPUT(a.out elf32-i386)

Cross Reference Table

Symbol                                            File
_GLOBAL_OFFSET_TABLE_                             file_1.o
a                                                 file_2.o
                                                  file_1.o
b                                                 file_2.o
global_code_1                                     file_1.o
                                                  file_2.o
```

here we noticed address is assigned only for global symbols all the local symbols are handled internally


```sh
$ nm a.out
0804a000 R a
0804a013 R b
0804b01b D __bss_start
0804b01b D _edata
0804b01c D _end
08049002 T global_code_1
0804a012 r loc
0804900e t local_code_1
         U _start
```

#### Maunal calc and cross verify

Address for variables will be allocated directly

Jump needs calculation

##### .data

e9 fe ff ff ff
    $$\text{Result} = S + A - P$$
    .data == `0x0804b014` + 3 (offset)
    symbol (global_code_1) == `08049002`
    $$\text{Result} = S + A - P = 08049002 + fffffffe  - 804b017=FF FF DF E9$$
    expected = FF FF DF E7

##### .text
e9 fc ff ff ff
    .text=`0x08049010` + 1 (offset)
    $$\text{Result} = S + A - P = 08049002 + fffffffc  - 08049011=FF FF FF ED$$

#### .code
e9 fc ff ff ff 
    .code=`0804a001` + 1 (Offser)
    $$\text{Result} = S + A - P = 08049002 + fffffffc  - 0804a002=FF FF EF FC$$

```sh
$ objdump -D a.out 

a.out:     file format elf32-i386


Disassembly of section .text:

08049000 <global_code_1-0x2>:
 8049000:       90                      nop
 8049001:       90                      nop

08049002 <global_code_1>:
 8049002:       66 b8 11 11             mov    $0x1111,%ax
 8049006:       66 a1 00 a0 04 08       mov    0x804a000,%ax
 804900c:       eb f4                   jmp    8049002 <global_code_1>

0804900e <local_code_1>:
 804900e:       90                      nop
 804900f:       90                      nop
 8049010:       e9 ed ff ff ff          jmp    8049002 <global_code_1>

Disassembly of section .cs:

0804a000 <a>:
        ...

Disassembly of section .code:

0804a001 <.code>:
 804a001:       e9 fc ef ff ff          jmp    8049002 <global_code_1>
 804a006:       66 a1 12 a0 04 08       mov    0x804a012,%ax
 804a00c:       66 a1 13 a0 04 08       mov    0x804a013,%ax

Disassembly of section .ji:

0804a012 <loc>:
        ...

0804a013 <b>:
        ...

Disassembly of section .data:

0804b014 <__bss_start-0x7>:
 804b014:       11 11                   adc    %edx,(%ecx)
 804b016:       e9 e7 df ff ff          jmp    8049002 <global_code_1>
```