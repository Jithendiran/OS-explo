Between sections

```
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

```objdump
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

Here `jmp local_start` in section `.aaa` is jumping to different section. Compiler don't know where the `.text` and `.aaa` section is going to place in real address, compiler only aware of the offset of each position related to it's section
It is Linker's job to place the section in real address and replace the correct value in the jump offset

How linker knows particular thing require a relocateable address?
Here Compiler will help linker by telling this particular place require relocation. when processing  byte 7 of `.aaa` section compiler knows it's is a near jump by looking the opcode, so it will create a relocation record in section `.aaa` relocatable table for linker
what are the things needs to be modified from byte 7?
- Defenitely not byte 7, it's is the opcode for jmp, from 8 till 11 is the offset address for jump it has to be modified by linker so compiler will create a new record with offset `8`
- linker needs to know what kind of value it is replacing (32 bit, 64 bit or Program counter offset, or regular address) to tell this to linker, compiler also place a type column in that record in our case we are using jump instruction of 4 byte, jump instruction is always corresponds to PC register so it will put `R_386_PC32`. `R` means relocateable, `386` means intel `x386` family, `PC` means program counter offset and `32` is length in bits  
- Linker needs to know to which section that jump is going to do (symbold corresponds to which section), so compiler will put `.text` in Value columns 

```
RELOCATION RECORDS FOR [.aaa]:
OFFSET   TYPE              VALUE
00000008 R_386_PC32        .text
```

each section has it's own RELOCATION RECORDS table

so far compiler/assembler created a record of which one needs relocation and to which section. in relocation table one more information is missing that is offset of that symbol in target section. offset is like the unique id in the section. Compiler will put the offset in jump instruction it self 
`local_start`'s offset is `00` compiler/assembler will fill up `00 00 00 00` from byte 8 till 11
`section .aaa`'s instruction 7 looks like this `7:   e9 00 00 00 00 `, but you can see `7:   e9 fc ff ff ff ` it is different from what we identified, let's come to that point later, for now assume `7:   e9 00 00 00 00 `

Now linker execution started
> for now let's see in decimal numbers instead of hexa
It decides to put `.text` from `1001` location and `.aaa` from `2000` location, so `local_start` in location 1001 and `7:   e9 fc ff ff ff` become `2007:   e9 fc ff ff ff`
then linker will look on relocation record for that section it has `00000008 R_386_PC32        .text` record, as per the record the offset 8 require relocation to `.text` section, it will go to offset 8 in section `.aaa`, it finds `00`, the type says it is 32 bit so it look 4 bytes in 8th offset (`00 00 00 00`) it will calculate the target address for local_start

- `.text` start from `1001` and offset of `local_start` is `0 (00 00 00 00)`, so the tartget address is `1001 + 0 = 1001`
- `.aaa` starts from `2000` and offset of our relocation start from `8` -> `2008-2011` 
-  To go to 1001 from 2008, `1001-2008 = -1007`, so linker will replace `-1007` instead of 0's 

Now computer execution started
- cpu execute from 2007, it see jump -1007, cpu will jump to `1005` not `1001`, how 2012−1007 = 1005?  why 2012?
- As we know when a instruction is execution, PC will point to next instruction start address (legth of near jump is 5 bytes = 1 byte for instruction and 4 byte for offset), jump instruction will consider from the PC value not based on the relocation or cpu current instruction line. 
- Our cpu needs to go to `1001` not `1005`, it is off by `1005-1001` = 4 bytes ok why 4 bytes?
our jump instruction start from 2007 till 2011, next instruction start from 2012, size of the offset of jump is 4 bytes, so cpu is overshot 4 bytes, if our jump instruction is 2 byte length it will over shot by 2 bytes, it is based on the length of the jump offset and where the PC is points to, because we calulated ever thing from linker prespective, linker will look from byte 2008
2008-1007 = 1001, it is correct for linker, but not for cpu execution
- what we can do is we cannot modify linker offset or linker execution because linker has to find the offset by the correct address, and linker is general program it has to work for all thing, if we modify linker flow, it will affect other flows also
- so we have 2 options 1 is cpu execution and assembler/compiler, cpu blindly follows the instruction. We should over come this problem only from assembler/compiler
- when assembler/compiler is filling the offset value in jump instruction it has to minus 4 bytes (length of the offset) from that offset
    in our case offset of  `local_start` is 0 and length of jump offset is 4 bytes, so 0-4 = -4, now place the -4 in jump instruction `jmp -4`

    Let's recalculate
    Linker's calculation
        - Target address: `.text` start from `1001`, offset is `-4` target address is `1001 - 4 = 997`
        - To go to 997 from 2008, `997-2008 = -1011`, so linker will replace `-1011` instead of 0's 
        $$\text{target start address} - \text{offset (Addend)} - \text{offset address start}$$
    cpu execution 
        - when executing 2007 instruction, PC points to 2012
        - 2012 - 1011 = 1001, now flow is go to 1001
    -4 == fc in hex signed value so it put ` e9 fc ff ff ff`, `e9` is near jump, `fc ff ff ff` is -4

Lets see after linker process what is the updated value for `fc ff ff ff`

```
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
Linker calc
The linker uses a specific "Relocation Formula" to find address, S + A - P
- $S$ (Symbol): The final address of section .text
- $A$ (Addend): The value already stored in those 4 bytes (e.g., -4).
- $P$ (Position): The final address where the relocation is being applied (Relocation table offset 00000008 points to 0x0804a02f).

$$\text{Result} = S + A - P$$
$$\text{Result} = 0x08049000 + (-4) - 0x0804a02f$$
$$0x08049000 - 4 = 8048FFC$$
$$8048FFC - 0x0804a02f =-1033 $$
$$\text{Result} = -0x1033 \quad (\text{which is } \mathbf{FFFFEFCD})$$

.text address 08049000
    08049000 + 0 = local_start
.aaa address 0804a029
    0804a029 + 7 = jump instruction (804a02e)
    0804a029 + c = next instruction after jump (804a033)

Jump offset = target - next instruction
            = (08049000 + 0) - (804a033) = FF FF EF CD == -4147

804a033 + FF FF EF CD = 8049000 

In modern 64-bit systems (ELF64), the addend is often stored explicitly in the relocation table itself (this is called RELA). In 32-bit systems (like your R_386 example), the addend is usually stored "implicitly" in the section data itself (called REL).

compiler/assembler puts 00 00 00 00 and store the offset (addend) in relocation table it self, calculation remains same

```
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

linker calc 

401000 - 4 - 40202f = -1033 == FF FF EF CD
401000 - 1 - 40203d = −103E == FF FF EF C2 