target remote :1234

break *0x7c00

define print_flags_verbose
  
  printf "--- FLAGS Register Status (0x%x) ---\n", $eflags
  
  # Standard 16-bit Flags (FLAGS)
  
  # CF (Carry Flag) - Bit 0
  printf "CF=%d ", ($eflags & 0x1)
  
  # PF (Parity Flag) - Bit 2
  printf "PF=:%d ", ($eflags & 0x4) >> 2
  
  # AF (Auxiliary Carry Flag) - Bit 4
  printf "AF=%d ", ($eflags & 0x10) >> 4
  
  # ZF (Zero Flag) - Bit 6
  printf "ZF=%d ", ($eflags & 0x40) >> 6
  
  # SF (Sign Flag) - Bit 7
  printf "SF=%d ", ($eflags & 0x80) >> 7
  
  # TF (Trap Flag/Single Step) - Bit 8
  printf "TF=%d ", ($eflags & 0x100) >> 8
  
  # IF (Interrupt Enable Flag) - Bit 9
  printf "IF=%d ", ($eflags & 0x200) >> 9
  
  # DF (Direction Flag) - Bit 10
  printf "DF=%d ", ($eflags & 0x400) >> 10
  
  # OF (Overflow Flag) - Bit 11
  printf "OF=%d\n", ($eflags & 0x800) >> 11
end

define print_reg_stack
  if $argc == 0
      set $stack_max_size = 5
  else 
    set $stack_max_size = $arg0
  end

  # --- Print Registers ---
  # 1. Current Instruction
  printf "\n--- Current Instruction ---\n"
  x/i $pc

  # 2. Segment and Pointer Registers (CS:IP, SS:SP)
  printf "\n--- Segment and Pointer Registers ---\n"
  printf "CS:EIP  : 0x%02x:0x%02x\n", $cs, $eip
  printf "SS:ESP  : 0x%02x:0x%02x\n", $ss, $esp
  
  # 3. Flags (EFLAGS/RFLAGS)
  print_flags_verbose
  
  # --- Print Stack Memory Loop ---
  printf "\n--- Stack Trace (SS:SP linear address: 0x%x) ---\n", ($ss * 0x10) + $sp
  # Start address of the stack
  set $addr = ($ss * 0x10) + $sp
  set $i = 0

  # Loop to print N words (2-byte units) from the stack
  while $i < $stack_max_size
    printf "0x%x:  0x%02x\n", $addr, *(short *)$addr
    set $addr = $addr + 2 
    set $i = $i + 1
  end

  printf "-------------------------------------------\n"
end

# Go to next step and dump info
define next_step_dump
  stepi
  print_reg_stack 5
end