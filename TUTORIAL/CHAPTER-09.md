# Chapter 9: Arithmetic and Logic Instructions

## Introduction

The previous chapter explained how constants are encoded.  This chapter covers every arithmetic and logic instruction used in our button driver, explaining what each one does at the bit level and showing exactly where it appears in the source code.

## Arithmetic Instructions

### add — Addition

```asm
  add   r4, r4, r5                               // PADS_BANK0_BASE + PAD_OFFSET
```

Adds the values in two registers and stores the result.  In gpio.s and button.s, this computes the final peripheral register address by adding a base address and an offset.

**Operation:** `r4 = r4 + r5`

If r4 = `0x40038000` (PADS_BANK0_BASE) and r5 = `0x40` (GPIO15 pad offset), then after execution r4 = `0x40038040`.

### sub / subs — Subtraction

```asm
  subs  r5, r5, #1                               // decrement counter
```

Subtracts the immediate value from the register.  The `s` suffix updates the condition flags.  In delay.s this decrements the loop counter and sets the Z flag when it reaches zero.

**Operation:** `r5 = r5 - 1`, update N, Z, C, V

When r5 transitions from 1 to 0, the Z flag is set, causing the following `bne` to fall through and end the loop.

### mul — Multiplication

```asm
  mul   r5, r0, r4                               // MS * 3600
```

Multiplies two registers.  In delay.s, this converts milliseconds to loop iterations: if r0 = 10 (ms) and r4 = 3600 (loops per ms), then r5 = 36,000.

**Operation:** `r5 = r0 × r4`

### cmp — Compare

```asm
  cmp   r0, #0                                   // compare with 0 (pressed)
```

Subtracts the immediate from the register, discards the result, and updates the flags.  In main.s, this tests whether Button_Read returned 0 (pressed) or 1 (released).

**Operation:** Compute `r0 - 0`, set N, Z, C, V, discard result.

If r0 = 0: Z=1, and the following `beq` branches to `.Button_Pressed`.
If r0 = 1: Z=0, and execution falls through to `.Button_Released`.

Also used in delay.s:

```asm
  cmp   r0, #0                                   // if MS is not valid, return
  ble   .Delay_MS_Done                           // branch if less or equal to 0
```

Checks for invalid delay values before entering the loop.

## Logic Instructions

### orr — Bitwise OR

```asm
  orr   r5, r5, #(1<<6)                          // set IE bit (enable input)
```

Sets specific bits without changing others.  ORing with a mask that has a 1 in the target position forces that bit to 1.

**Operation:** `r5 = r5 | 0x40`

Before: `r5 = 0bxxxxxxx0xxxxxxxx` (bit 6 = 0)
After:  `r5 = 0bxxxxxxx1xxxxxxxx` (bit 6 = 1)

Used extensively in button.s, gpio.s, xosc.s, and coprocessor.s to set individual control bits.

### bic — Bit Clear

```asm
  bic   r5, r5, #(1<<7)                          // clear OD bit (disable output)
```

Clears specific bits.  BIC performs AND with the complement of the mask: if the mask bit is 1, the corresponding bit in the result is cleared to 0.

**Operation:** `r5 = r5 & ~0x80`

Before: `r5 = 0bxxxxxxxx xxxxxxxx` (bit 7 unknown)
After:  `r5 = 0b0xxxxxxx xxxxxxxx` (bit 7 = 0)

Also used to clear FUNCSEL before setting it:

```asm
  bic   r5, r5, #0x1f                            // clear FUNCSEL
```

This clears the lower 5 bits (bits [4:0]) to prepare for writing a new function select value.

### and — Bitwise AND

```asm
  and   r0, r4, #1                               // mask to get just bit 0
```

Keeps only the bits where both operands have a 1.  In button.s, after shifting GPIO15's bit to position 0, this masks off all other bits.

**Operation:** `r0 = r4 & 0x01`

If r4 = `0x00000001`: r0 = 1 (button released)
If r4 = `0x00000000`: r0 = 0 (button pressed)

### eor — Exclusive OR

```asm
  eor   r0, r0, #1                               // invert (pressed=1, released=0)
```

Flips specific bits.  XORing with 1 inverts bit 0.  In button.s, this converts the active-low button signal (0=pressed) to an active-high result (1=pressed).

**Operation:** `r0 = r0 ^ 0x01`

If r0 = 0: r0 becomes 1 (pressed)
If r0 = 1: r0 becomes 0 (not pressed)

### tst — Bitwise Test

```asm
  tst   r1, #(1<<31)                             // test STABLE bit
```

Performs AND but discards the result, keeping only the flag update.  In xosc.s, this checks whether the XOSC stable bit is set without modifying r1.

**Operation:** Compute `r1 & 0x80000000`, set Z flag, discard result.

If bit 31 = 0: Z=1, and `beq` branches back to keep waiting.
If bit 31 = 1: Z=0, and `beq` falls through — the oscillator is stable.

Also used in reset.s to check the IO_BANK0 reset-done bit:

```asm
  tst   r1, #(1<<6)                              // test IO_BANK0 reset done
  beq   .GPIO_Subsystem_Reset_Wait               // wait until done
```

## Shift Instructions

### lsr — Logical Shift Right

```asm
  lsr   r4, r4, #15                              // shift bit 15 to bit 0
```

Shifts all bits right by the specified amount, filling vacated positions with zeros.  In button.s, this moves the GPIO15 input state from bit position 15 to bit position 0, where it can be masked with `and r0, r4, #1`.

**Operation:** `r4 = r4 >> 15` (logical, zero-fill)

Before: `r4 = 0bxxxxxxxxxxxxxxxx Bxxxxxxxxxxxxxxx`   (B = GPIO15 state)
After:  `r4 = 0b000000000000000 xxxxxxxxxxxxxxxxB`

## Instruction Summary Table

| Instruction | Operation | Flags | Files |
|-------------|-----------|-------|-------|
| `add Rd, Rn, Rm` | Rd = Rn + Rm | No | gpio.s, button.s |
| `subs Rd, Rn, #imm` | Rd = Rn - imm | N,Z,C,V | delay.s |
| `mul Rd, Rn, Rm` | Rd = Rn × Rm | No | delay.s |
| `cmp Rn, #imm` | Rn - imm (discard) | N,Z,C,V | main.s, delay.s |
| `orr Rd, Rn, #imm` | Rd = Rn OR imm | No | gpio.s, button.s, xosc.s, coprocessor.s |
| `bic Rd, Rn, #imm` | Rd = Rn AND NOT imm | No | gpio.s, button.s, reset.s |
| `and Rd, Rn, #imm` | Rd = Rn AND imm | No | button.s |
| `eor Rd, Rn, #imm` | Rd = Rn XOR imm | No | button.s |
| `tst Rn, #imm` | Rn AND imm (discard) | N,Z,C,V | xosc.s, reset.s |
| `lsr Rd, Rn, #imm` | Rd = Rn >> imm | No | button.s |

## Summary

- Arithmetic instructions (`add`, `subs`, `mul`, `cmp`) perform math on register contents.
- Logic instructions (`orr`, `bic`, `and`, `eor`, `tst`) manipulate individual bits — essential for configuring hardware registers.
- The `s` suffix and dedicated flag-setting instructions (`cmp`, `tst`) update condition flags that drive conditional branches.
- `lsr` shifts bits right to isolate individual GPIO pin states from the 32-bit input register.
- The `eor` instruction in button.s is key to the active-low to active-high conversion for the button signal.
