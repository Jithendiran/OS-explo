## Assembler 

1. The Raw Start (The "Echo" Method)
Before we had assemblers, we had to look up hex codes in a book and type them manually.
If you want the CPU to move a value into a register and then exit, you do this:    `echo -ne "\xba\x08\x00\xb4\x09\xcd\x21\xc3" > manual.bin`

* `\xba\x08\x00`    : `mov dx, 0008`
* `\xb4\x09`        : `mov ah, 09`
* `\xcd\x21`        : `int 21 (The "Print" interrupt)`
* `\xc3`            : `ret (Return)`

The Problem: If you add one single byte of code in the middle, your "0008" address is now wrong. You have to go back and recalculate every single hex address by hand. This is why we use an Assembler.

2. The Assembler's Job

The Assembler (like NASM) is just a translator. It takes your text and does the math for you.

```asm
; display.asm
[org 0x100]        ; Tell assembler we start at 0x100 (standard for DOS)

start:
    mov dx, msg    ; Assembler calculates the address of 'msg'
    mov ah, 0x09   ; Sub-function 9 (print string)
    int 0x21       ; Call DOS interrupt
    mov ax, 0x4c00 ; Sub-function 4C (exit)
    int 0x21

msg db 'Hello!$'   ; The data is just bytes sitting at the end
```

When you run `nasm -f bin display.asm -o display.com`, the assembler creates the hex for you. It sees msg is exactly 11 bytes after the start, so it fills in the address automatically.

> [org 0x100]  means offset address is calculated from 0x100, for example 

To view the content use hexdump -C
```
hexdump -C display.com 
00000000  ba 0c 01 b4 09 cd 21 b8  00 4c cd 21 48 65 6c 6c  |......!..L.!Hell|
00000010  6f 21 24                                          |o!$|
00000013
```

**The "ORG" Rule: Thinking vs. Being**
You have to distinguish between where the code sits in the file and where the code thinks it is.

When you run hexdump -C, you are looking at the Hard Drive view. 
1. The File View (Physical Address)
    A file is just a box of bytes. The first byte of any file is always at index 0.
    hexdump doesn't care about your code; it only cares about the file size.
2. The first byte of any file is always at index 0.
    The [org 0x100] directive is a message for the Assembler's internal calculator.
    If you didn't have [org 0x100], the assembler would calculate the address of msg as 0x000C.But since you added `[org 0x100]`, the assembler does this math: $0x100 (Base) + 0x000C (Offset) = 0x010C$
3. Proof in the Hex
    Look at your hexdump again:  `ba 0c 01 ...`
    * `ba` is `mov dx`.
    * `0c 01` is the address `0x010C` (Little Endian).

The assembler put 010C into the machine code because you told it the code starts at 100. If you change it to [org 0x200], that hex will change to 0c 02, but the file will still start at 00000000 in hexdump.

The ouput given by nasm is final product

**Moving Code to the "Magic" Address**

Every CPU has a "Reset Vector"—a hardcoded address where it looks for its very first instruction when you turn the power on. For example, an 8086 looks at 0xFFFF0.

If your binary file is only 20 bytes long, it will be loaded at 0x0000. The CPU will find nothing at 0xFFFF0 and crash. You have to physically move your code to that exact spot in the file.

1. Option 1: The "Padding" Trick (Inside the Assembler)

    You can tell the assembler to fill the "empty space" with zeros (or NOP instructions) until it reaches the target address.

    ```
    ; --- The "Void" ---
    ; Everything from address 0 to 0xFFFEF will be zeros
    times 0xFFFF0 - ($ - $$) db 0 

    ; --- The Start ---
    ; This code will now physically sit at offset 0xFFFF0 in the file
    start_logic:
        mov dx, msg
        mov ah, 0x09
        int 0x21
        jmp $          ; Infinite loop
    ```

2. Option 2: The "Lego" Method (Using cat)
    Instead of one giant file, you build pieces and snap them together using the command line.

    1. Create padding.bin (filled with zeros) using    `Python` or `dd`.
    2. Create code.bin using your assembler.
    3. Combine them: `cat padding.bin code.bin > final_bios.bin`

3. Option 3: Scripted Construction

    If you have many sections (Code at 0xFFFF0, Data at 0x7000, Stack at 0x9000), doing it by hand is impossible. You write a script (Python/Bash) to "place" the bytes.

    ```py
    # Simple Python builder logic
    image = bytearray(1024 * 1024) # 1MB of empty memory
    code = open("code.bin", "rb").read()
    image[0xFFFF0 : 0xFFFF0 + len(code)] = code
    open("bios.img", "wb").write(image)
    ```

If CPU connected to multiple device, it's address is splitted accordingly 

