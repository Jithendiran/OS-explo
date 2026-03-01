### Call Gate Privilege working

#### 1. Initialization and Initial Instruction

* **Current State:** CPL is 3 (User Mode). TSS and LDTR are loaded.  Three 2-byte parameters are pushed onto the Ring 3 stack.
* **Instruction:** `CALL 0x50:0x12345678`.
* **Selector Breakdown:** `0x50` translates to Binary `0000 0000 0101 0000`.
* **RPL:** 00.
* **Table (TI):** 0 (Global Descriptor Table).
* **Index:** 1010 (10) ($10 \times 8 = 80$ bytes into the GDT).
* **Offset:** The instruction offset `0x12345678` is ignored by the CPU.

#### 2. Call Gate Identification

* The CPU accesses the 80th byte in the GDT and finds the **Call Gate Descriptor**.
    - selector = 0x24
    - offset = 0x0000 0100
    - p = 1
    - DPL = 3 
    - Type = 01100
    - Dowrd = 3
* **Type Check:** Type `01100` identifies it as a 32-bit Call Gate.
* **Privilege Check 1:** Gate DPL must be $\geq$ Max(CPL, Selector RPL).
* $3 \geq \text{Max}(3, 0)$ is true. Access is granted.


#### 3. Target Code Segment Lookup

* The Call Gate contains a **Target Selector** (`0x24`) and a **Target Offset** (`0x00000100`).
* **Selector Breakdown:** `0x24` translates to Binary `0000 0000 0010 0100`.
* **Table (TI):** 1 (Local Descriptor Table).
* **Index:** 0100 4 ($4 \times 8 = 32$ bytes into the table).
* **RPL:** 00. (ignored here) 
* The CPU accesses the LDT at the specified index to find the Code Segment Descriptor.
    - p = 1
    - DPL = 0
    - S = 1
    - X = 1
    - Type S = 1 (bits and value)
        - 3 -> 1
        - 2(Conforming) -> 0 ( if Conforming 1 no stack switch occur, it execute as CPL 3, Jump only execute if c = 1 )
        - 1 -> 1
        - 0 -> 1
    - G = 0
    - base address = 0x50000000
    - offset = 0x0

#### 4. Code Segment Validation

* **Permissions:** Segment is Executable, Non-conforming ($C=0$), and DPL is 0.
* **Privilege Check 2:** Target DPL must be $\leq$ CPL.
* $0 \leq 3$ is true. Elevation to Ring 0 is required.

* **Final Entry Point:** Base Address from executabe code segment (`0x50000000`) + Gate Offset (`0x00000100`) = `0x50000100`.

#### 5. Stack Switch (Ring 3 to Ring 0)

* Because a privilege change occurs ($C=0$ and DPL < CPL), the CPU initiates a stack switch.
* **TSS Lookup:** The CPU reads the Ring 0 (use executable code segment DLP as index to select ring 0 stack from TSS) Stack Selector (`SS0`) and Stack Pointer (`ESP0`) from the current TSS.  If the Target DPL were $1$, it would pull SS1 and ESP1
* **Descriptor Check:** The new Stack Segment must be a writable data segment with DPL 0.
    - ESP0 =  `0x30` -> 0000 0000 0011 0000
    - RPL   = `00` 
    - Table = `0` GDT
    - index = `0110` (6 * 8 = 48)
    - now go to the GDT 48th index

    Take the descriptor for stack segment 
    - p = 1
    - DPL = 0
    - S = 1
    - X = 0
    - Type S = 1 (bits and value)
        - 3 -> 0
        - 2 -> 1 
        - 1 -> 1
        - 0 -> 1
    - G = 0
    - base address = `0xf0000000`
    - offset = `0xff`
    **Check new CPL (0) <= RPL (0), pass**

* **New Stack Address:** Base `0xf0000000` + Offset `0xff` = `0xf00000ff`.

#### 6. Information Saving (New Stack Layout)

The CPU pushes the following onto the **Ring 0 Stack** in this specific order:

1. **Old SS:** User stack segment.
2. **Old ESP:** User stack pointer.
3. **Parameters:** The 3 parameters are copied from the Ring 3 stack to the Ring 0 stack.
4. **Old CS:** User code segment.
5. **Old EIP:** User instruction pointer.

#### 7. Execution and Return

* CPL is now 0. The kernel code executes.
* **Return Instruction:** `RET n` (where $n$ is the total byte count of parameters).
* **Privilege Check 3:** The CPU pops the saved CS and checks its RPL. Since RPL is 3 and CPL is 0, a transition back to lower privilege is triggered.

#### 8. Restoring User State

1. **Instruction Pointer:** CS and EIP are popped. check `DPL >= Max(RPL, CPL) ; 3 >= Max(3, 0)`
2. **Parameter Cleanup:** The `n` in `RET n` increments the Ring 0 ESP to bypass the copied parameters.
3. **Stack Restoration:** SS and ESP are popped, restoring the original Ring 3 stack context. `DPL >= Max(RPL, CPL) ; 3 >= Max(3, 0)`
4. **Final State:** CPL returns to 3.