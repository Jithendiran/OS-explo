## Reading 64 KB

### How address is calculated?**

`mov ax, [data]` — when executing this line, `data` is fetched from RAM and `ax` is a register. The CPU uses segment registers to locate data in memory. `data` belongs to the data segment `DS`. `data` is the offset within `DS`.

In 16-bit mode, the CPU registers (`AX`, `BX`, `CX`, `DX`, `SI`, `DI`, `BP`, `SP`) are only 16 bits wide.

$$2^{16} = 65{,}536 \text{ (64KB)}$$

If a 16-bit register like `BX` is incremented past `0xFFFF` (65,535), it simply rolls over to `0x0000`. It cannot physically point to a higher address on its own.

So segmented addressing is used: **Physical Address = Segment × 16 + Offset**

The segment register holds a fixed base. The offset selects a location within that base. The offset can range from `0x0000` to `0xFFFF`. If the offset is incremented by one byte past `0xFFFF`, it rolls over to `0x0000`.

When reading data, it must always stay within the 64KB segment range — for example, `0x10000` to `0x1FFFF` when `DS = 0x1000`.

A 64KB window is only valid when it starts at a multiple of 0x10000. Examples of valid natural 64KB windows:

```
0x00000 – 0x0FFFF
0x10000 – 0x1FFFF
0x20000 – 0x2FFFF
```

when we have offset address is `0x1001`, it will be converted to `0x10010` when we add our offset `0xFFFF` = `0x10010 + 0xFFFF` = `2000F` but the problem here is it is not in 64KB address range

The segment `DS = 0x1001` produces base `0x10010`. This base does **not** start at a 0x10000 boundary. So the segment range `0x10010 – 0x2000F` is **not** a natural 64KB window — it is a 64KB region that **crosses** the boundary between two natural windows.

`0x2000F` **is** inside the segment `DS = 0x1001`. The segment is exactly 64KB wide — `0x10010` to `0x2000F` = `0x10000` bytes = 64KB. That arithmetic is correct.

However, this segment is **not aligned** to a natural 64KB boundary. It starts at `0x10010`, not at `0x10000`. The segment cuts across two natural windows — the lower part sits in `0x10000–0x1FFFF`, and the upper part sits in `0x20000–0x2FFFF`.  0x10010 – 0x2000F is valid rangle from CPU view, only it is not aligned, CPU use extra clock cycle to read

Problem will happen when data is spanned between 64KB window


**Example with DS = 0x1001**

`DS = 0x1001` -> physical base = `0x1001 × 16` = `0x10010`

Adding the maximum offset: `0x10010 + 0xFFFF` = `0x2000F`

So the valid segment range is `0x10010` to `0x2000F`.**Reading a single byte at `0x2000F` is valid** — the offset is `0xFFFF`, which is within range, and the physical address resolves correctly.

**Reading a 2-byte word at `0x2000F` fails.** The first byte is read from `0x2000F` correctly. For the second byte, the offset register must increment from `0xFFFF` to `0x10000`. But the offset is only 16 bits wide — it cannot hold `0x10000`. The high bit `1` is truncated, and the offset becomes `0x0000`. The physical address calculated is:

```
DS base + 0x0000 = 0x10010 + 0x0000 = 0x10010
```

The expected address was `0x20010`. The CPU reads from `0x10010` instead — this is the **start of the segment**, not the next byte. The 2-byte value assembled from these two reads is completely incorrect.

**Reading a 4-byte dword at `0x2000F` fails in the same way.** Only the first byte is valid. Bytes 2, 3, and 4 all wrap back and read from offsets `0x0000`, `0x0001`, `0x0002` — all at the wrong physical locations.

**The rule is:** Multi-byte data must be placed so that all bytes fit within offset `0x0000` to `0xFFFF`. The last byte of the data must not exceed offset `0xFFFF`. This is what it means to stay within the **64KB segment boundary**.


To read 120KB of data, one must increment the segment register by `0x1000` and reset the offset to `0x0000` every time the 16-bit offset reaches its `0xFFFF` limit.

### Checks