No labels, symbols are preserved 
* Labels: Converted to address immediately.
* Sections: Fixed in place.
* Output: Ready to run (e.g., a .COM or bootloader).
* Multi-file: Extremely difficult to manage.

> nm display.out 
> $ nm: display.out: file format not recognized

> objdump -aD display.out 
> $ objdump: display.out: file format not recognized

When you compine multiple binary file using linker, It will fail. It will say something like: a.o: file not recognized: File format not recognized. This is because ld expects an object file with a header (ELF), and you gave it raw machine code.


------

## Linker 

The more files and sections you have, the harder it is to maintain. Here is why it breaks:
1. Hardcoded Math: If  `file_A.bin` needs to call a function in `file_B.bin`, you have to manually find the address in the hexdump of B and type it into A. If B changes by 1 byte, A is now broken.
2. Space Inefficiency: Using times `0xFFFF0` ... creates files full of "air" (zeros). This wastes disk space.
3. No "Smart" Placement: The assembler just puts things in order. It can't say, "Put this code in the fast RAM and this data in the slow ROM" automatically.

**Enter the Linker: The Professional "Stitcher"**

The Linker (like ld) allows you to stop using times and cat. 

Instead of generating a finished product immediately, the assembler creates an Relocatable Object File (like .o or .obj).

**Relocatable Object** means the address given by assembler is not the final, the part of code or data will be relocated to different address

When multifiles are there. If main.asm wants to call a function in graphics.asm, the assembler fails. Why? Because when the assembler is looking at main.asm, it has no idea where graphics.asm will be in memory.

1. The "Object File" (.o) – The Half-Baked Product
    To solve the "multi-file" problem, we stopped asking the assembler to make a finished .bin. Instead, we told it to make an Object File (-f elf).
    An Object File It says:
    * My Code: "Here is my raw machine code."
    * My Labels: "I have a label called start_logic at offset 0."
    * My Needs: "I need the address for a label called msg, but I don't have it."

    The Assembler leaves "Holes" in the code. If you hexdump a `.o` file, you will see `ba 00 00`. The `00 00` is a blank spot. The assembler puts a note in the ELF header saying: "Dear Linker, please fill this hole with the real address of msg later."


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

> $ nasm -f elf display.asm -o display.o


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

`00000160  66 "ba 00 00" ..`

Also it has many field it is very hard to look in hexdump do let's see in objdump

The Assembler says: "I put 00 00 here for now, but I've added a note in the .rel.text section telling the linker to patch this offset with the final address of msg."


```
$ objdump -Da display.o

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

It also preserve's `label` and every thing

The instruction in .data section is not valid, When you ran objdump -D, it tried to disassemble the .data section as if it were executable code. you have to only look for the opcodes like `48 65 6c,...`

also notice `.text` and `.data` section each start's at address  `00000000` clearly it is not possible to start two section in same address like this, this address will be relocated by linker 

You can see the labels/symbols `start_logic` and `msg`, To view only symbols 

```
$ nm display.o
00000000 d msg              ; addresss section symbol
00000000 t start_logic
```

When we have multiple sections like .text, .data we have to define a address where it should go in the real hardware address

A linker script is essentially the "blueprint" for your final executable. While the compiler turns your code into object files, the linker’s job is to stitch those files together. The linker script tells the linker exactly where in the hardware's memory those pieces should go.

Let's say we need a section at address 0x10, 0x100 and 0x150, to meet our objective let's create a linker script to guide linker

```
// linker.ld
SECTIONS
{
    /* The '.' is the Location Counter. It tells the linker "Start here" */

    . = 0x10;
    .low_data : { 
        *(.low_data) 
    }

    . = 0x100;
    .text : { 
        *(.text) 
    }

    . = 0x150;
    .high_data : { 
        *(.high_data) 
    }
}
```

```
section .low_data
    db 0xAA, 0xAA    ; This should end up at 0x10

section .text
    mov ax, 0x1234   ; This should end up at 0x100

section .high_data
    db 0xBB, 0xBB    ; This should end up at 0x150
