# variable usage in nasm

The code used here 

```asm
section .custom_0
var_1:
    db 0x00
var_2:
    dw 0x00

section .text
var_3:
    db 0x00
    mov ax, [var_1]
    mov bx, [var_2]
    nop
    mov ax, [var_3]
    mov bx, [var_4]
    nop
    mov ax, [var_5]
    mov bx, [var_6]
var_4:
    dw 0x00


section .custom_1
var_5:
    db 0x00
var_6:
    dw 0x00
```

## 32 bit

```sh
$ nasm -f elf32 file_1.asm -o file_1_32.o
$ objdump -D file_1_32.o

file_1_32.o:     file format elf32-i386


Disassembly of section .custom_0:

00000000 <var_1>:
        ...

00000001 <var_2>:
        ...

Disassembly of section .text:

00000000 <var_3>:
   0:   00 66 a1                add    %ah,-0x5f(%esi)      ; 0 -> 00 ; 1 -> 66 a1 00 00 00 00    
   3:   00 00                   add    %al,(%eax)
   5:   00 00                   add    %al,(%eax)
   7:   66 8b 1d 01 00 00 00    mov    0x1,%bx
   e:   90                      nop
   f:   66 a1 00 00 00 00       mov    0x0,%ax
  15:   66 8b 1d 2a 00 00 00    mov    0x2a,%bx
  1c:   90                      nop
  1d:   66 a1 00 00 00 00       mov    0x0,%ax
  23:   66 8b 1d 01 00 00 00    mov    0x1,%bx

0000002a <var_4>:
        ...

Disassembly of section .custom_1:

00000000 <var_5>:
        ...

00000001 <var_6>:
        ...


$ objdump -r file_1_32.o


file_1_32.o:     file format elf32-i386

RELOCATION RECORDS FOR [.text]:
OFFSET   TYPE              VALUE
00000003 R_386_32          .custom_0
0000000a R_386_32          .custom_0
00000011 R_386_32          .text
00000018 R_386_32          .text
0000001f R_386_32          .custom_1
00000026 R_386_32          .custom_1
```

TYPE `R_386_32` is absolute placement offset, the offset stored in instruction is the offset from the section 
- As per relocation record 1st entry offset is `3` and type says it is 32 bit, the value is `00 00 00 00` meaning, `.custom_0`'s 0'th byte 
- 2nd entry offset is `a`, type 32 bit the value is `01 00 00 00` meaning, `.custom_0`'s 1'st byte 

in 32 bit even though var_3 and var_4 in it's local section it have relocation entry
- 3rd, offset `11` -> `00 00 00 00`, `.text` section's 0th byte
- 4th, offset `18` -> `2a 00 00 00 `, `.text` section's 2a(42)th byte

- 5th, offset `1f` -> `00 00 00 00 `,  `.custom_1` section's 0th byte
- 6th, offset `26` -> `01 00 00 00 `, `.custom_1` section's 1'st byte 

```sh
$ ld -m elf_i386 file_1_32.o -o file_1_32.out
$ objdump -D file_1_32.out


file_1_32.out:     file format elf32-i386


Disassembly of section .text:

08049000 <var_3>:
 8049000:       00 66 a1                add    %ah,-0x5f(%esi)
 8049003:       00 a0 04 08 66 8b       add    %ah,-0x7499f7fc(%eax)
 8049009:       1d 01 a0 04 08          sbb    $0x804a001,%eax
 804900e:       90                      nop
 804900f:       66 a1 00 90 04 08       mov    0x8049000,%ax
 8049015:       66 8b 1d 2a 90 04 08    mov    0x804902a,%bx
 804901c:       90                      nop
 804901d:       66 a1 03 a0 04 08       mov    0x804a003,%ax
 8049023:       66 8b 1d 04 a0 04 08    mov    0x804a004,%bx

0804902a <var_4>:
        ...

Disassembly of section .custom_0:

0804a000 <var_1>:
        ...

0804a001 <var_2>:
        ...

Disassembly of section .custom_1:

0804a003 <var_5>:
        ...

0804a004 <var_6>:
        ...
```

