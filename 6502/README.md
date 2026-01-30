## W6502
[Datasheet](https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf)
A Vector is a specific memory address where the CPU looks to find the starting location of an interrupt handler. It’s like a "shortcut" or a "pointer." For example, when a Reset occurs, the CPU always looks at a specific spot in memory to find out where the program starts.


```
() -> indirect

# -> immediate

add, y/x -> index
```
### Absolute Indexed Indirect (a,x)
Instruction: JMP ($1000, X)

1. Base Address: $1000

2. If X = 4: The CPU looks at `$1000 + 4 = $1004`. `1004` is the effective address

3. The Pointer: The CPU looks at memory locations `$1004` and `$1005`.

4. The Result: If `$1004` contains `$55` and `$1005` contains `$80`, the CPU jumps to address `$8055` (new address).

### Absolute Indexed with X a,x
1. Base Address: $1000
2. If X = 4: The CPU looks at `$1000 + 4 = $1004`. `1004` is the effective address

### Absolute Indexed with Y a,y
1. Base Address: $1000
2. If Y = 4: The CPU looks at `$1000 + 4 = $1004`. `1004` is the effective address

### Absolute Indirect (a)
JMP $1000 (only for jmp)
new address become 1000

### Accumulator A
INC A, DEC A, ..

### Immediate Addressing #
LDA #$05
`05` is not address it is the value, it will store in the `A` register

Immediate	LDA #$10	Put the number 10 into the Accumulator.
Absolute	LDA $10	    Go to Address $0010 and get whatever number is hiding there.

### Implied i
No address involved directly, but it is part of the instruction eg:
1. TAY: Transfer Accumulator to Y.
2. TAX: Transfer Accumulator to X.
3. CLC: CLear Carry flag. (The CPU knows to just flip the Carry switch to 0).
4. PHA: PHush Accumulator onto the stack.

### Program Counter Relative r
0600: `BEQ $05` (If Zero flag is set, branch with offset 05)

0602: `LDA #$01` (Next instruction)

1. The CPU reads the BEQ at $0600.
2. The Program Counter (PC) automatically moves to $0602 (the instruction after the branch).
3. If the branch is taken, the CPU adds the offset $05 to the current PC: `$0602 + $05 = $0607`
4. The CPU "jumps" to $0607 and executes whatever is there.

### Zero Page zp
In 6502 Assembly, the Zero Page is the first 256 bytes of memory (addresses $0000 to $00FF). Because the 6502 has very few internal registers ($A$, $X$, and $Y$), the designers created the Zero Page to act like a massive bank of "pseudo-registers" that are faster and more efficient than the rest of memory.

`LDA $05` (Zero Page): The CPU sees the instruction and immediately knows the address is $0005.

`LDA $0205` (Absolute): The CPU has to do extra work to fetch the $05 and the $02 before it even knows where to look.

----

Memory in the 6502 is divided into "pages" of 256 bytes each.

Page 0: $0000 – $00FF (Zero Page)

Page 1: $0100 – $01FF (The Stack)

$\vdots$

$FFFA - $FFFB - NMI 
$FFFC - $FFFD - Reset
$FFFE - $FFFF - IRQ/BRK 

## W65C22S
This is a middle man chip between the CPU and the outside world (like buttons, LEDs, or printers).
[DataSheet](https://web.archive.org/web/20080920212004if_/http://archive.6502.org:80/datasheets/wdc_w65c22s_mar_2004.pdf)

For an OS or driver developer, there are three big concepts we need to master to make this chip work.

### 1. The Registers (The "Control Panel")
The chip has 16 "slots" called registers. Each slot is mapped to a memory address. To the CPU, talking to the chip looks just like reading or writing to RAM.
* Data Direction Registers (DDRA/DDRB): This is the first thing your driver touches. You tell the chip: "Is this pin an Input (listening) or an Output (talking)?"
* Input-Output Registers (IR A/B - OR A/B): This is where the actual data lives. If you want to turn on an LED connected to the chip, you write a 1 to this register.
* Other importanat are Counters, timers, interrupt

### 2. Interrupts (The "Doorbell")
As an OS developer, you don't want your CPU to sit in a loop constantly asking the chip, "Do you have data yet?" (This is called polling, and it wastes power/time).
* On the W65C22S, you enable interrupts using the IER (Interrupt Enable Register). It has a weird rule: to turn an interrupt on, you must set the top bit (Bit 7) to 1. To turn it off, you set Bit 7 to 0.

### 3. Timers (The "Metronome")
This chip has two built-in clocks (Timer 1 and Timer 2). This is how your OS knows that time is passing.
* Timer 1 is usually used for the "System Tick." You program it to count down and "interrupt" the CPU every 1 millisecond.
* This "tick" is what allows your OS to switch between different apps (multitasking). When the timer hits zero, the kernel says, "Time's up for App A; let's give App B a turn."


https://github.com/mkayaalp/computer-organization-logisim/blob/main/added_lcd_display.circ


### Vasm

```
cd /tmp
curl -O http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
tar -xvf vasm.tar.gz
cd vasm

make CPU=6502 SYNTAX=oldstyle
alias vasm='/tmp/vasm/vasm6502_oldstyle'

alias vasm='/media/ssd/Project/minimal-os-exploration/6502/vasm/vasm6502_oldstyle'

vasm /tmp/test.s -Fbin -dotdir -o /tmp/test.bin

hexdump -C /tmp/test.bin
```


```
address
-----------
lda 6002 -> 6002 is address in decimal
lda $6002 -> 6002 is address in hexadecimal
lda %101010.. -> address in binary

immediate value
-------------------
lda #$ff    -> load immediate(#), hexa value ff
lda #62     -> load immediate 62 decimal
```