```

To understand the script above, you need to know these three pillars:

* The Location Counter (.)
    The dot is the most important symbol. It represents the current memory address.
    - When you say `. = 0x100;`, you are forcing the linker to "jump" to that address.
    - If the previous section ended at `0x50` and you set `. = 0x100`, the linker will automatically insert "padding" (zeros) to fill the gap.

* Sections and Wildcards (*)
    - Inside the curly braces `{ ... }`, we tell the linker which input sections to grab.
    - *(.text) means: "Look through all input files ( * ) and grab their .text sections, then glue them here."
    - To specify only a specific region in a file instead of `*`, use like this `startup.o(.text)`, to grap multiple section in a file `startup.o(.text .rodata)`, `startup.o` is the object file given by assembler 

* VMA vs. LMA (Thinking vs. Being)
    - VMA (Virtual Memory Address): Where the code expects to be when it runs (the address the CPU uses)(runtime).
    - LMA (Load Memory Address): Where the code is physically stored (e.g., in a ROM chip). For simple flat binaries, these are usually the same.

**Compile**
1. Assemble to Object: `nasm -f elf32 nasm_file.asm -o file.o`
2. Linker with Script: `ld -m elf_i386 -T linker.ld file.o -o final.bin`

> linker script is optional, if custom script not use it use default address

```
$ hexdump -C final.bin
00000000  7f 45 4c 46 01 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 03 00 01 00 00 00  00 01 00 00 34 00 00 00  |............4...|
00000020  bc 11 00 00 00 00 00 00  34 00 20 00 01 00 28 00  |........4. ...(.|
00000030  07 00 06 00 01 00 00 00  10 10 00 00 10 00 00 00  |................|
00000040  10 00 00 00 42 01 00 00  42 01 00 00 05 00 00 00  |....B...B.......|
00000050  00 10 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00001010  aa aa 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00001020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00001100  66 b8 34 12 00 00 00 00  00 00 00 00 00 00 00 00  |f.4.............|
00001110  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00001150  bb bb 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00001160  00 00 00 00 01 00 00 00  00 00 00 00 00 00 00 00  |................|
00001170  04 00 f1 ff 00 6e 61 73  6d 5f 66 69 6c 65 2e 61  |.....nasm_file.a|
00001180  73 6d 00 00 2e 73 79 6d  74 61 62 00 2e 73 74 72  |sm...symtab..str|
00001190  74 61 62 00 2e 73 68 73  74 72 74 61 62 00 2e 6c  |tab..shstrtab..l|
000011a0  6f 77 5f 64 61 74 61 00  2e 74 65 78 74 00 2e 68  |ow_data..text..h|
000011b0  69 67 68 5f 64 61 74 61  00 00 00 00 00 00 00 00  |igh_data........|
000011c0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000011e0  00 00 00 00 1b 00 00 00  01 00 00 00 02 00 00 00  |................|
000011f0  10 00 00 00 10 10 00 00  02 00 00 00 00 00 00 00  |................|
00001200  00 00 00 00 01 00 00 00  00 00 00 00 25 00 00 00  |............%...|
00001210  01 00 00 00 06 00 00 00  00 01 00 00 00 11 00 00  |................|
00001220  04 00 00 00 00 00 00 00  00 00 00 00 10 00 00 00  |................|
00001230  00 00 00 00 2b 00 00 00  01 00 00 00 02 00 00 00  |....+...........|
00001240  50 01 00 00 50 11 00 00  02 00 00 00 00 00 00 00  |P...P...........|
00001250  00 00 00 00 01 00 00 00  00 00 00 00 01 00 00 00  |................|
00001260  02 00 00 00 00 00 00 00  00 00 00 00 54 11 00 00  |............T...|
00001270  20 00 00 00 05 00 00 00  02 00 00 00 04 00 00 00  | ...............|
00001280  10 00 00 00 09 00 00 00  03 00 00 00 00 00 00 00  |................|
00001290  00 00 00 00 74 11 00 00  0f 00 00 00 00 00 00 00  |....t...........|
000012a0  00 00 00 00 01 00 00 00  00 00 00 00 11 00 00 00  |................|
000012b0  03 00 00 00 00 00 00 00  00 00 00 00 83 11 00 00  |................|
000012c0  36 00 00 00 00 00 00 00  00 00 00 00 01 00 00 00  |6...............|
000012d0  00 00 00 00                                       |....|
000012d4
```

```
$ objdump -D final.bin 

final.bin:     file format elf32-i386


Disassembly of section .low_data:

00000010 <.low_data>:
  10:	aa                   	stos   %al,%es:(%edi)
  11:	aa                   	stos   %al,%es:(%edi)

Disassembly of section .text:

00000100 <.text>:
 100:	66 b8 34 12          	mov    $0x1234,%ax

Disassembly of section .high_data:

00000150 <.high_data>:
 150:	bb                   	.byte 0xbb
 151:	bb                   	.byte 0xbb

```

Now we can see the sections are start at address 010, 0100,..

here there is a small problem boot loaders don't understand `elf`, it only need raw binary at the start up, to omit the ELF related works use  `--oformat binary`, `ld -m elf_i386 -T linker.ld file.o -o final.bin --oformat binary`

```
$objdump -D final.bin 
objdump: final.bin: file format not recognized
```

```
$ hexdump -C final.bin
00000000  aa aa 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000000f0  66 b8 34 12 00 00 00 00  00 00 00 00 00 00 00 00  |f.4.............|
00000100  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00000140  bb bb                                             |..|
00000142

```

here elf stuff are removed, also it removed empty padding from address `0x00 - 0x10` 
1. When you use --oformat binary, the linker creates a "Flat Binary."
2. A flat binary doesn't naturally understand "empty space before the first byte."
3. The linker looks at your script and sees that the very first thing it needs to write is .low_data at address 0x10.
4. Since there is nothing defined at addresses 0x00 through 0x0F, the linker doesn't see a reason to write 16 bytes of zeros at the start of the file. It just starts the file at your first defined section.

We have to force the linker in this flat binary case

```
//linker.ld
SECTIONS
{
    /* Anchor the start of the file at 0x0 */
    . = 0x0;

    /* 2. Create a dummy anchor at the very beginning */
    /*This is needed, some times linker is smarter to save file space truncate the starting 0's*/
    .anchor : {
        BYTE(0x00); 
    }

    /* Move to 0x10. Because we started at 0x0, 
       the linker will now fill the gap with zeros. */
    . = 0x10;
    .low_data : { *(.low_data) }

    . = 0x100;
    .text : { *(.text) }

    . = 0x150;
    .high_data : { *(.high_data) }
}
```

```
$ hexdump -C final.bin
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000010  aa aa 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00000100  66 b8 34 12 00 00 00 00  00 00 00 00 00 00 00 00  |f.4.............|
00000110  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00000150  bb bb                                             |..|
00000152

```

### The MEMORY Block (The Map)
In complex systems (like a microcontroller with 64KB of Flash and 16KB of RAM), you should define the hardware map first. This prevents you from accidentally putting 2MB of code into a 64KB chip.

```linker.ld
MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
    /*ROM memory start at 0x00000000, it's length is 64kb, ROM 0 - 0x0000FFFF */
    /* Empty space 0x00010000 - 0x1FFFFFFF*/
    RAM (rwx): ORIGIN = 0x20000000, LENGTH = 16K
    /*RAM memory 0x20000000 - 0x20003FFF*/
}

