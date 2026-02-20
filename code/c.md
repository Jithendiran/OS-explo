## C and asm

### Call from NASM
Call from asm

```c
// main.c
int test_func(int a, int b) {
	int c = a + b;
	return c;
}
```

```sh
$ gcc main.c --freestanding -fno-pic -m32 -fno-stack-protector   -fno-asynchronous-unwind-tables -O2 -c -o main.o
$ readelf -a main.o
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
  Start of section headers:          256 (bytes into file)
  Flags:                             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           40 (bytes)
  Number of section headers:         9
  Section header string table index: 8

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000040 000009 00  AX  0   0 16
  [ 2] .data             PROGBITS        00000000 000049 000000 00  WA  0   0  1
  [ 3] .bss              NOBITS          00000000 000049 000000 00  WA  0   0  1
  [ 4] .comment          PROGBITS        00000000 000049 00002c 01  MS  0   0  1
  [ 5] .note.GNU-stack   PROGBITS        00000000 000075 000000 00      0   0  1
  [ 6] .symtab           SYMTAB          00000000 000078 000030 10      7   2  4
  [ 7] .strtab           STRTAB          00000000 0000a8 000012 00      0   0  1
  [ 8] .shstrtab         STRTAB          00000000 0000ba 000045 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

There are no relocations in this file.
No processor specific unwind information to decode

Symbol table '.symtab' contains 3 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS main.c
     2: 00000000     9 FUNC    GLOBAL DEFAULT    1 test_func

No version information found in this file.

$ objdump -D main.o

main.o:     file format elf32-i386


Disassembly of section .text:

00000000 <test_func>:
   0:	67 66 8b 44 24       	mov    0x24(%si),%ax
   5:	08 67 66             	or     %ah,0x66(%edi)
   8:	03 44 24 04          	add    0x4(%esp),%eax
   c:	66 c3                	retw

Disassembly of section .comment:

00000000 <.comment>:
   0:	00 47 43             	add    %al,0x43(%edi)
   3:	43                   	inc    %ebx
   4:	3a 20                	cmp    (%eax),%ah
   6:	28 55 62             	sub    %dl,0x62(%ebp)
   9:	75 6e                	jne    79 <test_func+0x79>
   b:	74 75                	je     82 <test_func+0x82>
   d:	20 31                	and    %dh,(%ecx)
   f:	33 2e                	xor    (%esi),%ebp
  11:	33 2e                	xor    (%esi),%ebp
  13:	30 2d 36 75 62 75    	xor    %ch,0x75627536
  19:	6e                   	outsb  %ds:(%esi),(%dx)
  1a:	74 75                	je     91 <test_func+0x91>
  1c:	32 7e 32             	xor    0x32(%esi),%bh
  1f:	34 2e                	xor    $0x2e,%al
  21:	30 34 29             	xor    %dh,(%ecx,%ebp,1)
  24:	20 31                	and    %dh,(%ecx)
  26:	33 2e                	xor    (%esi),%ebp
  28:	33 2e                	xor    (%esi),%ebp
  2a:	30 00                	xor    %al,(%eax)
```

For standalone program  like bootloader or OS the above function can be used, to run inside regular linux we need sections which throwed away by `--freestanding ` and other flags

use this options `gcc -m32 -O1 -c main.c -o main.o` to run inside linux

```asm
; call_test.s
section .text
    global _start       ; Entry point for the linker
    extern test_func    

_start:
    
    ; Push arguments onto the stack in reverse order
    push 20             ; Push 'b'
    push 10             ; Push 'a'

    ; Call the function
    call test_func      ; After this, eax will contain 30 (10 + 20)

    ; Clean up the stack (2 arguments * 4 bytes each = 8 bytes)
    add esp, 8

    ; Exit Program
    mov ebx, eax        ; ebx = 30
    mov eax, 1          ; sys_exit syscall number
    int 0x80            ; Trigger interrupt

    section .note.GNU-stack noalloc noexec nowrite progbits ; this is only require to run inside linux
```

