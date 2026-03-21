# Chapter 4: What Is a Register?

## Introduction

Registers are small, fast storage locations inside the processor.  Every computation the Cortex-M33 performs happens in registers: loading data from memory, performing arithmetic, testing conditions, and storing results back.  This chapter catalogues every register our button driver uses and explains the role each one plays.

## General-Purpose Registers

The Cortex-M33 has 16 general-purpose registers, each 32 bits wide:

| Register | ABI Name | Role in Our Firmware |
|----------|----------|---------------------|
| r0 | a1 | First argument / return value |
| r1 | a2 | Second argument |
| r2 | a3 | Third argument |
| r3 | a4 | Fourth argument |
| r4 | v1 | Callee-saved working register |
| r5 | v2 | Callee-saved working register |
| r6–r11 | v3–v8 | Callee-saved (preserved by push/pop) |
| r12 | ip | Intra-procedure scratch |
| r13 | sp | Stack Pointer |
| r14 | lr | Link Register (return address) |
| r15 | pc | Program Counter |

### Caller-Saved vs Callee-Saved

- **Caller-saved** (r0–r3, r12): any function may overwrite these without saving them.  The caller must assume they are destroyed after a `bl` call.
- **Callee-saved** (r4–r11): a function that uses these must save them on entry and restore them on exit.

Our firmware uses `push {r4-r12, lr}` at the start of most functions and `pop {r4-r12, lr}` at the end, preserving all callee-saved registers plus the return address.

## Special-Purpose Registers

### Stack Pointer (SP / r13)

The stack pointer tracks the top of the stack.  The Cortex-M33 has two stack pointers:

| Register | Name | Purpose |
|----------|------|---------|
| MSP | Main Stack Pointer | Used in handler mode and by default |
| PSP | Process Stack Pointer | Used in thread mode (optional) |

Our Init_Stack function sets both:

```asm
  msr   PSP, r0                                  // set Process Stack Pointer
  msr   MSP, r0                                  // set Main Stack Pointer
```

### Link Register (LR / r14)

When `bl` (branch with link) executes, it stores the return address in LR.  The called function returns with `bx lr`.

```asm
  bl    GPIO_Config                              // LR = address after this instruction
  ...
  bx    lr                                       // return to caller
```

### Program Counter (PC / r15)

The PC holds the address of the next instruction to fetch.  Branches modify the PC:

```asm
  b     .Loop                                    // PC = address of .Loop
```

## Stack Limit Registers

The Cortex-M33 provides hardware stack overflow detection:

| Register | Purpose |
|----------|---------|
| MSPLIM | MSP lower limit — fault if MSP goes below this |
| PSPLIM | PSP lower limit — fault if PSP goes below this |

Our firmware sets both to `STACK_LIMIT` (`0x2007A000`):

```asm
  msr   MSPLIM, r0                               // set MSP limit
  msr   PSPLIM, r0                               // set PSP limit
```

## The Program Status Register (xPSR)

The xPSR combines three registers into one 32-bit value:

| Field | Bits | Purpose |
|-------|------|---------|
| APSR | 31:28 | Condition flags (N, Z, C, V) |
| IPSR | 8:0 | Exception number |
| EPSR | 26:24 | Execution state (Thumb bit) |

The condition flags are set by instructions like `cmp`, `subs`, and `tst`:

```asm
  cmp   r0, #0                                   // set Z flag if r0 == 0
  beq   .Button_Pressed                          // branch if Z == 1
```

| Flag | Name | Set When |
|------|------|----------|
| N | Negative | Result bit 31 is 1 |
| Z | Zero | Result is 0 |
| C | Carry | Unsigned overflow |
| V | Overflow | Signed overflow |

## CPACR — Coprocessor Access Control

The CPACR register at `PPB_BASE + 0x0ED88` controls access to coprocessors.  Our firmware enables CP0 (the SIO GPIO coprocessor):

```asm
  orr   r1, r1, #(1<<1)                          // enable CP0 access bit 1
  orr   r1, r1, #(1<<0)                          // enable CP0 access bit 0
```

Setting bits [1:0] to `0b11` grants full (privileged + unprivileged) access to coprocessor 0.

## Register Usage in Our Button Driver

| Register | Where Used | Value |
|----------|-----------|-------|
| r0 | Function arguments | PAD_OFFSET, CTRL_OFFSET, GPIO number, delay ms |
| r1 | Second argument, register reads | CTRL_OFFSET, register values |
| r2 | Third argument | GPIO number |
| r4 | Working register in GPIO/button functions | Base addresses, bit values |
| r5 | Working register in GPIO/button functions | Register values, GPIO pin |
| sp | Stack operations | Managed by push/pop |
| lr | Return address | Set by bl, used by bx lr |

## Summary

- The Cortex-M33 has 16 general-purpose registers (r0–r15), each 32 bits wide.
- r0–r3 are caller-saved arguments; r4–r11 are callee-saved.
- SP (r13) tracks the stack; LR (r14) holds return addresses; PC (r15) holds the next instruction.
- MSPLIM and PSPLIM provide hardware stack overflow detection.
- The xPSR contains condition flags (N, Z, C, V) set by comparison and arithmetic instructions.
- CPACR controls coprocessor access — we enable CP0 for SIO GPIO operations.
