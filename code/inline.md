## Inline assembly
Usually we write in c compiler translates to assembley, Inline assembley is a way we directly write assembley code.
But here problem is C uses Variables (like int x), and Assembly uses Registers (like eax) need a way to bridge the connection.

```c
asm ( "The Instruction"                         // 1. What do you want to do?
    : "Output Variables"      /* optional */    // 2. Where should the result go?
    : "Input Variables"       /* optional */    // 3. What values are you starting with?
    : "Clobber List"          /* optional */    // 4. What did you "mess up" or change?
);
```

### The Instruction
This section contains the actual instructions for the processor.
* Instructions are enclosed in double quotes.
* Registers name can be used (like eax or rbx) or placeholders like %0, %1, and %2 are used.
* These placeholders correspond to the order of variables listed in the Output and Input sections.

###  Output Variables
This section specifies which C variables will receive data from the assembly code. They are prefixed with a constraint string eg: `"=r" (result)` tells the compiler to use a general-purpose register for this variable.
* The `=` symbol indicates the variable is being written to (output) and the r tells the compiler to use a General Purpose Register.
* : The name of the C variable is placed in parentheses, such as (result).

### Input Variables
These are C variables providing data to the assembly code. A constraint like `"r"` indicates the value should be placed in a register before the assembly executes.

### Clobber List
This section informs the compiler which registers or memory locations are modified by the assembly code. This prevents the compiler from assuming those registers still hold their previous C values, avoiding data corruption.


### Constraints and Variables

```c
int main() {
    int src = 10;
    int dst;
    asm (
        ".intel_syntax noprefix;" // Switch to Intel syntax
        "mov eax, %1;"            // Move %1 (src) into eax
        "add eax, 5;"             // Add 5 to eax
        "mov %0, eax;"            // Move eax into %0 (dst)
        ".att_syntax;"            // Switch back to AT&T (important!)
        : "=r" (dst)              // %0
        : "r" (src)               // %1
        : "eax"                   // Clobber list
    );
    return 0;
}
```

```sh
$ gcc main.c
$ objdump -d -M intel a.out 
0000000000001129 <main>:
    1129:	f3 0f 1e fa          	endbr64
    112d:	55                   	push   rbp
    112e:	48 89 e5             	mov    rbp,rsp
    1131:	c7 45 f8 0a 00 00 00 	mov    DWORD PTR [rbp-0x8],0xa      // src = 10
    1138:	8b 55 f8             	mov    edx,DWORD PTR [rbp-0x8]      // moving src to edx
    113b:	89 d0                	mov    eax,edx                      // ;---- asm start; 
    113d:	83 c0 05             	add    eax,0x5                      // add
    1140:	89 c2                	mov    edx,eax                      // moving eax result ti edx
    1142:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx      // moving edx to dst
    1145:	b8 00 00 00 00       	mov    eax,0x0
    114a:	5d                   	pop    rbp
    114b:	c3                   	ret

```
> The compiler usually expects AT&T syntax for the rest of the C file. If the assembly block does not switch back, the compiler may crash when it tries to generate the remaining code for the program.
> Instead of writing .intel_syntax inside the string, the entire project can be compiled with the flag `-masm=intel`. If this flag is used, the assembly block simplifies significantly:

#### The Operand Numbering System
The compiler assigns a number to every C variable listed in the input and output sections. These numbers start at %0 and increase based on the order of appearance.
* `%0`: Refers to the first variable listed (usually the first output).
* `%1`: Refers to the second variable listed.
* `%2`: Refers to the third variable listed.

#### Constraints and Variables
The syntax uses a specific format to link C variables to the assembly code: `"constraint" (variable_name)`
* `The Constraint ("r")`: This tells the compiler to pick a general-purpose register (like EAX, EBX, or ECX) for this variable. The compiler decides which specific register is best.
* `The Variable ((dst))`: This is the actual C variable name. If the code mentions `(dst)`, the compiler knows to link the value of `dst` to the assigned operand number.
* `dst` value is assigned to general purpose register, Compiler will choose the register  
* if `=` present tells the compiler that the assembly code will write a value to this variable. 
* if `=` not present tells the compiler to put this value in a register.


**Important**
* Using `asm volatile` prevents the compiler from optimizing out or moving the assembly code.
* `"r"` represents a register, `"m"` represents memory, and `"i"` represents an immediate (constant) value.



