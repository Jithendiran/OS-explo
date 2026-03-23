This doc is get the idea on qemu log analysis

`qemu-system-i386 -d int,cpu_reset -D /tmp/qemu.log -no-reboot -fda /tmp/boot.img `

* `-d int,cpu_reset` - this will cause log on interrupt and cpu reset

* `-no-reboot` - when triple fault happen by default system will reboot, when this option is enabled it won't reboot

## Reading the log

```log
SMM: enter
EAX=000000b5 EBX=000f7e0e ECX=00001234 EDX=000069ff
ESI=00006990 EDI=06ffec55 EBP=00006950 ESP=00006950
EIP=00007e0b EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =d900 000d9000 ffffffff 00809300
CS =f000 000f0000 ffffffff 00809b00
SS =0000 00000000 ffffffff 00809300
DS =0000 00000000 ffffffff 00809300
FS =0000 00000000 ffffffff 00809300
GS =ca00 000ca000 ffffffff 00809300
LDT=0000 00000000 0000ffff 00008200
TR =0000 00000000 0000ffff 00008b00
GDT=     00000000 00000000
IDT=     00000000 000003ff
CR0=00000010 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000000 CCD=00006950 CCO=ADDL
EFER=0000000000000000
SMM: after RSM
EAX=000000b5 EBX=000f7e0e ECX=00001234 EDX=000069ff
ESI=00006990 EDI=06ffec55 EBP=00006950 ESP=00006950
EIP=000f7e0e EFL=00000046 [---Z-P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
CS =0008 00000000 ffffffff 00c09b00 DPL=0 CS32 [-RA]
SS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
DS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
FS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
GS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
LDT=0000 00000000 0000ffff 00008200 DPL=0 LDT
TR =0000 00000000 0000ffff 00008b00 DPL=0 TSS32-busy
GDT=     000f61e0 00000037
IDT=     000f621e 00000000
CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000044 CCD=00000000 CCO=EFLAGS
EFER=0000000000000000
SMM: enter
EAX=000000b5 EBX=00007e28 ECX=00005678 EDX=00000003
ESI=06f0b050 EDI=06ffec55 EBP=00006950 ESP=00006950
EIP=000f7e25 EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
CS =0008 00000000 ffffffff 00c09b00 DPL=0 CS32 [-RA]
SS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
DS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
FS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
GS =0010 00000000 ffffffff 00c09300 DPL=0 DS   [-WA]
LDT=0000 00000000 0000ffff 00008200 DPL=0 LDT
TR =0000 00000000 0000ffff 00008b00 DPL=0 TSS32-busy
GDT=     000f61e0 00000037
IDT=     000f621e 00000000
CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000008 CCD=0000693c CCO=ADDL
EFER=0000000000000000
SMM: after RSM
EAX=000000b5 EBX=00007e28 ECX=00005678 EDX=00000003
ESI=06f0b050 EDI=06ffec55 EBP=00006950 ESP=00006950
EIP=00007e28 EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =d900 000d9000 ffffffff 00809300
CS =f000 000f0000 ffffffff 00809b00
SS =0000 00000000 ffffffff 00809300
DS =0000 00000000 ffffffff 00809300
FS =0000 00000000 ffffffff 00809300
GS =ca00 000ca000 ffffffff 00809300
LDT=0000 00000000 0000ffff 00008200
TR =0000 00000000 0000ffff 00008b00
GDT=     00000000 00000000
IDT=     00000000 000003ff
CR0=00000010 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000004 CCD=00000001 CCO=EFLAGS
EFER=0000000000000000

Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
Servicing hardware INT=0x08
Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
-------------------------------------------------------------------------------More focus here
check_exception old: 0xffffffff new 0xd
     0: v=0d e=0000 i=0 cpl=3 IP=000f:00000593 pc=00000593 SP=0017:00000501 env->regs[R_EAX]=00000041
EAX=00000041 EBX=00000000 ECX=00000000 EDX=00000000
ESI=00000e00 EDI=00000e00 EBP=00000000 ESP=00000501
EIP=00000593 EFL=00000006 [-----P-] CPL=3 II=0 A20=1 SMM=0 HLT=0
ES =0000 00000000 007fffff 00c01300
CS =000f 00000000 003fffff 00c0fa00 DPL=3 CS32 [-R-]
SS =0017 00000000 003fffff 00c0f200 DPL=3 DS   [-W-]
DS =0017 00000000 003fffff 00c0f300 DPL=3 DS   [-WA]
FS =0000 00000000 007fffff 00c01300
GS =0000 00000000 007fffff 00c01300
LDT=0028 00000508 00000040 0000e200 DPL=3 LDT
TR =0020 00000521 00000068 0000e900 DPL=3 TSS32-avl
GDT=     000000c0 0000002f
IDT=     000000f8 00000007
CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000004 CCD=00000006 CCO=EFLAGS
EFER=0000000000000000
check_exception old: 0xd new 0xd
     1: v=08 e=0000 i=0 cpl=3 IP=000f:00000593 pc=00000593 SP=0017:00000501 env->regs[R_EAX]=00000041
EAX=00000041 EBX=00000000 ECX=00000000 EDX=00000000
ESI=00000e00 EDI=00000e00 EBP=00000000 ESP=00000501
EIP=00000593 EFL=00000006 [-----P-] CPL=3 II=0 A20=1 SMM=0 HLT=0
ES =0000 00000000 007fffff 00c01300
CS =000f 00000000 003fffff 00c0fa00 DPL=3 CS32 [-R-]
SS =0017 00000000 003fffff 00c0f200 DPL=3 DS   [-W-]
DS =0017 00000000 003fffff 00c0f300 DPL=3 DS   [-WA]
FS =0000 00000000 007fffff 00c01300
GS =0000 00000000 007fffff 00c01300
LDT=0028 00000508 00000040 0000e200 DPL=3 LDT
TR =0020 00000521 00000068 0000e900 DPL=3 TSS32-avl
GDT=     000000c0 0000002f
IDT=     000000f8 00000007
CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000004 CCD=00000006 CCO=EFLAGS
EFER=0000000000000000
check_exception old: 0x8 new 0xd
Triple fault
```

