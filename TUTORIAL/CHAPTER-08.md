# Chapter 8: Immediate and Upper-Immediate Instructions

## Introduction

Many instructions in our button driver embed a constant value directly inside the instruction word rather than reading it from a register or memory.  These are **immediate** values.  This chapter explains how immediate values are encoded in Thumb-2, what the barrel shifter does, and how the pseudo-instruction `ldr Rd, =value` handles constants that do not fit.

## What Is an Immediate Value?

An immediate is a numeric constant encoded within the instruction itself.  The processor does not need to access memory or another register to obtain it — the value is part of the binary instruction.

```asm
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
```

Here `#(1<<6)` evaluates to `#0x40` at assembly time.  The value 0x40 is embedded in the 32-bit instruction encoding.

## Thumb-2 Modified Immediate Encoding

Thumb-2 data processing instructions reserve 12 bits for the immediate field, but those 12 bits do not represent a plain 12-bit number.  Instead, they encode a **modified immediate constant**:

- **8-bit value** (bits [7:0]) — the base constant
- **4-bit rotation** (bits [11:8]) — selects one of several right-rotations of the 8-bit value within a 32-bit word

This scheme can represent:

| Pattern | Example | Encoding |
|---------|---------|----------|
| 0x000000XX | `#1`, `#0x40`, `#0xFF` | 8-bit value, no rotation |
| 0x00XX00XX | `#0x00410041` | Repeat pattern |
| 0xXX00XX00 | `#0x41004100` | Repeat pattern |
| 0xXXXXXXXX | `#0x41414141` | Repeat pattern |
| Rotated byte | `#0x80000000` | 0x01 rotated right by 2 |

### Examples from Our Driver

```asm
  bic   r5, r5, #(1<<7)                          // #0x80 — fits in 8 bits
  orr   r5, r5, #(1<<6)                          // #0x40 — fits in 8 bits
  orr   r5, r5, #(1<<3)                          // #0x08 — fits in 8 bits
  bic   r5, r5, #(1<<2)                          // #0x04 — fits in 8 bits
  bic   r5, r5, #(1<<8)                          // #0x100 — 0x01 rotated
  orr   r1, r1, #(1<<11)                         // #0x800 — 0x01 rotated
```

All of these fit the modified immediate scheme because they are a single set bit at various positions.

## The Barrel Shifter

The ARM barrel shifter can shift or rotate the immediate value as part of the instruction execution — at no extra cost in cycles.  This is why `#(1<<8)` works even though 0x100 exceeds 8 bits: the assembler encodes it as the byte 0x01 with a left rotation.

The barrel shifter also applies to register operands in shift instructions:

```asm
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
```

This shifts r4 right by 15 positions, moving the GPIO15 input bit to the least significant position.  The shift amount `#15` is an immediate operand to the barrel shifter.

## Constants That Don't Fit: The ldr Pseudo-Instruction

When a constant cannot be encoded as a modified immediate, the assembler uses the **ldr pseudo-instruction**:

```asm
  ldr   r4, =PADS_BANK0_BASE                     // load 0x40038000
```

`0x40038000` cannot be represented by any 8-bit rotation — it has too many non-zero bits.  The assembler handles this by:

1. Placing the 32-bit value `0x40038000` in a **literal pool** — a small data table embedded in the `.text` section
2. Encoding the instruction as `ldr r4, [pc, #offset]` — a PC-relative load

The result is a single memory read from flash, which takes one extra cycle compared to an immediate instruction.

### Literal Pool Placement

The assembler places literal pools after the function or at a convenient point in the code.  The PC-relative offset must be within ±4 KB for Thumb-2 `ldr` instructions.

## Immediate vs. Pseudo-Instruction Usage in Our Driver

| Value | Representation | Encoding |
|-------|---------------|----------|
| `#0` | `cmp r0, #0` | Modified immediate |
| `#1` | `subs r5, r5, #1` | Modified immediate |
| `#0x05` | `orr r5, r5, #0x05` | Modified immediate |
| `#0x1f` | `bic r5, r5, #0x1f` | Modified immediate |
| `#(1<<6)` | `orr r5, r5, #(1<<6)` | Modified immediate |
| `#(1<<31)` | `tst r1, #(1<<31)` | Modified immediate (0x80000000) |
| `=PADS_BANK0_BASE` | `ldr r4, =PADS_BANK0_BASE` | Literal pool |
| `=IO_BANK0_BASE` | `ldr r4, =IO_BANK0_BASE` | Literal pool |
| `=CPACR` | `ldr r0, =CPACR` | Literal pool |
| `=3600` | `ldr r4, =3600` | Literal pool (0xE10 doesn't fit) |
| `=10` | `ldr r0, =10` | Assembler may use `movs r0, #10` |
| `=16` | `ldr r0, =16` | Assembler may use `movs r0, #16` |

Small constants like `=10` and `=16` may be optimized by the assembler into a `movs` instruction instead of a literal pool load, since they fit in a modified immediate.

## The movw/movt Pair

For 32-bit constants, the assembler can also use a two-instruction sequence:

```
movw  r4, #0x8000                                // load lower 16 bits
movt  r4, #0x4003                                // load upper 16 bits
```

This loads `0x40038000` into r4 without needing a literal pool.  The assembler chooses between this and a literal pool based on optimization settings.

## Summary

- Immediate values are constants embedded directly in the instruction encoding.
- Thumb-2 uses a modified immediate scheme: an 8-bit value with a 4-bit rotation field.
- The barrel shifter applies rotations and shifts at no extra cycle cost.
- Constants that do not fit the modified immediate scheme use `ldr Rd, =value`, which the assembler converts to a PC-relative literal pool load.
- Small constants used with `ldr Rd, =value` may be optimized to `movs` instructions.