SECTIONS
{
    .text : { 
        *(.text)
        *(.rodata)
    } > ROM              /* Put code in ROM */
    .data : { *(.data) } > RAM AT > ROM     /* VMA is RAM, LMA is ROM */
}
```

```test.asm
SECTION .text
    nop                 

SECTION .data
    db 0xAA, 0xBB, 0xCC 

SECTION .rodata
    db 0xDD, 0xEE, 0xFF

SECTION .text
    mov ax, 123               

SECTION .data
    db 0xDA, 0xDA, 0xDA 

SECTION .rodata
    db 0x11, 0x22, 0x33
```

1. `> ROM`
    This is straightforward. It tells the linker: "Put this section in ROM, and keep it there."
    - `.text` contains your actual machine code (instructions).
    - Since code is usually "execute-in-place," the address where it is stored is the same address where the CPU reads it to run it.
    - LMA = VMA.

2. `> RAM AT > ROM`
    This is used for the .data section (global variables that have an initial value, like int x = 5;).
    - `> RAM` (VMA): The program expects these variables to be at a RAM address because RAM is readable and writable. You can't change x = 10; if it stays in ROM! 
    - `AT > ROM` (LMA): Because RAM is volatile (it wipes when power is lost), the initial value (the 5) must be stored in ROM while the device is in a box on a shelf.

    When you turn on the microcontroller, the hardware doesn't automatically move that 5 from ROM to RAM. You (or your startup code/CRT0) must write a small loop that copies the data from the LMA (ROM) to the VMA (RAM) before main() starts.

This is standard `> [VMA] AT > [LMA]`, 1st VMA then LMA


`> [VMA] > [LMA]`, this is not valid for LMA

1. `> ROM`	VMA = ROM, LMA = ROM. Simple and standard for code.
2. `> RAM AT > ROM` VMA = RAM, LMA = ROM. The standard "Load-to-Flash, Run-from-RAM" setup.
3. `> RAM` VMA = RAM, LMA = RAM. Used for things that don't need to be saved when power is off (like the stack or zeroed variables).

Think of AT as the "Storage" pointer. By using `AT > ROM`, you ensure that the value(constant) is burnt into the permanent Flash memory, ready to be copied into RAM every time the chip boots up.

> $ nasm -f elf32 test.asm -o test.o
> $ ld -m elf_i386 -T linker.ld test.o -o test.elf

```
objdump -D test.elf

test.elf:     file format elf32-i386


Disassembly of section .text:

00000000 <.text>:
   0:	90                   	nop
   1:	66 b8 7b 00          	mov    $0x7b,%ax
   5:	66 90                	xchg   %ax,%ax
   7:	90                   	nop
   8:	dd ee                	fucomp %st(6)
   a:	ff 11                	call   *(%ecx)
   c:	22 33                	and    (%ebx),%dh