```sh
$ nasm -f elf32 call_test.s -o call_test.o
$ readelf -a call_test.o
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
  Number of section headers:         6
  Section header string table index: 2

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000130 000015 00  AX  0   0 16
  [ 2] .shstrtab         STRTAB          00000000 000150 00002b 00      0   0  1
  [ 3] .symtab           SYMTAB          00000000 000180 000050 10      4   3  4
  [ 4] .strtab           STRTAB          00000000 0001d0 000020 00      0   0  1
  [ 5] .rel.text         REL             00000000 0001f0 000008 08      3   1  4
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rel.text' at offset 0x1f0 contains 1 entry:
 Offset     Info    Type            Sym.Value  Sym. Name
00000005  00000302 R_386_PC32        00000000   test_func
No processor specific unwind information to decode

Symbol table '.symtab' contains 5 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS call_test.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND test_func
     4: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 _start

No version information found in this file.

$ objdump -D call_test.o

call_test.o:     file format elf32-i386


Disassembly of section .text:

00000000 <_start>:
   0:	6a 14                	push   $0x14
   2:	6a 0a                	push   $0xa
   4:	e8 fc ff ff ff       	call   5 <_start+0x5>
   9:	83 c4 08             	add    $0x8,%esp
   c:	89 c3                	mov    %eax,%ebx
   e:	b8 01 00 00 00       	mov    $0x1,%eax
  13:	cd 80                	int    $0x80

$ ld -m elf_i386 call_test.o main.o -o my_program
$ ./my_program
```

### Call in two ways

```asm
;call_test.asm
section .text
    global _start
    global asm_math      ; Export this so C can call it
    extern test_func     ; Import from C

_start:
    push 20              ; arg b
    push 10              ; arg a
    call test_func       ; Jump to C
    add esp, 8

    mov ebx, eax        
    mov eax, 1          
    int 0x80

; This is the function C will call
asm_math:
    push ebp             ; Standard prologue
    mov ebp, esp

    mov eax, [ebp + 8]   ; Get first argument
    add eax, 5           ; Add 5 just for fun

    pop ebp              ; Standard epilogue
    ret                  ; Return to C

section .note.GNU-stack noalloc noexec nowrite progbits ; This is need for linux execution
```

```c
extern int asm_math(int value); // Take from asm, without thos c compiler will provide warning

int test_func(int a, int b) {
    int sum = a + b;           // 10 + 20 = 30
    int final = asm_math(sum); // Call Assembly: 30 + 5 = 35
    return final;
}
```

```sh
# 1. Compile C
$ gcc -m32  -fno-stack-protector -O0 -c main.c -o main.o
$ objdump -d main.o 

main.o:     file format elf32-i386


Disassembly of section .text:

00000000 <test_func>:
   0:   55                      push   %ebp
   1:   89 e5                   mov    %esp,%ebp
   3:   53                      push   %ebx
   4:   83 ec 14                sub    $0x14,%esp
   7:   e8 fc ff ff ff          call   8 <test_func+0x8>
   c:   05 01 00 00 00          add    $0x1,%eax
  11:   8b 4d 08                mov    0x8(%ebp),%ecx
  14:   8b 55 0c                mov    0xc(%ebp),%edx
  17:   01 ca                   add    %ecx,%edx
  19:   89 55 f4                mov    %edx,-0xc(%ebp)
  1c:   83 ec 0c                sub    $0xc,%esp
  1f:   ff 75 f4                push   -0xc(%ebp)
  22:   89 c3                   mov    %eax,%ebx
  24:   e8 fc ff ff ff          call   25 <test_func+0x25>
  29:   83 c4 10                add    $0x10,%esp
  2c:   89 45 f0                mov    %eax,-0x10(%ebp)
  2f:   8b 45 f0                mov    -0x10(%ebp),%eax
  32:   8b 5d fc                mov    -0x4(%ebp),%ebx
  35:   c9                      leave
  36:   c3                      ret

Disassembly of section .text.__x86.get_pc_thunk.ax:

00000000 <__x86.get_pc_thunk.ax>:
   0:   8b 04 24                mov    (%esp),%eax
   3:   c3                      ret

$ readelf -a main.o 
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
  Start of section headers:          604 (bytes into file)
  Flags:                             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           40 (bytes)
  Number of section headers:         14
  Section header string table index: 13

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .group            GROUP           00000000 000034 000008 04     11   5  4
  [ 2] .text             PROGBITS        00000000 00003c 000037 00  AX  0   0  1
  [ 3] .rel.text         REL             00000000 0001b8 000018 08   I 11   2  4
  [ 4] .data             PROGBITS        00000000 000073 000000 00  WA  0   0  1
  [ 5] .bss              NOBITS          00000000 000073 000000 00  WA  0   0  1
  [ 6] .text.__x86.[...] PROGBITS        00000000 000073 000004 00 AXG  0   0  1
  [ 7] .comment          PROGBITS        00000000 000077 00002c 01  MS  0   0  1
  [ 8] .note.GNU-stack   PROGBITS        00000000 0000a3 000000 00      0   0  1
  [ 9] .eh_frame         PROGBITS        00000000 0000a4 000050 00   A  0   0  4
  [10] .rel.eh_frame     REL             00000000 0001d0 000010 08   I 11   9  4
  [11] .symtab           SYMTAB          00000000 0000f4 000080 10     12   4  4
  [12] .strtab           STRTAB          00000000 000174 000044 00      0   0  1
  [13] .shstrtab         STRTAB          00000000 0001e0 00007a 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

COMDAT group section [    1] `.group' [__x86.get_pc_thunk.ax] contains 1 sections:
   [Index]    Name
   [    6]   .text.__x86.get_pc_thunk.ax

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rel.text' at offset 0x1b8 contains 3 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
00000008  00000502 R_386_PC32        00000000   __x86.get_pc_thunk.ax
0000000d  0000060a R_386_GOTPC       00000000   _GLOBAL_OFFSET_TABLE_
00000025  00000704 R_386_PLT32       00000000   asm_math

