As we know instructions like mov, add has hexa decimal opcode

machine only understand that opcode, but for humans it will be difficult to write in that form, so we use assembler, it will take human readable text into machine readable code

for example 

```asm
; display.asm
section .text

start_logic:       ; This 'start_logic' is private to display.asm
    mov dx, msg
    mov ah, 0x09
    int 0x21
    ret

section .data
    msg db 'Hello World$', 0
```

> nasm display.asm -o display.asm or nasm -f bin display.asm -o display.asm

> hexdump -C display.out

```
00000000  ba 08 00 b4 09 cd 21 c3  48 65 6c 6c 6f 20 57 6f  |......!.Hello Wo|
00000010  72 6c 64 24 00                                    |rld$.|
00000015
```

It is flat object, the assembler tries to create a finished product immediately.

Labels: Converted to address immediately.
Sections: Fixed in place.
Output: Ready to run (e.g., a .COM or bootloader).
Multi-file: Extremely difficult to manage.


> nm display.out 
$ nm: display.out: file format not recognized

> objdump -aD display.out 
$ objdump: display.out: file format not recognized

The linker will fail. It will say something like: math.o: file not recognized: File format not recognized. This is because ld expects an object file with a header (ELF), and you gave it raw machine code.


------

If we use multiple file, like splitting the loggin into multiple files, but we need the binary as single object then in this case we need to use linker
assembler should not give finished product 
Labels: Kept as names for the linker to see.
Sections: Flexible; can be moved by the linker.
Output: Needs a linker to become a program.
Multi-file: Standard way to build large projects.

```asm
; display.asm
section .text

start_logic:       ; This 'start_logic' is private to display.asm
    mov dx, msg
    mov ah, 0x09
    int 0x21
    ret

section .data
    msg db 'Hello World$', 0
```

nasm -f elf display.asm -o display.o

```
hexdump -C display.o
00000000  7f 45 4c 46 01 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  01 00 03 00 01 00 00 00  00 00 00 00 00 00 00 00  |................|
00000020  40 00 00 00 00 00 00 00  34 00 00 00 00 00 28 00  |@.......4.....(.|
00000030  07 00 03 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000040  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00000060  00 00 00 00 00 00 00 00  01 00 00 00 01 00 00 00  |................|
00000070  06 00 00 00 00 00 00 00  60 01 00 00 09 00 00 00  |........`.......|
00000080  00 00 00 00 00 00 00 00  10 00 00 00 00 00 00 00  |................|
00000090  07 00 00 00 01 00 00 00  03 00 00 00 00 00 00 00  |................|
000000a0  70 01 00 00 0d 00 00 00  00 00 00 00 00 00 00 00  |p...............|
000000b0  04 00 00 00 00 00 00 00  0d 00 00 00 03 00 00 00  |................|
000000c0  00 00 00 00 00 00 00 00  80 01 00 00 31 00 00 00  |............1...|
000000d0  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
000000e0  17 00 00 00 02 00 00 00  00 00 00 00 00 00 00 00  |................|
000000f0  c0 01 00 00 60 00 00 00  05 00 00 00 06 00 00 00  |....`...........|
00000100  04 00 00 00 10 00 00 00  1f 00 00 00 03 00 00 00  |................|
00000110  00 00 00 00 00 00 00 00  20 02 00 00 1a 00 00 00  |........ .......|
00000120  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
00000130  27 00 00 00 09 00 00 00  00 00 00 00 00 00 00 00  |'...............|
00000140  40 02 00 00 08 00 00 00  04 00 00 00 01 00 00 00  |@...............|
00000150  04 00 00 00 08 00 00 00  00 00 00 00 00 00 00 00  |................|
00000160  66 ba 00 00 b4 09 cd 21  c3 00 00 00 00 00 00 00  |f......!........|
00000170  48 65 6c 6c 6f 20 57 6f  72 6c 64 24 00 00 00 00  |Hello World$....|
00000180  00 2e 74 65 78 74 00 2e  64 61 74 61 00 2e 73 68  |..text..data..sh|
00000190  73 74 72 74 61 62 00 2e  73 79 6d 74 61 62 00 2e  |strtab..symtab..|
000001a0  73 74 72 74 61 62 00 2e  72 65 6c 2e 74 65 78 74  |strtab..rel.text|
000001b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000001d0  01 00 00 00 00 00 00 00  00 00 00 00 04 00 f1 ff  |................|
000001e0  00 00 00 00 00 00 00 00  00 00 00 00 03 00 01 00  |................|
000001f0  00 00 00 00 00 00 00 00  00 00 00 00 03 00 02 00  |................|
00000200  0a 00 00 00 00 00 00 00  00 00 00 00 00 00 01 00  |................|
00000210  16 00 00 00 00 00 00 00  00 00 00 00 00 00 02 00  |................|
00000220  00 6d 61 74 68 2e 61 73  6d 00 73 74 61 72 74 5f  |.math.asm.start_|
00000230  6c 6f 67 69 63 00 6d 73  67 00 00 00 00 00 00 00  |logic.msg.......|
00000240  02 00 00 00 14 03 00 00  00 00 00 00 00 00 00 00  |................|
00000250

```
clearly this is not a finished product, it preserved lables 

```
objdump -Da display.o

display.o:     file format elf32-i386
display.o


Disassembly of section .text:

00000000 <start_logic>:
   0:	66 ba 00 00          	mov    $0x0,%dx
   4:	b4 09                	mov    $0x9,%ah
   6:	cd 21                	int    $0x21
   8:	c3                   	ret

Disassembly of section .data:

00000000 <msg>:
   0:	48                   	dec    %eax
   1:	65 6c                	gs insb (%dx),%es:(%edi)
   3:	6c                   	insb   (%dx),%es:(%edi)
   4:	6f                   	outsl  %ds:(%esi),(%dx)
   5:	20 57 6f             	and    %dl,0x6f(%edi)
   8:	72 6c                	jb     76 <msg+0x76>
   a:	64 24 00             	fs and $0x0,%al

```
```
$ nm display.o
00000000 d msg
00000000 t start_logic
```