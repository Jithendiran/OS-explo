# 6502 after reset, do 7 cycle init then read address 0xfffc and 0xfffd, what ever the content read from that address, it consider as the start address.
# 6502 follows little endian 0xfffc will have lower part of the address and 0x7ffd have the higher part of the address,
# ROM will active only when 6502's 16 bit is active
# MPU adrress is 8000, ROM's corresponsing address is 0000
# fffc -> 7ffc

c = bytearray([
      # 0,  1 
      0xa9,0xff,       # lda #$ff
      # 2,  3,    4
      0x8d,0x02, 0x60, # sta $6002
      # 5,  6
      0xa9,0x55,       # lda #$55
      # 7,  8,  9
      0x8d,0x00, 0x60  # sta $6000
      ])

rom = c + bytearray([0xea] * (32768 - len(c)))
# go to start of the ROM
rom[0x7ffc] = 0x00 # 32764
rom[0x7ffd] = 0x80 # 32765

with open("/tmp/rom.bin", "wb") as out_file:
    out_file.write(rom)

'''
$ hexdump -C /tmp/rom.bin 
00000000  a9 ff 8d 02 60 a9 55 8d  00 60 ea ea ea ea ea ea  |....`.U..`......|
00000010  ea ea ea ea ea ea ea ea  ea ea ea ea ea ea ea ea  |................|
*
00007ff0  ea ea ea ea ea ea ea ea  ea ea ea ea 00 80 ea ea  |................|
00008000
$ 
'''