Relocation section '.rel.eh_frame' at offset 0x1d0 contains 2 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
00000020  00000202 R_386_PC32        00000000   .text
00000044  00000302 R_386_PC32        00000000   .text.__x86.get_p[...]
No processor specific unwind information to decode

Symbol table '.symtab' contains 8 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS main.c
     2: 00000000     0 SECTION LOCAL  DEFAULT    2 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    6 .text.__x86.get_[...]
     4: 00000000    55 FUNC    GLOBAL DEFAULT    2 test_func
     5: 00000000     0 FUNC    GLOBAL HIDDEN     6 __x86.get_pc_thunk.ax
     6: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND _GLOBAL_OFFSET_TABLE_
     7: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND asm_math

No version information found in this file.

# 2. Assemble
$ nasm -f elf32 call_test.asm -o call_test.o

$ readelf -a call_test.o 
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
  [ 1] .text             PROGBITS        00000000 000160 000020 00  AX  0   0 16
  [ 2] .note.GNU-stack   PROGBITS        00000000 000180 000000 00      0   0  1
  [ 3] .shstrtab         STRTAB          00000000 000180 00003b 00      0   0  1
  [ 4] .symtab           SYMTAB          00000000 0001c0 000070 10      5   4  4
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
00000005  00000402 R_386_PC32        00000000   test_func
No processor specific unwind information to decode

Symbol table '.symtab' contains 7 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS call_test.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .note.GNU-stack
     4: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND test_func
     5: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 _start
     6: 00000015     0 NOTYPE  GLOBAL DEFAULT    1 asm_math

No version information found in this file.

$ objdump -d call_test.o 

call_test.o:     file format elf32-i386


Disassembly of section .text:

00000000 <_start>:
   0:   6a 14                   push   $0x14
   2:   6a 0a                   push   $0xa
   4:   e8 fc ff ff ff          call   5 <_start+0x5>
   9:   83 c4 08                add    $0x8,%esp
   c:   89 c3                   mov    %eax,%ebx
   e:   b8 01 00 00 00          mov    $0x1,%eax
  13:   cd 80                   int    $0x80

00000015 <asm_math>:
  15:   55                      push   %ebp
  16:   89 e5                   mov    %esp,%ebp
  18:   8b 45 08                mov    0x8(%ebp),%eax
  1b:   83 c0 05                add    $0x5,%eax
  1e:   5d                      pop    %ebp
  1f:   c3                      ret

# 3. Link
$ ld -m elf_i386 call_test.o main.o -o my_program

$ readelf -a my_program 
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           Intel 80386
  Version:                           0x1
  Entry point address:               0x8049000
  Start of program headers:          52 (bytes into file)
  Start of section headers:          12692 (bytes into file)
  Flags:                             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         6
  Size of section headers:           40 (bytes)
  Number of section headers:         8
  Section header string table index: 7

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        08049000 001000 00005b 00  AX  0   0 16
  [ 2] .eh_frame         PROGBITS        0804a000 002000 000050 00   A  0   0  4
  [ 3] .got.plt          PROGBITS        0804bff4 002ff4 00000c 04  WA  0   0  4
  [ 4] .comment          PROGBITS        00000000 003000 00002b 01  MS  0   0  1
  [ 5] .symtab           SYMTAB          00000000 00302c 0000c0 10      6   5  4
  [ 6] .strtab           STRTAB          00000000 0030ec 00006a 00      0   0  1
  [ 7] .shstrtab         STRTAB          00000000 003156 00003d 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