To determine if a memory address aligns with a **64 KB boundary**, the kernel performs a bitwise check. A 64 KB boundary occurs at every address that is a multiple of $2^{16}$ (65,536 bytes). In hexadecimal, these addresses always end in four zeros (e.g., `0x10000`, `0x20000`).

### The Logic of the 64 KB Boundary
For a location to be aligned to 64 KB, the least significant 16 bits (the last four hex digits) must be zero. If any of those bits are set to 1, the address is not aligned.

The mask `0x0FFF` mentioned refers to a segment-based check. When the segment is shifted left by 4 bits (a standard x86 real-mode operation), it effectively monitors the bits that would violate a 64 KB alignment.


### Step-by-Step Bitwise Analysis

Below is the breakdown of how the `TEST` operation validates the location using the mask.

#### 1. Transformation of the Mask
The initial mask `0x0FFF` is shifted left by 4 bits to align with the way segments are calculated.
* **Original Mask:** `0x0FFF` $\rightarrow$ `0000 1111 1111 1111`
* **Shifted Mask:** `0x0FFF0` $\rightarrow$ `0000 1111 1111 1111 0000`

#### 2. Success Case: Aligned Address
An address is successful if it has no bits in common with the mask.
* **Desired Location:** `0x10000` (A 64 KB boundary)
* **Operation:** `0x10000` AND `0x0FFF0`

| Format | Value |
| :--- | :--- |
| **Location (0x10000)** | `0001 0000 0000 0000 0000` |
| **Mask (0x0FFF0)** | `0000 1111 1111 1111 0000` |
| **Result** | **`0000 0000 0000 0000 0000`** |

> **Result:** The output is **0**. The **Zero Flag (ZF)** is set to 1. The kernel confirms the module is on a 64 KB boundary.

#### 3. Failure Case: Unaligned Address
An address fails if any bit overlaps with the mask.
* **Desired Location:** `0x10500` (Not a 64 KB boundary)
* **Operation:** `0x10500` AND `0x0FFF0`

| Format | Value |
| :--- | :--- |
| **Location (0x10500)** | `0001 0000 0101 0000 0000` |
| **Mask (0x0FFF0)** | `0000 1111 1111 1111 0000` |
| **Result** | **`0000 0000 0101 0000 0000`** |

> **Result:** The output is **non-zero** (`0x0500`). The **Zero Flag (ZF)** is cleared to 0. The kernel rejects the location as it is not aligned.

## floppy disk
```
INT 0x13
```
* AH      0x02 function: read sectors, 0x00 Reset Disk, 0x03 Write Sectors, 0x04 Verify Sectors
* AL      Number of Sectors to read
* CH      Track/Cylinder number
* CL      Sector number
    - CX bits:
    - bit 15-8  = CH = cylinder bits 7 to 0   (lower 8 bits of cylinder)
    - bit 7-6   = CL = cylinder bits 9 and 8  (upper 2 bits of cylinder)
    - bit 5-0   = CL = sector number          (bits 5 to 0)

* DH      Head number
* DL      Drive number
* ES:BX   Destination Address

A Track is a single, circular path on the surface of one disk platter. On a disk, the outermost circle is usually Track 0. As you move toward the center of the wheel, the track numbers increase. Each track is further divided into small "slices" called Sectors (usually 512 bytes).

A Cylinder is the collection of all tracks that are at the same distance from the center across all platter surfaces.
- Modern hard drives have multiple platters (disks) stacked on top of each other.
- There is a "Read/Write Head" for the top and bottom of every platter.
- All these heads move together on a single arm.
- If the arm moves to Track 5, it is positioned over Track 5 on Platter 1, Track 5 on Platter 2, and so on.

Platter is the CD like structure, both sides we can write/read using head, so single Platter have 2 heads
- Head 0: Reads the top surface.
- Head 1: Reads the bottom surface.

if we have second Platter
- Head 2: Reads the top surface.
- Head 3: Reads the bottom surface.

A floppy disk drive physically reads sector by sector

Cylinder  $\implies$  starts at 0   (0 to 79)
Head      $\implies$  starts at 0   (0 to 1)
Sector    $\implies$  starts at 1   (1 to 18)

Floppy disk type

