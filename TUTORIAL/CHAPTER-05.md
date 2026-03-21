# Chapter 5: Load-Store Architecture

## Introduction

The ARM Cortex-M33 is a **load-store architecture**: the only instructions that access memory are loads (`ldr`) and stores (`str`).  All arithmetic, logic, and comparison instructions operate exclusively on registers.  This fundamental design principle shapes every line of our button driver.

## The Load-Store Rule

In a load-store architecture, data flows through a strict pattern:

```
Memory  --ldr-->  Register  --operation-->  Register  --str-->  Memory
```

You cannot add a value directly to a memory location.  Instead:

1. **Load** the value from memory into a register
2. **Modify** the value in the register
3. **Store** the result back to memory

This pattern appears throughout our firmware:

```asm
  ldr   r5, [r4]                                 // load: read pad register
  bic   r5, r5, #(1<<7)                          // modify: clear OD bit
  str   r5, [r4]                                 // store: write back
```

## Load Instructions in Our Firmware

### `ldr Rd, =immediate` — Load Constant

```asm
  ldr   r0, =PADS_BANK0_BASE                     // r0 = 0x40038000
```

This is a pseudo-instruction.  The assembler places the 32-bit constant in a literal pool (a data area near the code) and generates a PC-relative load.  It works for any 32-bit value.

### `ldr Rd, [Rn]` — Load from Address

```asm
  ldr   r1, [r0]                                 // r1 = word at address in r0
```

Reads 4 bytes from the memory address in r0 and places the 32-bit value in r1.  This is how we read peripheral registers.

### `ldr Rd, [Rn, #offset]` — Load with Offset

The Cortex-M33 supports base + offset addressing.  While our firmware typically computes the full address first, the encoding allows:

```asm
  ldr   r1, [r0, #4]                             // r1 = word at r0 + 4
```

## Store Instructions in Our Firmware

### `str Rd, [Rn]` — Store to Address

```asm
  str   r1, [r0]                                 // word at address in r0 = r1
```

Writes the 32-bit value in r1 to the memory address in r0.  This is how we write peripheral registers.

## The Read-Modify-Write Pattern

Most peripheral configuration requires reading a register, changing specific bits, and writing it back.  This three-step pattern is the cornerstone of bare-metal programming:

```asm
  ldr   r5, [r4]                                 // READ:  load current value
  orr   r5, r5, #(1<<6)                          // MODIFY: set IE bit
  str   r5, [r4]                                 // WRITE: store modified value
```

We use this pattern in:
- **gpio.s** — configuring pad and control registers
- **button.s** — configuring button pad with pull-up
- **xosc.s** — enabling the peripheral clock
- **coprocessor.s** — enabling CP0 access

## Push and Pop — Stack Access

`push` and `pop` are specialized load/store instructions that use the stack pointer:

```asm
  push  {r4-r12, lr}                             // store 10 registers to stack
  pop   {r4-r12, lr}                             // load 10 registers from stack
```

`push` decrements SP and stores registers; `pop` loads registers and increments SP.  These are equivalent to multiple `str` and `ldr` instructions with SP update.

## Why Load-Store?

The load-store design simplifies the processor hardware:

1. **Simpler pipeline** — memory access happens in a dedicated stage
2. **Faster registers** — register-to-register operations complete in one cycle
3. **Predictable timing** — only loads and stores can stall on slow memory

For our button driver, this means every peripheral access is explicit: you can see exactly which registers are read and written by looking at the `ldr`/`str` instructions.

## Summary

- The Cortex-M33 is a load-store architecture: only `ldr` and `str` access memory.
- `ldr Rd, =imm` loads constants; `ldr Rd, [Rn]` reads memory; `str Rd, [Rn]` writes memory.
- The read-modify-write pattern (load, bit operation, store) is the standard way to configure peripherals.
- `push` and `pop` are stack-specific load/store operations for saving and restoring registers.
