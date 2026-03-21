The 80386 microprocessor introduces paging as a second level of address translation. This mechanism operates after segmentation to map linear addresses into physical addresses.

### Address Translation Flow

The process occurs in two main stages: **Segmentation** and **Paging**.

1. **Logical Address (Virtual Address):** This consists of a **Selector** and an **Offset**.
2. **Segmentation Unit:** The processor uses the Selector to find a descriptor in the GDT or LDT. It adds the **Base Address** from that descriptor to the **Offset**.
3. **Linear Address:** The result of the segmentation step is a 32-bit Linear Address.
4. **Paging Unit Check:**
    * **If Paging is Disabled (CR0 PG bit = 0):** The Linear Address becomes the **Physical Address**.
    * **If Paging is Enabled (CR0 PG bit = 1):** The Linear Address passes through the Paging Unit to become the **Physical Address**.


## Paging
Paging divides the linear address space into fixed-size blocks called pages (4 KB each). The physical memory is similarly divided into page frames. This allows the operating system to store data in non-contiguous areas of physical RAM while maintaining a contiguous appearance in the linear address space.

**Control Register 3 (CR3)**
The CR3 register, also known as the Page Directory Base Register (PDBR), holds the physical address of the Page Directory. Paging is enabled by setting the PG bit (bit 31) in the CR0 register. If the PG bit is zero, linear addresses are treated as physical addresses.

**Linear Address Breakdown**
The 80386 translates a 32-bit linear address by splitting it into three distinct fields:

| Field | Bits | Description |
| --- | --- | --- |
| **Directory** | 31 – 22 | Index into the Page Directory (10 bits). |
| **Table** | 21 – 12 | Index into a Page Table (10 bits). |
| **Offset** | 11 – 0 | The specific byte within the 4 KB page (12 bits). |


### Two-Level Structure

The 80386 utilizes a two-level table structure to minimize memory overhead for page mapping.


**Structure for Page Directory and Table**

| Bit Range | Field Name | Description |
| --- | --- | --- |
| **31–12** | **Page Frame Address** | High-order 20  bits of the physical address to locate page table entry or page frame . |
| **11–9** | **Avail** | Bits available for software use; ignored by hardware. |
| **8–7** | **Reserved** | Must be set to 0. |
| **6** | **D (Dirty)** | 1 = Page has been written to page reference by this entry(PTE only). |
| **5** | **A (Accessed)** | 1 = Entry has been used for a translation. |
| **4–3** | **Reserved** | Must be set to 0. |
| **2** | **U/S** | 0 = Supervisor; 1 = User. |
| **1** | **R/W** | 0 = Read-Only; 1 = Read/Write. |
| **0** | **P (Present)** | 1 = Entry is valid and in RAM. |

**Why 20 Bits are Required?**
Physical memory on the 80386 is addressed using 32 bits. However, every page starts on a 4 KB boundary.
- A 4 KB boundary means the last 12 bits of the address are always zero $(2^{12} = 4,096)$
- Because the last 12 bits are always zero, the processor only needs to store the top 20 bits ($32 - 12 = 20$) to identify the start of any 4 KB page frame in physical RAM.

1. Locating the Page Directory Entry (PDE)
    The CR3 register holds the 20-bit physical base address of the Page Directory.
    - The 12 Missing Bits: Because the Page Directory must start on a 4 KB boundary, the lower 12 bits of its physical address are always zero. The processor automatically appends twelve zeros to the 20 bits from CR3 to form a 32-bit address.
    - The 10-bit Offset: The top 10 bits of the Linear Address (bits 31–22) serve as an index. The processor multiplies this 10-bit index by 4 (because each entry is 4 bytes) and adds it to the Page Directory base address.
    - Result: This identifies one specific 4-byte Page Directory Entry.

2. Locating the Page Table Entry (PTE)
    The Page Directory Entry contains a 20-bit physical base address for a Page Table.
    - The 10-bit Offset: The middle 10 bits of the Linear Address (bits 21–12) serve as the index for the Page Table.
    - Result: The processor combines the 20-bit base from the PDE with this 10-bit index to find one specific 4-byte Page Table Entry.

3. Locating the Physical Page Frame
    The Page Table Entry contains a 20-bit physical base address for the final 4 KB Page Frame.
    - Combining for 32 bits: The processor takes the 20 bits from the PTE and appends the 12-bit Offset from the Linear Address (bits 11–0).
    - Physical Address: This results in the final 32-bit Physical Address used to access data in RAM.

#### 1. Page Directory

