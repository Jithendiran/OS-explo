import gdb
import subprocess

class Dash32(gdb.Command):
    """Custom Dashboard for 80386 Protected Mode Debugging.
    Usage: (gdb) dash32
    """
    def __init__(self):
        super(Dash32, self).__init__("dash32", gdb.COMMAND_USER)

    def get_reg(self, reg):
        return int(gdb.parse_and_eval(f"${reg}"))

    def is_pmode(self):
        # Bit 0 of CR0 is the Protection Enable (PE) bit
        cr0 = self.get_reg("cr0")
        return (cr0 & 1) == 1

    def disassemble_32(self, addr, count):
        # Read memory from GDB
        try:
            inferior = gdb.selected_inferior()
            # Read enough bytes for 10 instructions (max 15 bytes each)
            mem = inferior.read_memory(addr, count * 15).tobytes()
        except:
            return "Could not read memory"

        mode = "32" if self.is_pmode() else "16"
        # Call ndisasm
        process = subprocess.run(
            ["ndisasm", "-b", mode, "-o", hex(addr), "-"],
            input=mem, capture_output=True
        )
        lines = process.stdout.decode('utf-8').splitlines()
        return lines[:count]

    def invoke(self, arg, from_tty):
        gdb.write("\033[H\033[J") # Clear screen
        
        pm = self.is_pmode()
        mode_str = "\033[31mPROTECTED MODE\033[0m" if pm else "\033[32mREAL MODE\033[0m"
        
        # 1. Header
        gdb.write(f"┌── STATUS: {mode_str} " + "─" * 30 + "┐\n")
        
        # 2. Registers (32-bit extended)
        regs = ["eax", "ebx", "ecx", "edx", "esi", "edi", "ebp", "esp", "eip"]
        for r in regs:
            val = self.get_reg(r)
            gdb.write(f"│ {r.upper():<4}: {hex(val):<48} │\n")
        
        # Segment Registers
        gdb.write("├" + "─" * 56 + "┤\n")
        for s in ["cs", "ds", "ss", "es"]:
            val = self.get_reg(s)
            gdb.write(f"│ {s.upper():<4}: {hex(val):<48} │\n")

        # 3. Disassembly
        gdb.write("├─ DISASSEMBLY " + "─" * 42 + "┤\n")
        
        # Calculate Linear Address
        eip = self.get_reg("eip")
        if not pm:
            # Real Mode: Segment * 16 + Offset
            cs = self.get_reg("cs")
            linear_pc = (cs << 4) + eip
        else:
            # Protected Mode: In a Flat Model, Base is 0, so Linear = Offset
            # If you use a non-zero base, this script would need to parse the GDT
            linear_pc = eip

        asm_lines = self.disassemble_32(linear_pc, 8)
        for line in asm_lines:
            if hex(linear_pc).lower() in line.lower():
                gdb.write(f"│ \033[33m=> {line[:40]:<48}\033[0m │\n")
            else:
                gdb.write(f"│    {line[:40]:<51} │\n")
                
        gdb.write("└" + "─" * 56 + "┘\n")

a = Dash32()

def stop_handler(event):
    # Only run if we have a valid thread and frame
    try:
        if gdb.selected_thread() is not None:
            global a
            del a
            a = Dash32()
    except gdb.error:
        pass # Handle cases where registers might not be accessible

# Register the handler with GDB's event system
gdb.events.stop.connect(stop_handler)


'''
extend the helper to show logical address, linear address and physical address
show CPL
show all falgs
show CR0-CR3, show when page fault occured
utilize full horizontal, only half is used , by keeping the modules side by side, so we can use many tools

'''