Disassembly of section .data:

20000000 <.data>:
20000000:	aa                   	stos   %al,%es:(%edi)
20000001:	bb cc da da da       	mov    $0xdadadacc,%ebx
```

text section contains both rodata and text section
data section contains data

It's address also mapped according to the memory

MEMORY sections can be overlapping, so mapping should be done carefully

```
MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx): ORIGIN = 0x00000000, LENGTH = 16K
}
SECTIONS
{
    .text : {
        *(.text)
        *(.rodata)
    } > ROM              
    .data : { *(.data) } > RAM AT > ROM    
}
```

```
$ld -m elf_i386 -T linker.ld test.o -o test.elf
$ objdump -D test.elf

test.elf:     file format elf32-i386


Disassembly of section .text:

00000000 <.text>:
   0:	90                   	nop
   1:	66 b8 7b 00          	mov    $0x7b,%ax
   5:	66 90                	xchg   %ax,%ax
   7:	90                   	nop
   8:	dd ee                	fucomp %st(6)
   a:	ff 11                	call   *(%ecx)
   c:	22 33                	and    (%ebx),%dh

Disassembly of section .data:

00000000 <.data>:
   0:	aa                   	stos   %al,%es:(%edi)
   1:	bb cc da da da       	mov    $0xdadadacc,%ebx
```

If you don't specify a memory region (like > ROM or > RAM), the linker follows a specific set of fallback rules.

``` asm
section .lobed
db 0x77, 0x88, 0x99

section .utgobed
    mov ax, 567

SECTION .text
    nop                 

SECTION .data
    db 0xAA, 0xBB, 0xCC 

SECTION .rodata
    db 0xDD, 0xEE, 0xFF

SECTION .text
    mov ax, 123               

SECTION .data
    db 0xDA, 0xDA, 0xDA 

SECTION .rodata
    db 0x11, 0x22, 0x33

section .lobed
    db 0x44, 0x55, 0x66
```

    ```
    $ readelf -S test.o
    There are 9 section headers, starting at offset 0x40:

    Section Headers:
    [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
    [ 0]                   NULL            00000000 000000 000000 00      0   0  0
    [ 1] .lobed            PROGBITS        00000000 0001b0 000006 00   A  0   0  1
    [ 2] .utgobed          PROGBITS        00000000 0001c0 000004 00   A  0   0  1
    [ 3] .text             PROGBITS        00000000 0001d0 000005 00  AX  0   0 16
    [ 4] .data             PROGBITS        00000000 0001e0 000006 00  WA  0   0  4
    [ 5] .rodata           PROGBITS        00000000 0001f0 000006 00   A  0   0  4
    [ 6] .shstrtab         STRTAB          00000000 000200 00003f 00      0   0  1
    [ 7] .symtab           SYMTAB          00000000 000240 000070 10      8   7  4
    [ 8] .strtab           STRTAB          00000000 0002b0 00000a 00      0   0  1
    Key to Flags:
    W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
    L (link order), O (extra OS processing required), G (group), T (TLS),
    C (compressed), x (unknown), o (OS specific), E (exclude),
    D (mbind), p (processor specific)
```

```ld
MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx): ORIGIN = 0x20000000, LENGTH = 16K
}

SECTIONS
{
    .text : { 
        *(.text)
        *(.rodata)
    } > ROM             
    .data : { *(.data) }     
}

```

```
objdump -D test.elf

test.elf:     file format elf32-i386


Disassembly of section .text:

00000000 <.text>:
    0:	90                   	nop
    1:	66 b8 7b 00          	mov    $0x7b,%ax
    5:	66 90                	xchg   %ax,%ax
    7:	90                   	nop
    8:	dd ee                	fucomp %st(6)
    a:	ff 11                	call   *(%ecx)
    c:	22 33                	and    (%ebx),%dh

Disassembly of section .lobed:

0000000e <.lobed>:
    e:	77 88                	ja     0xffffff98
    10:	99                   	cltd
    11:	44                   	inc    %esp
    12:	55                   	push   %ebp
    13:	66                   	data16

Disassembly of section .utgobed:

00000014 <.utgobed>:
    14:	66 b8 37 02          	mov    $0x237,%ax

Disassembly of section .data:

    20000000 <.data>:
    20000000:	aa                   	stos   %al,%es:(%edi)
    20000001:	bb cc da da da       	mov    $0xdadadacc,%ebx