There is no relocation calculation much here
.custom_0's base address is `0804a000`
var_1 is at offset 0, so `0804a000` + 0 (from instruction)  = 0804a000
var_2 is at offset 1, so `0804a000` + 1 (from instruction) = 0804a001
like wise calcculated for all



## 64 bit


; nasm -f elf64 file_1.asm -o file_1_64.o
; objdump -D file_1_64.o
```

file_1_64.o:     file format elf64-x86-64


Disassembly of section .custom_0:

0000000000000000 <var_1>:
        ...

0000000000000001 <var_2>:
        ...

Disassembly of section .text:

0000000000000000 <var_3>:
   0:   00 66 8b                add    %ah,-0x75(%rsi) ; 0 -> 00, 1 -> 66 8b 04 25 00 00 00 00
   3:   04 25                   add    $0x25,%al
   5:   00 00                   add    %al,(%rax)
   7:   00 00                   add    %al,(%rax)
   9:   66 8b 1c 25 00 00 00    mov    0x0,%bx
  10:   00 
  11:   90                      nop
  12:   66 8b 04 25 00 00 00    mov    0x0,%ax
  19:   00 
  1a:   66 8b 1c 25 00 00 00    mov    0x0,%bx
  21:   00 
  22:   90                      nop
  23:   66 8b 04 25 00 00 00    mov    0x0,%ax
  2a:   00 
  2b:   66 8b 1c 25 00 00 00    mov    0x0,%bx
  32:   00 

0000000000000033 <var_4>:
        ...

Disassembly of section .custom_1:

0000000000000000 <var_5>:
        ...

0000000000000001 <var_6>:
        ...
```
; objdump -r file_1_64.o
```
file_1_64.o:     file format elf64-x86-64

RELOCATION RECORDS FOR [.text]:
OFFSET           TYPE              VALUE
0000000000000005 R_X86_64_32S      .custom_0
000000000000000d R_X86_64_32S      .custom_0+0x0000000000000001
0000000000000016 R_X86_64_32S      .text
000000000000001e R_X86_64_32S      .text+0x0000000000000033
0000000000000027 R_X86_64_32S      .custom_1
000000000000002f R_X86_64_32S      .custom_1+0x0000000000000001

```


Here addend are stored directly in relocation table



;  ld -m elf_x86_64 file_1_64.o -o file_1_64.out
; objdump -D file_1_64.out
```
Disassembly of section .text:

0000000000401000 <var_3>:
  401000:       00 66 8b                add    %ah,-0x75(%rsi)
  401003:       04 25                   add    $0x25,%al
  401005:       00 20                   add    %ah,(%rax)
  401007:       40 00 66 8b             add    %spl,-0x75(%rsi)
  40100b:       1c 25                   sbb    $0x25,%al
  40100d:       01 20                   add    %esp,(%rax)
  40100f:       40 00 90 66 8b 04 25    rex add %dl,0x25048b66(%rax)
  401016:       00 10                   add    %dl,(%rax)
  401018:       40 00 66 8b             add    %spl,-0x75(%rsi)
  40101c:       1c 25                   sbb    $0x25,%al
  40101e:       33 10                   xor    (%rax),%edx
  401020:       40 00 90 66 8b 04 25    rex add %dl,0x25048b66(%rax)
  401027:       03 20                   add    (%rax),%esp
  401029:       40 00 66 8b             add    %spl,-0x75(%rsi)
  40102d:       1c 25                   sbb    $0x25,%al
  40102f:       04 20                   add    $0x20,%al
  401031:       40 00                   rex add %al,(%rax)

0000000000401033 <var_4>:
        ...

Disassembly of section .custom_0:

0000000000402000 <var_1>:
        ...

0000000000402001 <var_2>:
        ...

Disassembly of section .custom_1:

0000000000402003 <var_5>:
        ...

0000000000402004 <var_6>:
        ...
```

Here problem is objdump lost the track

see the manual decodeing

0000000000401000 <var_3>:
  401000:       00
  401001:       66 8b 04 25 00 20 40 00 -> 66 8b 04 25 -> mov ax, 00 20 40 00 -> 00402000 it is var 1
