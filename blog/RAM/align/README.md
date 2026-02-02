## Page alignment

### 8 bit
In 8 bit era cpu were designed to handle 8 bit data, cpu registers were 8 bit length. so typically memory chips are designed in such a way for example

* with 8 bit address lines total 256 unique address can be used to address each 8 bit data, total size of the memory chip is 256 x 8 bit = 2048 bits or 256 bytes long
* when 16 bit address lines is used total 65536 unique address can be used to address each 8 bit data, total size of memory chip is 524288 bits or 65536 bytes or 64 KB

when a cpu needed 16 bit data it read data 2 times and did conjunction and used it

## 16 bit
In 16 bit era cpu's were used tdesigned to handle 16 bit data, cpu registers were 16bit length and also it support backward compactable
it can read 8 bit of data also. 16 bit has two 8 bit data, one is high byte and one is low byte. So it still used 8 bit data memory

To access data efficiently CPU prefer to store/access data in a specific order for example when it need to store/access 16 bit data it start with even address and end with odd address `feab` is the data, `0002` is the address. it store `fe` in even address `0002` and `ab` in odd address `0003`. In single cycle it read both the data

How it read both data in same cycle?
The trick here is it used 2 different chips to store the single 16 bit data, 2 chips are orgainzed in side by side likely one is odd chip and other one even chip, when need to read a 16 bit data from memory `0002` is read from even chip and `0003` is read from odd chip. `fe` is stored in even chips and `ab` is stored in odd chip
but how it access?
to know this let's see the address of `0002` and `0003`, form simplicity we will consider only Least significient byte rest are bunch of 0's
2 = `0010` 
3 = `0011`
The difference is the 1's place for odd address it is always 1 for even it is always 0, rest are same, it is true for all the continous even-odd pair of numbers, so if we exculde the least significient bit we get `001x` or by do right shift 1 bit data we get the common value it is `0001`, we can use this as the common address, in even chip's `0001` location store `fe`, in odd  chip's `0001` location store `ab`, by giving common address `0001` we can read data from both chips and fill the buffer at the same time

So 16 bit cpu era one memory chip contains 2 bank of memory unit one for odd and one for even, also the lower byte bit 0-7 is hardwired to lower byte of the reigster and high byte is hardwired to higher byte of register

Consider even chip is hardwired to ax's high byte(ah), odd chip is hardwired to ax's low byte(al)

what happen if start address is from odd address (read 0003 and 0004)
since the order follows different rows 3 = 0011 and 4 = 0100, there is no common address it has to read two times, it uses two cycles

3 = 0011, address of odd bank is 0001.  
4 = 0100, address of even bank is 0010.

1st it read low byte from 1st row and store in al then read high byte from next row's even address and store in ah
two differnt rows 2 cycles to read, same row 1 cycle the two different rows is also called as `misalign` byte order, if the data is aligned properly cpu id faster

do if start address is even, single cycle


## 32 bit
In 32 bit the cpu registers designed to handle  8 bit(ah, al), 16 bit(ax) and 32 bit (eax)

It has 4 banks to store

bank 0, bank 1, bank 2, bank 3

when 4 byte o r32 bit data is written 1st 8 bit will store in 1st bank, 2nd 8 bit for 2nd bank like wise 3 and 4, same common address used here till(1 2 4 8) 4th address 2 and 1's place not used when accessing 4 byte data

* bank 0 a is connected to ah, bank 1 is connected to al, also bank 2 is connected to ah and bank 3 is al (is this correct?)
* (bank 0+ bank 1) and (bank 2 + bank3) connected to ax
* (bank 0 + bank 1 + bank 2 + bank 3) is eax

if 1 read one byte data any where it will take only one cycle 
    any where 1 cycle

if 2 byte read operaton
    start address 0 one cycle, (because 0 - ah and 1 - al = ax) 
    start address 1 means read whole 4 byte and do left shift opeartion for 8 bit and read only 2 byte, it is not possible to read low byte then high byte in same cycle
    start 2 one cycle (2 - ah and 1 - al = ax)
    start 3, read high low byte from row 0 and read high byte from row1's 0th location

    if start address is even single cycle

if 4 byte read operation
    start address 0 span till 3 no problem single operation
    start address 1, span (1,2,3 = row 0 and 4 fom row 1), to read read whole word from row 0, do left shit by 1 byte and read 1 high byte from next row
    start address 2 span (row 0 = 2,3 and row 1 = 4 and 5) willl perform shifting
    start 3, span (row 0 = 3 and row 1 = 4, 5, 6), will perform read and shifting 
    start address 4, span (4,5,6,7) single cycle read

    if start address is divide 4 = 0 signle cycle (0, 4, 8, ..)

## 64 bit

In 32 bit the cpu registers designed to handle  8 bit(ah, al), 16 bit(ax) 32 bit (eax) and 64 bit (rax)

It has 8 banks to store