There are no section groups in this file.

Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  LOAD           0x000000 0x08048000 0x08048000 0x000f4 0x000f4 R   0x1000
  LOAD           0x001000 0x08049000 0x08049000 0x0005b 0x0005b R E 0x1000
  LOAD           0x002000 0x0804a000 0x0804a000 0x00050 0x00050 R   0x1000
  LOAD           0x002ff4 0x0804bff4 0x0804bff4 0x0000c 0x0000c RW  0x1000
  GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0x10
  GNU_RELRO      0x002ff4 0x0804bff4 0x0804bff4 0x0000c 0x0000c R   0x1

 Section to Segment mapping:
  Segment Sections...
   00     
   01     .text 
   02     .eh_frame 
   03     .got.plt 
   04     
   05     .got.plt 

There is no dynamic section in this file.

There are no relocations in this file.
No processor specific unwind information to decode

Symbol table '.symtab' contains 12 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS call_test.asm
     2: 00000000     0 FILE    LOCAL  DEFAULT  ABS main.c
     3: 00000000     0 FILE    LOCAL  DEFAULT  ABS 
     4: 0804bff4     0 OBJECT  LOCAL  DEFAULT    3 _GLOBAL_OFFSET_TABLE_
     5: 08049020    55 FUNC    GLOBAL DEFAULT    1 test_func
     6: 08049057     0 FUNC    GLOBAL HIDDEN     1 __x86.get_pc_thunk.ax
     7: 08049000     0 NOTYPE  GLOBAL DEFAULT    1 _start
     8: 08049015     0 NOTYPE  GLOBAL DEFAULT    1 asm_math
     9: 0804c000     0 NOTYPE  GLOBAL DEFAULT    3 __bss_start
    10: 0804c000     0 NOTYPE  GLOBAL DEFAULT    3 _edata
    11: 0804c000     0 NOTYPE  GLOBAL DEFAULT    3 _end

No version information found in this file.

$ objdump -d my_program 

my_program:     file format elf32-i386


Disassembly of section .text:

08049000 <_start>:
 8049000:       6a 14                   push   $0x14
 8049002:       6a 0a                   push   $0xa
 8049004:       e8 17 00 00 00          call   8049020 <test_func>
 8049009:       83 c4 08                add    $0x8,%esp
 804900c:       89 c3                   mov    %eax,%ebx
 804900e:       b8 01 00 00 00          mov    $0x1,%eax
 8049013:       cd 80                   int    $0x80

08049015 <asm_math>:
 8049015:       55                      push   %ebp
 8049016:       89 e5                   mov    %esp,%ebp
 8049018:       8b 45 08                mov    0x8(%ebp),%eax
 804901b:       83 c0 05                add    $0x5,%eax
 804901e:       5d                      pop    %ebp
 804901f:       c3                      ret

08049020 <test_func>:
 8049020:       55                      push   %ebp
 8049021:       89 e5                   mov    %esp,%ebp
 8049023:       53                      push   %ebx
 8049024:       83 ec 14                sub    $0x14,%esp
 8049027:       e8 2b 00 00 00          call   8049057 <__x86.get_pc_thunk.ax>
 804902c:       05 c8 2f 00 00          add    $0x2fc8,%eax
 8049031:       8b 4d 08                mov    0x8(%ebp),%ecx
 8049034:       8b 55 0c                mov    0xc(%ebp),%edx
 8049037:       01 ca                   add    %ecx,%edx
 8049039:       89 55 f4                mov    %edx,-0xc(%ebp)
 804903c:       83 ec 0c                sub    $0xc,%esp
 804903f:       ff 75 f4                push   -0xc(%ebp)
 8049042:       89 c3                   mov    %eax,%ebx
 8049044:       e8 cc ff ff ff          call   8049015 <asm_math>
 8049049:       83 c4 10                add    $0x10,%esp
 804904c:       89 45 f0                mov    %eax,-0x10(%ebp)
 804904f:       8b 45 f0                mov    -0x10(%ebp),%eax
 8049052:       8b 5d fc                mov    -0x4(%ebp),%ebx
 8049055:       c9                      leave
 8049056:       c3                      ret

08049057 <__x86.get_pc_thunk.ax>:
 8049057:       8b 04 24                mov    (%esp),%eax
 804905a:       c3                      ret

# 4. Run
$ ./my_program
$ echo $?
35
```