```


1. Why .data went to RAM?
    Even though we didn't type > RAM in our script, the linker moved it to 0x20000000.
    * The Attributes: Your readelf shows .data has flags WA (Write + Alloc).
    * The Match: The linker looks at your MEMORY list. ROM is (rx), which means Read and Execute only. It is not allowed to put a Write (W) section there.
    * The First Fit: RAM is (rwx). It has the W attribute. Since it's the first (and only) region that allows writing, the linker puts .data there by default.
2. Why .lobed and .utgobed went to ROM
    Looking at your objdump, these stayed at 0x0000000E and 0x00000014.
    * The Attributes: Your readelf shows these only have flag A (Alloc). They are not marked as Write (W) or Execute (X).
    * The Choice: Since they don't need to be written to, the linker puts them in the very first memory region defined: ROM.
    * Sequential Packing: The linker puts .text at 0x00000000. Since you didn't give .lobed a specific home in the SECTIONS block, the linker just stacks it right after .text in the same memory bank.


### ENTRY
Syntax: ENTRY(start_logic)
Even in a flat binary, the linker needs to know which function is the "start/main."

### KEEP
Linkers have a feature called "Garbage Collection" (--gc-sections). If the linker thinks a piece of code is never called, it deletes it to save space. However, Interrupt Vectors or Magic Signatures (like the 0xAA55 at the end of a bootloader) are never "called" by the code—they are read by hardware.

Syntax: `KEEP(*(.vectors))`

Tells the linker: "Do not delete this, even if it looks like no one is using it."

## Two Files

### Simple start
We have two files. Each has its own .text and .data. They don't know the other exists.

```file_1.asm
section .text
    mov ax, 0x1111

section .data
    db 0x11, 0x11
```

```file_2.asm
section .text
    mov bx, 0x2222

section .data
    db 0x22, 0x22
```

* nasm -f elf32 file_1.asm -o file_1.o 
```
objdump -D file_1.o

file_1.o:     file format elf32-i386


Disassembly of section .text:

00000000 <.text>:
   0:   66 b8 11 11             mov    $0x1111,%ax

Disassembly of section .data:

00000000 <.data>:
   0:   11 11                   adc    %edx,(%ecx)
```

* nasm -f elf32 file_2.asm -o file_2.o
```
file_2.o:     file format elf32-i386


Disassembly of section .text:

00000000 <.text>:
   0:   66 bb 22 22             mov    $0x2222,%bx

Disassembly of section .data:

00000000 <.data>:
   0:   22 22                   and    (%edx),%ah
```

Both files starting address are starts from `00000000`, it is local to that file only (relative addresse)

* ld -m elf_i386 file_1.o file_2.o -o output.elf --verbose

```
ld: warning: cannot find entry symbol _start; defaulting to 08049000
$ objdump -D output.elf

output.elf:     file format elf32-i386


Disassembly of section .text:

08049000 <.text>:
 8049000:       66 b8 11 11             mov    $0x1111,%ax
 8049004:       66 90                   xchg   %ax,%ax
 8049006:       66 90                   xchg   %ax,%ax
 8049008:       66 90                   xchg   %ax,%ax
 804900a:       66 90                   xchg   %ax,%ax
 804900c:       66 90                   xchg   %ax,%ax
 804900e:       66 90                   xchg   %ax,%ax
 8049010:       66 bb 22 22             mov    $0x2222,%bx

Disassembly of section .data:

0804a000 <__bss_start-0x6>:
 804a000:       11 11                   adc    %edx,(%ecx)
 804a002:       00 00                   add    %al,(%eax)
 804a004:       22 22                   and    (%edx),%ah

```

All the sections are grouped and arranged in the given order, `8049000` is start address

why `8049000` is start address, The short answer is that 0x08049000 is the default base address

### The Symbol Tabel

```file_1.asm
global global_code_1    ; Export this to the world

section .text
global_code_1:          ; GLOBAL
    mov ax, 0x1111

local_code_1:           ; LOCAL
    nop

section .data
    db 0x11, 0x11
```

```file_2.asm
global global_code_2    ; Export this to the world

section .text
global_code_2:          ; GLOBAL
    mov bx, 0x2222

local_code_1:           ; LOCAL (Same name as file_1!)
    nop

section .data
    db 0x22, 0x22
```

* nasm -f elf32 file_1.asm -o file_1.o

```
$ readelf -s file_1.o

Symbol table '.symtab' contains 6 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS file_1.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .data
     4: 00000004     0 NOTYPE  LOCAL  DEFAULT    1 local_code_1
     5: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 global_code_1
```

* nasm -f elf32 file_2.asm -o file_2.o

```
$ readelf -s file_2.o

Symbol table '.symtab' contains 6 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FILE    LOCAL  DEFAULT  ABS file_2.asm
     2: 00000000     0 SECTION LOCAL  DEFAULT    1 .text
     3: 00000000     0 SECTION LOCAL  DEFAULT    2 .data
     4: 00000004     0 NOTYPE  LOCAL  DEFAULT    1 local_code_1
     5: 00000000     0 NOTYPE  GLOBAL DEFAULT    1 global_code_2
