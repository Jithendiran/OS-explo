How global symbols relocation happens? 

```s
global global_code_1 
extern a;

section .text
global_code_1:          
    mov ax, 0x1111
    mov ax, [a]

local_code_1:          
    nop

section .data
    db 0x11, 0x11
```

```
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
  Number of section headers:         7
  Section header string table index: 3

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000160 00000b 00  AX  0   0 16
  [ 2] .data             PROGBITS        00000000 000170 000002 00  WA  0   0  4
  [ 3] .shstrtab         STRTAB          00000000 000180 000031 00      0   0  1
  [ 4] .symtab           SYMTAB          00000000 0001c0 000070 10      5   5  4
  [ 5] .strtab           STRTAB          00000000 000230 000029 00      0   0  1
  [ 6] .rel.text         REL             00000000 000260 000008 08      4   1  4
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rel.text' at offset 0x260 contains 1 entry:
 Offset     Info    Type            Sym.Value  Sym. Name
00000006  00000501 R_386_32          00000000   a
No processor specific unwind information to decode

Symbol table '.symtab' contains 7 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS file_1.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .data
     4: 0000000a     0 NOTYPE  LOCAL  DEFAULT    1 local_code_1
     5: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND a
     6: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 global_code_1

No version information found in this file.

$ objdump -D file_1.o

file_1.o:     file format elf32-i386


Disassembly of section .text:

00000000 <global_code_1>:
   0:   66 b8 11 11             mov    $0x1111,%ax
   4:   66 a1 00 00 00 00       mov    0x0,%ax

0000000a <local_code_1>:
   a:   90                      nop

Disassembly of section .data:

00000000 <.data>:
   0:   11 11                   adc    %edx,(%ecx)



$ nasm -f elf32 file_2.asm -o file_2.o

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

$ readelf -a file_2.o 
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

**Section Headers**
    Section header is a table which contains details every sections in the file
    This table has both relocatable and non-relocatable section

    How the it is consider as relocatable section

    Flag column `A` (Alloc) flag means it require allocation in RAM when program runs, if A flag is not present for a section then it is just a "paper work" for linker

    Type column also useful to determince the section is relocatable or not 
    - `PROGBITS` means  "Program Bits", linker don't know what this section about, this may be data or code,.. linker doesn't care about this section. it just knows it belongs to the final binary.

    - `SYMTAB / STRTAB` These are internal ELF structures. The linker "consumes" these to do its job. It is only for linker purpose, it will not be in part of final binary

    
    In our example section `.text` and `.data` are needs to be part of final binary, linker only knows the final address, so assembler  create a symbol table entry for these two sections

**Symbol Table**
    In the ELF world, the Symbol Table is a list of names that represent memory locations the program might need to reference during execution or relocation.

    - .text and .data are sections that contain your actual code and variables. The linker needs to move these around and calculate offsets relative to their start.
    - other sections are only for linker execution, so no symbol entry is created

    For relocation more important columns are Ndx, Bind
    If ndx is `UND` undefined which means this symbols have no definition in this file it must be part of other files
    bind says it is a local or global scope
    ABS (Absolute): The symbol isn't relative to any section (like a hardcoded constant).

     symbols
     `global_code_1` is marked as global in asm it's bind type is global and it is defined in .text section it's ndx is points to text section index
     `a` it has extern keyword, when compiler see this it create a Global bind and mark it as UND, because it is not defined in any of sections in this file

    
    The "Master Global List" is a conceptual internal structure the linker uses while it's working, but you can see the result of it in two ways:
```sh
$ ld -m elf_i386 file_1.o file_2.o -M > program.map
1. Open file and load
```
ld: mode elf_i386
attempt to open file_1.o succeeded
file_1.o
attempt to open file_2.o succeeded
file_2.o
```

2. start sections in ascending order and assign address for each


let's skip all other things look only needed 

read .text from file_1.o
```
.text          0x08049000        0xb file_1.o
                0x08049000                global_code_1
```

For global_code_1 it asigns address

Then it read .text from file_2.o

3. then read other sectiosn 

```
.cs             0x0804a000        0x1
 .cs            0x0804a000        0x1 file_2.o
                0x0804a000                a

.code           0x0804a001       0x11
 .code          0x0804a001       0x11 file_2.o

.ji             0x0804a012        0x2
 .ji            0x0804a012        0x2 file_2.o
                0x0804a013                b
```

here we noticed address is assigned only for global symbols all the local symbols are handled internally
```
```sh
$ nm a.out
0804a000 R a
0804a013 R b
0804b016 D __bss_start
0804b016 D _edata
0804b018 D _end
08049000 T global_code_1
0804a012 r loc
0804900a t local_code_1
         U _start
```

Collection: Linker reads file_1.o. It sees global_code_1 (Bind: Global, Ndx: 1). It adds global_code_1 to its internal "Master List" with a pointer to file_1.o.

Resolution: Linker reads file_1.o again and sees a Relocation Record for a (Bind: Global, Ndx: UND).

The Search: The linker looks at its Master List.
    If file_2.o defined a as Global, the linker finds it.
    The linker now knows the Address of a and the Address of the instruction in file_1.o.

The Patch: The linker performs the math ($S + A$) and writes the real address of a into the bytes of file_1.o.



How the Linker handles them during the Flow
Input: The linker reads file_1.o.
Filter: It looks at the Section Headers. It sees .text has the A flag. It says: "I need to find a home for this in RAM."
Merge: It finds all other .text sections from other files and puts them together.
Relocate: Because it moved .text to a new home (e.g., 0x08049000), it now looks at the .rel.text section to see which "holes" inside .text need to be patched with the new addresses.
Discard: It sees .symtab and .strtab. It uses them to resolve the names, but then it usually discards them or puts them at the very end of the file, completely outside the "Loadable" segments.