```
Type          Tracks per side    Heads    Sectors    Capacity
─────────────────────────────────────────────────────────────
5.25"  DD     40                 2        9          360  KB
5.25"  HD     80                 2        15         1.2  MB
3.5"   DD     80                 2        9          720  KB
3.5"  HD      80                 2        18         1.44 MB
3.5"  ED      80                 2        36         2.88 MB

Capacity = Tracks × Heads × Sectors × 512 bytes

3.5" HD  =  80 × 2 × 18 × 512  =  1,474,560 bytes  =  1.44 MB
5.25" DD =  40 × 2 ×  9 × 512  =    368,640 bytes   =  360  KB
```

#### calculation 

- Per side 40 tracks, 2 heads, 18 sectors per track
```
Total sectors to read = 25

── Track 0, Head 0 ──────────────────────────────
Sector 1  to Sector 18  =  18 sectors read
                            7 sectors remaining

── Track 1, Head 0 ──────────────────────────────
Sector 1  to Sector 7   =  7 sectors read
                            0 sectors remaining

Track 0, Head 0 -> sectors 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
Track 1, Head 0 -> sectors 1, 2, 3, 4, 5, 6, 7
```

- Per side 40 tracks, 2 heads, 18 sectors per track
- per track can store 18 (per track sectors ) * 512 (Per sector size in byte) = 9216 bytes
- 9216 * 40(tracks) = 368640 bytes per side storage
- 368640 * 2 = 737280  total storage in bytes == 720KB

- 18 (sector) * 40 (tracks per side) = 720 sectors per side
- 720 (sectors per side) * 2 (heads) = 1440 sectors per disk 
- 1440 (sectors per disk) * 512 (bytes per sector) = 737280 bytes

##### Reading in different 

To read 409600 bytes


```
Total bytes to read  =  409,600
Sector size          =  512 bytes

Total sectors        =  409,600 / 512  =  800 sectors   

Sectors per track    =  18
Total tracks needed  =  800 / 18  =  44.4  ->  45 tracks  

Per side             =  40 tracks
Side 0 (Head 0)      =  40 tracks * 18 sectors  =  720 sectors   
Side 1 (Head 1)      =  800 - 720               =   80 sectors remaining
80 / 18              =  4.4  ->  5 tracks on Head 1   

Summary: 
Head 0  ->  Track 0  to Track 39  =  40 tracks * 18 sectors  =  720 sectors
Head 1  ->  Track 0  to Track 3   =   4 tracks * 18 sectors  =   72 sectors
Head 1  ->  Track 4               =   1 track  *  8 sectors  =    8 sectors
                                                       total =  800 sectors 
```

Cannot read 720 sectors in a single INT 0x13 call.

INT 0x13 AH=02 reads by CHS address. The al register holds sectors to read, but there is a hard constraint: `The read cannot cross a track boundary.`

So maximum sectors per single INT 0x13 call is number of sectors availavle in single track
in our case it cannot read more than 18

To read 19th sector
1. Finish reading Track 0  ->  sectors 1–18   (18 sectors read)
2. Increment track number  ->  track = 1
3. Reset sector number     ->  sector = 1
4. Issue new INT 0x13 call with new CHS values
5. Read sector 1 of track 1  ->  this is the logical 19th sector

What if need to read data from next side of the disk?
1. Track number is 39 and sector readed is 18
2. Increment head by 1, reset track to 0 and sector to 1

We can form a loop here based on the length of the data to be read


**Write**

```c
int HM = 2;
int TM = 40;
int SM = 18;
int SECTOR_SIZE = 512;

int h = 0 ; //current head
int t = 0 ; //current track
int s = 1 ; //current sector

//-----------------------------
void floppy(char * data, int w) {
    while (w > 0) {

        if(h >= HM ||  (h + 1 >= HM && t+1 >= TM && s > SM)) {
            ERROR
        }
        // 18-19+1 = 0
        int r = (SM - s) + 1 ; 
        if (r >= w) { 
            // write completed
            write(data, w);
            s = s + w;
            w = 0;
            if (s > SM) {
                s = 1;
                t = t + 1;
            }
        } else {
            if(r > 0) { 
                write(data, r);
                data = data + (r * SECTOR_SIZE);
                w = w - r;
            }
            // t = 39
            t = t+1; // 40
            s = 1;      
        }
        if(t >= TM) { // 40 won't allow here
                t = 0;
                h = h + 1; // 2 
         }
    }
}
```

