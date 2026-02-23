# Processor Architecture: Power-On to Secure Process Execution

## Introduction: Document Scope

This guide charts the architectural evolution of the x86 processor, focusing on the fundamental steps required to transition from a simple, unprotected environment to a secure, modern execution model. It serves as a high-level, practical reference for key concepts, accompanied by documented assembly language programs that illustrate these principles.

## Prerequisites: 

The primary requirement for following this learning path is a genuine interest in computer architecture and how systems work at the foundational level.

To fully engage with the assembly programs and architectural concepts, a basic, working knowledge of core computer science principles is sufficient. You do not need to be an expert

## Software requirements
1. nasm compiler
2. qemu
3. GDB
4. GCC

## Concepts

### Part I: Basics
- Electronics
    * [Intro](./electronics/electronics.md)
        This give enough ideas and concepts required for electronics
    * [Timing](./electronics/timings.md)
        This is the basic timings and delays explained
    * [Timing analysis](./electronics/timing-diagram.md)
        This will provide a basics on how the timing are calculated and choose
- CPU
    * [Execution](Execution.md)
        This will give details on how CPU execute instruction and how the data and address are using the bus
    * [Info](./Firmware.md)
        This gives a details about firmwarem non firmware hardware

### Part II: 8086 Real Mode Foundation (Bare Metal)

[Basic](./Basic.md)

The 8086 phase focused on understanding basic hardware interactions, memory layout, and the simplest form of program control, all within a non-protected, $1\text{ MB}$ memory space.

#### Key Concepts covered
* Overview
* Power On routine
* Architecture
* Memory/IO/MMIO/DMA/Interrupt flow
* Registers
* Memory management
* code segment, stack segment switching between process
* Interrupt Vector Table and custom handler installation
* PIC configs

[Click for 8086 high level docs](./8086/README.md)

### Part III: Linking

This part give a brief about how multiple relocatable files get linked, how c files are used in with nasm
[code](./code/README.md)

### Part IV: 80386 Protected Mode Architecture

This phase implements the 80386 Protected Mode, which introduces hardware features necessary for a stable, multitasking environment. The focus is on protection, privilege separation, and virtual memory.

[Click for 80386 high level docs](./80386/README.md)

### [Blogs](./blog/README.md)



## Acknowledgements

I reframed texts using Gemini