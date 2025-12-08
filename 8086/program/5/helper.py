'''
Docstring for 8086.program.5.helper
How to run

inside gdb terminal source this file
(gdb) source helper.py
(gdb) dash16
'''
import gdb
import subprocess


class Dashboard16(gdb.Command):
    def __init__ (self):
        super (Dashboard16, self).__init__ ("dash16", gdb.COMMAND_USER)
    
    class dis_asm:
        def disassemble_with_ndisasm(self, start_address, inst_count):
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
                    raw_output.append({'addr': inst_set_stripped[0], 'opcode': inst_set_stripped[1], 'asm': " ".join(inst_set_stripped[2:])})

                return raw_output
            except gdb.error as e:
                gdb.write(f"NDISASM Execution Error: {e}\n", gdb.STDERR)
            return []

        def print_16(self):

            liner_addr = 0
            cs = gdb.parse_and_eval("$cs")
            eip = gdb.parse_and_eval("$eip")
            liner_addr = cs * 16 + eip
            raw_asm_lines = self.disassemble_with_ndisasm(liner_addr, 10)
            
            title = " Assembly by ndisasm (16-bit) "
            gdb.write(f"┌──\033[32m{title}\033[0m" + "─" * 20 + "──┐\n")
            
            for index, instr in enumerate(raw_asm_lines):
                line = f"0x{instr['addr']}  {instr['asm']}"
                if index == 0:
                    gdb.write(f"│ \033[32m{line:<52}\033[0m │\n")
                else:
                    gdb.write(f"│ {line:<52} │\n")
            gdb.write("└" + "─" * 54 + "┘\n")

            gdb.flush()

    class stack:
        count = 10 # if less thn 0, read till base
        kernel_stack_ss   = 0x54FF
        kernel_stack_top  = 0x000D
        Kernel_stack_base = 0x22FFD

        user_stack_ss   = 0x6DFF
        user_stack_top  = 0x000F
        user_stack_base = 0x9FFFF

        kernel_sp = 0
        user_sp = 0

        def get_stack_data(self, ss, sp):
            """Reads stack values from top (SS:SP) to base."""
            stack_data = []
 
            # Calculate how many words to read (limit to 10 or until base)
            # 8086 stack grows downwards, so base > linear_addr
            bytes_to_read = 10 * 2 # 2 for each stack content

            try:
                inferior = gdb.selected_inferior()
                raw_mem = inferior.read_memory(ss, bytes_to_read).tobytes()
                
                for index in range(len(raw_mem), 0, -2):

                    stack_data.append({
                        'addr': hex( sp + index),
                        'val': int.from_bytes(raw_mem[index:index+2], byteorder='little')
                    })

            except Exception as e:
                gdb.write(f"Stack read error: {e}\n")
                
            return stack_data

        def kernel_stack(self, c_linear, c_esp):

            ss = int(Dashboard16.stack.kernel_stack_ss)
            sp = int(Dashboard16.stack.kernel_stack_top)
            sb = int(Dashboard16.stack.Kernel_stack_base)
            s_top = ss * 16 + sp
            gdb.write(f"Kernel {hex(ss)} : {hex(sp)} -> {hex(s_top)}\n")
            if c_linear <=  s_top and c_linear >= s_top:
                # new
                sp = c_esp
                Dashboard16.stack.kernel_sp = sp
            else:
                # old
                # if c_esp 
                sp = s_top
            
            gdb.write(f"Kernel from {hex(sp)} -- to {hex(s_top)}\n")
        
            return self.get_stack_data(ss, sp)
            
        
        def user_stack(self, c_linear, c_esp):
            ss = int(Dashboard16.stack.user_stack_ss)
            sp = int(Dashboard16.stack.user_stack_top)
            sb = int(Dashboard16.stack.user_stack_base)
            s_top = ss * 16 + sp
            gdb.write(f"User {hex(ss)} : {hex(sp)} -> {hex(s_top)}\n")
            if c_linear <=  s_top and c_linear >= s_top:
                sp = c_esp
                Dashboard16.stack.user_sp = sp
            else:
                sp = s_top
            
            sp # from
            s_top # to
            gdb.write(f"User from {hex(sp)} -- to {hex(s_top)}\n")

            return self.get_stack_data(ss, sp)
        
        def print_16(self):
            c_ss = gdb.parse_and_eval("$ss")
            c_esp = gdb.parse_and_eval("$esp")
            c_linear = c_ss * 16 + c_esp
            gdb.write(f"Current stack : {hex(c_ss)} : {hex(c_esp)} -> {c_linear} ")
        
            gdb.write("\n┌────────────────── STACK VIEW ──────────────────┐\n")
            gdb.write(  "│ [Kernel Stack]                                 │\n")
            
            for index, kernel_set in enumerate(self.kernel_stack(c_linear, c_esp)):
                gdb.write(f"│ {kernel_set['addr']}: {kernel_set['val']:<37} │\n")
            
            gdb.write(  "├────────────────────────────────────────────────┤\n")
            
            gdb.write(  "│ [User Stack]                                   │\n")
            for index, user_set in enumerate(self.user_stack(c_linear, c_esp)):
                gdb.write(f"│ {user_set['addr']}: {user_set['val']:<37} │\n")

            gdb.write(  "└────────────────────────────────────────────────┘\n")

    def run():
        gdb.write("\033[H\033[J")

        asm_obj = Dashboard16.dis_asm()
        asm_obj.print_16()

        mem_obj = Dashboard16.stack()
        mem_obj.print_16()

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

