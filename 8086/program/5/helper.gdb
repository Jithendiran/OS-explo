target remote :1234

break *0x7c00

break *0x7c27

commands
    # The 'silent' command suppresses the usual message about hitting the breakpoint
    silent

    # The command to modify the Instruction Pointer (EIP)
    set $eip = 0x600

    # Optional: Print the new EIP to confirm the jump
    echo EIP automatically set to 0x600. Continuing execution.\n

    break *0x600

    # The 'continue' command resumes program execution
    continue
end