```

Here you we have 2 labels global_code_1, global_code_2 and local_code_1, if we generate flatobject these are directlty converted to address, since we are generating `ELF Relocatable object`, all the values will be preserved till linking stage or beyond linking stage

Why it have to preserve?
Because we know by using linker we will merge all the Relocatable object into single final binary, so one part of the file can call other part of the files with the labels defined

Labels can be local or global
* local variables are only visible to that file while doing linking
* Global variable are visible to all the files while doing linking

if we want to call one functionality from other file we have to use global variable

### Local Symbol Resolution 
```
section .text
local_start:        
    nop
    jmp local_start 

section .aaa

local_1:
    nop
    nop
local_2:
    mov ax, 1
    nop
    jmp local_start
    nop
    jmp local_1
    nop
    nop
    jmp local_2

```

```
$ nasm -f elf32 file_1.asm -o file_1.o
$ objdump -D file_1.o

file_1.o:     file format elf32-i386


Disassembly of section .text:

00000000 <local_start>:
   0:   90                      nop
   1:   eb fd                   jmp    0 <local_start>

Disassembly of section .aaa:

00000000 <local_1>:
   0:   90                      nop
   1:   90                      nop

00000002 <local_2>:
   2:   66 b8 01 00             mov    $0x1,%ax
   6:   90                      nop
   7:   e9 fc ff ff ff          jmp    8 <local_2+0x6>
   c:   90                      nop
   d:   eb f1                   jmp    0 <local_1>
   f:   90                      nop
  10:   90                      nop
  11:   eb ef                   jmp    2 <local_2>
```

```$ objdump -r file_1.o

file_1.o:     file format elf32-i386

RELOCATION RECORDS FOR [.aaa]:
OFFSET   TYPE              VALUE
00000008 R_386_PC32        .text
```

---

### LOADADDR

LOADADDR(.section_name) is a built-in linker function that returns the LMA (the physical storage address) of a section.

* `.data` usually refers to the VMA (the RAM address).
* `LOADADDR(.data)` refers to the LMA (the ROM address).

```
SECTIONS
{
    .text : { *(.text) } > ROM

    .data : 
    {
        _sdata = .;         /* Start of DATA in RAM (VMA) */
        *(.data)
        _edata = .;         /* End of DATA in RAM (VMA) */
    } > RAM AT > ROM

    /* Here is the magic: */
    _sidata = LOADADDR(.data); /* Get the physical location in ROM (LMA) */
}
```

```
; Simplified Assembly Startup
mov esi, _sidata    ; Source: Physical address in ROM
mov edi, _sdata     ; Destination: Logical address in RAM
mov ecx, _edata
sub ecx, edi        ; Calculate length: (End - Start)

rep movsb           ; "Repeat Move String Byte" 
                    ; This physically moves the data from Flash to RAM
```

// -----------------------------------

* multiple files, with same label, global, extern
* 


If we use multiple file, like splitting the loggin into multiple files, but we need the binary as single object then in this case we need to use linker
assembler should not give finished product 
Labels: Kept as names for the linker to see.
Sections: Flexible; can be moved by the linker.
Output: Needs a linker to become a program.
Multi-file: Standard way to build large projects.

The 3 Main Jobs of a Linker
A. Combining Files (Merging)
You might have code in one file and variables in another. The linker glues all the .text (code) sections together and all the .data (variables) sections together into one big file.

B. Resolution (Finding the Address)
In your code, you wrote mov dx, msg.
When you assembled the file, the assembler didn't know where msg would eventually live in the computer's memory. It just left a blank spot and a note saying: "Hey Linker, put the address of 'msg' here later."
The Linker finds out exactly where msg ended up and fills in that blank spot.

C. Relocation (Adjusting for the Start Line)
The Linker decides the "Base Address" (the starting point) of your program.
The Linker comes along. By default, Linux linkers like to start programs at a huge address, like 0x08048000 (an 8-digit number).


$ld -m elf_i386 -e start_logic -Ttext 0x100 display.o -o final_output.bin --oformat binary
ld: warning: cannot find entry symbol start_logic; defaulting to 00000100


In a raw binary, there is no "main" function header. The CPU simply executes the first byte it finds. However, the Linker still needs to know where to start arranging your code sections.

Tip: Ensure the file containing your startup logic is listed first in the ld command.

```
When you ran this: ld -m elf_i386 -e start_logic -Ttext 0x100 ...

-m elf_i386: "We are building for a 32-bit system (even if we are using 16-bit logic)."

-e start_logic: "The front door of the program is the label named start_logic."

-Ttext 0x100: "Start the code at memory address 256 (0x100)." Because 256 is a small number, it fits in your 16-bit DX register, and the error disappears.