**read**

- Before every read, the code calculates how much space is left in the current 64kB segment.
- If the remaining sectors in the current track would overflow that boundary, the code truncates the request. It reads only enough to fill the current segment exactly, then resets the memory pointers to the start of a new segment before continuing.

write in 64KB boundry
```c

int cu_off = 0; // from current offset we can write
//--------------------------------
void write_RAM(char* data, int len) {
    if (ds & 0x0fff)
    {
        // if ds is not aligned to 64kb boundry it will throw error 
        ERROR invalid
    }
    while(len > 0){
        int r = cu_off + len;
        if(r > 0xffff) {
            int avail_segment_byte = (0xffff - cu_off) + 1;
            if(avail_segment_byte == 0x10000) avail_segment_byte = 0xffff; 
            write(data, avail_segment_byte); 
            data += avail_segment_byte; // advance pointer
            len -=  avail_segment_byte;
            cu_off = 0;
            if (ds == 0xf000) {
                ERROR
            }
            add ds, 0x1000;
            
        } else {
            write(data, len);
            cu_off+= len;
            len = 0;
        }
   }
}

void write_RAM(char* data, int len) {
    while (len > 0) {
        // Calculate bytes left until the VERY end of the segment (0xFFFF)
        // If cu_off is 0, this is 65,535
        int avail_in_seg = 0xFFFF - cu_off;

        if (len > avail_in_seg) {
            // 1. Write up to 0xFFFF
            if (avail_in_seg > 0) {
                write(data, avail_in_seg); 
                data += avail_in_seg;
                len -= avail_in_seg;
            }

            // 2. Write the LAST byte of the segment (the 65,536th byte)
            write_single_byte(data, 0xFFFF); 
            data += 1;
            len -= 1;

            // 3. Segment Jump
            if (ds >= 0xF000) ERROR;
            ds += 0x1000;
            cu_off = 0;
        } else {
            // Fits within 0xFFFF
            write(data, len);
            cu_off += len;
            len = 0;
        }
    }
}

```

next knows number of bytes to read from floppy, it has to read properly and write in RAM 

floppy read if sector len exactly matched no problem, else if a sector has only half of data to read or write in sector it will read one whole sector, in sofware we have to filter it 

* Step 1: Remaining Sectors on Track
    ```s
    mov ax, [cs:sectors] ; ax = 18
    sub ax, [cs:sread]   ; ax = 18 - 1 = 17 sectors
    ```

    We want to read 17 sectors.

* Step 2: The Boundary Test
    The code checks if adding these 17 sectors to our current position (BX = 0xF000) will exceed 64KB (0x10000).

    ```s
    mov cx, ax           ; cx = 17
    shl cx, 9            ; 17 * 512 = 8,704 bytes (0x2200 in hex)
    add cx, bx           ; 0x2200 + 0xF000 = 0x11200
    ```
    - The result is 0x11200
    - The register CX becomes 0x1200.
    - The Carry Flag (CF) is set to 1.

* Step 3: The Branch
    ```s
    jnc ok2_read         ; Carry is 1, so we do NOT jump.
    je  ok2_read         ; Not equal, so we do NOT jump.
    ```
    Since the Carry Flag is set, the CPU knows we are about to go over the cliff. It proceeds to the "correction" code.

* Step 4: The Manual Correction
    Now we calculate exactly how many sectors will fit in the remaining space.

    ```s
    xor ax, ax           ; ax = 0x0000
    sub ax, bx           ; 0x0000 - 0xF000 = 0x1000
    ```

    - Wait, how is $0 - 0xF000 = 0x1000$? In 16-bit math (two's complement), 0x0000 is treated like 0x10000 during subtraction.
    - $65,536 - 61,440 = 4,096$ (which is 0x1000 in hex).
    - This 0x1000 is the exact number of bytes left until the end of the segment.

    ```
    shr ax, 9            ; 4096 / 512 = 8
    ```
    - The result in AX is now 8.
    
    Instead of trying to read the 17 sectors we wanted (which would have crashed), the routine has calculated that we can only safely read 8 sectors.