####  Common Constraint Characters
Constraints define the "storage class" for an operand. The compiler uses these to decide whether to load a value into a register, keep it in memory, or treat it as a constant.

| Character | Name | Description |
| --- | --- | --- |
| **`r`** | Register | The compiler chooses any available general-purpose register to hold the variable. |
| **`m`** | Memory | The variable is accessed directly in RAM. No register is used. |
| **`i`** | Immediate | Represents an integer constant (a literal value) known at compile time. |
| **`g`** | General | Allows the compiler to choose between a register, memory, or immediate based on efficiency. |
| **`f`** | Floating Point | Specifies the use of a floating-point register. |
| **`a`, `b`, `c`, `d`** | Specific Reg | Forces the use of specific x86 registers: `%eax`, `%ebx`, `%ecx`, or `%edx`. |


**Important of clobber list**
```c
int main() {
    int src = 10;
    int dst;
    asm (
        ".intel_syntax noprefix;" // Switch to Intel syntax
        "mov eax, %1;"            // Move %1 (src) into eax
        "add eax, 5;"             // Add 5 to eax
        "mov %0, eax;"            // Move eax into %0 (dst)
        ".att_syntax;"            // Switch back to AT&T (important!)
        : "=r" (dst)              // %0
        : "r" (src)               // %1
        :                         // Clobber list
    );
    return 0;
}
```

```sh
$ gcc main.c
$ objdump -d -M intel a.out 
0000000000001129 <main>:
    1129:	f3 0f 1e fa          	endbr64
    112d:	55                   	push   rbp
    112e:	48 89 e5             	mov    rbp,rsp
    1131:	c7 45 f8 0a 00 00 00 	mov    DWORD PTR [rbp-0x8],0xa
    1138:	8b 45 f8             	mov    eax,DWORD PTR [rbp-0x8]
    113b:	89 c0                	mov    eax,eax      //  **Notice the confusion**
    113d:	83 c0 05             	add    eax,0x5
    1140:	89 c0                	mov    eax,eax      //  **Notice the confusion**
    1142:	89 45 fc             	mov    DWORD PTR [rbp-0x4],eax
    1145:	b8 00 00 00 00       	mov    eax,0x0
    114a:	5d                   	pop    rbp
    114b:	c3                   	ret
```

### The Constraint Modifier `&` (Earlyclobber)

Sometimes the compiler uses the same register for an input and an output (as seen with `edx` in the previous objdump). If the assembly code needs the input to remain unchanged while it starts writing to the output, the Earlyclobber modifier & is used.

```c
int main() {
    int src = 10;
    int dst;
    asm (
        ".intel_syntax noprefix;" // Switch to Intel syntax
        "mov eax, %1;"            // Move %1 (src) into eax
        "add eax, 5;"             // Add 5 to eax
        "mov %0, eax;"            // Move eax into %0 (dst)
        ".att_syntax;"            // Switch back to AT&T (important!)
        : "=&r" (dst)             // %0
        : "r" (src)               // %1
        : "eax"                   // Clobber list
    );
    return 0;
}
```

```sh
$ gcc main.c
$ objdump -d -M intel a.out 
0000000000001129 <main>:
    1129:	f3 0f 1e fa          	endbr64
    112d:	55                   	push   rbp
    112e:	48 89 e5             	mov    rbp,rsp
    1131:	c7 45 f8 0a 00 00 00 	mov    DWORD PTR [rbp-0x8],0xa
    1138:	8b 4d f8             	mov    ecx,DWORD PTR [rbp-0x8]  // ecx for src
    113b:	89 c8                	mov    eax,ecx
    113d:	83 c0 05             	add    eax,0x5
    1140:	89 c2                	mov    edx,eax
    1142:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx  // edx for dst
    1145:	b8 00 00 00 00       	mov    eax,0x0
    114a:	5d                   	pop    rbp
    114b:	c3                   	ret
        	ret
```

### Other Constraint
1. **memory(m)**
    The `m` constraint tells the compiler to leave the variable in its original memory location rather than loading it into a CPU register. This is useful for instructions that can operate directly on memory.

2. **Immediate(i)**
    The `i` constraint is used for Immediate values. These are constants known at compile-time. The compiler replaces the placeholder with the literal number.