--oformat binary: "Don't add any fancy headers. Just give me the raw machine code."
```

jidesh@jidesh-MS-7E26:/tmp/pgm/asm$ hexdump -C final_output.bin 
00000000  ba 00 10 b4 09 cd 21 c3  00 00 00 00 00 00 00 00  |......!.........|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00000f00  48 65 6c 6c 6f 20 57 6f  72 6c 64 24 00           |Hello World$.|
00000f0d
jidesh@jidesh-MS-7E26:/tmp/pgm/asm$ 

Linker Script
While the Linker (ld) does the heavy lifting of joining files, the Linker Script tells it exactly where in the computer's memory those files should be placed. Without a script, the linker uses a "default" layout

```
/* 1. Define the Entry Point */
ENTRY(start_logic)

/* 2. Define Memory Regions (Optional but helpful) */
MEMORY
{
    ram (rwx) : ORIGIN = 0x0000, LENGTH = 64K
}

/* 3. Define the Sections Map */
SECTIONS
{
    . = 0x7C00;      /* Set the Location Counter to a specific address */

    .text : {        /* Put all code (.text) here */
        *(.text)    
    }

    .data : {        /* Put all variables (.data) here */
        *(.data)
    }

    .bss : {         /* Put uninitialized data here */
        *(.bss)
    }
}
```

The dot (.) is the most important symbol in a linker script. It represents the current memory address.
. = 0x1000;, you are telling the linker: "The very next byte of code should be placed at address 0x1000."
As the linker adds code, the dot automatically increases.

*(.text): The asterisk is a wildcard. It means "Take the .text section from all input files and put them here."

ENTRY: This tells the linker which label is the "Front Door" of your program. In your case, it would be ENTRY(start_logic). This ensures that even if you have 100 functions, the CPU knows which one to run first.

MEMORY (The Hardware Map)
This section is common in Embedded Systems or OS Development. It describes the physical hardware.
It tells the linker: "The Flash memory starts at X, and the RAM starts at Y."

```
/* linker.ld */
OUTPUT_FORMAT(binary)
SECTIONS
{
    . = 0x7C00;        /* Start address (common for bootloaders) */
    .text : { *(.text) }
    .data : { *(.data) }
}
```

ld -T linker.ld display.o -o final_output.bin




------------------
To truly master linkers, you need to stop thinking of them as "part of the compiler" and start seeing them as the **Project Manager** that organizes memory.

Here is a logical roadmap of the concepts you should cover, in order, to go from "truncated error" to "expert":

---

### 1. The Object File (The Input)

Before you link, you have `.o` files. You need to understand what's inside them besides just code.

* **Sections:** What exactly is the difference between `.text`, `.data`, `.rodata`, and `.bss`?
* **The Symbol Table:** How the assembler keeps a list of names (like `msg` or `start_logic`) but doesn't know their addresses yet.
* **Relocation Entries:** The "To-Do" list the assembler leaves for the linker (e.g., *"Please fill in the address for DX here later"*).

### 2. Symbol Resolution

This is the process of "matching."

* **Global vs. Local:** Why can the linker see `_start` but not a local label?
* **Undefined References:** What happens when you call a function that doesn't exist?
* **Strong vs. Weak Symbols:** What happens if you define the variable `x` in two different files? (The linker has to choose one).

### 3. The Relocation Process (The Core)

This is where your previous error lived.

* **Section Merging:** How the linker takes `.text` from `math.o` and `display.o` and glues them into one continuous block.
* **Calculating Addresses:** How the linker finally decides that `msg` is at exactly `0x7C0A`.
* **Patching:** The act of the linker physically writing that `0x7C0A` into the machine code of your binary.

### 4. Memory Layout & Linker Scripts

This is the "Architect" phase.

* **The Location Counter (`.`):** Mastering how to move the "cursor" in memory.
* **VMA vs. LMA:** * **VMA (Virtual Memory Address):** Where the code runs.
* **LMA (Load Memory Address):** Where the code is stored (very important for burning code to ROM/Flash).


* **Alignment:** Why some data *must* start at an address divisible by 4 or 16.

### 5. Executable Formats

The "wrapper" around your code.

* **ELF (Linux):** Complex, has headers and tables.
* **Flat Binary (`.bin`):** No headers, just raw instructions (what you are using now).
* **Entry Points:** How the OS knows the very first instruction to execute.

---

### Summary Checklist for You

If you can answer these three questions, you've learned the basics:

1. Why does the Assembler leave "holes" in the machine code?
2. How does a Linker Script prevent addresses from being too large for a register?
3. What is the difference between a Symbol and a Section?

**Which of these five areas feels the most "blurry" to you right now? I can dive deep into that specific one.**