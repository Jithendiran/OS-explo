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

### Part I: 8086 Real Mode Foundation (Bare Metal)

[Basic](./Basic.md)

The 8086 phase focused on understanding basic hardware interactions, memory layout, and the simplest form of program control, all within a non-protected, $1\text{ MB}$ memory space.

#### Key Concepts covered
* Overview
* Power On routine
* Architecture
* Memory/IO/MMIO/DMA/Interrupt flow
* Registers
* Memory management
* Interrupt Vector Table and custom handler installation

[Click for 8086 high level docs](./8086/README.md)



## Acknowledgements

The high-level concepts, architectural overviews, and foundational explanations throughout this documentation—especially within the "Key Concepts Covered" sections—were significantly developed and clarified through interactive conversations with Gemini (Flash 2.5). Specific details and code implementations were also verified against and supplemented by various external websites and technical books, ensuring accuracy.