- The Page Directory is a single 4 KB page containing ($2^{10} == 1024$) 1,024 entries, known as **Page Directory Entries (PDEs)**. 
- Each PDE points to the base address of a Page Table. 
- Each entry length is 4 bytes

#### 2. Page Table

- Each Page Table is also 4 KB and contains ($2^{10} == 1024$) 1,024 **Page Table Entries (PTEs)**. 
- Each PTE contains the starting physical address of a 4 KB page frame.
- Each entry length is 4 bytes
- Page table gives physical base address (page frame)


#### 3. Page offset
- Offset is 12bit length can address ($2^{12} == 4096$) unique physical address
- Total entries possible 
    $$\text{Total Page Directory} \times \text{Total Page Table for each Page Directory} \times \text{Offset for each page frame} = 1024 * 1024 * 4096 = 4294967296 = 4096\text { MB or } 4 \text{ GB}$$

### Translation Lookaside Buffer (TLB)

To accelerate this process, the 80386 uses a **TLB**. This is an on-chip cache that stores the most recently used linear-to-physical address translations. This reduces the need to read the Page Directory and Page Tables from memory for every bus cycle.

## Page Fault
When the Present (P) bit (bit 0) in a Page Directory Entry (PDE) or a Page Table Entry (PTE) is set to 0, the entry is considered invalid for address translation.

**The Page Fault Exception (Interrupt 14)**
If the processor attempts to access a linear address and finds the P bit is 0, it generates a Page Fault. This is an internal exception that stops the current instruction and transfers control to a specific handler.

The Role of the CR2 Register
When a Page Fault occurs, the processor automatically stores the 32-bit Linear Address that caused the fault into the Control Register 2 (CR2). This allows the operating system to identify exactly which part of the memory space requires attention.


The processor pushes an Error Code onto the stack of the Page Fault handler. This 15-bit code provides three specific pieces of information:


| Bit | Name | Description |
| --- | --- | --- |
| **0 (P)** | **Present** | 0 = Fault caused by a "Not Present" page; 1 = Page protection violation. |
| **1 (W/R)** | **Write/Read** | 0 = Fault caused by a Read; 1 = Fault caused by a Write. |
| **2 (U/S)** | **User/Supervisor** | 0 = Fault occurred in Supervisor mode; 1 = Fault occurred in User mode. |


**Handling the Page Fault**
The operating system uses the information in CR2 and the Error Code to decide how to proceed.
1. Demand Paging: If the page exists on a hard disk but not in RAM, the operating system loads the 4 KB page from the disk into a physical page frame.
2. Updating the Entry: The operating system puts the new 20-bit physical base address into the PTE and sets the Present (P) bit to 1.
3. Instruction Restart: The processor restarts the instruction that caused the fault. Because the P bit is now 1, the translation succeeds.

## Page-Level Protection
- The 80386 introduces Page-Level Protection, which allows the operating system to set specific rules for every 4 KB block of memory.
- The rules are stored in the Page Table Entry (PTE). Every PTE contains attribute bits that the hardware checks during every memory access.
- Present (P) Bit: Determines if the page is currently in physical RAM.
- Read/Write (R/W) Bit: 
    * 0: The page is Read-Only.
    * 1: The page is Read/Write.
- User/Supervisor (U/S) Bit:
    * 0: Supervisor mode only (Ring 0, 1, or 2).
    * 1: User mode (Ring 3) can also access this page.

When the processor attempts to access a linear address, the Memory Management Unit (MMU) compares the current state of the CPU against the bits in the Page Table.
| CPU State | Requested Action | Page Table Rule | Result |
| --- | --- | --- | --- |
| **User Mode** | Write | Read-Only (R/W=0) | **Page Fault (#PF)** |
| **User Mode** | Read | Supervisor Only (U/S=0) | **Page Fault (#PF)** |
| **Supervisor** | Write | Read-Only (R/W=0) | **Allowed** (on the 80386*) |
| **Any Mode** | Any Access | Not Present (P=0) | **Page Fault (#PF)** |

The Supervisor (Ring 0) can usually write to any page, even if it is marked "Read-Only".

The 80386 distinguishes between a memory address that does not exist and an address that the current program is not allowed to use.
- Not Present (P=0): This is used for Virtual Memory. The OS sees this, fetches the page from a disk, sets P=1, and restarts the instruction.
- Protection Violation (P=1): The page is in RAM, but the program tried to do something illegal (like a User-mode program trying to read Kernel-mode data). This usually results in the OS terminating the application.