# Chapter 7: ARM Cortex-M33 ISA Overview

## Introduction

Previous chapters covered generic computer science concepts.  This chapter introduces the specific instruction set architecture (ISA) that the RP2350's ARM Cortex-M33 core implements: ARMv8-M with the Thumb-2 instruction encoding.  Every instruction in our button driver is decoded and executed according to these rules.

## What Is an ISA?

An ISA is the contract between hardware and software.  It defines:

- The set of instructions the processor can execute
- The binary encoding of each instruction
- The registers available to the programmer
- The memory addressing modes
- The behavior of each instruction

The Cortex-M33 implements the ARMv8-M Mainline profile with the Thumb-2 instruction set.

## Thumb-2: Mixed 16-bit and 32-bit Instructions

ARM's Thumb-2 technology encodes instructions in either 16 bits (2 bytes) or 32 bits (4 bytes).  The processor determines the length by examining the first halfword:

| First Halfword Bits [15:11] | Encoding |
|-----------------------------|----------|
| `11101`, `11110`, `11111`   | 32-bit   |
| Anything else               | 16-bit   |

This mixed encoding provides excellent code density: simple operations like `push` and `pop` fit in 16 bits, while complex operations like `mcrr` require 32 bits.

### Examples from Our Driver

**16-bit instruction:**

```asm
  bx    lr                                       // return (16-bit encoding)
```

**32-bit instruction:**

```asm
  mcrr  p0, #4, r2, r4, c4                       // gpioc_bit_oe_put (32-bit)
```

## Instruction Categories

Every instruction in our button driver falls into one of these categories:

### Data Processing

Instructions that operate on registers: arithmetic, logic, shifts, comparisons.

```asm
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
  and   r0, r4, #1                               // mask to get just bit 0
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
  cmp   r0, #0                                   // set flags: Z=1 if r0==0
```

### Memory Access

Instructions that transfer data between registers and memory.

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load PADS_BANK0_BASE address
  ldr   r5, [r4]                                 // read PAD_OFFSET value
  str   r5, [r4]                                 // store value into PAD_OFFSET
```

### Branch

Instructions that alter the flow of execution.

```asm
  beq   .Button_Pressed                          // branch if button pressed (r0==0)
  bne   .Delay_MS_Loop                           // branch until zero
  b     .Loop                                    // loop forever
  bl    GPIO_Config                              // call GPIO_Config
  bx    lr                                       // return
```

### Stack Operations

Instructions that save and restore registers.

```asm
  push  {r4-r12, lr}                             // push registers to the stack
  pop   {r4-r12, lr}                             // pop registers from the stack
```

### Coprocessor

Instructions that communicate with coprocessor 0 (GPIO controller).

```asm
  mcrr  p0, #4, r0, r4, c0                       // gpioc_bit_out_put(GPIO, 1)
  mrc   p0, #0, r4, c0, c8                       // gpioc_lo_in_get - read GPIO inputs
```

### System

Instructions that access special registers and synchronization barriers.

```asm
  msr   MSP, r0                                  // set Main Stack Pointer
  dsb                                            // data synchronization barrier
  isb                                            // instruction synchronization barrier
```

## Condition Flags

Many instructions can optionally update the Application Program Status Register (APSR) flags:

| Flag | Name | Set When |
|------|------|----------|
| N | Negative | Result bit 31 is 1 |
| Z | Zero | Result is 0 |
| C | Carry | Unsigned overflow or shift-out |
| V | Overflow | Signed overflow |

The `s` suffix makes an instruction update flags.  `cmp` and `tst` always update flags.

```asm
  subs  r5, r5, #1                               // decrement counter, update N,Z,C,V
  bne   .Delay_MS_Loop                           // branch if Z==0
```

```asm
  tst   r1, #(1<<31)                             // test STABLE bit, update Z
  beq   .Init_XOSC_Wait                          // branch if Z==1 (bit not set)
```

## Unified Assembly Syntax

Every source file in our project begins with:

```asm
.syntax unified                                  // use unified assembly syntax
.cpu cortex-m33                                  // target Cortex-M33 core
.thumb                                           // use Thumb instruction set
```

- `.syntax unified` tells the assembler to accept the modern unified syntax where the same mnemonics work for both ARM and Thumb states
- `.cpu cortex-m33` selects the Cortex-M33 instruction set
- `.thumb` ensures all instructions are assembled as Thumb-2

The Cortex-M33 only supports Thumb state — it cannot execute classic 32-bit ARM instructions.

## Instruction Encoding Example

Consider the instruction `orr r5, r5, #(1<<6)`.  The assembler encodes it as a 32-bit Thumb-2 instruction:

| Field     | Bits     | Value | Meaning |
|-----------|----------|-------|---------|
| Prefix    | [31:27]  | 11110| 32-bit Thumb-2 marker |
| Op        | [25:21]  | 00010| ORR (immediate) |
| S         | [20]     | 0    | Do not update flags |
| Rn        | [19:16]  | 0101 | Source register r5 |
| Rd        | [11:8]   | 0101 | Destination register r5 |
| Immediate | [7:0]    | 0x40 | Bit 6 = 0x40 |

The processor fetches these 4 bytes, decodes the fields, and executes: r5 = r5 OR 0x40.

## Complete Instruction Map for This Driver

Every instruction used across all source files:

| Instruction | Category | Used In |
|-------------|----------|---------|
| `ldr Rd, =imm` | Pseudo/Load | All files |
| `ldr Rd, [Rn]` | Memory | gpio.s, button.s, xosc.s, reset.s, coprocessor.s |
| `str Rd, [Rn]` | Memory | gpio.s, button.s, xosc.s, reset.s, coprocessor.s |
| `add Rd, Rn, Rm` | Data Processing | gpio.s, button.s |
| `bic Rd, Rn, #imm` | Data Processing | gpio.s, button.s, reset.s |
| `orr Rd, Rn, #imm` | Data Processing | gpio.s, button.s, xosc.s, coprocessor.s |
| `and Rd, Rn, #imm` | Data Processing | button.s |
| `eor Rd, Rn, #imm` | Data Processing | button.s |
| `lsr Rd, Rn, #imm` | Data Processing | button.s |
| `mul Rd, Rn, Rm` | Data Processing | delay.s |
| `subs Rd, Rn, #imm` | Data Processing | delay.s |
| `cmp Rn, #imm` | Data Processing | main.s, delay.s |
| `tst Rn, #imm` | Data Processing | xosc.s, reset.s |
| `push {regs}` | Stack | All function files |
| `pop {regs}` | Stack | All function files |
| `b label` | Branch | main.s |
| `bl label` | Branch | reset_handler.s, main.s, button.s |
| `bx lr` | Branch | All function files |
| `beq label` | Branch | main.s, xosc.s, reset.s, delay.s |
| `bne label` | Branch | delay.s |
| `ble label` | Branch | delay.s |
| `msr reg, Rn` | System | stack.s |
| `mcrr p0, ...` | Coprocessor | gpio.s, button.s |
| `mrc p0, ...` | Coprocessor | button.s |
| `dsb` | System | coprocessor.s |
| `isb` | System | coprocessor.s |

## Summary

- The Cortex-M33 uses Thumb-2 encoding: a mix of 16-bit and 32-bit instructions.
- Instructions fall into six categories: data processing, memory, branch, stack, coprocessor, and system.
- Condition flags (N, Z, C, V) drive conditional branches.
- `.syntax unified`, `.cpu cortex-m33`, and `.thumb` configure the assembler for this core.
- The `mrc` instruction (used in button.s to read GPIO inputs) is unique to this driver and distinguishes it from output-only drivers.
