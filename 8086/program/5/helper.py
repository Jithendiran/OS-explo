'''
Docstring for 8086.program.5.helper
How to run

inside gdb setminal source this file
(gdb) source helper.py
(gdb) disas16
'''
import gdb

def fetch_asm(start, end_or_count):
    kwargs = {
        'start_pc': start,
        'count':end_or_count
    }
    asm = gdb.selected_frame().architecture().disassemble(**kwargs)
    
    return asm

def print_16():

    liner_addr = 0
    cs = gdb.parse_and_eval("$cs")
    eip = gdb.parse_and_eval("$eip")
    liner_addr = cs * 16 + eip
    asm = fetch_asm(liner_addr, 10)
    gdb.write("\033[H\033[J")
    for instr in asm:
        addr = instr['addr']
        length = instr['length']
        text = instr['asm']
        format_string = '{} : {} : {}\n'
    
        gdb.write(format_string.format(addr, length, text))
    
    gdb.flush()

class Disas16Command(gdb.Command):
    def __init__ (self):
        # Register the command name 'disas16'
        super (Disas16Command, self).__init__ ("disas16", gdb.COMMAND_USER)
    
    def invoke (self, arg, from_tty):
        print_16()

Disas16Command()