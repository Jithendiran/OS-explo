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

    def run():
        gdb.write("\033[H\033[J")

        asm_obj = Dashboard16.dis_asm()
        asm_obj.print_16()


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

