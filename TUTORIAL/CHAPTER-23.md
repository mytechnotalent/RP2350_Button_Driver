# Chapter 23: Stack and Vector Table — stack.s and vector_table.s

## Introduction

Two small files set up the most fundamental structures the Cortex-M33 needs: the vector table tells the hardware where to begin execution, and the stack initialization gives the processor a place to save data.  This chapter walks through both files.

## vector_table.s — The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .vectors, "ax"                          // vector table section
.align 2                                         // align to 4-byte boundary

.global _vectors                                 // export _vectors symbol
_vectors:
  .word STACK_TOP                                // initial stack pointer
  .word Reset_Handler + 1                        // reset handler (Thumb bit set)
```

### Line-by-Line Walkthrough

```asm
.section .vectors, "ax"                          // vector table section
```

Places the vector table in its own section named `.vectors` with attributes `"a"` (allocatable) and `"x"` (executable).  The linker script places this section at a 128-byte aligned address in the first 4 KB of flash.

```asm
.align 2                                         // align to 4-byte boundary
```

Ensures the vector table starts on a 4-byte boundary.  The 128-byte alignment in the linker script provides a stronger guarantee, but this directive ensures correctness even before linking.

```asm
.global _vectors                                 // export _vectors symbol
_vectors:
```

Exports the `_vectors` symbol so the linker script can reference it with `PROVIDE(__Vectors = ADDR(.vectors))`.

```asm
  .word STACK_TOP                                // initial stack pointer
```

The first word of the vector table.  On reset, the hardware loads this value into the Main Stack Pointer (MSP).  `STACK_TOP` = `0x20082000`, placing the initial stack at the top of our 32 KB stack region.

```asm
  .word Reset_Handler + 1                        // reset handler (Thumb bit set)
```

The second word of the vector table.  On reset, the hardware loads this value into the Program Counter (PC).  The `+ 1` sets bit 0 (the Thumb bit), telling the processor to execute in Thumb state.  Without it, the processor would fault.

### Vector Table at Runtime

```
Address 0x10000080:
  +-------------------+
  | 0x20082000        |  Word 0: Initial MSP value
  +-------------------+
  | Reset_Handler | 1 |  Word 1: Reset vector (Thumb bit set)
  +-------------------+
```

A full Cortex-M33 vector table can have up to 496 entries (16 system exceptions + 480 interrupts).  Our table has only 2 entries because we do not use interrupts.

## stack.s — The Complete Source

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set

.include "constants.s"

.section .text                                   // code section
.align 2                                         // align to 4-byte boundary

.global Init_Stack
.type Init_Stack, %function
Init_Stack:
  ldr   r0, =STACK_TOP                           // load stack top
  msr   PSP, r0                                  // set PSP
  ldr   r0, =STACK_LIMIT                         // load stack limit
  msr   MSPLIM, r0                               // set MSP limit
  msr   PSPLIM, r0                               // set PSP limit
  ldr   r0, =STACK_TOP                           // reload stack top
  msr   MSP, r0                                  // set MSP
  bx    lr                                       // return
```

### Line-by-Line Walkthrough

```asm
.global Init_Stack
.type Init_Stack, %function
```

Exports `Init_Stack` as a function symbol.  Called from reset_handler.s as the first initialization step.

```asm
Init_Stack:
  ldr   r0, =STACK_TOP                           // load stack top
```

Loads `0x20082000` into r0.  This is 8 KB past the end of the 512 KB SRAM region.

```asm
  msr   PSP, r0                                  // set PSP
```

Sets the Process Stack Pointer to `STACK_TOP`.  The PSP is used when the processor is in Thread mode with the SPSEL bit set.  Our code always uses Handler mode / MSP, but setting PSP provides a valid value for any mode switch.

```asm
  ldr   r0, =STACK_LIMIT                         // load stack limit
```

Loads `0x2007A000` into r0.  This is 32 KB below STACK_TOP.

```asm
  msr   MSPLIM, r0                               // set MSP limit
  msr   PSPLIM, r0                               // set PSP limit
```

Sets the stack limit registers.  The Cortex-M33 has hardware stack overflow detection: if the stack pointer ever goes below the limit, the processor triggers a UsageFault.  Both MSP and PSP limits are set to the same boundary.

```asm
  ldr   r0, =STACK_TOP                           // reload stack top
  msr   MSP, r0                                  // set MSP
```

Sets the Main Stack Pointer to `STACK_TOP`.  This re-initializes MSP, which was initially set from the vector table.  The reload ensures a clean, known value.

```asm
  bx    lr                                       // return
```

Returns to the caller (Reset_Handler).  This is a leaf function — it uses only r0 (caller-saved) and never calls `bl`, so no push/pop is needed.

### Stack Layout

```
     0x20082000 (STACK_TOP = MSP = PSP)
  +--------------+
  |              |  <- Stack grows downward
  |  32 KB       |
  |  Stack       |
  |  Region      |
  |              |
  +--------------+
     0x2007A000 (STACK_LIMIT = MSPLIM = PSPLIM)
```

### Why Both MSP and PSP?

The Cortex-M33 has two stack pointers:

| Stack Pointer | Used In | Purpose |
|---------------|---------|---------|
| MSP (Main) | Handler mode, default | Exception handling, privileged code |
| PSP (Process) | Thread mode (if configured) | Application code in RTOS scenarios |

Our bare-metal driver always uses MSP.  Setting PSP ensures a valid fallback if the processor ever switches modes.

## Initialization Order

These files are used at the very beginning of execution:

1. Hardware reads vector_table.s → loads MSP from word 0, PC from word 1
2. Execution begins at Reset_Handler
3. Reset_Handler calls Init_Stack → re-initializes MSP/PSP and sets limits
4. All subsequent function calls use the stack initialized here

## Summary

- The vector table is a hardware-defined data structure at a fixed location in flash.
- Word 0 is the initial MSP value; Word 1 is the reset handler address with Thumb bit set.
- Init_Stack configures both stack pointers (MSP/PSP) and their overflow limits.
- The MSPLIM/PSPLIM registers provide hardware stack overflow detection.
- Init_Stack is a leaf function — it uses only r0 and requires no push/pop.
- The stack occupies 32 KB of SRAM, growing downward from 0x20082000.
