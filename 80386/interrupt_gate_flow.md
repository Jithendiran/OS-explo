### Interrupt/trap Gate Privilege Working

- Technically Ring 0 can raise Interrupt gate using software instruction `int`
- Usually traps gate permisison is set to ring 3, ring 3 programs are eligible to raise exeception

#### 1. The Trigger

* **Current State:** CPL is 3 (User Mode).
* **Trigger:** 
    - Interrupt gate Hardware sends an IRQ (e.g., Timer,)
    - Trap gate software sends `INT 0x80`
* **Vector:** The CPU receives a vector number (e.g., `0x80`).
* **Table Lookup:** The CPU multiplies the vector by 8 to find the offset in the **IDT** (Interrupt Descriptor Table).

#### 2. Interrupt Gate Identification

* The CPU accesses the IDT entry.
    - Selector: `0000 0000 1000 0000`
    - DPL : 00
    - Table : 0 (ignore)
    - Index `00001 0000` (16) 16 * 8 = 128 = IDTR + 128
* **Selector:** `0x08`
    * **Offset:** `0x00001234` (The handler address)
    * **P:** 1
    * **DPL:** 0  
    * **Type:** 
        - `01110` (if Interrupt Gate)
        - `01111` (if Trap gate)


* **Privilege Check :** Gate DPL $\geq$ CPL. (This check is for can this user access?)
    * If interrupt is raised by hardware this check is skipped
    * if interrupt is raised by software this check is mandatory


#### 3. Target Code Segment Lookup

* The Gate contains a **Target Selector** (`0x08`). `0000 0000 0000 1000`
* **Table:** 0 (GDT).
* **Index:** 1 ($1 \times 8 = 8$ bytes into the GDT).
* The CPU accesses the GDT to find the Descriptor:
    * DPL: 0
    * Type: Executable, Non-conforming.

#### 4. Code Segment Validation

* **Privilege Check 2:** Target DPL $\leq$ CPL.
    - $0 \leq 3$ (True). Elevation to Ring 0 is required. 
    - if conforming set no Elevation and stack switch

* **Final Entry Point:** Base from GDT + Offset from IDT Gate.

#### 5. Stack Switch (The TSS Journey)

* Since CPL (3) $\neq$ Target DPL (0), a stack switch is mandatory. if CPL == target DPL no stack switch
* **TSS Lookup:** CPU reads `SS0` and `ESP0` from the TSS.
* **New Stack Address:** Base of SS0 + ESP0.

#### 6. Information Saving (The "Interrupt Stack Frame")

Unlike the Call Gate, there is **no parameter copying**. The CPU pushes these onto the **Ring 0 Stack**:

1. **Old SS**
2. **Old ESP**
3. **Old EFLAGS** (Crucial! The Call Gate does not save flags Trap and interrupt pushes).
4. **Old CS**
5. **Old EIP**
6. **Error Code:** (Only for specific exceptions like Page Faults; otherwise, nothing is pushed here).

#### 7. The "Interrupt Gate Magic" (CLI)

* Before the first line of code executes, the CPU sets **IF = 0** (Interrupt Flag if only for interrupt gate).
* **Result:** Hardware interrupts are now disabled. The kernel is now "atomic."
* **CPL** is now 0. Handler executes.

#### 8. Return (IRET)

* The handler ends with `IRET` (Interrupt Return), not `RET`.
* **IRET Action:**
1. Pops **EIP**, **CS**, and **EFLAGS** (this restores the user's Interrupt Flag, usually re-enabling interrupts).
2. Pops **ESP** and **SS** (restoring the User Stack).


* **CPL** returns to 3.