3. **General (g)**
    The `g` constraint stands for General. It gives the compiler the freedom to choose the most efficient option: a Register, Memory, or an Immediate value.
    * If a register is free, the compiler uses a register.
    * If all registers are busy, the compiler uses memory.
    * If the value is a constant, the compiler may use an immediate.

4. **Floating Point (f)**
    The `f` constraint is specific to Floating Point registers. On x86 architecture, this usually refers to the 80-bit registers in the FPU (Floating Point Unit) stack (ST0 through ST7).

```c
// using AT&T syntax
void main()
{

	int val = 10;

// Increment the value directly in memory
	asm ("incl %0"
	     : "=m" (val)  // %0 is a memory location
	     : "m" (val)
	    );

//---------------------------------------------------------------------------

#define ADD_AMOUNT 10

	int dst = 5;

	asm ("addl %1, %0"
	     : "+r" (dst)       // %0 is a register (`+` read/write), = is only write by using + we gave both permission
	     : "i" (ADD_AMOUNT) // %1 is the literal constant 10
	    );
//---------------------------------------------------------------------------
	int x = 100;
	int y;

	asm ("movl %1, %0"
	     : "=g" (y) // y can be register or memory
	     : "g" (x)  // x can be register, memory, or immediate
	    );

//-----------------------------------------------------------------------------
	float pi = 3.14f;
	float result;

	asm ("fld %1;"   // Load float onto FPU stack (Push pi to ST0)
	     "fld %1;"   // Load it again, (previous pi moves to ST1)
	     "faddp;"    // Add ST0 and ST1, pop result into ST0
	     : "=&t" (result) // // Output: result is at the top of stack (ST0)
	     : "f" (pi)
	    );
}
```
```sh
$ gcc main.c
$ objdump -d -M intel a.out 
0000000000001149 <main>:
    1149:	f3 0f 1e fa          	endbr64
    114d:	55                   	push   rbp
    114e:	48 89 e5             	mov    rbp,rsp
    1151:	48 83 ec 20          	sub    rsp,0x20
    1155:	64 48 8b 04 25 28 00 	mov    rax,QWORD PTR fs:0x28
    115c:	00 00 
    115e:	48 89 45 f8          	mov    QWORD PTR [rbp-0x8],rax
    1162:	31 c0                	xor    eax,eax
    1164:	c7 45 e0 0a 00 00 00 	mov    DWORD PTR [rbp-0x20],0xa

    116b:	ff 45 e0             	inc    DWORD PTR [rbp-0x20]

    116e:	c7 45 e4 05 00 00 00 	mov    DWORD PTR [rbp-0x1c],0x5
    1175:	8b 45 e4             	mov    eax,DWORD PTR [rbp-0x1c]
    1178:	83 c0 0a             	add    eax,0xa #immediate
    117b:	89 45 e4             	mov    DWORD PTR [rbp-0x1c],eax

    117e:	c7 45 e8 64 00 00 00 	mov    DWORD PTR [rbp-0x18],0x64
    1185:	8b 45 e8             	mov    eax,DWORD PTR [rbp-0x18]
    1188:	89 45 ec             	mov    DWORD PTR [rbp-0x14],eax
    118b:	f3 0f 10 05 71 0e 00 	movss  xmm0,DWORD PTR [rip+0xe71]        # 2004 <_IO_stdin_used+0x4>
    1192:	00 
    1193:	f3 0f 11 45 f0       	movss  DWORD PTR [rbp-0x10],xmm0

    
    1198:	d9 45 f0             	fld    DWORD PTR [rbp-0x10]
    119b:	d9 c0                	fld    st(0)
    119d:	d9 c0                	fld    st(0)
    119f:	de c1                	faddp  st(1),st
    11a1:	dd d9                	fstp   st(1)
    11a3:	d9 5d f4             	fstp   DWORD PTR [rbp-0xc]
    11a6:	90                   	nop
    11a7:	48 8b 45 f8          	mov    rax,QWORD PTR [rbp-0x8]
    11ab:	64 48 2b 04 25 28 00 	sub    rax,QWORD PTR fs:0x28
    11b2:	00 00 
    11b4:	74 05                	je     11bb <main+0x72>
    11b6:	e8 95 fe ff ff       	call   1050 <__stack_chk_fail@plt>
    11bb:	c9                   	leave
    11bc:	c3                   	ret
```
