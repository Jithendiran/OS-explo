'''
Docstring for 8086.program.5.helper
How to run

inside gdb terminal source this file
(gdb) source helper.py
(gdb) dash16
'''
import gdb
import subprocess

my_persistent_data = {
    "kernel_sttop": 0,
    "user_sttop": 0
}

class Dashboard16(gdb.Command):
    def __init__ (self):
        super (Dashboard16, self).__init__ ("dash16", gdb.COMMAND_USER)
    
    class dis_asm:
        def disassemble_with_ndisasm(self, start_address, eip,  inst_count):
            try:
                mem_block = gdb.selected_inferior().read_memory(start_address, inst_count * 5)
                raw_bytes = mem_block.tobytes()
            except gdb.error as e:
                gdb.write(f"Error reading target memory: {e}\n", gdb.STDERR)
                return []

            command = ["ndisasm", "-b", "16", "-o", str(start_address), "-"]
            try:
            
                process = subprocess.run(
                    command, 
                    input=raw_bytes, 
                    capture_output=True, 
                    text=False, 
                    check=True
                )
                raw_output = []
                for inst_set in (process.stdout.decode('utf-8').strip().splitlines())[:inst_count]:
                    inst_set_stripped = list(filter(None, inst_set.split(" ")))
                    length = int(len(inst_set_stripped[1])/2)
                    raw_output.append({
                        'addr': inst_set_stripped[0], 
                        'opcode': inst_set_stripped[1], 
                        'length': length,
                        'asm': " ".join(inst_set_stripped[2:]),
                        'gdb_addr': hex(eip)
                        })
                    
                    eip +=length

                return raw_output
            except gdb.error as e:
                gdb.write(f"NDISASM Execution Error: {e}\n", gdb.STDERR)
            return []

        def print_16(self):

            liner_addr = 0
            cs = gdb.parse_and_eval("$cs")
            eip = gdb.parse_and_eval("$eip")
            liner_addr = cs * 16 + eip
            raw_asm_lines = self.disassemble_with_ndisasm(liner_addr, eip, 10)
            
            title = " Assembly by ndisasm (16-bit) "
            gdb.write(f"┌──\033[32m{title}\033[0m" + "─" * 20 + "──┐\n")
            
            for index, instr in enumerate(raw_asm_lines):
                line = f"0x{instr['addr']} 0x{instr['gdb_addr']} {instr['length']}  {instr['asm']}"
                if index == 0:
                    gdb.write(f"│ \033[32m{line:<52}\033[0m │\n")
                else:
                    gdb.write(f"│ {line:<52} │\n")
            gdb.write("└" + "─" * 54 + "┘\n")

            gdb.flush()

    class stack:
        count = 10 # if less thn 0, read till base
        kernel_stack_ss   = int(0x54FF)
        kernel_stack_top  = int(0x000D)
        kernel_stack_base = int(0x22FFD)
        kernel_stack_top_lin = int(0x54FFD)

        user_stack_ss   = int(0x9FFF)
        user_stack_top  = int(0x000F)
        user_stack_base = int(0x6DFFF)
        user_stack_top_lin = int(0x9FFFF)

        kernel_sp = 0
        user_sp = 0

        def __init__(self):
            c_ss = gdb.parse_and_eval("$ss")
            c_esp = gdb.parse_and_eval("$esp")
            c_linear = int(c_ss * 16 + c_esp)
            

            if my_persistent_data["kernel_sttop"] == 0:
                my_persistent_data["kernel_sttop"] = Dashboard16.stack.kernel_stack_top_lin
            
            if my_persistent_data["user_sttop"] == 0:
                my_persistent_data["user_sttop"] = Dashboard16.stack.user_stack_top_lin
            

            if c_linear <= Dashboard16.stack.kernel_stack_top_lin \
                and c_linear > Dashboard16.stack.kernel_stack_base:
                my_persistent_data["kernel_sttop"] = c_linear
            
            if c_linear <= Dashboard16.stack.user_stack_top_lin \
                and c_linear > Dashboard16.stack.user_stack_base:
                my_persistent_data["user_sttop"] = c_linear


        def get_stack_data(self, address, bytes_to_read, stack_data):
            """Reads stack values from top (SS:SP) to base."""

            try:
                inferior = gdb.selected_inferior()
                raw_mem = inferior.read_memory(address, bytes_to_read).tobytes()
                for index in range(0, len(raw_mem), 2):
                    stack_data.append({
                        'addr': hex(address + index),
                        'val': hex(int.from_bytes(raw_mem[index:index+2], byteorder='little'))
                    })

            except Exception as e:
                gdb.write(f"Stack read error: {e}\n")
            return stack_data.reverse()

        def kernel_stack(self, data_toread):
            stack_data = []
            startaddr = my_persistent_data["kernel_sttop"]
            stopaddr = Dashboard16.stack.kernel_stack_top_lin
            data_toread = min(data_toread, stopaddr-startaddr)
            self.get_stack_data(startaddr, data_toread, stack_data)

            for kernel_set in stack_data:
                gdb.write(f"│ {kernel_set['addr']}: {kernel_set['val']:<34} │\n")
        
        def user_stack(self, data_toread):
            stack_data = []
            startaddr = my_persistent_data["user_sttop"]
            stopaddr = Dashboard16.stack.user_stack_top_lin
            data_toread = min(data_toread, stopaddr-startaddr)
            self.get_stack_data(startaddr, data_toread, stack_data)

            for kernel_set in stack_data:
                gdb.write(f"│ {kernel_set['addr']}: {kernel_set['val']:<34} │\n")
        
        
        def print_16(self):
            c_ss = gdb.parse_and_eval("$ss")
            c_esp = gdb.parse_and_eval("$esp")
            c_linear = int(c_ss * 16 + c_esp)
            gdb.write(f"Current stack : {hex(c_ss)} : {hex(c_esp)} -> {hex(c_linear)}\n")
            gdb.write(f"Kernel  stack : {hex(my_persistent_data['kernel_sttop'])}\n")
            gdb.write(f"User stack : {hex(my_persistent_data['user_sttop'])}\n")
        
            gdb.write("\n┌────────────────── STACK VIEW ──────────────┐\n")
            gdb.write(  "│ [Kernel Stack]                             │\n")
            if my_persistent_data["kernel_sttop"] < Dashboard16.stack.kernel_stack_top_lin:
                self.kernel_stack(20)
            
            gdb.write(  "├────────────────────────────────────────────┤\n")
            
            gdb.write(  "│ [User Stack]                               │\n")
            if my_persistent_data["user_sttop"] < Dashboard16.stack.user_stack_top_lin:
                self.user_stack(20)

            gdb.write(  "└────────────────────────────────────────────┘\n")

    class reg:
        def print_16(self):
            ax = hex(gdb.parse_and_eval("$ax"))
            bx = hex(gdb.parse_and_eval("$bx"))
            cx = hex(gdb.parse_and_eval("$cx"))
            dx = hex(gdb.parse_and_eval("$dx"))
            ss = hex(gdb.parse_and_eval("$ss"))
            esp = hex(gdb.parse_and_eval("$esp"))
            cs = hex(gdb.parse_and_eval("$cs"))
            eip = hex(gdb.parse_and_eval("$eip"))
            di = hex(gdb.parse_and_eval("$di"))
            si = hex(gdb.parse_and_eval("$si"))
            ef = hex(gdb.parse_and_eval("$eflags"))

            gdb.write("\n┌────────────────── REG VIEW ────────────────┐\n")
            gdb.write( f"│ AX      : {ax:<33}│\n")
            gdb.write( f"│ BX      : {bx:<33}│\n")
            gdb.write( f"│ CX      : {cx:<33}│\n")
            gdb.write( f"│ DX      : {dx:<33}│\n")
            gdb.write( f"│ SS      : {ss:<33}│\n")
            gdb.write( f"│ ESP     : {esp:<33}│\n")
            gdb.write( f"│ CS      : {cs:<33}│\n")
            gdb.write( f"│ EIP     : {eip:<33}│\n")
            gdb.write( f"│ DI      : {di:<33}│\n")
            gdb.write( f"│ SI      : {si:<33}│\n")
            gdb.write( f"│ EFLAGS  : {ef:<33}│\n")
            gdb.write(  "└────────────────────────────────────────────┘\n")

    def run():
        gdb.write("\033[H\033[J")

        asm_obj = Dashboard16.dis_asm()
        asm_obj.print_16()

        mem_obj = Dashboard16.stack()
        mem_obj.print_16()

        reg_obj = Dashboard16.reg()
        reg_obj.print_16()

    def invoke (self, arg, from_tty):
        Dashboard16.run()

obj = Dashboard16()

def stop_handler(event):
    # Only run if we have a valid thread and frame
    try:
        if gdb.selected_thread() is not None:
            Dashboard16.run()
    except gdb.error:
        pass # Handle cases where registers might not be accessible

# Register the handler with GDB's event system
gdb.events.stop.connect(stop_handler)

# x/1xh 0x60*16+0xe6