1. `SMM` (**System Management Mode**) -  This is a high-privilege mode used by BIOS/firmware to handle things like power management or hardware control.  OS have no control over it
2. `RSM` (**Resume from System Management**) - This returns the CPU to whatever it was doing before the SMI hit. Control back to user control


Look before Triple fault's and after RSM
```
SMM: after RSM
EAX=000000b5 EBX=00007e28 ECX=00005678 EDX=00000003
ESI=06f0b050 EDI=06ffec55 EBP=00006950 ESP=00006950
EIP=00007e28 EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =d900 000d9000 ffffffff 00809300
CS =f000 000f0000 ffffffff 00809b00
SS =0000 00000000 ffffffff 00809300
DS =0000 00000000 ffffffff 00809300
FS =0000 00000000 ffffffff 00809300
GS =ca00 000ca000 ffffffff 00809300
LDT=0000 00000000 0000ffff 00008200
TR =0000 00000000 0000ffff 00008b00
GDT=     00000000 00000000
IDT=     00000000 000003ff
CR0=00000010 CR2=00000000 CR3=00000000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
CCS=00000004 CCD=00000001 CCO=EFLAGS
EFER=0000000000000000
```

- Here, we can see the content of registers, `CR0=00000010` - Real mode
- CS:IP = `f000:00007e28`



```
Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
Servicing hardware INT=0x08
Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
Servicing hardware INT=0x0e
```

when executing code `f000:00007e28` it was interrupted

These represent the CPU attempting to handle hardware interrupts or exceptions. In x86, these hex codes have specific meanings:
- 0x08 : Double Fault
- 0x0E : Page Fault
- 0x0D : General Protection Fault


`check_exception old: 0xffffffff new 0xd` 
- `old` represents the previous exception or interrupt vector that was being processed when a `new` one occurred.
- The value `0xffffffff` is a sentinel value (essentially -1) used by the CPU emulator to indicate "None" or "No active exception."
- It means the CPU was running normally (no pending faults) and then suddenly hit a General Protection Fault (0x0d). This is the "Root Cause" of the crash sequence.

`0: v=0d e=0000 i=0 cpl=3 IP=000f:00000593 pc=00000593 SP=0017:00000501 env->regs[R_EAX]=00000041` This is state dump - usually right when a crash, interrupt, or breakpoint occurred.
- `v=0d`: This is the Interrupt/Exception vector for a General Protection Fault (GPF)
- `e=0000`: The Error Code. Some exceptions provide an extra code to help debug. Here, it’s zero, which is common for many GPFs.
- `i=0`: Indicates whether this was an internal exception (1) or an external interrupt (0).
- `cpl=3`: The Current Privilege Level. In x86 architecture, 3 is "User Mode" (the least privileged). If it were 0, the CPU would be in "Kernel Mode."
- `IP=000f:00000593`: This is the Instruction Pointer
- `SP=0017:00000501`: The Stack Pointer

## Analysis
Flow
1. First Fault: `old: 0xffffffff new 0xd`
    Translation: "Nothing was wrong, but now I just hit a GPF (0x0d). I need to look at the Interrupt Descriptor Table (IDT) to find the handler."
    The place is f:593
2. Second Fault: `old: 0xd new 0xd`
    Translation: "While I was trying to start the GPF handler, another GPF (0x0d) happened. Because I hit a fault while processing a fault, I am now upgrading this to a Double Fault (0x08)."
3. Third Fault:  `old: 0x8 new 0xd`
    Translation: "Now I'm trying to call the Double Fault (0x08) handler, but I just hit another GPF (0x0d). That’s three strikes."
4. Triple Fault:
    CPU giveup abd reboot

SO the issue here is CPL3 executing interrupt, that don't have permission


