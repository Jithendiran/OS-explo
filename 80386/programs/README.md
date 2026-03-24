To view the content of GDTR, IDTR use `monitor info registers` in gdb

## Programs

1. [GDT setup](./p1.asm)
    1. Define the GDT entries (Null, Code, and Data).
    2. Define the GDT Descriptor (The pointer the CPU actually reads).

    The Code Segment and the Data Segment point to the exact same physical memory (starting at address 0x0 and ending at 0xffffffff).
    > $ nasm -f bin p1.asm -o /tmp/boot.bin
    > $ qemu-system-i386 -d int,cpu_reset -D /tmp/qemu.log -no-reboot -fda /tmp/boot.img -s -S
    > gdb
    > $ target remote :1234
    > $ source helper.py
    > dash32
    > b *0x7c00
    > c
2. Simple task start
    > `nop` instruction is used in-between for easy looking the code adter compilation, to see compilation code use `ndisasm -b 32 -0 0x0 ./boot2.bin`
    * After start, CPU will move the current code to 07c00:0000, then it will load the task program, before jumping to task program it will setup the temp GDT then enable protected mode and jump the task program. Task program will setup the GDT, tss for task and jump to the task, task will run on user privilege (DPL=11)
    * Ring 0 and Ring 3 program and data segment mapped to same physical address
    * For learning purpose, print access given for user privilege DLP=11

    Task program will char `A`
    > nasm -f bin boot.asm -o /tmp/boot1.bin
    > nasm -f bin task_start/task.asm -o /tmp/boot2.bin
    > cat /tmp/boot1.bin /tmp/boot2.bin > /tmp/boot.img
    > qemu-system-i386 -d int,cpu_reset -D /tmp/qemu.log -no-reboot -fda /tmp/boot.img 

3. Simple multi task

    State at which boot loaded transfer control to out boot.asm
    ```
    eax            0xaa55              43605
    ecx            0x0                 0
    edx            0x80                128
    ebx            0x0                 0
    esp            0x6f08              0x6f08
    ebp            0x0                 0x0
    esi            0x0                 0
    edi            0x0                 0
    eip            0x7c00              0x7c00
    eflags         0x202               [ IOPL=0 IF ]
    cs             0x0                 0
    ss             0x0                 0
    ds             0x0                 0
    es             0x0                 0
    fs             0x0                 0
    gs             0x0                 0
    ```
    > nasm -f bin boot.asm -o /tmp/boot1.bin
    > nasm -f bin simple_multi_task/head.asm -o /tmp/boot2.bin
    > cat /tmp/boot1.bin /tmp/boot2.bin > /tmp/boot.img
    > qemu-system-i386 -d cpu_reset -D /tmp/qemu.log -no-reboot -fda /tmp/boot.img -s -S

programming yet to cover
1. set up GDT
2. setup IDT
3. set up LDT
4. 2 kernel process switch
5. 2 user process switch
6. kernel to user, then user to kernel process switch
7. interrupt handling
8. double faults
9. triple fault
10. paging
12. a20 line

Im just completed 8086 and entered 80386
completed the theory enough to start reading heavily commented linux 0.12 book
before this starting this book i would like to write some simple programs so it will help me in understanding the things faster
always give in simple english
don't generate any images 
produce code only in markdown text

I'll give the program questions one by one